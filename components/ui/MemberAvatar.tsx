"use client";

import { BillMember } from "@/lib/types";

interface MemberAvatarProps {
  member: BillMember;
  size?: number; // px, default 36
  /** Override background color (e.g. for selected state) */
  bgOverride?: string;
  className?: string;
}

/**
 * Renders a member avatar:
 * - If the member has a linked profile with avatar_url → shows the image
 * - Otherwise → shows colored circle with first letter initial
 */
export default function MemberAvatar({ member, size = 36, bgOverride, className = "" }: MemberAvatarProps) {
  const avatarUrl = member.profile?.avatar_url ?? null;
  const bg = bgOverride ?? member.color;
  const fontSize = Math.max(9, Math.round(size * 0.35));

  return (
    <div
      className={`rounded-full flex items-center justify-center flex-shrink-0 overflow-hidden ${className}`}
      style={{ width: size, height: size, backgroundColor: bg, minWidth: size }}
    >
      {avatarUrl ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={avatarUrl}
          alt={member.name}
          className="w-full h-full object-cover"
        />
      ) : (
        <span
          className="text-white font-bold leading-none select-none"
          style={{ fontSize }}
        >
          {member.name.charAt(0).toUpperCase()}
        </span>
      )}
    </div>
  );
}
