'use client'

import { useEffect, useState } from 'react'
import { useRouter } from '@/i18n/navigation'
import { toast } from '@/components/ui/toast'

export default function LineWebReturnPage() {
  const router = useRouter()
  const [status, setStatus] = useState('กำลังเข้าสู่ระบบ...')

  useEffect(() => {
    const url = new URL(window.location.href)
    const code = url.searchParams.get('code')
    const state = url.searchParams.get('state')
    const savedState = sessionStorage.getItem('line_state')

    if (!code || !state || state !== savedState) {
      setStatus('เข้าสู่ระบบไม่สำเร็จ')
      toast('LINE login failed', 'error')
      setTimeout(() => router.push('/login'), 1500)
      return
    }

    ;(async () => {
      const res = await fetch('/api/line-auth', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          code,
          redirectUri: `${window.location.origin}/line-web-return`,
        }),
      })
      if (!res.ok) {
        setStatus('เข้าสู่ระบบไม่สำเร็จ')
        setTimeout(() => router.push('/login'), 1500)
        return
      }
      router.push('/home')
      router.refresh()
    })()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <main className="flex min-h-dvh items-center justify-center">
      <p className="text-sm text-muted-foreground">{status}</p>
    </main>
  )
}
