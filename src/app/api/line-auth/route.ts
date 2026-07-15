import { NextResponse, type NextRequest } from 'next/server'

/**
 * Exchange a LINE authorization code for tokens and the user's LINE profile.
 *
 * NOTE: Fully bridging a LINE identity into a Supabase session requires the
 * Supabase service-role Admin API (create/lookup the user, then mint a session).
 * This handler performs the LINE OAuth2 token exchange and returns the verified
 * profile; wire the Admin step in once SUPABASE_SERVICE_ROLE_KEY is configured.
 */
export async function POST(request: NextRequest) {
  const { code, redirectUri } = await request.json()
  if (!code || !redirectUri) {
    return NextResponse.json({ error: 'missing_params' }, { status: 400 })
  }

  const channelId = process.env.NEXT_PUBLIC_LINE_CHANNEL_ID
  const channelSecret = process.env.LINE_CHANNEL_SECRET
  if (!channelId || !channelSecret) {
    return NextResponse.json({ error: 'line_not_configured' }, { status: 500 })
  }

  const tokenRes = await fetch('https://api.line.me/oauth2/v2.1/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: redirectUri,
      client_id: channelId,
      client_secret: channelSecret,
    }),
  })

  if (!tokenRes.ok) {
    return NextResponse.json({ error: 'token_exchange_failed' }, { status: 401 })
  }

  const tokens = await tokenRes.json()

  const profileRes = await fetch('https://api.line.me/v2/profile', {
    headers: { Authorization: `Bearer ${tokens.access_token}` },
  })
  const profile = profileRes.ok ? await profileRes.json() : null

  return NextResponse.json({ ok: true, profile })
}
