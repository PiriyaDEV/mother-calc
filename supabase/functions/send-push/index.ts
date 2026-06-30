import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface ServiceAccount {
  client_email: string
  private_key: string
}

// ── JWT helpers for FCM v1 OAuth2 ─────────────────────────────
function base64url(input: string | ArrayBuffer): string {
  const str =
    typeof input === 'string'
      ? btoa(input)
      : btoa(String.fromCharCode(...new Uint8Array(input)))
  return str.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const payload = base64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  )
  const signingInput = `${header}.${payload}`

  // Import RSA private key
  const pemBody = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')
  const der = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0))
  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(signingInput),
  )
  const jwt = `${signingInput}.${base64url(signature)}`

  // Exchange JWT for access token
  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  const { access_token } = await tokenRes.json()
  return access_token
}

// ── Main handler ───────────────────────────────────────────────
Deno.serve(async (req) => {
  // Only allow POST from service-role callers (DB trigger uses service-role key)
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  try {
    const { userId, title, body, data } = await req.json()
    if (!userId || !title) {
      return new Response(JSON.stringify({ error: 'userId and title required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Fetch FCM token from profiles
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', userId)
      .single()

    if (error || !profile?.fcm_token) {
      return new Response(JSON.stringify({ skipped: 'no fcm_token' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Build FCM v1 message
    const serviceAccount: ServiceAccount = JSON.parse(
      Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!,
    )
    const projectId = serviceAccount.client_email.split('@')[1].split('.')[0]
    const accessToken = await getAccessToken(serviceAccount)

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: profile.fcm_token,
            notification: { title, body: body ?? '' },
            data: data ?? {},
            android: { priority: 'high' },
            apns: {
              payload: { aps: { sound: 'default', badge: 1 } },
            },
          },
        }),
      },
    )

    const fcmJson = await fcmRes.json()
    return new Response(JSON.stringify(fcmJson), {
      status: fcmRes.ok ? 200 : 500,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('[send-push] error:', err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
