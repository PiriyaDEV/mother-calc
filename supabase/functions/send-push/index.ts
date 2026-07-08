// send-push Edge Function
// Triggered by a DB webhook on notifications INSERT.
// Sends FCM push (native apps) and/or Web Push VAPID (browser/PWA).
//
// Required Supabase secrets:
//   FIREBASE_SERVICE_ACCOUNT  — Firebase service account JSON string (for FCM)
//   VAPID_PUBLIC_KEY           — VAPID public key (base64url, from web-push generate-vapid-keys)
//   VAPID_PRIVATE_KEY          — VAPID private key (base64url)
//   VAPID_SUBJECT              — mailto: or https: URI (optional, defaults to mailto:admin@kidtang.app)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface ServiceAccount {
  client_email: string
  private_key: string
}

// ── Shared base64url helper ────────────────────────────────────────────────

function base64url(input: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(input)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

function base64urlStr(input: string): string {
  return btoa(input).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4)
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/')
  return Uint8Array.from(atob(base64), (c) => c.charCodeAt(0))
}

// ── FCM v1 OAuth2 helpers ──────────────────────────────────────────────────

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = base64urlStr(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const payload = base64urlStr(
    JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  )
  const signingInput = `${header}.${payload}`

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

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  const { access_token } = await tokenRes.json()
  return access_token
}

async function sendFcm(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<Response> {
  const serviceAccount: ServiceAccount = JSON.parse(
    Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!,
  )
  const projectId = serviceAccount.client_email.split('@')[1].split('.')[0]
  const accessToken = await getAccessToken(serviceAccount)

  return fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          data,
          android: { priority: 'high' },
          apns: {
            payload: { aps: { sound: 'default', badge: 1 } },
          },
        },
      }),
    },
  )
}

// ── Web Push (VAPID) — RFC 8291 aes128gcm encryption ─────────────────────
// Uses only Web Crypto APIs available in Deno — no npm dependencies needed.

/** Build a VAPID JWT (ES256) for the given push endpoint. */
async function buildVapidJwt(
  endpoint: string,
  vapidPublicKeyB64: string,
  vapidPrivateKeyB64: string,
  subject: string,
): Promise<string> {
  const audience = new URL(endpoint).origin
  const now = Math.floor(Date.now() / 1000)

  const header = base64urlStr(JSON.stringify({ typ: 'JWT', alg: 'ES256' }))
  const payload = base64urlStr(
    JSON.stringify({ aud: audience, exp: now + 43200, sub: subject }),
  )
  const signingInput = `${header}.${payload}`

  const publicKeyBytes = urlBase64ToUint8Array(vapidPublicKeyB64)
  const privateKeyBytes = urlBase64ToUint8Array(vapidPrivateKeyB64)

  // Build JWK from raw P-256 key bytes
  // Public key is uncompressed: 0x04 | x(32) | y(32)
  const x = base64url(publicKeyBytes.slice(1, 33).buffer)
  const y = base64url(publicKeyBytes.slice(33, 65).buffer)
  const d = base64url(privateKeyBytes.buffer)

  const key = await crypto.subtle.importKey(
    'jwk',
    { kty: 'EC', crv: 'P-256', x, y, d },
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign'],
  )

  const sig = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' },
    key,
    new TextEncoder().encode(signingInput),
  )

  return `${signingInput}.${base64url(sig)}`
}

