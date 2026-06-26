"use client";

import { useEffect, useState, useCallback, useMemo } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import {
  getMyGroups,
  getIndividualBills,
  getBills,
  createBill,
  deleteBill,
  updateBill,
  createGroup,
  deleteGroup,
  updateGroup,
  getUnreadNotificationCount,
  ensureMyProfile,
} from "@/lib/db";
import { Group, Bill } from "@/lib/types";
import { FEATURES } from "@/lib/constants";
import CreateEntityModal, { EntityFormData } from "@/components/ui/CreateEntityModal";
import ConfirmModal from "@/components/ui/ConfirmModal";
import {
  IoAdd,
  IoReceiptOutline,
  IoTrash,
  IoArrowForward,
  IoLogoGoogle,
  IoCheckmarkCircle,
  IoSparkles,
  IoPeopleOutline,
  IoBarChartOutline,
  IoNotificationsOutline,
  IoPeopleCircleOutline,
  IoChevronForward,
  IoSettingsOutline,
  IoWalletOutline,
} from "react-icons/io5";

// ── helpers ───────────────────────────────────────────────────
function getBillTotal(bill: Bill): number {
  return (bill.items ?? []).reduce((s, i) => s + i.price, 0);
}

function formatBaht(n: number): string {
  return n.toLocaleString("th-TH", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

// ── Main Home Page ────────────────────────────────────────────
export default function HomePage() {
  const { user, loading, signInWithGoogle, configured } = useAuth();
  const router = useRouter();

  const [groups, setGroups] = useState<Group[]>([]);
  const [personalBills, setPersonalBills] = useState<Bill[]>([]);
  const [groupBills, setGroupBills] = useState<Record<string, Bill[]>>({});
  const [unreadCount, setUnreadCount] = useState(0);
  const [dataLoading, setDataLoading] = useState(false);
  const [creating, setCreating] = useState(false);
  const [showCreateGroup, setShowCreateGroup] = useState(false);
  const [showCreateBill, setShowCreateBill] = useState(false);

  // Edit modals
  const [editingBill, setEditingBill] = useState<Bill | null>(null);
  const [editingGroup, setEditingGroup] = useState<Group | null>(null);

  // Confirm delete
  const [confirmDeleteBill, setConfirmDeleteBill] = useState<Bill | null>(null);
  const [confirmDeleteGroup, setConfirmDeleteGroup] = useState<Group | null>(null);

  const loadData = useCallback(async () => {
    if (!user) return;
    setDataLoading(true);
    try {
      await ensureMyProfile();
      const [grps, bills, unread] = await Promise.all([
        getMyGroups(),
        getIndividualBills(),
        getUnreadNotificationCount(),
      ]);
      setGroups(grps);
      setPersonalBills(bills);
      setUnreadCount(unread);

      const billMap: Record<string, Bill[]> = {};
      await Promise.all(
        grps.map(async (g) => {
          const gb = await getBills({ groupId: g.id });
          billMap[g.id] = gb;
        })
      );
      setGroupBills(billMap);
    } finally {
      setDataLoading(false);
    }
  }, [user]);

  useEffect(() => {
    if (user) loadData();
  }, [user, loadData]);

  // ── Computed totals ──────────────────────────────────────────
  const personalTotal = useMemo(
    () => personalBills.reduce((s, b) => s + getBillTotal(b), 0),
    [personalBills]
  );

  const groupTotals = useMemo(() => {
    const map: Record<string, number> = {};
    for (const [gid, bills] of Object.entries(groupBills)) {
      map[gid] = bills.reduce((s, b) => s + getBillTotal(b), 0);
    }
    return map;
  }, [groupBills]);

  const grandTotal = useMemo(
    () => personalTotal + Object.values(groupTotals).reduce((s, v) => s + v, 0),
    [personalTotal, groupTotals]
  );

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white dark:bg-gray-950">
        <div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" />
      </div>
    );
  }

  // ── Handlers ──────────────────────────────────────────────
  const handleCreatePersonalBill = async (data: EntityFormData) => {
    setCreating(true);
    try {
      const bill = await createBill({
        title: data.name,
        emoji: data.emoji,
        tags: data.tags,
        settings: data.settings,
      });
      setPersonalBills((prev) => [bill, ...prev]);
    } catch (e) {
      console.error(e);
    } finally {
      setCreating(false);
    }
  };

  const handleEditBill = async (data: EntityFormData) => {
    if (!editingBill) return;
    await updateBill(editingBill.id, {
      title: data.name,
      emoji: data.emoji,
      tags: data.tags,
      settings: data.settings,
    });
    setPersonalBills((prev) =>
      prev.map((b) =>
        b.id === editingBill.id
          ? { ...b, title: data.name, emoji: data.emoji, tags: data.tags, settings: data.settings ?? b.settings }
          : b
      )
    );
    setEditingBill(null);
  };

  const handleDeleteBill = async () => {
    if (!confirmDeleteBill) return;
    await deleteBill(confirmDeleteBill.id);
    setPersonalBills((prev) => prev.filter((b) => b.id !== confirmDeleteBill.id));
    setConfirmDeleteBill(null);
  };

  const handleCreateGroup = async (data: EntityFormData) => {
    const group = await createGroup({
      name: data.name,
      description: data.description || undefined,
      emoji: data.emoji,
      tags: data.tags,
    });
    setGroups((prev) => [group, ...prev]);
    setGroupBills((prev) => ({ ...prev, [group.id]: [] }));
  };

  const handleEditGroup = async (data: EntityFormData) => {
    if (!editingGroup) return;
    await updateGroup(editingGroup.id, {
      name: data.name,
      description: data.description || undefined,
      emoji: data.emoji,
      tags: data.tags,
    });
    setGroups((prev) =>
      prev.map((g) =>
        g.id === editingGroup.id
          ? { ...g, name: data.name, description: data.description || null, emoji: data.emoji, tags: data.tags }
          : g
      )
    );
    setEditingGroup(null);
  };

  const handleDeleteGroup = async () => {
    if (!confirmDeleteGroup) return;
    await deleteGroup(confirmDeleteGroup.id);
    setGroups((prev) => prev.filter((g) => g.id !== confirmDeleteGroup.id));
    setConfirmDeleteGroup(null);
  };

  // ── Logged-in Dashboard ──────────────────────────────────
  if (user) {
    const avatarUrl = user.user_metadata?.avatar_url as string | undefined;
    const displayName = (user.user_metadata?.full_name as string | undefined) || user.email?.split("@")[0] || "คุณ";
    const firstName = displayName.split(" ")[0];
    const initials = displayName.slice(0, 1).toUpperCase();

    return (
      <div className="min-h-screen bg-[#f4f6fb] dark:bg-gray-950 flex flex-col">
        {/* Navbar */}
        <nav className="sticky top-0 z-40 bg-white/90 dark:bg-gray-900/90 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
          <div className="max-w-lg mx-auto px-4 h-14 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg bg-[#4366f4] flex items-center justify-center">
                <span className="text-white text-xs font-bold">฿</span>
              </div>
              <span className="text-sm font-bold text-gray-900 dark:text-white">Kidtang</span>
            </div>
            <div className="flex items-center gap-1.5">
              <button
                onClick={() => router.push("/notifications")}
                className="relative w-9 h-9 flex items-center justify-center rounded-xl text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
              >
                <IoNotificationsOutline size={20} />
                {unreadCount > 0 && (
                  <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full" />
                )}
              </button>
              <button
                onClick={() => router.push("/profile")}
                className="w-8 h-8 rounded-full overflow-hidden flex items-center justify-center bg-[#4366f4] text-white text-xs font-bold flex-shrink-0"
              >
                {avatarUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={avatarUrl} alt={displayName} className="w-full h-full object-cover" />
                ) : (
                  initials
                )}
              </button>
            </div>
          </div>
        </nav>

        <main className="flex-1 max-w-lg mx-auto w-full px-4 py-5 flex flex-col gap-5">
          {/* Hero card — grand total */}
          <div className="bg-gradient-to-br from-[#4366f4] to-[#6b8aff] rounded-3xl p-5 text-white shadow-lg shadow-blue-200/40 dark:shadow-none">
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm font-medium opacity-80">สวัสดี, {firstName} 👋</p>
                <p className="text-xs opacity-60 mt-0.5">ยอดรวมทั้งหมดของคุณ</p>
              </div>
              <div className="w-9 h-9 rounded-xl bg-white/20 flex items-center justify-center">
                <IoWalletOutline size={18} className="text-white" />
              </div>
            </div>
            <div className="mt-4">
              {dataLoading ? (
                <div className="w-6 h-6 border-2 border-white/40 border-t-white rounded-full animate-spin" />
              ) : (
                <>
                  <p className="text-3xl font-bold tracking-tight">{formatBaht(grandTotal)} บาท</p>
                  <div className="flex items-center gap-3 mt-2">
                    <span className="text-xs opacity-70">{groups.length} กลุ่ม</span>
                    <span className="text-xs opacity-40">·</span>
                    <span className="text-xs opacity-70">{personalBills.length} บิลส่วนตัว</span>
                  </div>
                </>
              )}
            </div>
          </div>

          {/* Quick actions */}
          <div className="grid grid-cols-2 gap-3">
            <button
              onClick={() => setShowCreateGroup(true)}
              className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 hover:border-purple-200 dark:hover:border-purple-800 hover:shadow-sm transition-all group"
            >
              <div className="w-9 h-9 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center flex-shrink-0">
                <IoPeopleOutline size={18} className="text-purple-500" />
              </div>
              <div className="text-left">
                <p className="text-sm font-semibold text-gray-800 dark:text-white">กลุ่มใหม่</p>
                <p className="text-[10px] text-gray-400 mt-0.5">หารกับเพื่อน</p>
              </div>
            </button>
            <button
              onClick={() => setShowCreateBill(true)}
              disabled={creating}
              className="flex items-center gap-3 p-4 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 rounded-2xl shadow-sm hover:shadow-md transition-all group"
            >
              <div className="w-9 h-9 rounded-xl bg-white/20 flex items-center justify-center flex-shrink-0">
                <IoReceiptOutline size={18} className="text-white" />
              </div>
              <div className="text-left">
                <p className="text-sm font-semibold text-white">{creating ? "กำลังสร้าง..." : "บิลใหม่"}</p>
                <p className="text-[10px] text-white/70 mt-0.5">บิลส่วนตัว</p>
              </div>
            </button>
          </div>

          {dataLoading ? (
            <div className="flex items-center justify-center py-12">
              <div className="w-6 h-6 border-2 border-[#4366f4] border-t-transparent rounded-full animate-spin" />
            </div>
          ) : (
            <>
              {/* ── Groups Section ── */}
              <section>
                <div className="flex items-center justify-between mb-3">
                  <h2 className="text-sm font-bold text-gray-900 dark:text-white">กลุ่มของฉัน</h2>
                  <div className="flex items-center gap-2">
                    {groups.length > 0 && (
                      <span className="text-xs text-gray-400">{groups.length} กลุ่ม</span>
                    )}
                    <button
                      onClick={() => setShowCreateGroup(true)}
                      className="w-6 h-6 flex items-center justify-center rounded-lg bg-gray-100 dark:bg-gray-800 text-gray-500 hover:bg-purple-50 hover:text-purple-500 transition-colors"
                    >
                      <IoAdd size={14} />
                    </button>
                  </div>
                </div>

                {groups.length === 0 ? (
                  <div
                    onClick={() => setShowCreateGroup(true)}
                    className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-dashed border-gray-200 dark:border-gray-700 cursor-pointer hover:border-purple-300 dark:hover:border-purple-700 transition-colors group"
                  >
                    <div className="w-10 h-10 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center flex-shrink-0">
                      <IoPeopleCircleOutline size={22} className="text-purple-400" />
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-500 dark:text-gray-400">สร้างกลุ่มแรก</p>
                      <p className="text-xs text-gray-400 mt-0.5">หารบิลกับเพื่อนหรือครอบครัว</p>
                    </div>
                    <IoAdd size={16} className="text-gray-300 group-hover:text-purple-400 ml-auto transition-colors" />
                  </div>
                ) : (
                  <div className="flex flex-col gap-2">
                    {groups.map((group) => {
                      const gTotal = groupTotals[group.id] ?? 0;
                      const billCount = (groupBills[group.id] ?? []).length;
                      return (
                        <div
                          key={group.id}
                          onClick={() => router.push(`/groups/${group.id}`)}
                          className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 hover:border-purple-200 dark:hover:border-purple-800 hover:shadow-sm transition-all cursor-pointer group"
                        >
                          <div className="w-11 h-11 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center flex-shrink-0 text-xl">
                            {group.emoji ?? <IoPeopleOutline size={20} className="text-purple-500" />}
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{group.name}</p>
                            <div className="flex items-center gap-1.5 mt-0.5">
                              <p className="text-xs text-gray-400">{billCount} บิล</p>
                              {group.tags && group.tags.slice(0, 1).map((tag) => (
                                <span key={tag} className="px-1.5 py-0.5 bg-purple-50 dark:bg-purple-900/20 text-purple-500 text-[10px] rounded-full font-medium">
                                  {tag}
                                </span>
                              ))}
                            </div>
                          </div>
                          <div className="text-right flex-shrink-0 flex items-center gap-2">
                            <div>
                              <p className="text-sm font-bold text-gray-900 dark:text-white">
                                {formatBaht(gTotal)}
                              </p>
                              <p className="text-[10px] text-gray-400">บาท</p>
                            </div>
                            <div className="flex items-center gap-0.5">
                              <button
                                onClick={(e) => { e.stopPropagation(); setEditingGroup(group); }}
                                className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-300 hover:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                              >
                                <IoSettingsOutline size={13} />
                              </button>
                              <IoChevronForward size={14} className="text-gray-300 group-hover:text-purple-400 transition-colors" />
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </section>

              {/* ── Personal Bills Section ── */}
              <section>
                <div className="flex items-center justify-between mb-3">
                  <h2 className="text-sm font-bold text-gray-900 dark:text-white">บิลส่วนตัว</h2>
                  <div className="flex items-center gap-2">
                    {personalBills.length > 0 && (
                      <span className="text-xs text-gray-400">
                        รวม {formatBaht(personalTotal)} บาท
                      </span>
                    )}
                    <button
                      onClick={() => setShowCreateBill(true)}
                      className="w-6 h-6 flex items-center justify-center rounded-lg bg-gray-100 dark:bg-gray-800 text-gray-500 hover:bg-blue-50 hover:text-[#4366f4] transition-colors"
                    >
                      <IoAdd size={14} />
                    </button>
                  </div>
                </div>

                {personalBills.length === 0 ? (
                  <div
                    onClick={() => setShowCreateBill(true)}
                    className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-dashed border-gray-200 dark:border-gray-700 cursor-pointer hover:border-[#4366f4]/30 transition-colors group"
                  >
                    <div className="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
                      <IoReceiptOutline size={20} className="text-[#4366f4]" />
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-500 dark:text-gray-400">สร้างบิลแรก</p>
                      <p className="text-xs text-gray-400 mt-0.5">บิลส่วนตัวไม่ผูกกับกลุ่ม</p>
                    </div>
                    <IoAdd size={16} className="text-gray-300 group-hover:text-[#4366f4] ml-auto transition-colors" />
                  </div>
                ) : (
                  <div className="flex flex-col gap-2">
                    {personalBills.map((bill) => {
                      const bTotal = getBillTotal(bill);
                      return (
                        <div
                          key={bill.id}
                          onClick={() => router.push(`/app?id=${bill.id}`)}
                          className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 hover:border-[#4366f4]/20 hover:shadow-sm transition-all cursor-pointer group"
                        >
                          <div className="w-11 h-11 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0 text-xl">
                            {bill.emoji ?? <IoReceiptOutline size={20} className="text-[#4366f4]" />}
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{bill.title}</p>
                            <div className="flex items-center gap-1.5 mt-0.5 flex-wrap">
                              <p className="text-xs text-gray-400">
                                {new Date(bill.updated_at).toLocaleDateString("th-TH", {
                                  day: "numeric",
                                  month: "short",
                                })}
                              </p>
                              {bill.tags && bill.tags.slice(0, 1).map((tag) => (
                                <span key={tag} className="px-1.5 py-0.5 bg-blue-50 dark:bg-blue-900/20 text-[#4366f4] text-[10px] rounded-full font-medium">
                                  {tag}
                                </span>
                              ))}
                            </div>
                          </div>
                          <div className="text-right flex-shrink-0 flex items-center gap-2">
                            <div>
                              <p className="text-sm font-bold text-gray-900 dark:text-white">
                                {formatBaht(bTotal)}
                              </p>
                              <p className="text-[10px] text-gray-400">บาท</p>
                            </div>
                            <div className="flex items-center gap-0.5">
                              <button
                                onClick={(e) => { e.stopPropagation(); setEditingBill(bill); }}
                                className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-300 hover:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                              >
                                <IoSettingsOutline size={13} />
                              </button>
                              <button
                                onClick={(e) => { e.stopPropagation(); setConfirmDeleteBill(bill); }}
                                className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-300 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                              >
                                <IoTrash size={13} />
                              </button>
                              <IoArrowForward size={14} className="text-gray-300 group-hover:text-[#4366f4] transition-colors" />
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </section>
            </>
          )}
        </main>

        {/* Modals */}
        {showCreateGroup && (
          <CreateEntityModal
            type="group"
            onClose={() => setShowCreateGroup(false)}
            onSave={handleCreateGroup}
          />
        )}
        {showCreateBill && (
          <CreateEntityModal
            type="bill"
            onClose={() => setShowCreateBill(false)}
            onSave={handleCreatePersonalBill}
          />
        )}
        {editingBill && (
          <CreateEntityModal
            type="bill"
            mode="edit"
            initialData={{
              name: editingBill.title,
              emoji: editingBill.emoji,
              tags: editingBill.tags ?? [],
              settings: editingBill.settings,
            }}
            onClose={() => setEditingBill(null)}
            onSave={handleEditBill}
          />
        )}
        {editingGroup && (
          <CreateEntityModal
            type="group"
            mode="edit"
            initialData={{
              name: editingGroup.name,
              emoji: editingGroup.emoji,
              description: editingGroup.description ?? "",
              tags: editingGroup.tags ?? [],
            }}
            onClose={() => setEditingGroup(null)}
            onSave={handleEditGroup}
            onDelete={() => { setEditingGroup(null); setConfirmDeleteGroup(editingGroup); }}
          />
        )}
        {confirmDeleteBill && (
          <ConfirmModal
            title={`ลบบิล "${confirmDeleteBill.title}"?`}
            description="การกระทำนี้ไม่สามารถย้อนกลับได้"
            confirmLabel="ลบบิล"
            danger
            onConfirm={handleDeleteBill}
            onCancel={() => setConfirmDeleteBill(null)}
          />
        )}
        {confirmDeleteGroup && (
          <ConfirmModal
            title={`ลบกลุ่ม "${confirmDeleteGroup.name}"?`}
            description="บิลทั้งหมดในกลุ่มจะถูกลบด้วย ไม่สามารถย้อนกลับได้"
            confirmLabel="ลบกลุ่ม"
            danger
            onConfirm={handleDeleteGroup}
            onCancel={() => setConfirmDeleteGroup(null)}
          />
        )}
      </div>
    );
  }

  // ── Landing Page (not logged in) ─────────────────────────────
  const handleCTA = () => {
    if (configured) {
      router.push("/login");
    } else {
      setShowCreateBill(true);
    }
  };

  return (
    <div className="min-h-screen bg-[#f8f9fc] dark:bg-gray-950 flex flex-col">
      {/* Navbar */}
      <nav className="sticky top-0 z-40 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
        <div className="max-w-5xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-xl bg-[#4366f4] flex items-center justify-center">
              <span className="text-white text-sm font-bold">฿</span>
            </div>
            <span className="text-base font-bold text-gray-900 dark:text-white">Kidtang</span>
          </div>
          <button
            onClick={handleCTA}
            className="flex items-center gap-2 px-4 py-2 bg-[#4366f4] hover:bg-[#3355e0] text-white text-sm font-semibold rounded-xl transition-colors"
          >
            เริ่มใช้งาน
            <IoArrowForward size={14} />
          </button>
        </div>
      </nav>

      {/* Hero */}
      <section className="flex-1 flex flex-col items-center justify-center px-6 py-20 text-center">
        <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-blue-50 dark:bg-blue-900/20 text-[#4366f4] text-xs font-semibold rounded-full mb-6 border border-blue-100 dark:border-blue-800">
          <IoSparkles size={12} />
          หารบิลง่าย ไม่ต้องคิดเอง
        </div>

        <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 dark:text-white leading-tight mb-4 max-w-xl">
          หารบิลกับเพื่อน
          <br />
          <span className="text-[#4366f4]">ง่ายกว่าที่เคย</span>
        </h1>

        <p className="text-base text-gray-500 dark:text-gray-400 max-w-md mb-10 leading-relaxed">
          คำนวณค่าใช้จ่าย หารเท่า หรือไม่เท่า รองรับ VAT, Service Charge,
          ทิป และส่วนลด พร้อม QR PromptPay
        </p>

        <div className="flex flex-col sm:flex-row gap-3 items-center">
          {configured && FEATURES.GOOGLE_LOGIN && (
            <button
              onClick={signInWithGoogle}
              className="flex items-center gap-2 px-6 py-3.5 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 text-gray-800 dark:text-white text-sm font-semibold rounded-2xl hover:bg-gray-50 dark:hover:bg-gray-800 transition-all hover:-translate-y-0.5 shadow-sm"
            >
              <IoLogoGoogle size={16} className="text-[#4285f4]" />
              เข้าสู่ระบบด้วย Google
            </button>
          )}
          <button
            onClick={handleCTA}
            disabled={creating}
            className="flex items-center gap-2 px-6 py-3.5 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 text-white text-sm font-semibold rounded-2xl shadow-sm hover:shadow-md transition-all hover:-translate-y-0.5"
          >
            {creating ? "กำลังสร้าง..." : "เริ่มใช้งานเลย"}
            <IoArrowForward size={14} />
          </button>
        </div>

        {/* Trust badges */}
        <div className="flex items-center gap-6 mt-10 text-xs text-gray-400">
          <span className="flex items-center gap-1.5">
            <IoCheckmarkCircle size={14} className="text-emerald-500" />
            ฟรี 100%
          </span>
          <span className="flex items-center gap-1.5">
            <IoCheckmarkCircle size={14} className="text-emerald-500" />
            ไม่ต้องลงทะเบียน
          </span>
          <span className="flex items-center gap-1.5">
            <IoCheckmarkCircle size={14} className="text-emerald-500" />
            บันทึกอัตโนมัติ
          </span>
        </div>
      </section>

      {/* Features */}
      <section className="max-w-5xl mx-auto px-6 pb-20 w-full">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {[
            {
              icon: <IoPeopleOutline size={24} />,
              title: "จัดการสมาชิก",
              desc: "เพิ่มสมาชิกพร้อม PromptPay สำหรับโอนเงินได้เลย",
              color: "bg-blue-50 dark:bg-blue-900/20 text-[#4366f4]",
            },
            {
              icon: <IoReceiptOutline size={24} />,
              title: "รายการยืดหยุ่น",
              desc: "หารเท่าหรือกำหนดสัดส่วนเอง รองรับ VAT และ Service Charge",
              color: "bg-purple-50 dark:bg-purple-900/20 text-purple-500",
            },
            {
              icon: <IoBarChartOutline size={24} />,
              title: "สรุปชัดเจน",
              desc: "ดูกราฟสัดส่วน และ QR PromptPay สำหรับโอนเงินทันที",
              color: "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-500",
            },
          ].map((f) => (
            <div
              key={f.title}
              className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 hover:shadow-md transition-shadow"
            >
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center mb-3 ${f.color}`}>
                {f.icon}
              </div>
              <h3 className="text-sm font-bold text-gray-900 dark:text-white mb-1">{f.title}</h3>
              <p className="text-xs text-gray-500 dark:text-gray-400 leading-relaxed">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-gray-100 dark:border-gray-800 py-6 text-center">
        <p className="text-xs text-gray-400">© 2025 Kidtang · หารบิลง่ายๆ สำหรับทุกคน</p>
      </footer>

      {/* Create Bill Modal (landing) */}
      {showCreateBill && (
        <CreateEntityModal
          type="bill"
          onClose={() => setShowCreateBill(false)}
          onSave={handleCreatePersonalBill}
        />
      )}
    </div>
  );
}
