'use client'

import { useMemo } from 'react'

const COLORS = ['#3b82f6', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6']

/** Lightweight burst confetti. Mount when a celebration should fire. */
export function Confetti({ count = 60 }: { count?: number }) {
  const pieces = useMemo(
    () =>
      Array.from({ length: count }, (_, i) => ({
        left: `${(i * 53) % 100}%`,
        bg: COLORS[i % COLORS.length],
        delay: `${(i % 10) * 0.05}s`,
        duration: `${1.6 + ((i * 7) % 10) / 10}s`,
        rotate: `${(i * 47) % 360}deg`,
      })),
    [count]
  )

  return (
    <div className="pointer-events-none fixed inset-0 z-[90] overflow-hidden">
      {pieces.map((p, i) => (
        <span
          key={i}
          className="absolute top-[-10px] h-2.5 w-2 rounded-sm"
          style={{
            left: p.left,
            backgroundColor: p.bg,
            transform: `rotate(${p.rotate})`,
            animation: `kidtang-confetti ${p.duration} ease-in ${p.delay} forwards`,
          }}
        />
      ))}
      <style>{`
        @keyframes kidtang-confetti {
          0% { transform: translateY(0) rotate(0deg); opacity: 1; }
          100% { transform: translateY(100vh) rotate(720deg); opacity: 0; }
        }
      `}</style>
    </div>
  )
}
