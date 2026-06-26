"use client";

import { useEffect, useState, useCallback, useMemo } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import {
  getGroup,
  getBills,
  createBill,
  deleteBill,
  updateBill,
  updateGroup,
  deleteGroup,
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
  IoSettingsOutline,
  IoBarChartOutline,
  IoAnalyticsOutline,
  IoChevronDown,
  IoChevronUp,
} from "react-icons/io5";
import SummaryPage from "@/components/summary/SummaryPage";
import CreateEntityModal, { EntityFormData } from "@/components/ui/CreateEntityModal";
import ConfirmModal from "@/components/ui/ConfirmModal";
import BottomNav from "@/components/ui/BottomNav";

type GroupTab = "members" | "bills" | "summary" | "analytics";

const TABS: { id: GroupTab; label: string; icon: React.ReactNode }[] = [
  { id: "members", label: "สมาชิก", icon: <IoPeopleOutline size={16} /> },
  { id: "bills", label: "บิล", icon: <IoReceiptOutline size={16} /> },
  { id: "summary", label: "สรุป", icon: <IoBarChartOutline size={16} /> },
  { id: "analytics", label: "วิเคราะห์", icon: <IoAnalyticsOutline size={16} /> },
];

export default function GroupPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { user, loading } = useAuth();

  const [tab, setTab] = useState<GroupTab>("bills");
  const [group, setGroup] = useState<Group | null>(null);
  const [bills, setBills] = useState<Bill[]>([]);
  const [members, setMembers] = useState<GroupMember[]>([]);
  const [dataLoading, setDataLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [notFound, setNotFound] = useState(false);
  const [showCreateBill, setShowCreateBill] = useState(false);
  const [editingBill, setEditingBill] = useState<Bill | null>(null);
  const [confirmDeleteBill, setConfirmDeleteBill] = useState<Bill | null>(null);
  const [showGroupSettings, setShowGroupSettings] = useState(false);
  const [confirmDeleteGroup, setConfirmDeleteGroup] = useState(false);

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

  useEffect(() => {
    if (!loading && !user) router.push("/login");
  }, [loading, user, router]);

  const acceptedMembers = useMemo(
    () => members.filter((m) => m.status === "accepted"),
    [members]
  );

  if (loading || dataLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white dark:bg-gray-950">
        <div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" />
      </div>
    );
  }

  if (notFound) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-white dark:bg-gray-950 gap-4">
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

  // ── Handlers ──────────────────────────────────────────────
  const handleCreateBill = async (data: EntityFormData) => {
    if (!group) return;
    setCreating(true);
    try {
      const bill = await createBill({
        title: data.name,
        emoji: data.emoji,
        tags: data.tags,
        settings: data.settings,
        group_id: group.id,
      });
      router.push(`/app?id=${bill.id}`);
    } catch (e) {
      console.error(e);
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
    setBills((prev) =>
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
    setBills((prev) => prev.filter((b) => b.id !== confirmDeleteBill.id));
    setConfirmDeleteBill(null);
  };

  const handleEditGroup = async (data: EntityFormData) => {
    if (!group) return;
    await updateGroup(group.id, {
      name: data.name,
      description: data.description || undefined,
      emoji: data.emoji,
      tags: data.tags,
    });
    setGroup((g) => g ? { ...g, name: data.name, description: data.description || null, emoji: data.emoji, tags: data.tags } : g);
  };

  const handleDeleteGroup = async () => {
    if (!group) return;
    await deleteGroup(group.id);
    router.push("/");
  };

  return (
    <div className="min-h-screen bg-white dark:bg-gray-950 flex flex-col pb-20">
      {/* Header */}
      <header className="sticky top-0 z-30 bg-white/90 dark:bg-gray-950/90 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
        <div className="max-w-lg mx-auto px-4 py-3 flex items-center gap-3">
          <button
            onClick={() => router.back()}
            className="w-9 h-9 flex items-center justify-center rounded-xl text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors flex-shrink-0"
          >
            <IoArrowBack size={18} />
          </button>

          {/* Title */}
          <div className="flex-1 min-w-0 flex items-center gap-2">
            {group?.emoji && <span className="text-xl flex-shrink-0">{group.emoji}</span>}
            <div className="min-w-0">
              <h1 className="text-base font-semibold text-gray-900 dark:text-white truncate">
                {group?.name ?? "กลุ่ม"}
              </h1>
              {group?.description && (
                <p className="text-xs text-gray-400 truncate leading-tight">{group.description}</p>
              )}
            </div>
          </div>

          <button
            onClick={() => setShowGroupSettings(true)}
            className="w-9 h-9 flex items-center justify-center rounded-xl text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors flex-shrink-0"
          >
            <IoSettingsOutline size={18} />
          </button>
        </div>

        {/* Tabs */}
        <div className="max-w-lg mx-auto px-4 pb-3">
          <div className="flex gap-1 bg-gray-100 dark:bg-gray-800 rounded-2xl p-1">
            {TABS.map((t) => (
              <button
                key={t.id}
                onClick={() => setTab(t.id)}
                className={`flex items-center justify-center gap-1.5 flex-1 px-3 py-2 text-sm font-semibold rounded-xl transition-all ${
                  tab === t.id
                    ? "bg-white dark:bg-gray-700 text-[#4366f4] shadow-sm"
                    : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
                }`}
              >
                {t.icon}
                {t.label}
                {t.id === "members" && acceptedMembers.length > 0 && (
                  <span className={`text-[10px] rounded-full px-1.5 py-0.5 font-bold ${
                    tab === t.id
                      ? "bg-blue-50 dark:bg-blue-900/30 text-[#4366f4]"
                      : "bg-gray-200 dark:bg-gray-700 text-gray-500"
                  }`}>
                    {acceptedMembers.length}
                  </span>
                )}
                {t.id === "bills" && bills.length > 0 && (
                  <span className={`text-[10px] rounded-full px-1.5 py-0.5 font-bold ${
                    tab === t.id
                      ? "bg-blue-50 dark:bg-blue-900/30 text-[#4366f4]"
                      : "bg-gray-200 dark:bg-gray-700 text-gray-500"
                  }`}>
                    {bills.length}
                  </span>
                )}
              </button>
            ))}
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="flex-1 max-w-lg mx-auto w-full px-4 py-5">
        {tab === "members" && (
          <MembersTab
            members={members}
            groupId={id}
            onViewAll={() => router.push(`/groups/${id}/members`)}
          />
        )}
        {tab === "bills" && (
          <BillsTab
            bills={bills}
            creating={creating}
            onCreateBill={() => setShowCreateBill(true)}
            onOpenBill={(billId) => router.push(`/app?id=${billId}`)}
            onEditBill={(bill) => setEditingBill(bill)}
            onDeleteBill={(bill) => setConfirmDeleteBill(bill)}
          />
        )}
        {tab === "summary" && (
          <GroupSummaryTab bills={bills} currentUserId={user?.id ?? null} />
        )}
        {tab === "analytics" && (
          <GroupAnalyticsTab bills={bills} />
        )}
      </main>

      {/* Modals */}
      {showCreateBill && (
        <CreateEntityModal
          type="bill"
          onClose={() => setShowCreateBill(false)}
          onSave={handleCreateBill}
        />
      )}

      {showGroupSettings && group && (
        <CreateEntityModal
          type="group"
          mode="edit"
          initialData={{
            name: group.name,
            emoji: group.emoji,
            description: group.description ?? "",
            tags: group.tags ?? [],
          }}
          onClose={() => setShowGroupSettings(false)}
          onSave={handleEditGroup}
          onDelete={() => { setShowGroupSettings(false); setConfirmDeleteGroup(true); }}
        />
      )}

      {confirmDeleteGroup && group && (
        <ConfirmModal
          title={`ลบกลุ่ม "${group.name}"?`}
          description="บิลทั้งหมดในกลุ่มจะถูกลบด้วย ไม่สามารถย้อนกลับได้"
          confirmLabel="ลบกลุ่ม"
          danger
          onConfirm={handleDeleteGroup}
          onCancel={() => setConfirmDeleteGroup(false)}
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

      {/* Bottom Nav */}
      <BottomNav />
    </div>
  );
}

// ── Members Tab ───────────────────────────────────────────────
function MembersTab({
  members,
  groupId,
  onViewAll,
}: {
  members: GroupMember[];
  groupId: string;
  onViewAll: () => void;
}) {
  const accepted = members.filter((m) => m.status === "accepted");
  const pending = members.filter((m) => m.status === "pending");

  return (
    <div className="flex flex-col gap-3">
      {/* Manage button */}
      <button
        onClick={onViewAll}
        className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-2xl bg-[#4366f4] hover:bg-[#3355e0] text-white text-sm font-semibold shadow-sm transition-all active:scale-95"
      >
        จัดการสมาชิก
      </button>

      {/* Pending invites */}
      {pending.length > 0 && (
        <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-100 dark:border-amber-800/30 rounded-2xl px-4 py-3">
          <p className="text-xs font-semibold text-amber-600 dark:text-amber-400 mb-2">
            รอตอบรับ {pending.length} คน
          </p>
          <div className="flex flex-col gap-2">
            {pending.map((m) => (
              <div key={m.id} className="flex items-center gap-2">
                <div className="w-7 h-7 rounded-full bg-amber-200 dark:bg-amber-800 flex items-center justify-center text-amber-700 dark:text-amber-300 text-xs font-bold overflow-hidden flex-shrink-0">
                  {m.profile?.avatar_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={m.profile.avatar_url} alt="" className="w-full h-full object-cover" />
                  ) : (
                    (m.profile?.display_name ?? "?").slice(0, 1).toUpperCase()
                  )}
                </div>
                <span className="text-sm text-amber-700 dark:text-amber-300">
                  {m.profile?.display_name ?? m.profile?.username ?? "ไม่ทราบชื่อ"}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Member list */}
      {accepted.length === 0 ? (
        <div className="flex flex-col items-center gap-3 py-10 text-center">
          <div className="w-14 h-14 rounded-2xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center">
            <IoPeopleOutline size={24} className="text-gray-400" />
          </div>
          <p className="text-sm text-gray-500 dark:text-gray-400">ยังไม่มีสมาชิก</p>
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {accepted.map((m) => (
            <div key={m.id} className="flex items-center gap-3 bg-gray-50 dark:bg-gray-800/60 rounded-2xl px-4 py-3">
              <div className="w-9 h-9 rounded-full bg-[#4366f4] flex items-center justify-center text-white text-sm font-bold overflow-hidden flex-shrink-0">
                {m.profile?.avatar_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={m.profile.avatar_url} alt="" className="w-full h-full object-cover" />
                ) : (
                  (m.profile?.display_name ?? "?").slice(0, 1).toUpperCase()
                )}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                  {m.profile?.display_name ?? m.profile?.username ?? "ไม่ทราบชื่อ"}
                </p>
                {m.profile?.username && (
                  <p className="text-xs text-gray-400">@{m.profile.username}</p>
                )}
              </div>
              <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium flex-shrink-0 ${
                m.role === "owner"
                  ? "bg-purple-50 dark:bg-purple-900/20 text-purple-500"
                  : "bg-gray-100 dark:bg-gray-700 text-gray-500"
              }`}>
                {m.role === "owner" ? "เจ้าของ" : "สมาชิก"}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ── Bills Tab ─────────────────────────────────────────────────
function BillsTab({
  bills,
  creating,
  onCreateBill,
  onOpenBill,
  onEditBill,
  onDeleteBill,
}: {
  bills: Bill[];
  creating: boolean;
  onCreateBill: () => void;
  onOpenBill: (id: string) => void;
  onEditBill: (bill: Bill) => void;
  onDeleteBill: (bill: Bill) => void;
}) {
  return (
    <div className="flex flex-col gap-3">
      {/* Create button */}
      <div className="sticky top-0 z-10 pt-1 pb-2 bg-white dark:bg-gray-950">
        <button
          onClick={onCreateBill}
          disabled={creating}
          className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-2xl bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 text-white text-sm font-semibold shadow-sm transition-all active:scale-95"
        >
          {creating ? "กำลังสร้าง..." : "สร้างบิลใหม่"}
        </button>
      </div>

      {/* Empty state */}
      {bills.length === 0 && (
        <div
          onClick={onCreateBill}
          className="flex items-center gap-3 p-4 bg-gray-50 dark:bg-gray-800/60 rounded-2xl border border-dashed border-gray-200 dark:border-gray-700 cursor-pointer hover:border-[#4366f4]/30 transition-colors group"
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
      )}

      {/* Bill list */}
      <div className="flex flex-col gap-2">
        {bills.map((bill) => (
          <div
            key={bill.id}
            onClick={() => onOpenBill(bill.id)}
            className="flex items-center gap-3 p-4 bg-gray-50 dark:bg-gray-800/60 rounded-2xl border border-transparent hover:border-[#4366f4]/20 hover:shadow-sm transition-all cursor-pointer group"
          >
            <div className="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0 text-xl">
              {bill.emoji ?? <IoReceiptOutline size={20} className="text-[#4366f4]" />}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{bill.title}</p>
              <div className="flex items-center gap-1.5 mt-0.5 flex-wrap">
                <p className="text-xs text-gray-400">
                  {new Date(bill.updated_at).toLocaleDateString("th-TH", {
                    day: "numeric",
                    month: "short",
                    year: "numeric",
                  })}
                </p>
                {bill.tags && bill.tags.length > 0 && (
                  <>
                    {bill.tags.slice(0, 2).map((tag) => (
                      <span key={tag} className="px-1.5 py-0.5 bg-blue-50 dark:bg-blue-900/20 text-[#4366f4] text-[10px] rounded-full font-medium">
                        {tag}
                      </span>
                    ))}
                    {bill.tags.length > 2 && (
                      <span className="text-[10px] text-gray-400">+{bill.tags.length - 2}</span>
                    )}
                  </>
                )}
              </div>
            </div>
            <div className="flex items-center gap-1 flex-shrink-0">
              <button
                onClick={(e) => { e.stopPropagation(); onEditBill(bill); }}
                className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-400 hover:text-[#4366f4] hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-colors"
              >
                <IoSettingsOutline size={13} />
              </button>
              <button
                onClick={(e) => { e.stopPropagation(); onDeleteBill(bill); }}
                className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
              >
                <IoTrash size={13} />
              </button>
              <IoArrowForward size={14} className="text-gray-300 group-hover:text-[#4366f4] transition-colors ml-1" />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Group Summary Tab ─────────────────────────────────────────
function GroupSummaryTab({ bills, currentUserId }: { bills: Bill[]; currentUserId?: string | null }) {
  const [expandedBillId, setExpandedBillId] = useState<string | null>(
    bills.length === 1 ? bills[0].id : null
  );

  const totalAmount = bills.reduce((sum, b) => {
    const items = b.items ?? [];
    return sum + items.reduce((s, i) => s + i.price, 0);
  }, 0);

  if (bills.length === 0) {
    return (
      <div className="flex flex-col items-center gap-3 py-10 text-center">
        <div className="w-14 h-14 rounded-2xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center">
          <IoBarChartOutline size={24} className="text-gray-400" />
        </div>
        <p className="text-sm text-gray-500 dark:text-gray-400">ยังไม่มีบิลในกลุ่ม</p>
        <p className="text-xs text-gray-400">สร้างบิลก่อนเพื่อดูสรุป</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      {/* Hero */}
      <div className="bg-gradient-to-br from-[#4366f4] to-[#6b8aff] rounded-3xl p-5 text-white">
        <p className="text-sm font-medium opacity-80">ยอดรวมทั้งกลุ่ม</p>
        <p className="text-3xl font-bold tracking-tight mt-1">
          {totalAmount.toLocaleString("th-TH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} บาท
        </p>
        <p className="text-xs opacity-70 mt-1">{bills.length} บิล</p>
      </div>

      {/* Per-bill summaries */}
      <div className="flex flex-col gap-3">
        <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide px-1">
          สรุปแยกตามบิล
        </h3>
        {bills.map((bill) => {
          const billTotal = (bill.items ?? []).reduce((s, i) => s + i.price, 0);
          const isExpanded = expandedBillId === bill.id;
          const billMembers = bill.members ?? [];
          return (
            <div key={bill.id} className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl overflow-hidden">
              {/* Bill header — tap to expand */}
              <button
                onClick={() => setExpandedBillId(isExpanded ? null : bill.id)}
                className="w-full flex items-center gap-3 px-4 py-3 text-left"
              >
                <div className="w-9 h-9 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0 text-lg">
                  {bill.emoji ?? <IoReceiptOutline size={18} className="text-[#4366f4]" />}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{bill.title}</p>
                  <p className="text-xs text-gray-400">
                    {(bill.items ?? []).length} รายการ · {billMembers.length} คน
                  </p>
                </div>
                <div className="flex items-center gap-2 flex-shrink-0">
                  <p className="text-sm font-bold text-gray-900 dark:text-white">
                    {billTotal.toLocaleString("th-TH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} บาท
                  </p>
                  {isExpanded ? (
                    <IoChevronUp size={14} className="text-gray-400" />
                  ) : (
                    <IoChevronDown size={14} className="text-gray-400" />
                  )}
                </div>
              </button>

              {/* Expanded: full SummaryPage for this bill */}
              {isExpanded && (
                <div className="border-t border-gray-100 dark:border-gray-700/50 px-4 py-4">
                  <SummaryPage
                    bill={{ ...bill, members: billMembers, items: bill.items ?? [] }}
                    members={billMembers}
                    currentUserId={currentUserId}
                  />
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ── Group Analytics Tab ───────────────────────────────────────
function GroupAnalyticsTab({ bills }: { bills: Bill[] }) {
  // Aggregate all items across all bills
  const allItems = bills.flatMap((b) => b.items ?? []);
  const totalAmount = allItems.reduce((s, i) => s + i.price, 0);

  // Top items by price
  const topItems = [...allItems]
    .sort((a, b) => b.price - a.price)
    .slice(0, 5);

  if (bills.length === 0) {
    return (
      <div className="flex flex-col items-center gap-3 py-10 text-center">
        <div className="w-14 h-14 rounded-2xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center">
          <IoAnalyticsOutline size={24} className="text-gray-400" />
        </div>
        <p className="text-sm text-gray-500 dark:text-gray-400">ยังไม่มีข้อมูลวิเคราะห์</p>
        <p className="text-xs text-gray-400">สร้างบิลและเพิ่มรายการก่อน</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      {/* Stats row */}
      <div className="grid grid-cols-3 gap-3">
        <StatCard label="บิลทั้งหมด" value={String(bills.length)} unit="บิล" color="text-[#4366f4]" />
        <StatCard label="รายการทั้งหมด" value={String(allItems.length)} unit="รายการ" color="text-purple-500" />
        <StatCard
          label="เฉลี่ย/บิล"
          value={(bills.length > 0 ? totalAmount / bills.length : 0).toLocaleString("th-TH", { maximumFractionDigits: 0 })}
          unit="บาท"
          color="text-emerald-500"
        />
      </div>

      {/* Top items */}
      {topItems.length > 0 && (
        <div className="flex flex-col gap-2">
          <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide px-1">
            รายการราคาสูงสุด
          </h3>
          <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl overflow-hidden">
            {topItems.map((item, i) => {
              const pct = totalAmount > 0 ? (item.price / totalAmount) * 100 : 0;
              return (
                <div key={item.id} className={`px-4 py-3 flex items-center gap-3 ${i < topItems.length - 1 ? "border-b border-gray-100 dark:border-gray-700/50" : ""}`}>
                  <span className="text-xs font-bold text-gray-400 w-4 flex-shrink-0">{i + 1}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 dark:text-white truncate">{item.name}</p>
                    <div className="mt-1 h-1.5 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-[#4366f4] rounded-full"
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                  </div>
                  <p className="text-sm font-bold text-gray-900 dark:text-white flex-shrink-0">
                    {item.price.toLocaleString("th-TH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} บาท
                  </p>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Bills over time */}
      <div className="flex flex-col gap-2">
        <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide px-1">
          บิลล่าสุด
        </h3>
        <div className="flex flex-col gap-2">
          {[...bills].sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()).slice(0, 5).map((bill) => {
            const billTotal = (bill.items ?? []).reduce((s, i) => s + i.price, 0);
            const pct = totalAmount > 0 ? (billTotal / totalAmount) * 100 : 0;
            return (
              <div key={bill.id} className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl px-4 py-3">
                <div className="flex items-center justify-between mb-1.5">
                  <p className="text-sm font-semibold text-gray-900 dark:text-white truncate flex-1">{bill.title}</p>
                  <p className="text-sm font-bold text-gray-900 dark:text-white flex-shrink-0 ml-2">
                    {billTotal.toLocaleString("th-TH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} บาท
                  </p>
                </div>
                <div className="h-1.5 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-[#4366f4] to-[#6b8aff] rounded-full"
                    style={{ width: `${pct}%` }}
                  />
                </div>
                <p className="text-[10px] text-gray-400 mt-1">
                  {new Date(bill.updated_at).toLocaleDateString("th-TH", { day: "numeric", month: "short", year: "numeric" })}
                  {" · "}{pct.toFixed(1)}% ของทั้งหมด
                </p>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function StatCard({ label, value, unit, color }: { label: string; value: string; unit: string; color: string }) {
  return (
    <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-3 flex flex-col gap-1">
      <p className="text-[10px] text-gray-400 font-medium">{label}</p>
      <p className={`text-xl font-bold ${color}`}>{value}</p>
      <p className="text-[10px] text-gray-400">{unit}</p>
    </div>
  );
}
