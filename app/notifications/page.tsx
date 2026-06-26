"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import {
  getMyNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  respondToGroupInvite,
} from "@/lib/db";
import { Notification } from "@/lib/types";
import { IoArrowBack, IoCheckmarkDone, IoNotificationsOutline } from "react-icons/io5";

export default function NotificationsPage() {
  const router = useRouter();
  const { user, loading } = useAuth();
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [dataLoading, setDataLoading] = useState(true);
  const [responding, setResponding] = useState<string | null>(null);

  const loadNotifications = useCallback(async () => {
    setDataLoading(true);
    try {
      const data = await getMyNotifications();
      setNotifications(data);
    } finally {
      setDataLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!loading && !user) router.push("/login");
  }, [loading, user, router]);

  useEffect(() => {
    if (user) loadNotifications();
  }, [user, loadNotifications]);

  const handleMarkAllRead = async () => {
    await markAllNotificationsRead();
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
  };

  const handleRespond = async (
    notif: Notification,
    action: "accepted" | "declined"
  ) => {
    setResponding(notif.id);
    try {
      await markNotificationRead(notif.id);
      await respondToGroupInvite(notif.data.group_member_id, action === "accepted");
      setNotifications((prev) => prev.map((n) => n.id === notif.id ? { ...n, read: true } : n));
      if (action === "accepted") {
        router.push(`/groups/${notif.data.group_id}`);
      }
    } finally {
      setResponding(null);
    }
  };

  if (loading || dataLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f8f9fc] dark:bg-gray-950">
        <div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" />
      </div>
    );
  }

  const unreadCount = notifications.filter((n) => !n.read).length;

  return (
    <div className="min-h-screen bg-[#f8f9fc] dark:bg-gray-950 flex flex-col">
      {/* Navbar */}
      <nav className="sticky top-0 z-40 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
        <div className="max-w-2xl mx-auto px-5 h-14 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button
              onClick={() => router.push("/")}
              className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
            >
              <IoArrowBack size={18} />
            </button>
            <h1 className="text-sm font-bold text-gray-900 dark:text-white">การแจ้งเตือน</h1>
            {unreadCount > 0 && (
              <span className="px-2 py-0.5 bg-[#4366f4] text-white text-xs font-bold rounded-full">
                {unreadCount}
              </span>
            )}
          </div>
          {unreadCount > 0 && (
            <button
              onClick={handleMarkAllRead}
              className="flex items-center gap-1.5 text-xs text-[#4366f4] font-medium hover:underline"
            >
              <IoCheckmarkDone size={14} />
              อ่านทั้งหมด
            </button>
          )}
        </div>
      </nav>

      <main className="flex-1 max-w-2xl mx-auto w-full px-5 py-5">
        {notifications.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-16 text-center">
            <div className="w-14 h-14 rounded-2xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center">
              <IoNotificationsOutline size={24} className="text-gray-400" />
            </div>
            <p className="text-sm text-gray-500 dark:text-gray-400">ไม่มีการแจ้งเตือน</p>
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            {notifications.map((notif) => (
              <div
                key={notif.id}
                onClick={() => !notif.read && markNotificationRead(notif.id).then(() =>
                  setNotifications((prev) => prev.map((n) => n.id === notif.id ? { ...n, read: true } : n))
                )}
                className={`p-4 rounded-2xl border transition-all ${
                  notif.read
                    ? "bg-white dark:bg-gray-900 border-gray-100 dark:border-gray-800"
                    : "bg-blue-50 dark:bg-blue-900/10 border-blue-100 dark:border-blue-800/30"
                }`}
              >
                <div className="flex items-start gap-3">
                  {/* Avatar */}
                  <div className="w-10 h-10 rounded-xl bg-[#4366f4] flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                    {(notif.data.invited_by_display_name ?? notif.data.invited_by_username)
                      .slice(0, 1)
                      .toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-gray-900 dark:text-white">
                      <span className="font-semibold">
                        {notif.data.invited_by_display_name ?? `@${notif.data.invited_by_username}`}
                      </span>{" "}
                      เชิญคุณเข้าร่วมกลุ่ม{" "}
                      <span className="font-semibold text-[#4366f4]">{notif.data.group_name}</span>
                    </p>
                    <p className="text-xs text-gray-400 mt-0.5">
                      {new Date(notif.created_at).toLocaleDateString("th-TH", {
                        day: "numeric",
                        month: "short",
                        year: "numeric",
                        hour: "2-digit",
                        minute: "2-digit",
                      })}
                    </p>

                    {/* Action buttons — only for unread invites */}
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
                  {!notif.read && (
                    <div className="w-2 h-2 rounded-full bg-[#4366f4] flex-shrink-0 mt-1" />
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
