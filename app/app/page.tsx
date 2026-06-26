"use client";

import { useState, useEffect, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import {
  IoPeopleOutline,
  IoReceiptOutline,
  IoBarChartOutline,
  IoSettingsOutline,
  IoArrowBack,
  IoAnalyticsOutline,
} from "react-icons/io5";
import { useBillState } from "@/hooks/useBillState";
import { useAuth } from "@/hooks/useAuth";
import MemberPage from "@/components/members/MemberPage";
import ItemPage from "@/components/items/ItemPage";
import SummaryPage from "@/components/summary/SummaryPage";
import AnalyticsPage from "@/components/summary/AnalyticsPage";
import CreateEntityModal, { EntityFormData } from "@/components/ui/CreateEntityModal";
import ConfirmModal from "@/components/ui/ConfirmModal";
import { deleteBill } from "@/lib/db";
import { AppTab } from "@/lib/types";

const TABS: { id: AppTab; label: string; icon: React.ReactNode }[] = [
  { id: "members", label: "สมาชิก", icon: <IoPeopleOutline size={16} /> },
  { id: "items", label: "รายการ", icon: <IoReceiptOutline size={16} /> },
  { id: "summary", label: "สรุป", icon: <IoBarChartOutline size={16} /> },
  { id: "analytics", label: "วิเคราะห์", icon: <IoAnalyticsOutline size={16} /> },
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
  const [showEditBill, setShowEditBill] = useState(false);
  const [confirmDeleteBill, setConfirmDeleteBill] = useState(false);

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
    updateBillMeta,
    saveSettings,
    addMember,
    editMember,
    deleteMember,
    addItem,
    editItem,
    deleteItem,
  } = useBillState(billId, user);

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

  const handleSaveBillMeta = async (data: EntityFormData) => {
    await updateBillMeta({
      title: data.name,
      emoji: data.emoji,
      tags: data.tags,
      settings: data.settings,
    });
  };

  const handleDeleteBill = async () => {
    await deleteBill(billId);
    router.push("/");
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
          <div className="flex-1 min-w-0 flex items-center gap-2">
            {bill.emoji && <span className="text-xl flex-shrink-0">{bill.emoji}</span>}
            <h1 className="text-base font-semibold text-gray-900 dark:text-white truncate">
              {bill.title}
            </h1>
          </div>

          <button
            onClick={() => setShowEditBill(true)}
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
                {t.id === "members" && members.length > 0 && (
                  <span className={`text-[10px] rounded-full px-1.5 py-0.5 font-bold ${
                    tab === t.id
                      ? "bg-blue-50 dark:bg-blue-900/30 text-[#4366f4]"
                      : "bg-gray-200 dark:bg-gray-700 text-gray-500"
                  }`}>
                    {members.length}
                  </span>
                )}
                {t.id === "items" && items.length > 0 && (
                  <span className={`text-[10px] rounded-full px-1.5 py-0.5 font-bold ${
                    tab === t.id
                      ? "bg-blue-50 dark:bg-blue-900/30 text-[#4366f4]"
                      : "bg-gray-200 dark:bg-gray-700 text-gray-500"
                  }`}>
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
          <SummaryPage bill={{ ...bill, members, items }} members={members} />
        )}
        {tab === "analytics" && (
          <AnalyticsPage bill={{ ...bill, members, items }} members={members} />
        )}
      </main>

      {/* Edit Bill Modal */}
      {showEditBill && (
        <CreateEntityModal
          type="bill"
          mode="edit"
          initialData={{
            name: bill.title,
            emoji: bill.emoji,
            tags: bill.tags ?? [],
            settings: bill.settings,
          }}
          onClose={() => setShowEditBill(false)}
          onSave={handleSaveBillMeta}
          onDelete={() => { setShowEditBill(false); setConfirmDeleteBill(true); }}
        />
      )}

      {/* Confirm delete bill */}
      {confirmDeleteBill && (
        <ConfirmModal
          title={`ลบบิล "${bill.title}"?`}
          description="การกระทำนี้ไม่สามารถย้อนกลับได้"
          confirmLabel="ลบบิล"
          danger
          onConfirm={handleDeleteBill}
          onCancel={() => setConfirmDeleteBill(false)}
        />
      )}
    </div>
  );
}
