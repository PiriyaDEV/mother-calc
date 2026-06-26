"use client";

import { useState, useEffect, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import {
  IoPeopleOutline,
  IoReceiptOutline,
  IoBarChartOutline,
  IoSettingsOutline,
  IoArrowBack,
  IoPencil,
  IoCheckmark,
  IoClose,
} from "react-icons/io5";
import { useBillState } from "@/hooks/useBillState";
import { useAuth } from "@/hooks/useAuth";
import MemberPage from "@/components/members/MemberPage";
import ItemPage from "@/components/items/ItemPage";
import SummaryPage from "@/components/summary/SummaryPage";
import SettingsModal from "@/components/settings/SettingsModal";
import Input from "@/components/ui/Input";
import { AppTab } from "@/lib/types";

const TABS: { id: AppTab; label: string; icon: React.ReactNode }[] = [
  { id: "members", label: "สมาชิก", icon: <IoPeopleOutline size={18} /> },
  { id: "items", label: "รายการ", icon: <IoReceiptOutline size={18} /> },
  { id: "summary", label: "สรุป", icon: <IoBarChartOutline size={18} /> },
];

export default function BillPageWrapper() {
  return (
    <Suspense fallback={
      <div className="flex items-center justify-center min-h-screen">
        <div className="w-8 h-8 border-2 border-[#4366f4] border-t-transparent rounded-full animate-spin" />
      </div>
    }>
      <BillPage />
    </Suspense>
  );
}

function BillPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const billId = searchParams.get("id") ?? "";

  const { user, loading: authLoading, configured } = useAuth();

  const [tab, setTab] = useState<AppTab>("members");
  const [showSettings, setShowSettings] = useState(false);
  const [editingTitle, setEditingTitle] = useState(false);
  const [titleInput, setTitleInput] = useState("");

  // Auth guard — redirect to /login if Supabase is configured and user is not logged in
  useEffect(() => {
    if (!authLoading && configured && !user) {
      router.replace("/login");
    }
  }, [authLoading, configured, user, router]);

  const {
    bill,
    members,
    items,
    loading,
    error,
    updateTitle,
    saveSettings,
    addMember,
    editMember,
    deleteMember,
    addItem,
    editItem,
    deleteItem,
  } = useBillState(billId);

  useEffect(() => {
    if (bill && !editingTitle) {
      setTitleInput(bill.title);
    }
  }, [bill?.title]);

  // Redirect to home if no bill ID
  useEffect(() => {
    if (!billId) {
      router.replace("/");
    }
  }, [billId, router]);

  if (!billId) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="w-8 h-8 border-2 border-[#4366f4] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="w-8 h-8 border-2 border-[#4366f4] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (error || !bill) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen gap-4">
        <p className="text-red-500 text-sm">{error ?? "ไม่พบบิล"}</p>
        <button onClick={() => router.push("/")} className="text-[#4366f4] text-sm">
          กลับหน้าหลัก
        </button>
      </div>
    );
  }

  const handleSaveTitle = async () => {
    if (titleInput.trim() && titleInput.trim() !== bill.title) {
      await updateTitle(titleInput.trim());
    }
    setEditingTitle(false);
  };

  return (
    <div className="min-h-screen bg-white dark:bg-gray-950 flex flex-col">
      {/* Header */}
      <header className="sticky top-0 z-30 bg-white/90 dark:bg-gray-950/90 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
        <div className="max-w-lg mx-auto px-4 py-3 flex items-center gap-3">
          <button
            onClick={() => router.push("/")}
            className="w-9 h-9 flex items-center justify-center rounded-xl text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors flex-shrink-0"
          >
            <IoArrowBack size={18} />
          </button>

          {/* Title */}
          <div className="flex-1 min-w-0">
            {editingTitle ? (
              <div className="flex items-center gap-2">
                <Input
                  value={titleInput}
                  onChange={(e) => setTitleInput(e.target.value)}
                  className="text-sm font-semibold h-8 py-0"
                  autoFocus
                  onKeyDown={(e) => {
                    if (e.key === "Enter") handleSaveTitle();
                    if (e.key === "Escape") setEditingTitle(false);
                  }}
                />
                <button onClick={handleSaveTitle} className="text-[#4366f4]">
                  <IoCheckmark size={18} />
                </button>
                <button onClick={() => setEditingTitle(false)} className="text-gray-400">
                  <IoClose size={18} />
                </button>
              </div>
            ) : (
              <button
                onClick={() => { setTitleInput(bill.title); setEditingTitle(true); }}
                className="flex items-center gap-1.5 group"
              >
                <h1 className="text-base font-semibold text-gray-900 dark:text-white truncate">
                  {bill.title}
                </h1>
                <IoPencil size={12} className="text-gray-400 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0" />
              </button>
            )}
          </div>

          <button
            onClick={() => setShowSettings(true)}
            className="w-9 h-9 flex items-center justify-center rounded-xl text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors flex-shrink-0"
          >
            <IoSettingsOutline size={18} />
          </button>
        </div>

        {/* Tabs */}
        <div className="max-w-lg mx-auto px-4 pb-0">
          <div className="flex gap-1">
            {TABS.map((t) => (
              <button
                key={t.id}
                onClick={() => setTab(t.id)}
                className={`flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium rounded-t-xl transition-colors ${
                  tab === t.id
                    ? "text-[#4366f4] border-b-2 border-[#4366f4]"
                    : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
                }`}
              >
                {t.icon}
                {t.label}
                {t.id === "members" && members.length > 0 && (
                  <span className="text-[10px] bg-gray-100 dark:bg-gray-800 text-gray-500 rounded-full px-1.5 py-0.5">
                    {members.length}
                  </span>
                )}
                {t.id === "items" && items.length > 0 && (
                  <span className="text-[10px] bg-gray-100 dark:bg-gray-800 text-gray-500 rounded-full px-1.5 py-0.5">
                    {items.length}
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
          <MemberPage
            members={members}
            onAdd={async (input) => { await addMember(input); }}
            onEdit={editMember}
            onDelete={deleteMember}
          />
        )}
        {tab === "items" && (
          <ItemPage
            items={items}
            members={members}
            onAdd={async (data) => { await addItem(data); }}
            onEdit={editItem}
            onDelete={deleteItem}
          />
        )}
        {tab === "summary" && (
          <SummaryPage bill={bill} />
        )}
      </main>

      {/* Settings Modal */}
      <SettingsModal
        isOpen={showSettings}
        onClose={() => setShowSettings(false)}
        settings={bill.settings}
        tip={bill.tip}
        discount={bill.discount}
        onSave={saveSettings}
      />
    </div>
  );
}