/** Encrypt a Web Push payload using RFC 8291 aes128gcm content encoding. */
async function encryptPayload(
  plaintext: Uint8Array,
  clientPublicKeyB64: string,
  authSecretB64: string,
): Promise<{ ciphertext: Uint8Array; serverPublicKey: Uint8Array; salt: Uint8Array }> {
  // Generate ephemeral server ECDH key pair
  const serverKeyPair = await crypto.subtle.generateKey(
    { name: 'ECDH', namedCurve: 'P-256' },
    true,
    ['deriveBits'],
  )
  const serverPublicKey = new Uint8Array(
    await crypto.subtle.exportKey('raw', serverKeyPair.publicKey),
  )

  // Import client public key
  const clientPublicKey = await crypto.subtle.importKey(
    'raw',
    urlBase64ToUint8Array(clientPublicKeyB64),
    { name: 'ECDH', namedCurve: 'P-256' },
    false,
    [],
  )

  // ECDH shared secret
  const sharedSecret = new Uint8Array(
    await crypto.subtle.deriveBits(
      { name: 'ECDH', public: clientPublicKey },
      serverKeyPair.privateKey,
      256,
    ),
  )

  const authSecret = urlBase64ToUint8Array(authSecretB64)
  const salt = crypto.getRandomValues(new Uint8Array(16))

  // RFC 8291 key derivation
  // ikm = HKDF-Extract(auth_secret, shared_secret) with info = "WebPush: info\0" + clientKey + serverKey
  const enc = new TextEncoder()

  async function hkdfExpand(
    prk: Uint8Array,
    info: Uint8Array,
    length: number,
  ): Promise<Uint8Array> {
    const key = await crypto.subtle.importKey('raw', prk, { name: 'HKDF' }, false, ['deriveBits'])
    return new Uint8Array(
      await crypto.subtle.deriveBits(
        { name: 'HKDF', hash: 'SHA-256', salt: new Uint8Array(32), info },
        key,
        length * 8,
      ),
    )
  }

  async function hkdf(
    salt: Uint8Array,
    ikm: Uint8Array,
    info: Uint8Array,
    length: number,
  ): Promise<Uint8Array> {
    const ikmKey = await crypto.subtle.importKey('raw', ikm, { name: 'HKDF' }, false, ['deriveBits'])
    const prk = new Uint8Array(
      await crypto.subtle.deriveBits(
        { name: 'HKDF', hash: 'SHA-256', salt, info: new Uint8Array(0) },
        ikmKey,
        256,
      ),
    )
    return hkdfExpand(prk, info, length)
  }

  const clientPublicKeyBytes = urlBase64ToUint8Array(clientPublicKeyB64)

  // info for IKM: "WebPush: info\0" + clientPublicKey + serverPublicKey
  const ikmInfo = new Uint8Array([
    ...enc.encode('WebPush: info\0'),
    ...clientPublicKeyBytes,
    ...serverPublicKey,
  ])

  const ikm = await hkdf(authSecret, sharedSecret, ikmInfo, 32)

  // CEK: HKDF(salt, ikm, "Content-Encoding: aes128gcm\0", 16)
  const cekInfo = enc.encode('Content-Encoding: aes128gcm\0')
  const cek = await hkdf(salt, ikm, cekInfo, 16)

  // Nonce: HKDF(salt, ikm, "Content-Encoding: nonce\0", 12)
  const nonceInfo = enc.encode('Content-Encoding: nonce\0')
  const nonce = await hkdf(salt, ikm, nonceInfo, 12)

  const aesKey = await crypto.subtle.importKey('raw', cek, { name: 'AES-GCM' }, false, ['encrypt'])

  // Pad: plaintext + \x02 (delimiter) — minimal padding
  const padded = new Uint8Array(plaintext.length + 1)
  padded.set(plaintext)
  padded[plaintext.length] = 2 // record delimiter

  const encrypted = new Uint8Array(
    await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce }, aesKey, padded),
  )

  // Build aes128gcm content: salt(16) + rs(4, big-endian) + keyid_len(1) + keyid + ciphertext
  const rs = plaintext.length + 1 + 16 // record size
  const header = new Uint8Array(21 + serverPublicKey.length)
  header.set(salt, 0)
  new DataView(header.buffer).setUint32(16, rs, false)
  header[20] = serverPublicKey.length
  header.set(serverPublicKey, 21)

  const ciphertext = new Uint8Array(header.length + encrypted.length)
  ciphertext.set(header)
  ciphertext.set(encrypted, header.length)

  return { ciphertext, serverPublicKey, salt }
}

async function sendWebPush(
  subscriptionJson: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<Response> {
  const vapidPublicKey = Deno.env.get('VAPID_PUBLIC_KEY')!
  const vapidPrivateKey = Deno.env.get('VAPID_PRIVATE_KEY')!
  const vapidSubject = Deno.env.get('VAPID_SUBJECT') ?? 'mailto:admin@kidtang.app'

  const sub = JSON.parse(subscriptionJson) as {
    endpoint: string
    keys: { p256dh: string; auth: string }
  }

  const payloadBytes = new TextEncoder().encode(
    JSON.stringify({ title, body, data, tag: 'kidtang-push' }),
  )

  const { ciphertext } = await encryptPayload(
    payloadBytes,
    sub.keys.p256dh,
    sub.keys.auth,
  )

  const jwt = await buildVapidJwt(sub.endpoint, vapidPublicKey, vapidPrivateKey, vapidSubject)

  return fetch(sub.endpoint, {
    method: 'POST',
    headers: {
      Authorization: `vapid t=${jwt},k=${vapidPublicKey}`,
      'Content-Type': 'application/octet-stream',
      'Content-Encoding': 'aes128gcm',
      TTL: '86400',
    },
    body: ciphertext,
  })
}

// ── Main handler ───────────────────────────────────────────────────────────

Deno.serve(async (req) => {
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

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { data: profile, error } = await supabase
      .from('profiles')
      .select('fcm_token, vapid_subscription')
      .eq('id', userId)
      .single()

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const normalizedData: Record<string, string> = {}
    if (data && typeof data === 'object') {
      for (const [k, v] of Object.entries(data)) {
        normalizedData[k] = String(v)
      }
    }

    const results: Record<string, unknown> = {}

    // Send FCM push to native apps
    if (profile?.fcm_token) {
      try {
        const fcmRes = await sendFcm(profile.fcm_token, title, body ?? '', normalizedData)
        results.fcm = await fcmRes.json()
      } catch (e) {
        console.error('[send-push] FCM error:', e)
        results.fcm = { error: String(e) }
      }
    }

    // Send Web Push to browser/PWA sessions
    if (profile?.vapid_subscription) {
      try {
        const webRes = await sendWebPush(
          profile.vapid_subscription,
          title,
          body ?? '',
          normalizedData,
        )
        results.webPush = { status: webRes.status, ok: webRes.ok }
        if (!webRes.ok) {
          const text = await webRes.text()
          console.error('[send-push] Web Push error response:', webRes.status, text)
          results.webPush = { ...results.webPush as object, body: text }
        }
      } catch (e) {
        console.error('[send-push] Web Push error:', e)
        results.webPush = { error: String(e) }
      }
    }

    if (!profile?.fcm_token && !profile?.vapid_subscription) {
      return new Response(
        JSON.stringify({ skipped: 'no fcm_token or vapid_subscription' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      )
    }

    return new Response(JSON.stringify(results), {
      status: 200,
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
