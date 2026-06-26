"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import { getMyNotifications, markNotificationRead, markAllNotificationsRead, respondToGroupInvite, ensureMyProfile } from "@/lib/db";
import { Notification } from "@/lib/types";
import { IoNotificationsOutline, IoCheckmarkDone } from "react-icons/io5";
import BottomNav from "@/components/ui/BottomNav";

export default function FriendsPage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [dataLoading, setDataLoading] = useState(true);
  const [responding, setResponding] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!user) return;
    setDataLoading(true);
    try {
      await ensureMyProfile();
      setNotifications(await getMyNotifications());
    } finally { setDataLoading(false); }
  }, [user]);

  useEffect(() => { if (user) loadData(); }, [user, loadData]);
  useEffect(() => { if (!loading && !user) router.push("/login"); }, [loading, user, router]);

  const unreadCount = notifications.filter((n) => !n.read).length;

  const handleMarkAllRead = async () => {
    await markAllNotificationsRead();
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
  };

  const handleRespond = async (notif: Notification, action: "accepted" | "declined") => {
    setResponding(notif.id);
    try {
      await markNotificationRead(notif.id);
      await respondToGroupInvite(notif.data.group_member_id, action === "accepted");
      setNotifications((prev) => prev.map((n) => n.id === notif.id ? { ...n, read: true } : n));
      if (action === "accepted") router.push(`/groups/${notif.data.group_id}`);
    } finally { setResponding(null); }
  };

  if (loading || (!user && !loading)) {
    return <div className="min-h-screen flex items-center justify-center bg-white dark:bg-gray-950"><div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" /></div>;
  }

  return (
    <div className="min-h-screen bg-[#f4f6fb] dark:bg-gray-950 flex flex-col pb-20">
      <main className="flex-1 max-w-lg mx-auto w-full px-4 py-5">
        {/* Page title */}
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-xl font-bold text-gray-900 dark:text-white">เพื่อน</h1>
            {unreadCount > 0 && <p className="text-xs text-gray-400 mt-0.5">{unreadCount} รายการใหม่</p>}
          </div>
          {unreadCount > 0 && (
            <button onClick={handleMarkAllRead} className="flex items-center gap-1.5 text-xs text-[#4366f4] font-medium hover:underline">
              <IoCheckmarkDone size={14} /> อ่านทั้งหมด
            </button>
          )}
        </div>
        {dataLoading ? (
          <div className="flex items-center justify-center py-16"><div className="w-6 h-6 border-2 border-[#4366f4] border-t-transparent rounded-full animate-spin" /></div>
        ) : notifications.length === 0 ? (
          <div className="flex flex-col items-center gap-4 py-16 text-center">
            <div className="w-16 h-16 rounded-2xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center">
              <IoNotificationsOutline size={28} className="text-gray-400" />
            </div>
            <div>
              <p className="text-sm font-semibold text-gray-700 dark:text-gray-300">ยังไม่มีการแจ้งเตือน</p>
              <p className="text-xs text-gray-400 mt-1">เมื่อมีคนเชิญคุณเข้ากลุ่ม จะแสดงที่นี่</p>
            </div>
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            {notifications.map((notif) => (
              <div
                key={notif.id}
                onClick={() => !notif.read && markNotificationRead(notif.id).then(() =>
                  setNotifications((prev) => prev.map((n) => n.id === notif.id ? { ...n, read: true } : n))
                )}
                className={`p-4 rounded-2xl border transition-all ${notif.read ? "bg-white dark:bg-gray-900 border-gray-100 dark:border-gray-800" : "bg-blue-50 dark:bg-blue-900/10 border-blue-100 dark:border-blue-800/30"}`}
              >
                <div className="flex items-start gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#4366f4] flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                    {(notif.data.invited_by_display_name ?? notif.data.invited_by_username).slice(0, 1).toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-gray-900 dark:text-white">
                      <span className="font-semibold">{notif.data.invited_by_display_name ?? `@${notif.data.invited_by_username}`}</span>{" "}
                      เชิญคุณเข้าร่วมกลุ่ม{" "}
                      <span className="font-semibold text-[#4366f4]">{notif.data.group_name}</span>
                    </p>
                    <p className="text-xs text-gray-400 mt-0.5">
                      {new Date(notif.created_at).toLocaleDateString("th-TH", { day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" })}
                    </p>
                    {!notif.read && notif.type === "group_invite" && (
                      <div className="flex gap-2 mt-3">
                        <button
                          onClick={(e) => { e.stopPropagation(); handleRespond(notif, "accepted"); }}
                          disabled={responding === notif.id}
                          className="flex-1 py-2 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 text-white text-xs font-semibold rounded-xl transition-colors"
                        >
                          {responding === notif.id ? "กำลังดำเนินการ..." : "ยอมรับ"}
                        </button>
                        <button
                          onClick={(e) => { e.stopPropagation(); handleRespond(notif, "declined"); }}
                          disabled={responding === notif.id}
                          className="flex-1 py-2 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 disabled:opacity-60 text-gray-600 dark:text-gray-400 text-xs font-semibold rounded-xl transition-colors"
                        >
                          ปฏิเสธ
                        </button>
                      </div>
                    )}
                  </div>
                  {!notif.read && <div className="w-2 h-2 rounded-full bg-[#4366f4] flex-shrink-0 mt-1" />}
                </div>
              </div>
            ))}
          </div>
        )}
      </main>

      <BottomNav friendBadge={unreadCount} />
    </div>
  );
}
