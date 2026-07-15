'use client'

import * as React from 'react'
import { cn } from '@/lib/utils/cn'

export const ShimmerButton = React.forwardRef<
  HTMLButtonElement,
  React.ButtonHTMLAttributes<HTMLButtonElement>
>(({ className, children, ...props }, ref) => (
  <button
    ref={ref}
    className={cn(
      'group relative inline-flex items-center justify-center gap-2 overflow-hidden rounded-2xl bg-gradient-to-br from-primary-500 to-primary-600 px-6 py-3 font-bold text-white shadow-lg transition-transform active:scale-95',
      className
    )}
    {...props}
  >
    <span className="pointer-events-none absolute inset-0 -translate-x-full bg-gradient-to-r from-transparent via-white/30 to-transparent transition-transform duration-1000 group-hover:translate-x-full" />
    <span className="relative z-10 inline-flex items-center gap-2">{children}</span>
  </button>
))
ShimmerButton.displayName = 'ShimmerButton'
