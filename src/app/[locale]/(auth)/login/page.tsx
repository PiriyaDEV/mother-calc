'use client'

import Image from 'next/image'
import { useTranslations } from 'next-intl'
import { createClient } from '@/lib/supabase/client'
import { Meteors } from '@/components/magic/meteors'
import { AnimatedGradientText } from '@/components/magic/misc'
import { toast } from '@/components/ui/toast'

export default function LoginPage() {
  const t = useTranslations('auth')

  async function signInWithGoogle() {
    const supabase = createClient()
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: `${window.location.origin}/api/auth/callback` },
    })
    if (error) toast(error.message, 'error')
  }

  function signInWithLine() {
    const channelId = process.env.NEXT_PUBLIC_LINE_CHANNEL_ID
    const redirectUri = `${window.location.origin}/line-web-return`
    const state = Math.random().toString(36).slice(2)
    sessionStorage.setItem('line_state', state)
    const url =
      `https://access.line.me/oauth2/v2.1/authorize?response_type=code` +
      `&client_id=${channelId}` +
      `&redirect_uri=${encodeURIComponent(redirectUri)}` +
      `&state=${state}&scope=profile%20openid%20email`
    window.location.href = url
  }

  return (
    <main className="relative flex min-h-dvh flex-col items-center justify-center overflow-hidden bg-gradient-to-br from-primary-500 via-primary-600 to-primary-700 px-6 text-white">
      <Meteors number={24} />

      <div className="relative z-10 flex flex-col items-center gap-6">
        <div className="flex h-24 w-24 items-center justify-center rounded-[28px] bg-white/15 backdrop-blur">
          <Image src="/logo.png" alt="Kidtang" width={72} height={72} className="rounded-2xl" />
        </div>

        <div className="text-center">
          <h1 className="text-4xl font-bold">
            <AnimatedGradientText>กิดตัง</AnimatedGradientText>
          </h1>
          <p className="mt-2 text-white/80">{t('tagline')}</p>
        </div>

        <div className="mt-6 flex w-full max-w-xs flex-col gap-3">
          <button
            onClick={signInWithGoogle}
            className="flex h-14 items-center justify-center gap-3 rounded-full bg-white font-bold text-gray-800 shadow-lg transition-transform active:scale-95"
          >
            <Image src="/google-logo.png" alt="" width={22} height={22} />
            {t('sign_in_google')}
          </button>
          <button
            onClick={signInWithLine}
            className="flex h-14 items-center justify-center gap-3 rounded-full bg-[#06C755] font-bold text-white shadow-lg transition-transform active:scale-95"
          >
            <Image src="/line-logo.png" alt="" width={24} height={24} />
            {t('sign_in_line')}
          </button>
        </div>
      </div>
    </main>
  )
}
