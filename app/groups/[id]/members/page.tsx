"use client";

import { useEffect, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import {
  getGroup,
  getGroupMembers,
  inviteMemberByUsername,
  removeGroupMember,
} from "@/lib/db";
import { Group, GroupMember } from "@/lib/types";
import {
  IoArrowBack,
  IoPersonAdd,
  IoTrash,
  IoClose,
  IoCheckmark,
  IoPeopleOutline,
  IoTimeOutline,
} from "react-icons/io5";

export default function GroupMembersPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { user, loading } = useAuth();

  const [group, setGroup] = useState<Group | null>(null);
  const [members, setMembers] = useState<GroupMember[]>([]);
  const [dataLoading, setDataLoading] = useState(true);

  const [inviteUsername, setInviteUsername] = useState("");
  const [inviting, setInviting] = useState(false);
  const [inviteError, setInviteError] = useState<string | null>(null);
  const [inviteSuccess, setInviteSuccess] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!user || !id) return;
    setDataLoading(true);
    try {
      const [grp, grpMembers] = await Promise.all([
        getGroup(id),
        getGroupMembers(id),
      ]);
      setGroup(grp);
      setMembers(grpMembers);
    } finally {
      setDataLoading(false);
    }
  }, [user, id]);

  useEffect(() => {
    if (!loading && !user) router.push("/login");
  }, [loading, user, router]);

  useEffect(() => {
    if (user) loadData();
  }, [user, loadData]);

  const handleInvite = async () => {
    const username = inviteUsername.trim().replace(/^@/, "");
    if (!username) return;
    setInviting(true);
    setInviteError(null);
    setInviteSuccess(null);
    try {
      const result = await inviteMemberByUsername(id, username);
      if (result.error) {
        setInviteError(result.error);
      } else {
        setInviteSuccess(`ส่งคำเชิญถึง @${username} แล้ว`);
        setInviteUsername("");
        await loadData();
        setTimeout(() => setInviteSuccess(null), 3000);
      }
    } finally {
      setInviting(false);
    }
  };

  const handleRemove = async (member: GroupMember) => {
    const name = member.profile?.display_name ?? member.profile?.username ?? "สมาชิก";
    if (!confirm(`ลบ ${name} ออกจากกลุ่ม?`)) return;
    await removeGroupMember(member.id);
    setMembers((prev) => prev.filter((m) => m.id !== member.id));
  };

  if (loading || dataLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f8f9fc] dark:bg-gray-950">
        <div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" />
      </div>
    );
  }

  const isOwner = group?.owner_id === user?.id;
  const accepted = members.filter((m) => m.status === "accepted");
  const pending = members.filter((m) => m.status === "pending");

  return (
    <div className="min-h-screen bg-[#f8f9fc] dark:bg-gray-950 flex flex-col">
      {/* Navbar */}
      <nav className="sticky top-0 z-40 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
        <div className="max-w-2xl mx-auto px-5 h-14 flex items-center gap-3">
          <button
            onClick={() => router.push(`/groups/${id}`)}
            className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
          >
            <IoArrowBack size={18} />
          </button>
          <div>
            <h1 className="text-sm font-bold text-gray-900 dark:text-white">สมาชิก</h1>
            {group?.name && (
              <p className="text-xs text-gray-400 leading-tight">{group.name}</p>
            )}
          </div>
        </div>
      </nav>

      <main className="flex-1 max-w-2xl mx-auto w-full px-5 py-5 flex flex-col gap-5">
        {/* Invite section — owner only */}
        {isOwner && (
          <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4">
            <p className="text-sm font-semibold text-gray-900 dark:text-white mb-3">เชิญสมาชิก</p>
            <div className="flex gap-2">
              <div className="flex-1 flex items-center gap-2 px-3 py-2.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                <span className="text-sm text-gray-400">@</span>
                <input
                  value={inviteUsername}
                  onChange={(e) => setInviteUsername(e.target.value.toLowerCase())}
                  onKeyDown={(e) => e.key === "Enter" && handleInvite()}
                  placeholder="username"
                  className="flex-1 text-sm bg-transparent outline-none text-gray-900 dark:text-white placeholder-gray-400"
                />
                {inviteUsername && (
                  <button onClick={() => setInviteUsername("")} className="text-gray-400 hover:text-gray-600">
                    <IoClose size={14} />
                  </button>
                )}
              </div>
              <button
                onClick={handleInvite}
                disabled={inviting || !inviteUsername.trim()}
                className="px-4 py-2.5 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-50 text-white text-sm font-semibold rounded-xl transition-colors flex items-center gap-1.5"
              >
                <IoPersonAdd size={14} />
                {inviting ? "..." : "เชิญ"}
              </button>
            </div>
            {inviteError && (
              <p className="text-xs text-red-500 mt-2">{inviteError}</p>
            )}
            {inviteSuccess && (
              <p className="text-xs text-green-600 dark:text-green-400 mt-2 flex items-center gap-1">
                <IoCheckmark size={12} /> {inviteSuccess}
              </p>
            )}
          </div>
        )}

        {/* Accepted members */}
        <section>
          <div className="flex items-center gap-2 mb-3">
            <IoPeopleOutline size={14} className="text-gray-400" />
            <h2 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">
              สมาชิก ({accepted.length})
            </h2>
          </div>
          <div className="flex flex-col gap-2">
            {accepted.map((member) => (
              <div
                key={member.id}
                className="flex items-center gap-3 p-3 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800"
              >
                <div className="w-10 h-10 rounded-xl bg-[#4366f4] flex items-center justify-center text-white text-sm font-bold overflow-hidden flex-shrink-0">
                  {member.profile?.avatar_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={member.profile.avatar_url} alt="" className="w-full h-full object-cover" />
                  ) : (
                    (member.profile?.display_name ?? member.profile?.username ?? "?")
                      .slice(0, 1)
                      .toUpperCase()
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                    {member.profile?.display_name ?? `@${member.profile?.username}`}
                  </p>
                  <p className="text-xs text-gray-400">
                    @{member.profile?.username}
                    {member.role === "owner" && (
                      <span className="ml-1.5 px-1.5 py-0.5 bg-amber-100 dark:bg-amber-900/20 text-amber-600 dark:text-amber-400 rounded-md text-[10px] font-semibold">
                        เจ้าของ
                      </span>
                    )}
                  </p>
                </div>
                {isOwner && member.user_id !== user?.id && (
                  <button
                    onClick={() => handleRemove(member)}
                    className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-300 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                  >
                    <IoTrash size={14} />
                  </button>
                )}
              </div>
            ))}
          </div>
        </section>

        {/* Pending invites */}
        {pending.length > 0 && (
          <section>
            <div className="flex items-center gap-2 mb-3">
              <IoTimeOutline size={14} className="text-gray-400" />
              <h2 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">
                รอตอบรับ ({pending.length})
              </h2>
            </div>
            <div className="flex flex-col gap-2">
              {pending.map((member) => (
                <div
                  key={member.id}
                  className="flex items-center gap-3 p-3 bg-white dark:bg-gray-900 rounded-2xl border border-dashed border-gray-200 dark:border-gray-700 opacity-70"
                >
                  <div className="w-10 h-10 rounded-xl bg-gray-200 dark:bg-gray-700 flex items-center justify-center text-gray-500 text-sm font-bold flex-shrink-0">
                    {(member.profile?.display_name ?? member.profile?.username ?? "?")
                      .slice(0, 1)
                      .toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-gray-700 dark:text-gray-300 truncate">
                      {member.profile?.display_name ?? `@${member.profile?.username}`}
                    </p>
                    <p className="text-xs text-gray-400">รอการตอบรับ</p>
                  </div>
                  {isOwner && (
                    <button
                      onClick={() => handleRemove(member)}
                      className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-300 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                    >
                      <IoClose size={14} />
                    </button>
                  )}
                </div>
              ))}
            </div>
          </section>
        )}
      </main>
    </div>
  );
}
