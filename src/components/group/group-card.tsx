'use client'

import { Link } from '@/i18n/navigation'
import { AvatarCircles } from '@/components/magic/avatar-circles'
import { MagicCard } from '@/components/magic/misc'
import type { Group } from '@/types/group'

export function GroupCard({ group }: { group: Group }) {
  return (
    <Link href={`/groups/${group.id}`} className="block">
      <MagicCard className="card-surface p-4">
        <div className="flex items-center gap-3">
          <span className="text-4xl">{group.emoji}</span>
          <div className="min-w-0 flex-1">
            <p className="truncate font-bold">{group.name}</p>
            {group.description && (
              <p className="truncate text-xs text-muted-foreground">{group.description}</p>
            )}
          </div>
          <AvatarCircles
            avatars={group.members.map((m) => ({
              name: m.displayName ?? m.username ?? '?',
              avatarUrl: m.avatarUrl,
            }))}
            size={30}
          />
        </div>
      </MagicCard>
    </Link>
  )
}
