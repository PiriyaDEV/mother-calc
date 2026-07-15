'use client'

import * as React from 'react'
import { motion } from 'motion/react'
import { cn } from '@/lib/utils/cn'

/** Rotating border glow for active / selected cards. */
export function BorderBeam({ className }: { className?: string }) {
  return (
    <span
      className={cn(
        'pointer-events-none absolute inset-0 rounded-[inherit] [background:linear-gradient(90deg,transparent,transparent),conic-gradient(from_var(--angle),transparent_0%,#3b82f6_10%,transparent_20%)] [background-clip:padding-box,border-box] [background-origin:border-box] [border:2px_solid_transparent]',
        className
      )}
      style={{ animation: 'kidtang-beam 4s linear infinite' }}
    >
      <style>{`
        @property --angle { syntax: '<angle>'; initial-value: 0deg; inherits: false; }
        @keyframes kidtang-beam { to { --angle: 360deg; } }
      `}</style>
    </span>
  )
}

/** Gradient shimmer text for hero / app name. */
export function AnimatedGradientText({
  children,
  className,
}: {
  children: React.ReactNode
  className?: string
}) {
  return (
    <span
      className={cn(
        'inline-block bg-gradient-to-r from-primary-300 via-white to-primary-300 bg-[length:200%_auto] bg-clip-text text-transparent',
        className
      )}
      style={{ animation: 'kidtang-shine 3s linear infinite' }}
    >
      <style>{`@keyframes kidtang-shine { to { background-position: 200% center; } }`}</style>
      {children}
    </span>
  )
}

/** Horizontal scrolling loop for tags. */
export function Marquee({
  children,
  className,
}: {
  children: React.ReactNode
  className?: string
}) {
  return (
    <div className={cn('flex gap-2 overflow-hidden no-scrollbar', className)}>
      <div className="flex shrink-0 gap-2" style={{ animation: 'kidtang-marquee 18s linear infinite' }}>
        {children}
        {children}
      </div>
      <style>{`@keyframes kidtang-marquee { to { transform: translateX(-50%); } }`}</style>
    </div>
  )
}

/** Spotlight-on-hover card. */
export function MagicCard({
  children,
  className,
}: {
  children: React.ReactNode
  className?: string
}) {
  const [pos, setPos] = React.useState({ x: 0, y: 0, active: false })
  return (
    <div
      onMouseMove={(e) => {
        const r = e.currentTarget.getBoundingClientRect()
        setPos({ x: e.clientX - r.left, y: e.clientY - r.top, active: true })
      }}
      onMouseLeave={() => setPos((p) => ({ ...p, active: false }))}
      className={cn('relative overflow-hidden', className)}
    >
      <div
        className="pointer-events-none absolute -inset-px z-0 transition-opacity duration-300"
        style={{
          opacity: pos.active ? 1 : 0,
          background: `radial-gradient(240px circle at ${pos.x}px ${pos.y}px, rgba(59,130,246,0.12), transparent 60%)`,
        }}
      />
      <div className="relative z-10">{children}</div>
    </div>
  )
}

/** Subtle expanding-ripple background for empty states. */
export function Ripple({ className }: { className?: string }) {
  return (
    <div className={cn('pointer-events-none absolute inset-0 flex items-center justify-center', className)}>
      {[0, 1, 2].map((i) => (
        <motion.span
          key={i}
          className="absolute rounded-full border border-primary/20"
          initial={{ width: 40, height: 40, opacity: 0.6 }}
          animate={{ width: 260, height: 260, opacity: 0 }}
          transition={{ duration: 3, repeat: Infinity, delay: i * 1 }}
        />
      ))}
    </div>
  )
}
