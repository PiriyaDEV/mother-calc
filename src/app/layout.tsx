import type { Metadata, Viewport } from 'next'
import { Noto_Sans_Thai, Anuphan } from 'next/font/google'
import './globals.css'

const notoSansThai = Noto_Sans_Thai({
  subsets: ['thai', 'latin'],
  variable: '--font-noto-sans-thai',
  display: 'swap',
})

const anuphan = Anuphan({
  subsets: ['thai', 'latin'],
  weight: ['500', '600', '700'],
  variable: '--font-anuphan',
  display: 'swap',
})

export const metadata: Metadata = {
  title: 'กิดตัง · Kidtang',
  description: 'แบ่งบิล จ่ายง่าย ไม่ต้องทวง',
  icons: { icon: '/logo.png' },
}

export const viewport: Viewport = {
  themeColor: '#3b82f6',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html suppressHydrationWarning>
      <body className={`${notoSansThai.variable} ${anuphan.variable} font-sans`}>
        {children}
      </body>
    </html>
  )
}
