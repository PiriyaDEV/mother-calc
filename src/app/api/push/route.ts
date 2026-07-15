import { NextResponse, type NextRequest } from 'next/server'
import webpush from 'web-push'
import { createServiceClient } from '@/lib/supabase/server'

function configured() {
  const pub = process.env.VAPID_PUBLIC_KEY
  const priv = process.env.VAPID_PRIVATE_KEY
  if (!pub || !priv) return false
  webpush.setVapidDetails(process.env.VAPID_SUBJECT ?? 'mailto:admin@kidtang.app', pub, priv)
  return true
}

// Send a Web Push notification to a user's stored subscriptions.
export async function POST(request: NextRequest) {
  if (!configured()) {
    return NextResponse.json({ error: 'vapid_not_configured' }, { status: 500 })
  }

  const { userId, title, body, url } = await request.json()
  if (!userId) return NextResponse.json({ error: 'missing_user' }, { status: 400 })

  const supabase = createServiceClient()
  const { data } = await supabase
    .from('profiles')
    .select('vapid_subscription')
    .eq('id', userId)
    .maybeSingle()

  if (!data?.vapid_subscription) {
    return NextResponse.json({ sent: 0 })
  }

  const payload = JSON.stringify({ title: title ?? 'กิดตัง', body: body ?? '', url: url ?? '/' })

  let subscription: webpush.PushSubscription
  try {
    subscription = JSON.parse(data.vapid_subscription) as webpush.PushSubscription
  } catch {
    return NextResponse.json({ error: 'bad_subscription' }, { status: 422 })
  }

  const results = await Promise.allSettled([webpush.sendNotification(subscription, payload)])

  return NextResponse.json({ sent: results.filter((r) => r.status === 'fulfilled').length })
}
