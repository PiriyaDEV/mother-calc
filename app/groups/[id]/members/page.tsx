"use client";

import { useEffect, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import {
  getGroup,
  getGroupMembers,
  inviteMemberByUsername,
  removeGroupMember,
  getMyFriends,
} from "@/lib/db";
import { Group, GroupMember, Friend, Profile } from "@/lib/types";
import {
  IoArrowBack,
  IoPersonAdd,
  IoTrash,
  IoClose,
  IoPeopleOutline,
  IoCheckmarkCircle,
} from "react-icons/io5";

/** Get the "other" profile from a friend row */
function getFriendProfile(friend: Friend, myId: string): Profile | undefined {
  return friend.requester_id === myId ? friend.addressee : friend.requester;
}

function Avatar({ profile, size = 10 }: { profile?: Profile; size?: number }) {
  const initials = (profile?.display_name ?? profile?.username ?? "?").slice(0, 1).toUpperCase();
  if (profile?.avatar_url) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={profile.avatar_url}
        alt={profile.display_name ?? profile.username}
        className={`w-${size} h-${size} rounded-xl object-cover flex-shrink-0`}
      />
    );
  }
  return (
    <div className={`w-${size} h-${size} rounded-xl bg-[#4366f4] flex items-center justify-center text-white font-bold flex-shrink-0 text-sm`}>
      {initials}
    </div>
  );
}

export default function GroupMembersPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { user, loading } = useAuth();

  const [group, setGroup] = useState<Group | null>(null);
  const [members, setMembers] = useState<GroupMember[]>([]);
  const [friends, setFriends] = useState<Friend[]>([]);
  const [dataLoading, setDataLoading] = useState(true);

  const [adding, setAdding] = useState<string | null>(null); // username being added
  const [addError, setAddError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!user || !id) return;
    setDataLoading(true);
    try {
      const [grp, grpMembers, myFriends] = await Promise.all([
        getGroup(id),
        getGroupMembers(id),
        getMyFriends(),
      ]);
      setGroup(grp);
      setMembers(grpMembers);
      setFriends(myFriends);
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

  const handleAddFriend = async (friendProfile: Profile) => {
    setAdding(friendProfile.username);
    setAddError(null);
    try {
      const result = await inviteMemberByUsername(id, friendProfile.username);
      if (result.error) {
        setAddError(result.error);
      } else {
        await loadData();
      }
    } finally {
      setAdding(null);
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
  const memberUserIds = new Set(accepted.map((m) => m.user_id));

  // Friends not yet in the group
  const friendsNotInGroup = friends
    .map((f) => getFriendProfile(f, user!.id))
    .filter((p): p is Profile => !!p && !memberUserIds.has(p.id));

  return (
    <div className="min-h-screen bg-[#f8f9fc] dark:bg-gray-950 flex flex-col">
      {/* Navbar */}
      <nav className="sticky top-14 z-40 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
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

        {/* Add from friends — owner only */}
        {isOwner && (
          <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 flex flex-col gap-3">
            <div className="flex items-center gap-2">
              <IoPersonAdd size={14} className="text-gray-400" />
              <p className="text-sm font-semibold text-gray-900 dark:text-white">เพิ่มสมาชิกจากเพื่อน</p>
            </div>

            {addError && (
              <p className="text-xs text-red-500 bg-red-50 dark:bg-red-900/20 px-3 py-2 rounded-xl">{addError}</p>
            )}

            {friendsNotInGroup.length === 0 ? (
              <div className="flex flex-col items-center gap-2 py-4 text-center">
                <IoPeopleOutline size={24} className="text-gray-300" />
                <p className="text-xs text-gray-400">
                  {friends.length === 0
                    ? "ยังไม่มีเพื่อน — ไปเพิ่มเพื่อนที่หน้าเพื่อนก่อน"
                    : "เพื่อนทุกคนอยู่ในกลุ่มนี้แล้ว"}
                </p>
                {friends.length === 0 && (
                  <button
                    onClick={() => router.push("/friends")}
                    className="text-xs text-[#4366f4] font-semibold hover:underline"
                  >
                    ไปหน้าเพื่อน →
                  </button>
                )}
              </div>
            ) : (
              <div className="flex flex-col gap-2">
                {friendsNotInGroup.map((profile) => (
                  <div
                    key={profile.id}
                    className="flex items-center gap-3 p-3 rounded-xl bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700"
                  >
                    <Avatar profile={profile} size={9} />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                        {profile.display_name ?? `@${profile.username}`}
                      </p>
                      <p className="text-[10px] text-gray-400">@{profile.username}</p>
                    </div>
                    <button
                      onClick={() => handleAddFriend(profile)}
                      disabled={adding === profile.username}
                      className="flex items-center gap-1.5 px-3 py-1.5 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-50 text-white text-xs font-semibold rounded-lg transition-colors"
                    >
                      {adding === profile.username ? (
                        <div className="w-3 h-3 border border-white border-t-transparent rounded-full animate-spin" />
                      ) : (
                        <IoPersonAdd size={12} />
                      )}
                      เพิ่ม
                    </button>
                  </div>
                ))}
              </div>
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
                  <p className="text-xs text-gray-400 flex items-center gap-1">
                    @{member.profile?.username}
                    {member.role === "owner" && (
                      <span className="ml-1 px-1.5 py-0.5 bg-amber-100 dark:bg-amber-900/20 text-amber-600 dark:text-amber-400 rounded-md text-[10px] font-semibold">
                        เจ้าของ
                      </span>
                    )}
                  </p>
                </div>
                {member.user_id === user?.id ? (
                  <IoCheckmarkCircle size={16} className="text-green-400 flex-shrink-0" />
                ) : isOwner ? (
                  <button
                    onClick={() => handleRemove(member)}
                    className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-300 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                  >
                    <IoTrash size={14} />
                  </button>
                ) : null}
              </div>
            ))}
          </div>
        </section>

        {/* Pending section removed — members are added directly now */}
        {members.filter((m) => m.status === "pending").length > 0 && (
          <section>
            <div className="flex items-center gap-2 mb-3">
              <h2 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">
                รอตอบรับ ({members.filter((m) => m.status === "pending").length})
              </h2>
            </div>
            <div className="flex flex-col gap-2">
              {members.filter((m) => m.status === "pending").map((member) => (
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
