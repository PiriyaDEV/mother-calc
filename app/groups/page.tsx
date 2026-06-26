"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import { getMyGroups, getBills, createGroup, updateGroup, deleteGroup, ensureMyProfile } from "@/lib/db";
import { Group, Bill } from "@/lib/types";
import { IoAdd, IoPeopleOutline, IoPeopleCircleOutline, IoChevronForward, IoSettingsOutline } from "react-icons/io5";
import BottomNav from "@/components/ui/BottomNav";
import CreateEntityModal, { EntityFormData } from "@/components/ui/CreateEntityModal";
import ConfirmModal from "@/components/ui/ConfirmModal";

function getBillTotal(bill: Bill): number { return (bill.items ?? []).reduce((s, i) => s + i.price, 0); }
function formatBaht(n: number): string { return n.toLocaleString("th-TH", { minimumFractionDigits: 2, maximumFractionDigits: 2 }); }

export default function GroupsPage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  const [groups, setGroups] = useState<Group[]>([]);
  const [groupBills, setGroupBills] = useState<Record<string, Bill[]>>({});
  const [dataLoading, setDataLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [editingGroup, setEditingGroup] = useState<Group | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<Group | null>(null);

  const loadData = useCallback(async () => {
    if (!user) return;
    setDataLoading(true);
    try {
      await ensureMyProfile();
      const grps = await getMyGroups();
      setGroups(grps);
      const billMap: Record<string, Bill[]> = {};
      await Promise.all(grps.map(async (g) => { billMap[g.id] = await getBills({ groupId: g.id }); }));
      setGroupBills(billMap);
    } finally { setDataLoading(false); }
  }, [user]);

  useEffect(() => { if (user) loadData(); }, [user, loadData]);
  useEffect(() => { if (!loading && !user) router.push("/login"); }, [loading, user, router]);

  const handleCreate = async (data: EntityFormData) => {
    const group = await createGroup({ name: data.name, description: data.description || undefined, emoji: data.emoji, tags: data.tags });
    setGroups((prev) => [group, ...prev]);
    setGroupBills((prev) => ({ ...prev, [group.id]: [] }));
    setShowCreate(false);
  };

  const handleEdit = async (data: EntityFormData) => {
    if (!editingGroup) return;
    await updateGroup(editingGroup.id, { name: data.name, description: data.description || undefined, emoji: data.emoji, tags: data.tags });
    setGroups((prev) => prev.map((g) => g.id === editingGroup.id ? { ...g, name: data.name, description: data.description || null, emoji: data.emoji, tags: data.tags } : g));
    setEditingGroup(null);
  };

  const handleDelete = async () => {
    if (!confirmDelete) return;
    await deleteGroup(confirmDelete.id);
    setGroups((prev) => prev.filter((g) => g.id !== confirmDelete.id));
    setConfirmDelete(null);
  };

  if (loading || (!user && !loading)) {
    return <div className="min-h-screen flex items-center justify-center bg-white dark:bg-gray-950"><div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" /></div>;
  }

  return (
    <div className="min-h-screen bg-[#f4f6fb] dark:bg-gray-950 flex flex-col pb-20">
      <main className="flex-1 max-w-lg mx-auto w-full px-4 py-5">
        {/* Page title — sticky */}
        <div className="sticky top-14 z-20 bg-[#f4f6fb] dark:bg-gray-950 pt-5 pb-3 -mt-5 -mx-4 px-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-xl font-bold text-gray-900 dark:text-white">กลุ่มของฉัน</h1>
              {groups.length > 0 && !dataLoading && <p className="text-xs text-gray-400 mt-0.5">{groups.length} กลุ่ม</p>}
            </div>
            <button onClick={() => setShowCreate(true)} className="flex items-center gap-1.5 px-3 py-2 bg-purple-500 hover:bg-purple-600 text-white text-xs font-semibold rounded-xl transition-colors">
              <IoAdd size={14} /> สร้างกลุ่ม
            </button>
          </div>
        </div>
        {dataLoading ? (
          <div className="flex items-center justify-center py-16"><div className="w-6 h-6 border-2 border-[#4366f4] border-t-transparent rounded-full animate-spin" /></div>
        ) : groups.length === 0 ? (
          <div onClick={() => setShowCreate(true)} className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-dashed border-gray-200 dark:border-gray-700 cursor-pointer hover:border-purple-300 transition-colors group">
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
              const bills = groupBills[group.id] ?? [];
              const gTotal = bills.reduce((s, b) => s + getBillTotal(b), 0);
              return (
                <div key={group.id} onClick={() => router.push(`/groups/${group.id}`)} className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 hover:border-purple-200 hover:shadow-sm transition-all cursor-pointer group">
                  <div className="w-11 h-11 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center flex-shrink-0 text-xl">
                    {group.emoji ?? <IoPeopleOutline size={20} className="text-purple-500" />}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{group.name}</p>
                    <div className="flex items-center gap-1.5 mt-0.5">
                      <p className="text-xs text-gray-400">{bills.length} บิล</p>
                      {group.tags?.slice(0, 1).map((tag) => (
                        <span key={tag} className="px-1.5 py-0.5 bg-purple-50 dark:bg-purple-900/20 text-purple-500 text-[10px] rounded-full font-medium">{tag}</span>
                      ))}
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0 flex items-center gap-1">
                    <div>
                      <p className="text-sm font-bold text-gray-900 dark:text-white">{formatBaht(gTotal)}</p>
                      <p className="text-[10px] text-gray-400">บาท</p>
                    </div>
                    <button onClick={(e) => { e.stopPropagation(); setEditingGroup(group); }} className="w-7 h-7 flex items-center justify-center rounded-lg text-gray-300 hover:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors">
                      <IoSettingsOutline size={13} />
                    </button>
                    <IoChevronForward size={14} className="text-gray-300 group-hover:text-purple-400 transition-colors" />
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </main>

      <BottomNav />

      {showCreate && <CreateEntityModal type="group" onClose={() => setShowCreate(false)} onSave={handleCreate} />}
      {editingGroup && (
        <CreateEntityModal type="group" mode="edit"
          initialData={{ name: editingGroup.name, emoji: editingGroup.emoji, description: editingGroup.description ?? "", tags: editingGroup.tags ?? [] }}
          onClose={() => setEditingGroup(null)} onSave={handleEdit}
          onDelete={() => { setEditingGroup(null); setConfirmDelete(editingGroup); }}
        />
      )}
      {confirmDelete && (
        <ConfirmModal title={`ลบกลุ่ม "${confirmDelete.name}"?`} description="บิลทั้งหมดในกลุ่มจะถูกลบด้วย" confirmLabel="ลบกลุ่ม" danger onConfirm={handleDelete} onCancel={() => setConfirmDelete(null)} />
      )}
    </div>
  );
}
