'use client'

import Image from 'next/image'
import { cn } from '@/lib/utils/cn'

export interface AvatarInfo {
  name: string
  avatarUrl?: string | null
  color?: string
}

interface AvatarCirclesProps {
  avatars: AvatarInfo[]
  max?: number
  size?: number
  className?: string
}

export function AvatarCircles({ avatars, max = 4, size = 36, className }: AvatarCirclesProps) {
  const shown = avatars.slice(0, max)
  const extra = avatars.length - shown.length

  return (
    <div className={cn('flex items-center', className)}>
      {shown.map((a, i) => (
        <div
          key={i}
          className="relative -ml-3 flex items-center justify-center overflow-hidden rounded-full border-2 border-card font-bold text-white first:ml-0"
          style={{
            width: size,
            height: size,
            backgroundColor: a.color ?? '#3b82f6',
            fontSize: size * 0.4,
            zIndex: shown.length - i,
          }}
          title={a.name}
        >
          {a.avatarUrl ? (
            <Image src={a.avatarUrl} alt={a.name} fill className="object-cover" />
          ) : (
            <span>{a.name.charAt(0).toUpperCase()}</span>
          )}
        </div>
      ))}
      {extra > 0 && (
        <div
          className="-ml-3 flex items-center justify-center rounded-full border-2 border-card bg-muted font-bold text-muted-foreground"
          style={{ width: size, height: size, fontSize: size * 0.34 }}
        >
          +{extra}
        </div>
      )}
    </div>
  )
}
