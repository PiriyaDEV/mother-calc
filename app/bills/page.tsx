"use client";

import { useEffect, useState, useCallback, useMemo } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import {
  getIndividualBills,
  createBill,
  deleteBill,
  updateBill,
  ensureMyProfile,
} from "@/lib/db";
import { Bill } from "@/lib/types";
import {
  IoAdd,
  IoReceiptOutline,
  IoTrash,
  IoArrowForward,
  IoSettingsOutline,
} from "react-icons/io5";
import BottomNav from "@/components/ui/BottomNav";
import CreateEntityModal, { EntityFormData } from "@/components/ui/CreateEntityModal";
import ConfirmModal from "@/components/ui/ConfirmModal";

function getBillTotal(bill: Bill): number {
  return (bill.items ?? []).reduce((s, i) => s + i.price, 0);
}
function formatBaht(n: number): string {
  return n.toLocaleString("th-TH", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

export default function BillsPage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  const [bills, setBills] = useState<Bill[]>([]);
  const [dataLoading, setDataLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [showCreate, setShowCreate] = useState(false);
  const [editingBill, setEditingBill] = useState<Bill | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<Bill | null>(null);

  const loadData = useCallback(async () => {
    if (!user) return;
    setDataLoading(true);
    try {
      await ensureMyProfile();
      setBills(await getIndividualBills());
    } finally {
      setDataLoading(false);
    }
  }, [user]);

  useEffect(() => { if (user) loadData(); }, [user, loadData]);
  useEffect(() => { if (!loading && !user) router.push("/login"); }, [loading, user, router]);

  const personalTotal = useMemo(() => bills.reduce((s, b) => s + getBillTotal(b), 0), [bills]);

  const handleCreate = async (data: EntityFormData) => {
    setCreating(true);
    try {
      const bill = await createBill({ title: data.name, emoji: data.emoji, tags: data.tags, settings: data.settings });
      router.push(`/app?id=${bill.id}`);
    } catch (e) { console.error(e); setCreating(false); }
  };

  const handleEdit = async (data: EntityFormData) => {
    if (!editingBill) return;
    await updateBill(editingBill.id, { title: data.name, emoji: data.emoji, tags: data.tags, settings: data.settings });
    setBills((prev) => prev.map((b) => b.id === editingBill.id ? { ...b, title: data.name, emoji: data.emoji, tags: data.tags, settings: data.settings ?? b.settings } : b));
    setEditingBill(null);
  };

  const handleDelete = async () => {
    if (!confirmDelete) return;
    await deleteBill(confirmDelete.id);
    setBills((prev) => prev.filter((b) => b.id !== confirmDelete.id));
    setConfirmDelete(null);
  };

  if (loading || (!user && !loading)) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white dark:bg-gray-950">
        <div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#f4f6fb] dark:bg-gray-950 flex flex-col pb-20">
      <main className="flex-1 max-w-lg mx-auto w-full px-4 py-5">
        {/* Page title */}
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-xl font-bold text-gray-900 dark:text-white">บิลของฉัน</h1>
            {bills.length > 0 && !dataLoading && (
              <p className="text-xs text-gray-400 mt-0.5">รวม {formatBaht(personalTotal)} บาท</p>
            )}
          </div>
          <button
            onClick={() => setShowCreate(true)}
            disabled={creating}
            className="flex items-center gap-1.5 px-3 py-2 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 text-white text-xs font-semibold rounded-xl transition-colors"
          >
            <IoAdd size={14} /> {creating ? "กำลังสร้าง..." : "สร้างบิล"}
          </button>
        </div>
        {dataLoading ? (
          <div className="flex items-center justify-center py-16">
            <div className="w-6 h-6 border-2 border-[#4366f4] border-t-transparent rounded-full animate-spin" />
          </div>
        ) : bills.length === 0 ? (
          <div
            onClick={() => setShowCreate(true)}
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
            {bills.map((bill) => {
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
                        {new Date(bill.updated_at).toLocaleDateString("th-TH", { day: "numeric", month: "short" })}
                      </p>
                      {bill.tags?.slice(0, 1).map((tag) => (
                        <span key={tag} className="px-1.5 py-0.5 bg-blue-50 dark:bg-blue-900/20 text-[#4366f4] text-[10px] rounded-full font-medium">{tag}</span>
                      ))}
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0 flex items-center gap-1">
                    <div>
                      <p className="text-sm font-bold text-gray-900 dark:text-white">{formatBaht(bTotal)}</p>
                      <p className="text-[10px] text-gray-400">บาท</p>
                    </div>
                    <button
                      onClick={(e) => { e.stopPropagation(); setEditingBill(bill); }}
                      className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-300 hover:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                    >
                      <IoSettingsOutline size={13} />
                    </button>
                    <button
                      onClick={(e) => { e.stopPropagation(); setConfirmDelete(bill); }}
                      className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-300 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                    >
                      <IoTrash size={13} />
                    </button>
                    <IoArrowForward size={14} className="text-gray-300 group-hover:text-[#4366f4] transition-colors" />
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </main>
      {/* close main */}

      <BottomNav />

      {showCreate && (
        <CreateEntityModal type="bill" onClose={() => setShowCreate(false)} onSave={handleCreate} />
      )}
      {editingBill && (
        <CreateEntityModal
          type="bill" mode="edit"
          initialData={{ name: editingBill.title, emoji: editingBill.emoji, tags: editingBill.tags ?? [], settings: editingBill.settings }}
          onClose={() => setEditingBill(null)} onSave={handleEdit}
        />
      )}
      {confirmDelete && (
        <ConfirmModal
          title={`ลบบิล "${confirmDelete.title}"?`}
          description="การกระทำนี้ไม่สามารถย้อนกลับได้"
          confirmLabel="ลบบิล" danger
          onConfirm={handleDelete} onCancel={() => setConfirmDelete(null)}
        />
      )}
    </div>
  );
}
