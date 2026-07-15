import { BottomNav } from '@/components/shared/bottom-nav'
import { PageTransition } from '@/components/shared/page-transition'

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="mx-auto min-h-dvh max-w-md px-4 pb-28 pt-6">
      <PageTransition>{children}</PageTransition>
      <BottomNav />
    </div>
  )
}
