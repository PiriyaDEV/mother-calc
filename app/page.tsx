"use client";

import {
  useEffect,
  useState,
  useCallback,
  useMemo,
  useRef,
  Suspense,
} from "react";
import { useRouter, useSearchParams } from "next/navigation";
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
  getMyNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  respondToGroupInvite,
  getMyProfile,
  upsertProfile,
  isUsernameTaken,
  uploadAvatar,
  ensureMyProfile,
} from "@/lib/db";
import { Group, Bill, Notification, Profile } from "@/lib/types";
import { FEATURES } from "@/lib/constants";
import { isValidUsername } from "@/lib/utils";
import { useTheme } from "@/hooks/useTheme";
import CreateEntityModal, {
  EntityFormData,
} from "@/components/ui/CreateEntityModal";
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
  IoPeopleCircleOutline,
  IoChevronForward,
  IoSettingsOutline,
  IoWalletOutline,
  IoHomeOutline,
  IoHome,
  IoReceipt,
  IoPeople,
  IoPeopleSharp,
  IoPersonOutline,
  IoPerson,
  IoCheckmarkDone,
  IoNotificationsOutline,
  IoPencil,
  IoCheckmark,
  IoClose,
  IoCamera,
  IoMoonOutline,
  IoSunnyOutline,
  IoLogOutOutline,
  IoPersonCircleOutline,
  IoTrendingUpOutline,
  IoFlameOutline,
  IoStarOutline,
  IoCalendarOutline,
} from "react-icons/io5";

// ── helpers ───────────────────────────────────────────────────
function getBillTotal(bill: Bill): number {
  return (bill.items ?? []).reduce((s, i) => s + i.price, 0);
}
function formatBaht(n: number): string {
  return n.toLocaleString("th-TH", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

type HomeTab = "home" | "bills" | "groups" | "friends" | "me";

// ── Bottom Nav ────────────────────────────────────────────────
function BottomNav({
  tab,
  setTab,
  friendBadge,
}: {
  tab: HomeTab;
  setTab: (t: HomeTab) => void;
  friendBadge: number;
}) {
  const items: {
    id: HomeTab;
    label: string;
    icon: React.ReactNode;
    activeIcon: React.ReactNode;
  }[] = [
    {
      id: "home",
      label: "หน้าหลัก",
      icon: <IoHomeOutline size={22} />,
      activeIcon: <IoHome size={22} />,
    },
    {
      id: "bills",
      label: "บิลของฉัน",
      icon: <IoReceiptOutline size={22} />,
      activeIcon: <IoReceipt size={22} />,
    },
    {
      id: "groups",
      label: "กลุ่ม",
      icon: <IoPeopleOutline size={22} />,
      activeIcon: <IoPeopleSharp size={22} />,
    },
    {
      id: "friends",
      label: "เพื่อน",
      icon: <IoPeopleCircleOutline size={22} />,
      activeIcon: <IoPeople size={22} />,
    },
    {
      id: "me",
      label: "ฉัน",
      icon: <IoPersonOutline size={22} />,
      activeIcon: <IoPerson size={22} />,
    },
  ];
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-white/95 dark:bg-gray-900/95 backdrop-blur-md border-t border-gray-100 dark:border-gray-800 safe-area-pb">
      <div className="max-w-lg mx-auto flex items-center">
        {items.map((item) => (
          <button
            key={item.id}
            onClick={() => setTab(item.id)}
            className={`flex-1 flex flex-col items-center gap-0.5 py-2.5 transition-colors relative ${
              tab === item.id
                ? "text-[#4366f4]"
                : "text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
            }`}
          >
            {tab === item.id ? item.activeIcon : item.icon}
            <span className="text-[10px] font-medium">{item.label}</span>
            {item.id === "friends" && friendBadge > 0 && (
              <span className="absolute top-2 right-[calc(50%-14px)] w-4 h-4 bg-red-500 text-white text-[9px] font-bold rounded-full flex items-center justify-center">
                {friendBadge > 9 ? "9+" : friendBadge}
              </span>
            )}
          </button>
        ))}
      </div>
    </nav>
  );
}

// ── Main Home Page ────────────────────────────────────────────
export default function HomePageWrapper() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-white dark:bg-gray-950">
          <div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" />
        </div>
      }
    >
      <HomePage />
    </Suspense>
  );
}

