"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import {
  getMyFriends,
  getPendingFriendRequests,
  sendFriendRequest,
  acceptFriendRequest,
  declineFriendRequest,
  removeFriend,
  ensureMyProfile,
} from "@/lib/db";
import { Friend, Profile } from "@/lib/types";
import {
  IoPersonAddOutline,
  IoCheckmarkOutline,
  IoCloseOutline,
  IoPeopleOutline,
  IoSearchOutline,
  IoTrashOutline,
  IoPersonOutline,
} from "react-icons/io5";
import BottomNav from "@/components/ui/BottomNav";

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
        className={`w-${size} h-${size} rounded-2xl object-cover flex-shrink-0`}
      />
    );
  }
  return (
    <div className={`w-${size} h-${size} rounded-2xl bg-[#286bfe] flex items-center justify-center text-white font-bold flex-shrink-0 text-sm`}>
      {initials}
    </div>
  );
}

export default function FriendsPage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  const [friends, setFriends] = useState<Friend[]>([]);
  const [requests, setRequests] = useState<Friend[]>([]);
  const [dataLoading, setDataLoading] = useState(true);

  // Add friend modal
  const [showAdd, setShowAdd] = useState(false);
  const [addUsername, setAddUsername] = useState("");
  const [addLoading, setAddLoading] = useState(false);
  const [addError, setAddError] = useState("");
  const [addSuccess, setAddSuccess] = useState("");

  // Responding to requests
  const [responding, setResponding] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!user) return;
    setDataLoading(true);
    try {
      await ensureMyProfile();
      const [f, r] = await Promise.all([getMyFriends(), getPendingFriendRequests()]);
      setFriends(f);
      setRequests(r);
    } finally {
      setDataLoading(false);
    }
  }, [user]);

  useEffect(() => { if (user) loadData(); }, [user, loadData]);
  useEffect(() => { if (!loading && !user) router.push("/login"); }, [loading, user, router]);

  const handleSendRequest = async () => {
    if (!addUsername.trim()) return;
    setAddLoading(true);
    setAddError("");
    setAddSuccess("");
    const result = await sendFriendRequest(addUsername.trim());
    setAddLoading(false);
    if (result.error) {
      setAddError(result.error);
    } else {
      setAddSuccess(`ส่งคำขอเป็นเพื่อนไปยัง @${addUsername.trim()} แล้ว!`);
      setAddUsername("");
    }
  };

  const handleAccept = async (friend: Friend) => {
    setResponding(friend.id);
    try {
      await acceptFriendRequest(friend.id);
      setRequests((prev) => prev.filter((r) => r.id !== friend.id));
      await loadData(); // reload to get full profile data
    } finally {
      setResponding(null);
    }
  };

  const handleDecline = async (friend: Friend) => {
    setResponding(friend.id);
    try {
      await declineFriendRequest(friend.id);
      setRequests((prev) => prev.filter((r) => r.id !== friend.id));
    } finally {
      setResponding(null);
    }
  };

  const handleRemove = async (friend: Friend) => {
    await removeFriend(friend.id);
    setFriends((prev) => prev.filter((f) => f.id !== friend.id));
  };

  if (loading || (!user && !loading)) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white dark:bg-gray-950">
        <div className="w-8 h-8 rounded-full border-2 border-[#286bfe] border-t-transparent animate-spin" />
      </div>
    );
  }

  const myId = user!.id;

  return (
    <div className="min-h-screen bg-[#f4f6fb] dark:bg-gray-950 flex flex-col pb-20">
      <main className="flex-1 max-w-lg mx-auto w-full px-4 py-5 flex flex-col gap-5">

        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900 dark:text-white">เพื่อน</h1>
            <p className="text-xs text-gray-400 mt-0.5">{friends.length} เพื่อน{requests.length > 0 ? ` · ${requests.length} คำขอใหม่` : ""}</p>
          </div>
          <button
            onClick={() => { setShowAdd(true); setAddError(""); setAddSuccess(""); setAddUsername(""); }}
            className="flex items-center gap-1.5 px-3 py-2 bg-[#286bfe] hover:bg-[#1a5ce0] text-white text-xs font-semibold rounded-xl transition-colors"
          >
            <IoPersonAddOutline size={14} />
            เพิ่มเพื่อน
          </button>
        </div>

        {/* Add friend modal */}
        {showAdd && (
          <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 flex flex-col gap-3">
            <div className="flex items-center justify-between">
              <p className="text-sm font-bold text-gray-900 dark:text-white">เพิ่มเพื่อนใหม่</p>
              <button onClick={() => setShowAdd(false)} className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <IoCloseOutline size={18} />
              </button>
            </div>
            <div className="flex gap-2">
              <div className="relative flex-1">
                <IoSearchOutline size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="@username"
                  value={addUsername}
                  onChange={(e) => { setAddUsername(e.target.value.replace(/^@/, "")); setAddError(""); setAddSuccess(""); }}
                  onKeyDown={(e) => e.key === "Enter" && handleSendRequest()}
                  className="w-full pl-8 pr-3 py-2.5 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-xl text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#286bfe]/30 focus:border-[#286bfe] transition-all"
                />
              </div>
              <button
                onClick={handleSendRequest}
                disabled={addLoading || !addUsername.trim()}
                className="px-4 py-2.5 bg-[#286bfe] hover:bg-[#1a5ce0] disabled:opacity-50 text-white text-xs font-semibold rounded-xl transition-colors"
              >
                {addLoading ? "..." : "ส่ง"}
              </button>
            </div>
            {addError && (
              <p className="text-xs text-red-500 bg-red-50 dark:bg-red-900/20 px-3 py-2 rounded-xl">{addError}</p>
            )}
            {addSuccess && (
              <p className="text-xs text-green-600 bg-green-50 dark:bg-green-900/20 px-3 py-2 rounded-xl flex items-center gap-1.5">
                <IoCheckmarkOutline size={14} /> {addSuccess}
              </p>
            )}
          </div>
        )}

        {dataLoading ? (
          <div className="flex items-center justify-center py-16">
            <div className="w-6 h-6 border-2 border-[#286bfe] border-t-transparent rounded-full animate-spin" />
          </div>
        ) : (
          <>
            {/* Pending requests */}
            {requests.length > 0 && (
              <div className="flex flex-col gap-3">
                <div className="flex items-center gap-2">
                  <h2 className="text-sm font-bold text-gray-900 dark:text-white">คำขอเป็นเพื่อน</h2>
                  <span className="px-2 py-0.5 bg-[#286bfe] text-white text-[10px] font-bold rounded-full">{requests.length}</span>
                </div>
                <div className="flex flex-col gap-2">
                  {requests.map((req) => {
                    const profile = req.requester;
                    return (
                      <div key={req.id} className="bg-white dark:bg-gray-900 rounded-2xl border border-blue-100 dark:border-blue-800/30 p-4 flex items-center gap-3">
                        <Avatar profile={profile} size={10} />
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                            {profile?.display_name ?? `@${profile?.username}`}
                          </p>
                          <p className="text-[10px] text-gray-400">@{profile?.username}</p>
                        </div>
                        <div className="flex gap-2 flex-shrink-0">
                          <button
                            onClick={() => handleAccept(req)}
                            disabled={responding === req.id}
                            className="w-8 h-8 rounded-xl bg-[#286bfe] hover:bg-[#1a5ce0] disabled:opacity-50 flex items-center justify-center text-white transition-colors"
                          >
                            <IoCheckmarkOutline size={16} />
                          </button>
                          <button
                            onClick={() => handleDecline(req)}
                            disabled={responding === req.id}
                            className="w-8 h-8 rounded-xl bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 disabled:opacity-50 flex items-center justify-center text-gray-500 transition-colors"
                          >
                            <IoCloseOutline size={16} />
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Friends list */}
            <div className="flex flex-col gap-3">
              <h2 className="text-sm font-bold text-gray-900 dark:text-white">รายชื่อเพื่อน</h2>
              {friends.length === 0 ? (
                <div className="flex flex-col items-center gap-4 py-12 text-center">
                  <div className="w-16 h-16 rounded-2xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center">
                    <IoPeopleOutline size={28} className="text-[#286bfe]" />
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-gray-700 dark:text-gray-300">ยังไม่มีเพื่อน</p>
                    <p className="text-xs text-gray-400 mt-1">เพิ่มเพื่อนด้วย @username เพื่อเพิ่มเข้ากลุ่มได้</p>
                  </div>
                  <button
                    onClick={() => { setShowAdd(true); setAddError(""); setAddSuccess(""); setAddUsername(""); }}
                    className="px-4 py-2 bg-[#286bfe] text-white text-xs font-semibold rounded-xl"
                  >
                    เพิ่มเพื่อนคนแรก
                  </button>
                </div>
              ) : (
                <div className="flex flex-col gap-2">
                  {friends.map((friend) => {
                    const profile = getFriendProfile(friend, myId);
                    return (
                      <div key={friend.id} className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 flex items-center gap-3">
                        <Avatar profile={profile} size={10} />
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                            {profile?.display_name ?? `@${profile?.username}`}
                          </p>
                          <p className="text-[10px] text-gray-400">@{profile?.username}</p>
                        </div>
                        <div className="flex items-center gap-2 flex-shrink-0">
                          <span className="px-2 py-1 bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400 text-[10px] font-semibold rounded-lg flex items-center gap-1">
                            <IoPersonOutline size={10} /> เพื่อน
                          </span>
                          <button
                            onClick={() => handleRemove(friend)}
                            className="w-7 h-7 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-red-50 dark:hover:bg-red-900/20 hover:text-red-500 flex items-center justify-center text-gray-400 transition-colors"
                          >
                            <IoTrashOutline size={13} />
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </>
        )}
      </main>

      <BottomNav friendBadge={requests.length} />
    </div>
  );
}
