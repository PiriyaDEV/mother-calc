'use client'

import { useMemo } from 'react'
import { cn } from '@/lib/utils/cn'

/** Falling-particle background decoration. Pure CSS animation, no deps. */
export function Meteors({ number = 20, className }: { number?: number; className?: string }) {
  const meteors = useMemo(
    () =>
      Array.from({ length: number }, (_, i) => ({
        left: `${(i / number) * 100 + Math.floor((i * 37) % 10)}%`,
        delay: `${(i % 5) * 0.6}s`,
        duration: `${3 + (i % 4)}s`,
      })),
    [number]
  )

  return (
    <div className={cn('pointer-events-none absolute inset-0 overflow-hidden', className)}>
      {meteors.map((m, i) => (
        <span
          key={i}
          className="absolute top-0 h-0.5 w-0.5 rotate-[215deg] rounded-full bg-white shadow-[0_0_0_1px_#ffffff10]"
          style={{
            left: m.left,
            animation: `kidtang-meteor ${m.duration} linear ${m.delay} infinite`,
          }}
        >
          <span className="absolute top-1/2 -z-10 h-px w-16 -translate-y-1/2 bg-gradient-to-r from-white/60 to-transparent" />
        </span>
      ))}
      <style>{`
        @keyframes kidtang-meteor {
          0% { transform: translateY(0) translateX(0) rotate(215deg); opacity: 1; }
          70% { opacity: 1; }
          100% { transform: translateY(500px) translateX(-500px) rotate(215deg); opacity: 0; }
        }
      `}</style>
    </div>
  )
}