function HomePage() {
  const { user, loading, signInWithGoogle, configured } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();

  // Read ?tab= from URL (used when navigating back from sub-pages)
  const initialTab = (searchParams.get("tab") as HomeTab | null) ?? "home";
  const [tab, setTab] = useState<HomeTab>(initialTab);

  // Sync tab if URL param changes (e.g. browser back/forward)
  useEffect(() => {
    const t = searchParams.get("tab") as HomeTab | null;
    if (t && ["home", "bills", "groups", "friends", "me"].includes(t)) {
      setTab(t);
    }
  }, [searchParams]);
  const [groups, setGroups] = useState<Group[]>([]);
  const [personalBills, setPersonalBills] = useState<Bill[]>([]);
  const [groupBills, setGroupBills] = useState<Record<string, Bill[]>>({});
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [dataLoading, setDataLoading] = useState(false);
  const [creating, setCreating] = useState(false);
  const [showCreateGroup, setShowCreateGroup] = useState(false);
  const [showCreateBill, setShowCreateBill] = useState(false);
  const [editingBill, setEditingBill] = useState<Bill | null>(null);
  const [editingGroup, setEditingGroup] = useState<Group | null>(null);
  const [confirmDeleteBill, setConfirmDeleteBill] = useState<Bill | null>(null);
  const [confirmDeleteGroup, setConfirmDeleteGroup] = useState<Group | null>(
    null,
  );

  const loadData = useCallback(async () => {
    if (!user) return;
    setDataLoading(true);
    try {
      await ensureMyProfile();
      const [grps, bills, notifs, prof] = await Promise.all([
        getMyGroups(),
        getIndividualBills(),
        getMyNotifications(),
        getMyProfile(),
      ]);
      setGroups(grps);
      setPersonalBills(bills);
      setNotifications(notifs);
      setProfile(prof);

      const billMap: Record<string, Bill[]> = {};
      await Promise.all(
        grps.map(async (g) => {
          billMap[g.id] = await getBills({ groupId: g.id });
        }),
      );
      setGroupBills(billMap);
    } finally {
      setDataLoading(false);
    }
  }, [user]);

  useEffect(() => {
    if (user) loadData();
  }, [user, loadData]);

  // ── Computed ──────────────────────────────────────────────
  const personalTotal = useMemo(
    () => personalBills.reduce((s, b) => s + getBillTotal(b), 0),
    [personalBills],
  );
  const groupTotals = useMemo(() => {
    const map: Record<string, number> = {};
    for (const [gid, bills] of Object.entries(groupBills))
      map[gid] = bills.reduce((s, b) => s + getBillTotal(b), 0);
    return map;
  }, [groupBills]);
  const grandTotal = useMemo(
    () => personalTotal + Object.values(groupTotals).reduce((s, v) => s + v, 0),
    [personalTotal, groupTotals],
  );
  const unreadCount = useMemo(
    () => notifications.filter((n) => !n.read).length,
    [notifications],
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
      setShowCreateBill(false);
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
          ? {
              ...b,
              title: data.name,
              emoji: data.emoji,
              tags: data.tags,
              settings: data.settings ?? b.settings,
            }
          : b,
      ),
    );
    setEditingBill(null);
  };

  const handleDeleteBill = async () => {
    if (!confirmDeleteBill) return;
    await deleteBill(confirmDeleteBill.id);
    setPersonalBills((prev) =>
      prev.filter((b) => b.id !== confirmDeleteBill.id),
    );
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
          ? {
              ...g,
              name: data.name,
              description: data.description || null,
              emoji: data.emoji,
              tags: data.tags,
            }
          : g,
      ),
    );
    setEditingGroup(null);
  };

  const handleDeleteGroup = async () => {
    if (!confirmDeleteGroup) return;
    await deleteGroup(confirmDeleteGroup.id);
    setGroups((prev) => prev.filter((g) => g.id !== confirmDeleteGroup.id));
    setConfirmDeleteGroup(null);
  };

  // ── Logged-in App ──────────────────────────────────────────
  if (user) {
    const avatarUrl = user.user_metadata?.avatar_url as string | undefined;
    const displayName =
      (user.user_metadata?.full_name as string | undefined) ||
      user.email?.split("@")[0] ||
      "คุณ";
    const firstName = displayName.split(" ")[0];
    const initials = displayName.slice(0, 1).toUpperCase();

    return (
      <div className="min-h-screen bg-[#f4f6fb] dark:bg-gray-950 flex flex-col pb-20">
        {/* Top Header */}
        <header className="sticky top-0 z-40 bg-white/90 dark:bg-gray-900/90 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
          <div className="max-w-lg mx-auto px-4 h-16 flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-[#4366f4] flex items-center justify-center shadow-sm">
                <span className="text-white text-sm font-bold">฿</span>
              </div>
              <span className="text-xl font-bold text-gray-900 dark:text-white tracking-tight">
                Kidtang
              </span>
            </div>
            {/* Avatar */}
            <button
              onClick={() => setTab("me")}
              className="w-9 h-9 rounded-full overflow-hidden flex items-center justify-center bg-[#4366f4] text-white text-sm font-bold flex-shrink-0 ring-2 ring-white dark:ring-gray-900"
            >
              {avatarUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={avatarUrl}
                  alt={displayName}
                  className="w-full h-full object-cover"
                />
              ) : (
                initials
              )}
            </button>
          </div>
        </header>

        {/* Tab Content */}
        <main className="flex-1 max-w-lg mx-auto w-full px-4 py-5">
          {tab === "home" && (
            <HomeTab
              firstName={firstName}
              grandTotal={grandTotal}
              personalTotal={personalTotal}
              groupTotals={groupTotals}
              groups={groups}
              personalBills={personalBills}
              groupBills={groupBills}
              dataLoading={dataLoading}
              onCreateBill={() => setShowCreateBill(true)}
              onCreateGroup={() => setShowCreateGroup(true)}
              onGoToBills={() => setTab("bills")}
              onGoToGroups={() => setTab("groups")}
            />
          )}
          {tab === "bills" && (
            <BillsTab
              bills={personalBills}
              creating={creating}
              onCreateBill={() => setShowCreateBill(true)}
              onOpenBill={(id) => router.push(`/app?id=${id}`)}
              onEditBill={setEditingBill}
              onDeleteBill={setConfirmDeleteBill}
              personalTotal={personalTotal}
              dataLoading={dataLoading}
            />
          )}
          {tab === "groups" && (
            <GroupsTab
              groups={groups}
              groupBills={groupBills}
              groupTotals={groupTotals}
              dataLoading={dataLoading}
              onCreateGroup={() => setShowCreateGroup(true)}
              onOpenGroup={(id) => router.push(`/groups/${id}`)}
              onEditGroup={setEditingGroup}
            />
          )}
          {tab === "friends" && (
            <FriendsTab
              notifications={notifications}
              setNotifications={setNotifications}
              router={router}
            />
          )}
          {tab === "me" && (
            <MeTab user={user} profile={profile} setProfile={setProfile} />
          )}
        </main>

        {/* Bottom Nav */}
        <BottomNav tab={tab} setTab={setTab} friendBadge={unreadCount} />

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
            onDelete={() => {
              setEditingGroup(null);
              setConfirmDeleteGroup(editingGroup);
            }}
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
            description="บิลทั้งหมดในกลุ่มจะถูกลบด้วย"
            confirmLabel="ลบกลุ่ม"
            danger
            onConfirm={handleDeleteGroup}
            onCancel={() => setConfirmDeleteGroup(null)}
          />
        )}
      </div>
    );
  }

  // ── Landing Page ──────────────────────────────────────────
  const handleCTA = () =>
    configured ? router.push("/login") : setShowCreateBill(true);

  return (
    <div className="min-h-screen bg-[#f8f9fc] dark:bg-gray-950 flex flex-col">
      <nav className="sticky top-0 z-40 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
        <div className="max-w-5xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-xl bg-[#4366f4] flex items-center justify-center">
              <span className="text-white text-sm font-bold">฿</span>
            </div>
            <span className="text-xl font-bold text-gray-900 dark:text-white">
              Kidtang
            </span>
          </div>
          <button
            onClick={handleCTA}
            className="flex items-center gap-2 px-4 py-2 bg-[#4366f4] hover:bg-[#3355e0] text-white text-sm font-semibold rounded-xl transition-colors"
          >
            เริ่มใช้งาน <IoArrowForward size={14} />
          </button>
        </div>
      </nav>
      <section className="flex-1 flex flex-col items-center justify-center px-6 py-20 text-center">
        <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-blue-50 dark:bg-blue-900/20 text-[#4366f4] text-xs font-semibold rounded-full mb-6 border border-blue-100 dark:border-blue-800">
          <IoSparkles size={12} /> หารบิลง่าย ไม่ต้องคิดเอง
        </div>
        <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 dark:text-white leading-tight mb-4 max-w-xl">
          หารบิลกับเพื่อน
          <br />
          <span className="text-[#4366f4]">ง่ายกว่าที่เคย</span>
        </h1>
        <p className="text-base text-gray-500 dark:text-gray-400 max-w-md mb-10 leading-relaxed">
          คำนวณค่าใช้จ่าย หารเท่า หรือไม่เท่า รองรับ VAT, Service Charge, ทิป
          และส่วนลด พร้อม QR PromptPay
        </p>
        <div className="flex flex-col sm:flex-row gap-3 items-center">
          {configured && FEATURES.GOOGLE_LOGIN && (
            <button
              onClick={signInWithGoogle}
              className="flex items-center gap-2 px-6 py-3.5 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 text-gray-800 dark:text-white text-sm font-semibold rounded-2xl hover:bg-gray-50 dark:hover:bg-gray-800 transition-all hover:-translate-y-0.5 shadow-sm"
            >
              <IoLogoGoogle size={16} className="text-[#4285f4]" />{" "}
              เข้าสู่ระบบด้วย Google
            </button>
          )}
          <button
            onClick={handleCTA}
            disabled={creating}
            className="flex items-center gap-2 px-6 py-3.5 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 text-white text-sm font-semibold rounded-2xl shadow-sm hover:shadow-md transition-all hover:-translate-y-0.5"
          >
            {creating ? "กำลังสร้าง..." : "เริ่มใช้งานเลย"}{" "}
            <IoArrowForward size={14} />
          </button>
        </div>
        <div className="flex items-center gap-6 mt-10 text-xs text-gray-400">
          {["ฟรี 100%", "ไม่ต้องลงทะเบียน", "บันทึกอัตโนมัติ"].map((t) => (
            <span key={t} className="flex items-center gap-1.5">
              <IoCheckmarkCircle size={14} className="text-emerald-500" />
              {t}
            </span>
          ))}
        </div>
      </section>
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
              <div
                className={`w-10 h-10 rounded-xl flex items-center justify-center mb-3 ${f.color}`}
              >
                {f.icon}
              </div>
              <h3 className="text-sm font-bold text-gray-900 dark:text-white mb-1">
                {f.title}
              </h3>
              <p className="text-xs text-gray-500 dark:text-gray-400 leading-relaxed">
                {f.desc}
              </p>
            </div>
          ))}
        </div>
      </section>
      <footer className="border-t border-gray-100 dark:border-gray-800 py-6 text-center">
        <p className="text-xs text-gray-400">
          © 2025 Kidtang · หารบิลง่ายๆ สำหรับทุกคน
        </p>
      </footer>
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

