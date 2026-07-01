// FIX-05 (see docs/FIXES.md) — NOT wired into the client yet.
//
// Replaces the fake email+deterministic-password pattern still used by
// AuthProvider._finishLineSignIn (lib/providers/auth_provider.dart). That
// pattern derives both the Supabase email and password from the LINE
// userId alone, so anyone who learns a user's LINE userId can compute
// their password and sign in as them directly against Supabase's public
// /auth/v1/token endpoint — no LINE involvement required. This function
// verifies the caller actually holds a live, LINE-issued access token for
// this channel before ever touching Supabase auth, and never sets a
// client-derivable password.
//
// Deploy with:
//   supabase functions deploy line-auth
// No extra secrets needed beyond what Supabase Edge Functions already
// inject automatically (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY). Also set:
//   supabase secrets set LINE_CHANNEL_ID=<your channel id>
//
// Client-side integration (once tested — see FIXES.md FIX-05):
//   final res = await http.post(Uri.parse('$supabaseUrl/functions/v1/line-auth'),
//       headers: {'Authorization': 'Bearer $anonKey', 'Content-Type': 'application/json'},
//       body: jsonEncode({'accessToken': lineAccessToken}));
//   final json = jsonDecode(res.body);
//   await supabase.auth.verifyOTP(
//     email: json['email'], token: json['hashedToken'], type: OtpType.magiclink);

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const LINE_CHANNEL_ID = Deno.env.get('LINE_CHANNEL_ID') ?? ''

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  try {
    const { accessToken } = await req.json()
    if (!accessToken) {
      return json({ error: 'accessToken required' }, 400)
    }

    // 1. Confirm the token is live and was issued by LINE for THIS
    //    channel — without this check, any valid LINE access token from
    //    any app could be replayed here to impersonate its owner.
    const verifyRes = await fetch(
      `https://api.line.me/oauth2/v2.1/verify?access_token=${encodeURIComponent(accessToken)}`,
    )
    if (!verifyRes.ok) {
      return json({ error: 'Invalid or expired LINE access token' }, 401)
    }
    const verifyJson = await verifyRes.json()
    if (LINE_CHANNEL_ID && verifyJson.client_id !== LINE_CHANNEL_ID) {
      return json({ error: 'Access token was not issued for this app' }, 401)
    }

    // 2. Fetch the profile using that same verified token — the userId
    //    here is authoritative, straight from LINE, not caller-supplied.
    const profileRes = await fetch('https://api.line.me/v2/profile', {
      headers: { Authorization: `Bearer ${accessToken}` },
    })
    if (!profileRes.ok) {
      return json({ error: 'Failed to fetch LINE profile' }, 401)
    }
    const lineProfile = await profileRes.json()
    const lineUserId: string = lineProfile.userId
    const displayName: string = lineProfile.displayName ?? 'LINE User'
    const pictureUrl: string | undefined = lineProfile.pictureUrl

    // 3. Find-or-create the Supabase auth user via the admin API
    //    (service-role key, never exposed to the client) and hand back a
    //    one-time magic-link token — no password ever set or transmitted.
    //    The email stays a deterministic lookup key, same as before; that
    //    part was never the vulnerability, the guessable password was.
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )
    const email = `line_${lineUserId}@kidtang.app`

    const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
      type: 'magiclink',
      email,
      options: {
        data: {
          display_name: displayName,
          avatar_url: pictureUrl,
          line_user_id: lineUserId,
          provider: 'line',
        },
      },
    })
    if (linkError || !linkData) {
      return json({ error: linkError?.message ?? 'Failed to create session' }, 500)
    }

    const userId = linkData.user.id

    // Only set username/display_name for brand-new accounts — existing
    // users keep whatever they customised during onboarding, and just
    // get avatar_url refreshed in case their LINE picture changed.
    const { data: existingProfile } = await supabase
      .from('profiles')
      .select('id')
      .eq('id', userId)
      .maybeSingle()

    if (!existingProfile) {
      const sanitized = displayName
        .trim()
        .replace(/\s+/g, '_')
        .replace(/[^\w฀-๿]/g, '')
      const usernameBase = sanitized || `line_${lineUserId.slice(0, 8)}`
      await supabase.from('profiles').upsert(
        {
          id: userId,
          username: usernameBase,
          display_name: displayName,
          avatar_url: pictureUrl,
        },
        { onConflict: 'id' },
      )
    } else {
      await supabase.from('profiles').update({ avatar_url: pictureUrl }).eq('id', userId)
    }

    return json({ email, hashedToken: linkData.properties.hashed_token })
  } catch (err) {
    console.error('[line-auth] error:', err)
    return json({ error: String(err) }, 500)
  }
})
