"use client";

import { useEffect, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import {
  getGroup,
  getBills,
  createBill,
  deleteBill,
  getGroupMembers,
  ensureMyProfile,
} from "@/lib/db";
import { Group, Bill, GroupMember } from "@/lib/types";
import {
  IoArrowBack,
  IoAdd,
  IoReceiptOutline,
  IoTrash,
  IoArrowForward,
  IoPeopleOutline,
  IoChevronForward,
  IoSettingsOutline,
} from "react-icons/io5";

export default function GroupPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { user, loading } = useAuth();

  const [group, setGroup] = useState<Group | null>(null);
  const [bills, setBills] = useState<Bill[]>([]);
  const [members, setMembers] = useState<GroupMember[]>([]);
  const [dataLoading, setDataLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [notFound, setNotFound] = useState(false);

  const loadData = useCallback(async () => {
    if (!user || !id) return;
    setDataLoading(true);
    try {
      await ensureMyProfile();
      const [grp, grpBills, grpMembers] = await Promise.all([
        getGroup(id),
        getBills({ groupId: id }),
        getGroupMembers(id),
      ]);
      if (!grp) {
        setNotFound(true);
        return;
      }
      setGroup(grp);
      setBills(grpBills);
      setMembers(grpMembers);
    } finally {
      setDataLoading(false);
    }
  }, [user, id]);

  useEffect(() => {
    if (user) loadData();
  }, [user, loadData]);

  // Redirect to login if not authenticated
  useEffect(() => {
    if (!loading && !user) router.push("/login");
  }, [loading, user, router]);

  if (loading || dataLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f8f9fc] dark:bg-gray-950">
        <div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" />
      </div>
    );
  }

  if (notFound) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-[#f8f9fc] dark:bg-gray-950 gap-4">
        <p className="text-gray-500 dark:text-gray-400">ไม่พบกลุ่มนี้</p>
        <button
          onClick={() => router.push("/")}
          className="px-4 py-2 bg-[#4366f4] text-white text-sm font-semibold rounded-xl"
        >
          กลับหน้าหลัก
        </button>
      </div>
    );
  }

  const handleCreateBill = async () => {
    if (!group) return;
    setCreating(true);
    try {
      const bill = await createBill({ title: "บิลใหม่", group_id: group.id });
      router.push(`/app?id=${bill.id}`);
    } catch (e) {
      console.error(e);
      setCreating(false);
    }
  };

  const handleDeleteBill = async (e: React.MouseEvent, billId: string) => {
    e.stopPropagation();
    if (!confirm("ลบบิลนี้?")) return;
    await deleteBill(billId);
    setBills((prev) => prev.filter((b) => b.id !== billId));
  };

  const acceptedMembers = members.filter((m) => m.status === "accepted");

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
            <div>
              <h1 className="text-sm font-bold text-gray-900 dark:text-white leading-tight">
                {group?.name ?? "กลุ่ม"}
              </h1>
              {group?.description && (
                <p className="text-xs text-gray-400 leading-tight">{group.description}</p>
              )}
            </div>
          </div>
          <button
            onClick={() => router.push(`/groups/${id}/settings`)}
            className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
          >
            <IoSettingsOutline size={18} />
          </button>
        </div>
      </nav>

      <main className="flex-1 max-w-2xl mx-auto w-full px-5 py-5">
        {/* Members strip */}
        <div
          onClick={() => router.push(`/groups/${id}/members`)}
          className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 mb-5 cursor-pointer hover:border-purple-200 dark:hover:border-purple-800 hover:shadow-sm transition-all group"
        >
          <div className="w-9 h-9 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center flex-shrink-0">
            <IoPeopleOutline size={18} className="text-purple-500" />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-gray-900 dark:text-white">สมาชิก</p>
            <p className="text-xs text-gray-400 mt-0.5">
              {acceptedMembers.length} คน
              {members.filter((m) => m.status === "pending").length > 0 &&
                ` · รอตอบรับ ${members.filter((m) => m.status === "pending").length} คน`}
            </p>
          </div>
          {/* Avatar stack */}
          <div className="flex -space-x-2 mr-1">
            {acceptedMembers.slice(0, 4).map((m) => (
              <div
                key={m.id}
                className="w-7 h-7 rounded-full border-2 border-white dark:border-gray-900 bg-[#4366f4] flex items-center justify-center text-white text-xs font-bold overflow-hidden flex-shrink-0"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                {m.profile?.avatar_url ? (
                  <img src={m.profile.avatar_url} alt={m.profile.display_name ?? ""} className="w-full h-full object-cover" />
                ) : (
                  (m.profile?.display_name ?? "?").slice(0, 1).toUpperCase()
                )}
              </div>
            ))}
            {acceptedMembers.length > 4 && (
              <div className="w-7 h-7 rounded-full border-2 border-white dark:border-gray-900 bg-gray-200 dark:bg-gray-700 flex items-center justify-center text-gray-500 text-xs font-bold flex-shrink-0">
                +{acceptedMembers.length - 4}
              </div>
            )}
          </div>
          <IoChevronForward size={14} className="text-gray-300 group-hover:text-purple-400 transition-colors flex-shrink-0" />
        </div>

        {/* Create bill button */}
        <button
          onClick={handleCreateBill}
          disabled={creating}
          className="w-full flex items-center justify-center gap-2 py-3.5 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 rounded-2xl text-sm font-semibold text-white transition-all shadow-sm hover:shadow-md mb-5"
        >
          <div className="w-6 h-6 rounded-lg bg-white/20 flex items-center justify-center">
            <IoAdd size={14} className="text-white" />
          </div>
          {creating ? "กำลังสร้าง..." : "+ สร้างบิลใหม่"}
        </button>

        {/* Bills list */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-sm font-bold text-gray-900 dark:text-white">บิลในกลุ่ม</h2>
            {bills.length > 0 && (
              <span className="text-xs text-gray-400">{bills.length} บิล</span>
            )}
          </div>

          {bills.length === 0 ? (
            <div
              onClick={handleCreateBill}
              className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-dashed border-gray-200 dark:border-gray-700 cursor-pointer hover:border-[#4366f4]/30 transition-colors group"
            >
              <div className="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
                <IoReceiptOutline size={20} className="text-[#4366f4]" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-500 dark:text-gray-400">สร้างบิลแรกของกลุ่ม</p>
                <p className="text-xs text-gray-400 mt-0.5">แตะเพื่อเริ่มหารค่าใช้จ่าย</p>
              </div>
              <IoAdd size={16} className="text-gray-300 group-hover:text-[#4366f4] ml-auto transition-colors" />
            </div>
          ) : (
            <div className="flex flex-col gap-2">
              {bills.map((bill) => (
                <div
                  key={bill.id}
                  onClick={() => router.push(`/app?id=${bill.id}`)}
                  className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 hover:border-[#4366f4]/20 hover:shadow-sm transition-all cursor-pointer group"
                >
                  <div className="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
                    <IoReceiptOutline size={20} className="text-[#4366f4]" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{bill.title}</p>
                    <p className="text-xs text-gray-400 mt-0.5">
                      {new Date(bill.updated_at).toLocaleDateString("th-TH", {
                        day: "numeric",
                        month: "short",
                        year: "numeric",
                      })}
                    </p>
                  </div>
                  <div className="flex items-center gap-1 flex-shrink-0">
                    <button
                      onClick={(e) => handleDeleteBill(e, bill.id)}
                      className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-300 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors opacity-0 group-hover:opacity-100"
                    >
                      <IoTrash size={13} />
                    </button>
                    <IoArrowForward size={14} className="text-gray-300 group-hover:text-[#4366f4] transition-colors" />
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>
      </main>
    </div>
  );
}