// ══════════════════════════════════════════════════════════════
// TAB: หน้าหลัก (Dashboard)
// ══════════════════════════════════════════════════════════════
function HomeTab({
  firstName,
  grandTotal,
  personalTotal,
  groupTotals,
  groups,
  personalBills,
  groupBills,
  dataLoading,
  onCreateBill,
  onCreateGroup,
  onGoToBills,
  onGoToGroups,
}: {
  firstName: string;
  grandTotal: number;
  personalTotal: number;
  groupTotals: Record<string, number>;
  groups: Group[];
  personalBills: Bill[];
  groupBills: Record<string, Bill[]>;
  dataLoading: boolean;
  onCreateBill: () => void;
  onCreateGroup: () => void;
  onGoToBills: () => void;
  onGoToGroups: () => void;
}) {
  const allBills = useMemo(() => {
    const gb = Object.values(groupBills).flat();
    return [...personalBills, ...gb];
  }, [personalBills, groupBills]);

  const totalItems = useMemo(
    () => allBills.reduce((s, b) => s + (b.items ?? []).length, 0),
    [allBills],
  );
  const avgBill = allBills.length > 0 ? grandTotal / allBills.length : 0;
  const biggestBill = useMemo(
    () => [...allBills].sort((a, b) => getBillTotal(b) - getBillTotal(a))[0],
    [allBills],
  );
  const recentBills = useMemo(
    () =>
      [...allBills]
        .sort(
          (a, b) =>
            new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime(),
        )
        .slice(0, 3),
    [allBills],
  );

  return (
    <div className="flex flex-col gap-5">
      {/* Hero */}
      <div className="bg-gradient-to-br from-[#4366f4] to-[#6b8aff] rounded-3xl p-5 text-white shadow-lg shadow-blue-200/40 dark:shadow-none">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-sm font-medium opacity-80">
              สวัสดี, {firstName} 👋
            </p>
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
              <p className="text-3xl font-bold tracking-tight">
                {formatBaht(grandTotal)} บาท
              </p>
              <div className="flex items-center gap-3 mt-2">
                <span className="text-xs opacity-70">
                  {groups.length} กลุ่ม
                </span>
                <span className="text-xs opacity-40">·</span>
                <span className="text-xs opacity-70">
                  {personalBills.length} บิลส่วนตัว
                </span>
                <span className="text-xs opacity-40">·</span>
                <span className="text-xs opacity-70">{totalItems} รายการ</span>
              </div>
            </>
          )}
        </div>
      </div>

      {/* Quick actions */}
      <div className="grid grid-cols-2 gap-3">
        <button
          onClick={onCreateGroup}
          className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 hover:border-purple-200 hover:shadow-sm transition-all"
        >
          <div className="w-9 h-9 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center flex-shrink-0">
            <IoPeopleOutline size={18} className="text-purple-500" />
          </div>
          <div className="text-left">
            <p className="text-sm font-semibold text-gray-800 dark:text-white">
              กลุ่มใหม่
            </p>
            <p className="text-[10px] text-gray-400 mt-0.5">หารกับเพื่อน</p>
          </div>
        </button>
        <button
          onClick={onCreateBill}
          className="flex items-center gap-3 p-4 bg-[#4366f4] hover:bg-[#3355e0] rounded-2xl shadow-sm hover:shadow-md transition-all"
        >
          <div className="w-9 h-9 rounded-xl bg-white/20 flex items-center justify-center flex-shrink-0">
            <IoReceiptOutline size={18} className="text-white" />
          </div>
          <div className="text-left">
            <p className="text-sm font-semibold text-white">บิลใหม่</p>
            <p className="text-[10px] text-white/70 mt-0.5">บิลส่วนตัว</p>
          </div>
        </button>
      </div>

      {dataLoading ? (
        <div className="flex items-center justify-center py-10">
          <div className="w-6 h-6 border-2 border-[#4366f4] border-t-transparent rounded-full animate-spin" />
        </div>
      ) : (
        <>
          {/* Stats / Facts */}
          {allBills.length > 0 && (
            <div className="flex flex-col gap-3">
              <h2 className="text-sm font-bold text-gray-900 dark:text-white">
                สถิติของคุณ
              </h2>
              <div className="grid grid-cols-2 gap-3">
                <FactCard
                  icon={<IoTrendingUpOutline size={18} />}
                  label="เฉลี่ยต่อบิล"
                  value={`${formatBaht(avgBill)} บาท`}
                  color="text-[#4366f4]"
                  bg="bg-blue-50 dark:bg-blue-900/20"
                />
                <FactCard
                  icon={<IoReceiptOutline size={18} />}
                  label="บิลทั้งหมด"
                  value={`${allBills.length} บิล`}
                  color="text-purple-500"
                  bg="bg-purple-50 dark:bg-purple-900/20"
                />
                <FactCard
                  icon={<IoFlameOutline size={18} />}
                  label="รายการทั้งหมด"
                  value={`${totalItems} รายการ`}
                  color="text-orange-500"
                  bg="bg-orange-50 dark:bg-orange-900/20"
                />
                <FactCard
                  icon={<IoStarOutline size={18} />}
                  label="บิลใหญ่สุด"
                  value={
                    biggestBill
                      ? `${formatBaht(getBillTotal(biggestBill))} บาท`
                      : "—"
                  }
                  color="text-amber-500"
                  bg="bg-amber-50 dark:bg-amber-900/20"
                />
              </div>

              {/* Biggest bill highlight */}
              {biggestBill && (
                <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <IoStarOutline size={14} className="text-amber-500" />
                    <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">
                      บิลที่ใหญ่ที่สุด
                    </p>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-amber-50 dark:bg-amber-900/20 flex items-center justify-center text-xl flex-shrink-0">
                      {biggestBill.emoji ?? (
                        <IoReceiptOutline
                          size={18}
                          className="text-amber-500"
                        />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                        {biggestBill.title}
                      </p>
                      <p className="text-xs text-gray-400">
                        {(biggestBill.items ?? []).length} รายการ
                      </p>
                    </div>
                    <p className="text-base font-bold text-amber-500 flex-shrink-0">
                      {formatBaht(getBillTotal(biggestBill))} บาท
                    </p>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Recent activity */}
          {recentBills.length > 0 && (
            <div className="flex flex-col gap-2">
              <div className="flex items-center justify-between">
                <h2 className="text-sm font-bold text-gray-900 dark:text-white">
                  กิจกรรมล่าสุด
                </h2>
                <button
                  onClick={onGoToBills}
                  className="text-xs text-[#4366f4] font-medium"
                >
                  ดูทั้งหมด
                </button>
              </div>
              {recentBills.map((bill) => (
                <div
                  key={bill.id}
                  className="flex items-center gap-3 p-3 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800"
                >
                  <div className="w-9 h-9 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center text-lg flex-shrink-0">
                    {bill.emoji ?? (
                      <IoReceiptOutline size={16} className="text-[#4366f4]" />
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                      {bill.title}
                    </p>
                    <p className="text-xs text-gray-400 flex items-center gap-1">
                      <IoCalendarOutline size={10} />
                      {new Date(bill.updated_at).toLocaleDateString("th-TH", {
                        day: "numeric",
                        month: "short",
                      })}
                    </p>
                  </div>
                  <p className="text-sm font-bold text-gray-900 dark:text-white flex-shrink-0">
                    {formatBaht(getBillTotal(bill))} บาท
                  </p>
                </div>
              ))}
            </div>
          )}

          {/* Empty state */}
          {allBills.length === 0 && (
            <div className="flex flex-col items-center gap-4 py-10 text-center">
              <div className="w-16 h-16 rounded-2xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center">
                <IoReceiptOutline size={28} className="text-[#4366f4]" />
              </div>
              <div>
                <p className="text-sm font-semibold text-gray-700 dark:text-gray-300">
                  ยังไม่มีบิล
                </p>
                <p className="text-xs text-gray-400 mt-1">
                  สร้างบิลแรกหรือเข้าร่วมกลุ่มเพื่อเริ่มต้น
                </p>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={onCreateBill}
                  className="px-4 py-2 bg-[#4366f4] text-white text-xs font-semibold rounded-xl"
                >
                  สร้างบิล
                </button>
                <button
                  onClick={onCreateGroup}
                  className="px-4 py-2 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 text-xs font-semibold rounded-xl"
                >
                  สร้างกลุ่ม
                </button>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}

function FactCard({
  icon,
  label,
  value,
  color,
  bg,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  color: string;
  bg: string;
}) {
  return (
    <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 flex items-center gap-3">
      <div
        className={`w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 ${bg} ${color}`}
      >
        {icon}
      </div>
      <div className="min-w-0">
        <p className="text-[10px] text-gray-400 font-medium">{label}</p>
        <p className="text-sm font-bold text-gray-900 dark:text-white truncate">
          {value}
        </p>
      </div>
    </div>
  );
}

// ══════════════════════════════════════════════════════════════
// TAB: บิลของฉัน
// ══════════════════════════════════════════════════════════════
function BillsTab({
  bills,
  creating,
  onCreateBill,
  onOpenBill,
  onEditBill,
  onDeleteBill,
  personalTotal,
  dataLoading,
}: {
  bills: Bill[];
  creating: boolean;
  onCreateBill: () => void;
  onOpenBill: (id: string) => void;
  onEditBill: (b: Bill) => void;
  onDeleteBill: (b: Bill) => void;
  personalTotal: number;
  dataLoading: boolean;
}) {
  return (
    <div className="flex flex-col gap-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">
            บิลของฉัน
          </h1>
          {bills.length > 0 && (
            <p className="text-xs text-gray-400 mt-0.5">
              รวม {formatBaht(personalTotal)} บาท
            </p>
          )}
        </div>
        <button
          onClick={onCreateBill}
          disabled={creating}
          className="flex items-center gap-1.5 px-3 py-2 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 text-white text-xs font-semibold rounded-xl transition-colors"
        >
          <IoAdd size={14} /> {creating ? "กำลังสร้าง..." : "สร้างบิล"}
        </button>
      </div>

      {dataLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="w-6 h-6 border-2 border-[#4366f4] border-t-transparent rounded-full animate-spin" />
        </div>
      ) : bills.length === 0 ? (
        <div
          onClick={onCreateBill}
          className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-dashed border-gray-200 dark:border-gray-700 cursor-pointer hover:border-[#4366f4]/30 transition-colors group"
        >
          <div className="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
            <IoReceiptOutline size={20} className="text-[#4366f4]" />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
              สร้างบิลแรก
            </p>
            <p className="text-xs text-gray-400 mt-0.5">
              บิลส่วนตัวไม่ผูกกับกลุ่ม
            </p>
          </div>
          <IoAdd
            size={16}
            className="text-gray-300 group-hover:text-[#4366f4] ml-auto transition-colors"
          />
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {bills.map((bill) => {
            const bTotal = getBillTotal(bill);
            return (
              <div
                key={bill.id}
                onClick={() => onOpenBill(bill.id)}
                className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 hover:border-[#4366f4]/20 hover:shadow-sm transition-all cursor-pointer group"
              >
                <div className="w-11 h-11 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0 text-xl">
                  {bill.emoji ?? (
                    <IoReceiptOutline size={20} className="text-[#4366f4]" />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                    {bill.title}
                  </p>
                  <div className="flex items-center gap-1.5 mt-0.5 flex-wrap">
                    <p className="text-xs text-gray-400">
                      {new Date(bill.updated_at).toLocaleDateString("th-TH", {
                        day: "numeric",
                        month: "short",
                      })}
                    </p>
                    {bill.tags?.slice(0, 1).map((tag) => (
                      <span
                        key={tag}
                        className="px-1.5 py-0.5 bg-blue-50 dark:bg-blue-900/20 text-[#4366f4] text-[10px] rounded-full font-medium"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
                <div className="text-right flex-shrink-0 flex items-center gap-1">
                  <div>
                    <p className="text-sm font-bold text-gray-900 dark:text-white">
                      {formatBaht(bTotal)}
                    </p>
                    <p className="text-[10px] text-gray-400">บาท</p>
                  </div>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      onEditBill(bill);
                    }}
                    className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-300 hover:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                  >
                    <IoSettingsOutline size={13} />
                  </button>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      onDeleteBill(bill);
                    }}
                    className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-300 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                  >
                    <IoTrash size={13} />
                  </button>
                  <IoArrowForward
                    size={14}
                    className="text-gray-300 group-hover:text-[#4366f4] transition-colors"
                  />
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ══════════════════════════════════════════════════════════════
// TAB: กลุ่ม
// ══════════════════════════════════════════════════════════════
function GroupsTab({
  groups,
  groupBills,
  groupTotals,
  dataLoading,
  onCreateGroup,
  onOpenGroup,
  onEditGroup,
}: {
  groups: Group[];
  groupBills: Record<string, Bill[]>;
  groupTotals: Record<string, number>;
  dataLoading: boolean;
  onCreateGroup: () => void;
  onOpenGroup: (id: string) => void;
  onEditGroup: (g: Group) => void;
}) {
  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">
            กลุ่มของฉัน
          </h1>
          {groups.length > 0 && (
            <p className="text-xs text-gray-400 mt-0.5">
              {groups.length} กลุ่ม
            </p>
          )}
        </div>
        <button
          onClick={onCreateGroup}
          className="flex items-center gap-1.5 px-3 py-2 bg-purple-500 hover:bg-purple-600 text-white text-xs font-semibold rounded-xl transition-colors"
        >
          <IoAdd size={14} /> สร้างกลุ่ม
        </button>
      </div>

      {dataLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="w-6 h-6 border-2 border-[#4366f4] border-t-transparent rounded-full animate-spin" />
        </div>
      ) : groups.length === 0 ? (
        <div
          onClick={onCreateGroup}
          className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-dashed border-gray-200 dark:border-gray-700 cursor-pointer hover:border-purple-300 transition-colors group"
        >
          <div className="w-10 h-10 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center flex-shrink-0">
            <IoPeopleCircleOutline size={22} className="text-purple-400" />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
              สร้างกลุ่มแรก
            </p>
            <p className="text-xs text-gray-400 mt-0.5">
              หารบิลกับเพื่อนหรือครอบครัว
            </p>
          </div>
          <IoAdd
            size={16}
            className="text-gray-300 group-hover:text-purple-400 ml-auto transition-colors"
          />
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {groups.map((group) => {
            const gTotal = groupTotals[group.id] ?? 0;
            const billCount = (groupBills[group.id] ?? []).length;
            return (
              <div
                key={group.id}
                onClick={() => onOpenGroup(group.id)}
                className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 hover:border-purple-200 hover:shadow-sm transition-all cursor-pointer group"
              >
                <div className="w-11 h-11 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center flex-shrink-0 text-xl">
                  {group.emoji ?? (
                    <IoPeopleOutline size={20} className="text-purple-500" />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                    {group.name}
                  </p>
                  <div className="flex items-center gap-1.5 mt-0.5">
                    <p className="text-xs text-gray-400">{billCount} บิล</p>
                    {group.tags?.slice(0, 1).map((tag) => (
                      <span
                        key={tag}
                        className="px-1.5 py-0.5 bg-purple-50 dark:bg-purple-900/20 text-purple-500 text-[10px] rounded-full font-medium"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
                <div className="text-right flex-shrink-0 flex items-center gap-1">
                  <div>
                    <p className="text-sm font-bold text-gray-900 dark:text-white">
                      {formatBaht(gTotal)}
                    </p>
                    <p className="text-[10px] text-gray-400">บาท</p>
                  </div>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      onEditGroup(group);
                    }}
                    className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-300 hover:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                  >
                    <IoSettingsOutline size={13} />
                  </button>
                  <IoChevronForward
                    size={14}
                    className="text-gray-300 group-hover:text-purple-400 transition-colors"
                  />
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ══════════════════════════════════════════════════════════════
// TAB: เพื่อน (Notifications / Invites)
// ══════════════════════════════════════════════════════════════
function FriendsTab({
  notifications,
  setNotifications,
  router,
}: {
  notifications: Notification[];
  setNotifications: React.Dispatch<React.SetStateAction<Notification[]>>;
  router: ReturnType<typeof useRouter>;
}) {
  const [responding, setResponding] = useState<string | null>(null);
  const unreadCount = notifications.filter((n) => !n.read).length;

  const handleMarkAllRead = async () => {
    await markAllNotificationsRead();
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
  };

  const handleRespond = async (
    notif: Notification,
    action: "accepted" | "declined",
  ) => {
    setResponding(notif.id);
    try {
      await markNotificationRead(notif.id);
      await respondToGroupInvite(
        notif.data.group_member_id,
        action === "accepted",
      );
      setNotifications((prev) =>
        prev.map((n) => (n.id === notif.id ? { ...n, read: true } : n)),
      );
      if (action === "accepted") router.push(`/groups/${notif.data.group_id}`);
    } finally {
      setResponding(null);
    }
  };

  return (
    <div className="flex flex-col gap-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">
            เพื่อน
          </h1>
          {unreadCount > 0 && (
            <p className="text-xs text-gray-400 mt-0.5">
              {unreadCount} รายการใหม่
            </p>
          )}
        </div>
        {unreadCount > 0 && (
          <button
            onClick={handleMarkAllRead}
            className="flex items-center gap-1.5 text-xs text-[#4366f4] font-medium hover:underline"
          >
            <IoCheckmarkDone size={14} /> อ่านทั้งหมด
          </button>
        )}
      </div>

      {notifications.length === 0 ? (
        <div className="flex flex-col items-center gap-4 py-16 text-center">
          <div className="w-16 h-16 rounded-2xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center">
            <IoNotificationsOutline size={28} className="text-gray-400" />
          </div>
          <div>
            <p className="text-sm font-semibold text-gray-700 dark:text-gray-300">
              ยังไม่มีการแจ้งเตือน
            </p>
            <p className="text-xs text-gray-400 mt-1">
              เมื่อมีคนเชิญคุณเข้ากลุ่ม จะแสดงที่นี่
            </p>
          </div>
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {notifications.map((notif) => (
            <div
              key={notif.id}
              onClick={() =>
                !notif.read &&
                markNotificationRead(notif.id).then(() =>
                  setNotifications((prev) =>
                    prev.map((n) =>
                      n.id === notif.id ? { ...n, read: true } : n,
                    ),
                  ),
                )
              }
              className={`p-4 rounded-2xl border transition-all ${notif.read ? "bg-white dark:bg-gray-900 border-gray-100 dark:border-gray-800" : "bg-blue-50 dark:bg-blue-900/10 border-blue-100 dark:border-blue-800/30"}`}
            >
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-xl bg-[#4366f4] flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                  {(
                    notif.data.invited_by_display_name ??
                    notif.data.invited_by_username
                  )
                    .slice(0, 1)
                    .toUpperCase()}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm text-gray-900 dark:text-white">
                    <span className="font-semibold">
                      {notif.data.invited_by_display_name ??
                        `@${notif.data.invited_by_username}`}
                    </span>{" "}
                    เชิญคุณเข้าร่วมกลุ่ม{" "}
                    <span className="font-semibold text-[#4366f4]">
                      {notif.data.group_name}
                    </span>
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
                  {!notif.read && notif.type === "group_invite" && (
                    <div className="flex gap-2 mt-3">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleRespond(notif, "accepted");
                        }}
                        disabled={responding === notif.id}
                        className="flex-1 py-2 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 text-white text-xs font-semibold rounded-xl transition-colors"
                      >
                        {responding === notif.id
                          ? "กำลังดำเนินการ..."
                          : "ยอมรับ"}
                      </button>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleRespond(notif, "declined");
                        }}
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
    </div>
  );
}

// ══════════════════════════════════════════════════════════════
// TAB: ฉัน (Profile)
// ══════════════════════════════════════════════════════════════
function MeTab({
  user,
  profile,
  setProfile,
}: {
  user: NonNullable<ReturnType<typeof useAuth>["user"]>;
  profile: Profile | null;
  setProfile: React.Dispatch<React.SetStateAction<Profile | null>>;
}) {
  const { signOut, updateDisplayName, updatePassword } = useAuth();
  const { theme, toggle: toggleTheme } = useTheme();
  const router = useRouter();

  const [editingName, setEditingName] = useState(false);
  const [editingUsername, setEditingUsername] = useState(false);
  const [editingPassword, setEditingPassword] = useState(false);
  const [editingPromptpay, setEditingPromptpay] = useState(false);
  const [nameVal, setNameVal] = useState(profile?.display_name ?? "");
  const [usernameVal, setUsernameVal] = useState(profile?.username ?? "");
  const [promptpayVal, setPromptpayVal] = useState(profile?.promptpay ?? "");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [saving, setSaving] = useState(false);
  const [uploadingAvatar, setUploadingAvatar] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const avatarInputRef = useRef<HTMLInputElement>(null);

  const showSuccess = (msg: string) => {
    setSuccess(msg);
    setTimeout(() => setSuccess(null), 3000);
  };

  const handleSaveName = async () => {
    if (!profile || !nameVal.trim()) return;
    setSaving(true);
    setError(null);
    try {
      await upsertProfile({ id: profile.id, display_name: nameVal.trim() });
      await updateDisplayName(nameVal.trim());
      setProfile((p) => (p ? { ...p, display_name: nameVal.trim() } : p));
      setEditingName(false);
      showSuccess("อัปเดตชื่อแล้ว");
    } catch {
      setError("เกิดข้อผิดพลาด กรุณาลองใหม่");
    } finally {
      setSaving(false);
    }
  };

  const handleSaveUsername = async () => {
    if (!profile || !usernameVal.trim()) return;
    if (!isValidUsername(usernameVal)) {
      setError("username ต้องเป็นตัวอักษรภาษาอังกฤษ ตัวเลข หรือ _ (3-30 ตัว)");
      return;
    }
    setSaving(true);
    setError(null);
    try {
      if (usernameVal !== profile.username) {
        const taken = await isUsernameTaken(usernameVal);
        if (taken) {
          setError("username นี้ถูกใช้งานแล้ว");
          return;
        }
      }
      await upsertProfile({ id: profile.id, username: usernameVal });
      setProfile((p) => (p ? { ...p, username: usernameVal } : p));
      setEditingUsername(false);
      showSuccess("อัปเดต username แล้ว");
    } catch {
      setError("เกิดข้อผิดพลาด กรุณาลองใหม่");
    } finally {
      setSaving(false);
    }
  };

  const handleSavePassword = async () => {
    if (newPassword.length < 6) {
      setError("รหัสผ่านต้องมีอย่างน้อย 6 ตัว");
      return;
    }
    if (newPassword !== confirmPassword) {
      setError("รหัสผ่านไม่ตรงกัน");
      return;
    }
    setSaving(true);
    setError(null);
    try {
      const err = await updatePassword(newPassword);
      if (err) {
        setError(err);
        return;
      }
      setEditingPassword(false);
      setNewPassword("");
      setConfirmPassword("");
      showSuccess("เปลี่ยนรหัสผ่านแล้ว");
    } finally {
      setSaving(false);
    }
  };

  const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !profile) return;
    if (!file.type.startsWith("image/")) {
      setError("กรุณาเลือกไฟล์รูปภาพ");
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setError("ขนาดไฟล์ต้องไม่เกิน 5 MB");
      return;
    }
    setUploadingAvatar(true);
    setError(null);
    try {
      const url = await uploadAvatar(profile.id, file);
      await upsertProfile({ id: profile.id, avatar_url: url });
      setProfile((p) => (p ? { ...p, avatar_url: url } : p));
      showSuccess("อัปเดตรูปโปรไฟล์แล้ว");
    } catch {
      setError("อัปโหลดรูปไม่สำเร็จ กรุณาลองใหม่");
    } finally {
      setUploadingAvatar(false);
      e.target.value = "";
    }
  };

  const handleSavePromptpay = async () => {
    if (!profile) return;
    setSaving(true);
    setError(null);
    try {
      const val = promptpayVal.trim() || null;
      await upsertProfile({ id: profile.id, promptpay: val });
      setProfile((p) => (p ? { ...p, promptpay: val } : p));
      setEditingPromptpay(false);
      showSuccess("อัปเดตพร้อมเพย์แล้ว");
    } catch {
      setError("เกิดข้อผิดพลาด กรุณาลองใหม่");
    } finally {
      setSaving(false);
    }
  };

  const handleSignOut = async () => {
    await signOut();
    router.push("/login");
  };
  const isGoogleUser = user?.app_metadata?.provider === "google";

  return (
    <div className="flex flex-col gap-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">ฉัน</h1>
        <button
          onClick={toggleTheme}
          className="w-9 h-9 flex items-center justify-center rounded-xl text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
          title={theme === "dark" ? "Light mode" : "Dark mode"}
        >
          {theme === "dark" ? (
            <IoSunnyOutline size={18} />
          ) : (
            <IoMoonOutline size={18} />
          )}
        </button>
      </div>

      {/* Toast */}
      {success && (
        <div className="px-4 py-3 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-2xl text-sm text-green-700 dark:text-green-400 font-medium">
          {success}
        </div>
      )}
      {error && (
        <div className="px-4 py-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-2xl text-sm text-red-600 dark:text-red-400">
          {error}
        </div>
      )}

      {/* Avatar card */}
      <div className="flex flex-col items-center gap-3 py-6 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800">
        <div className="relative">
          <div className="w-20 h-20 rounded-2xl bg-[#4366f4] flex items-center justify-center text-white text-2xl font-bold overflow-hidden">
            {profile?.avatar_url ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={profile.avatar_url}
                alt=""
                className="w-full h-full object-cover"
              />
            ) : (
              <IoPersonCircleOutline size={40} />
            )}
            {uploadingAvatar && (
              <div className="absolute inset-0 bg-black/40 flex items-center justify-center rounded-2xl">
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
              </div>
            )}
          </div>
          <button
            onClick={() => avatarInputRef.current?.click()}
            disabled={uploadingAvatar}
            className="absolute -bottom-1.5 -right-1.5 w-7 h-7 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 rounded-xl flex items-center justify-center text-white shadow-md transition-colors"
          >
            <IoCamera size={13} />
          </button>
          <input
            ref={avatarInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handleAvatarChange}
          />
        </div>
        <div className="text-center">
          <p className="text-base font-bold text-gray-900 dark:text-white">
            {profile?.display_name ?? "ไม่มีชื่อ"}
          </p>
          <p className="text-xs text-gray-400 mt-0.5">@{profile?.username}</p>
          <p className="text-xs text-gray-400">{user?.email}</p>
        </div>
      </div>

      {/* Fields */}
      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 overflow-hidden divide-y divide-gray-100 dark:divide-gray-800">
        {/* Display name */}
        <div className="px-4 py-3 flex items-center justify-between">
          <div className="flex-1 min-w-0">
            <p className="text-xs text-gray-400">ชื่อที่แสดง</p>
            {editingName ? (
              <input
                autoFocus
                value={nameVal}
                onChange={(e) => setNameVal(e.target.value)}
                className="mt-1 text-sm font-medium text-gray-900 dark:text-white bg-transparent border-b border-[#4366f4] outline-none w-full"
                onKeyDown={(e) => e.key === "Enter" && handleSaveName()}
              />
            ) : (
              <p className="text-sm font-medium text-gray-900 dark:text-white mt-0.5">
                {profile?.display_name ?? "—"}
              </p>
            )}
          </div>
          <div className="flex gap-1 flex-shrink-0">
            {editingName ? (
              <>
                <button
                  onClick={handleSaveName}
                  disabled={saving}
                  className="w-8 h-8 flex items-center justify-center rounded-xl bg-[#4366f4] text-white"
                >
                  <IoCheckmark size={14} />
                </button>
                <button
                  onClick={() => {
                    setEditingName(false);
                    setNameVal(profile?.display_name ?? "");
                    setError(null);
                  }}
                  className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
                >
                  <IoClose size={14} />
                </button>
              </>
            ) : (
              <button
                onClick={() => {
                  setEditingName(true);
                  setError(null);
                }}
                className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
              >
                <IoPencil size={14} />
              </button>
            )}
          </div>
        </div>

        {/* Username */}
        <div className="px-4 py-3 flex items-center justify-between">
          <div className="flex-1 min-w-0">
            <p className="text-xs text-gray-400">Username</p>
            {editingUsername ? (
              <div className="flex items-center gap-1 mt-1">
                <span className="text-sm text-gray-400">@</span>
                <input
                  autoFocus
                  value={usernameVal}
                  onChange={(e) => setUsernameVal(e.target.value.toLowerCase())}
                  className="text-sm font-medium text-gray-900 dark:text-white bg-transparent border-b border-[#4366f4] outline-none flex-1"
                  onKeyDown={(e) => e.key === "Enter" && handleSaveUsername()}
                />
              </div>
            ) : (
              <p className="text-sm font-medium text-gray-900 dark:text-white mt-0.5">
                @{profile?.username ?? "—"}
              </p>
            )}
          </div>
          <div className="flex gap-1 flex-shrink-0">
            {editingUsername ? (
              <>
                <button
                  onClick={handleSaveUsername}
                  disabled={saving}
                  className="w-8 h-8 flex items-center justify-center rounded-xl bg-[#4366f4] text-white"
                >
                  <IoCheckmark size={14} />
                </button>
                <button
                  onClick={() => {
                    setEditingUsername(false);
                    setUsernameVal(profile?.username ?? "");
                    setError(null);
                  }}
                  className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
                >
                  <IoClose size={14} />
                </button>
              </>
            ) : (
              <button
                onClick={() => {
                  setEditingUsername(true);
                  setError(null);
                }}
                className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
              >
                <IoPencil size={14} />
              </button>
            )}
          </div>
        </div>

        {/* PromptPay */}
        <div className="px-4 py-3 flex items-center justify-between">
          <div className="flex-1 min-w-0">
            <p className="text-xs text-gray-400">พร้อมเพย์</p>
            {editingPromptpay ? (
              <input
                autoFocus
                value={promptpayVal}
                onChange={(e) => setPromptpayVal(e.target.value)}
                placeholder="เบอร์โทร หรือ เลขบัตรประชาชน"
                className="mt-1 text-sm font-medium text-gray-900 dark:text-white bg-transparent border-b border-[#4366f4] outline-none w-full"
                onKeyDown={(e) => e.key === "Enter" && handleSavePromptpay()}
              />
            ) : (
              <p className="text-sm font-medium text-gray-900 dark:text-white mt-0.5">
                {profile?.promptpay ? (
                  <span className="flex items-center gap-1.5">
                    <span>📱</span>
                    {profile.promptpay}
                  </span>
                ) : (
                  <span className="text-gray-400">ยังไม่ได้ตั้งค่า</span>
                )}
              </p>
            )}
          </div>
          <div className="flex gap-1 flex-shrink-0">
            {editingPromptpay ? (
              <>
                <button
                  onClick={handleSavePromptpay}
                  disabled={saving}
                  className="w-8 h-8 flex items-center justify-center rounded-xl bg-[#4366f4] text-white"
                >
                  <IoCheckmark size={14} />
                </button>
                <button
                  onClick={() => {
                    setEditingPromptpay(false);
                    setPromptpayVal(profile?.promptpay ?? "");
                    setError(null);
                  }}
                  className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
                >
                  <IoClose size={14} />
                </button>
              </>
            ) : (
              <button
                onClick={() => {
                  setEditingPromptpay(true);
                  setError(null);
                }}
                className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
              >
                <IoPencil size={14} />
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Change password */}
      {!isGoogleUser && (
        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 overflow-hidden">
          <div className="px-4 py-3">
            <div className="flex items-center justify-between">
              <p className="text-sm font-medium text-gray-900 dark:text-white">
                เปลี่ยนรหัสผ่าน
              </p>
              <button
                onClick={() => {
                  setEditingPassword(!editingPassword);
                  setError(null);
                  setNewPassword("");
                  setConfirmPassword("");
                }}
                className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
              >
                {editingPassword ? (
                  <IoClose size={14} />
                ) : (
                  <IoPencil size={14} />
                )}
              </button>
            </div>
            {editingPassword && (
              <div className="flex flex-col gap-3 mt-3">
                <input
                  type="password"
                  placeholder="รหัสผ่านใหม่"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white outline-none focus:border-[#4366f4]"
                />
                <input
                  type="password"
                  placeholder="ยืนยันรหัสผ่านใหม่"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white outline-none focus:border-[#4366f4]"
                />
                <button
                  onClick={handleSavePassword}
                  disabled={saving}
                  className="w-full py-2.5 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 text-white text-sm font-semibold rounded-xl transition-colors"
                >
                  {saving ? "กำลังบันทึก..." : "บันทึก"}
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Sign out */}
      <button
        onClick={handleSignOut}
        className="flex items-center justify-center gap-2 w-full py-3.5 bg-white dark:bg-gray-900 border border-red-100 dark:border-red-900/30 rounded-2xl text-sm font-semibold text-red-500 hover:bg-red-50 dark:hover:bg-red-900/10 transition-colors"
      >
        <IoLogOutOutline size={18} /> ออกจากระบบ
      </button>
    </div>
  );
}
