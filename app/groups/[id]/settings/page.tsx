"use client";

import { useEffect, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import { getGroup, updateGroup, deleteGroup } from "@/lib/db";
import { Group } from "@/lib/types";
import {
  IoArrowBack,
  IoSettingsOutline,
  IoTrash,
  IoWarningOutline,
  IoPencil,
  IoPeopleOutline,
} from "react-icons/io5";
import CreateEntityModal, { EntityFormData } from "@/components/ui/CreateEntityModal";
import ConfirmModal from "@/components/ui/ConfirmModal";

export default function GroupSettingsPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { user, loading } = useAuth();

  const [group, setGroup] = useState<Group | null>(null);
  const [dataLoading, setDataLoading] = useState(true);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showConfirmDelete, setShowConfirmDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!user || !id) return;
    setDataLoading(true);
    try {
      const grp = await getGroup(id);
      if (!grp) { router.push("/"); return; }
      setGroup(grp);
    } finally {
      setDataLoading(false);
    }
  }, [user, id, router]);

  useEffect(() => {
    if (!loading && !user) router.push("/login");
  }, [loading, user, router]);

  useEffect(() => {
    if (user) loadData();
  }, [user, loadData]);

  const handleSaveGroup = async (data: EntityFormData) => {
    await updateGroup(id, {
      name: data.name,
      description: data.description || undefined,
      emoji: data.emoji,
      tags: data.tags,
    });
    setGroup((g) => g ? {
      ...g,
      name: data.name,
      description: data.description || null,
      emoji: data.emoji ?? null,
      tags: data.tags,
    } : g);
  };

  const handleDelete = async () => {
    setDeleting(true);
    try {
      await deleteGroup(id);
      router.push("/");
    } catch {
      setError("ลบกลุ่มไม่สำเร็จ กรุณาลองใหม่");
      setDeleting(false);
    }
  };

  if (loading || dataLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f8f9fc] dark:bg-gray-950">
        <div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" />
      </div>
    );
  }

  const isOwner = group?.owner_id === user?.id;

  return (
    <div className="min-h-screen bg-[#f8f9fc] dark:bg-gray-950 flex flex-col">
      {/* Navbar */}
      <nav className="sticky top-0 z-40 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
        <div className="max-w-2xl mx-auto px-5 h-14 flex items-center gap-3">
          <button
            onClick={() => router.push(`/groups/${id}`)}
            className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
          >
            <IoArrowBack size={18} />
          </button>
          <div className="flex items-center gap-2 flex-1 min-w-0">
            <IoSettingsOutline size={16} className="text-gray-400 flex-shrink-0" />
            <h1 className="text-sm font-bold text-gray-900 dark:text-white">ตั้งค่ากลุ่ม</h1>
          </div>
        </div>
      </nav>

      <main className="flex-1 max-w-2xl mx-auto w-full px-5 py-5 flex flex-col gap-4">
        {error && (
          <div className="px-4 py-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-2xl text-sm text-red-600 dark:text-red-400">
            {error}
          </div>
        )}

        {/* Group info card */}
        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center flex-shrink-0 text-2xl">
              {group?.emoji ?? <IoPeopleOutline size={22} className="text-purple-400" />}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-bold text-gray-900 dark:text-white truncate">{group?.name}</p>
              {group?.description && (
                <p className="text-xs text-gray-400 mt-0.5 truncate">{group.description}</p>
              )}
              {group?.tags && group.tags.length > 0 && (
                <div className="flex flex-wrap gap-1 mt-1.5">
                  {group.tags.map((tag) => (
                    <span key={tag} className="px-2 py-0.5 bg-gray-100 dark:bg-gray-800 text-gray-500 dark:text-gray-400 text-[10px] rounded-full">
                      {tag}
                    </span>
                  ))}
                </div>
              )}
            </div>
            {isOwner && (
              <button
                onClick={() => setShowEditModal(true)}
                className="w-9 h-9 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-[#4366f4] transition-colors flex-shrink-0"
              >
                <IoPencil size={16} />
              </button>
            )}
          </div>
        </div>

        {/* Edit button (owner only) */}
        {isOwner && (
          <button
            onClick={() => setShowEditModal(true)}
            className="w-full py-3 bg-[#4366f4] hover:bg-[#3355e0] text-white text-sm font-semibold rounded-2xl transition-colors flex items-center justify-center gap-2"
          >
            <IoPencil size={14} />
            แก้ไขข้อมูลกลุ่ม
          </button>
        )}

        {/* Danger zone — owner only */}
        {isOwner && (
          <div className="bg-white dark:bg-gray-900 rounded-2xl border border-red-100 dark:border-red-900/30 p-4">
            <div className="flex items-center gap-2 mb-3">
              <IoWarningOutline size={16} className="text-red-500" />
              <p className="text-sm font-semibold text-red-500">Danger Zone</p>
            </div>
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-4">
              การลบกลุ่มจะลบข้อมูลทั้งหมดที่เกี่ยวข้อง รวมถึงบิลและสมาชิก ไม่สามารถย้อนกลับได้
            </p>
            <button
              onClick={() => setShowConfirmDelete(true)}
              disabled={deleting}
              className="flex items-center justify-center gap-2 w-full py-3 border border-red-200 dark:border-red-800 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/10 disabled:opacity-60 text-sm font-semibold rounded-xl transition-colors"
            >
              <IoTrash size={16} />
              {deleting ? "กำลังลบ..." : "ลบกลุ่มนี้"}
            </button>
          </div>
        )}

        {/* Non-owner info */}
        {!isOwner && (
          <div className="px-4 py-3 bg-gray-50 dark:bg-gray-800/50 rounded-2xl border border-gray-100 dark:border-gray-700">
            <p className="text-xs text-gray-500 dark:text-gray-400 text-center">
              เฉพาะเจ้าของกลุ่มเท่านั้นที่สามารถแก้ไขการตั้งค่าได้
            </p>
          </div>
        )}
      </main>

      {/* Confirm delete group */}
      {showConfirmDelete && group && (
        <ConfirmModal
          title={`ลบกลุ่ม "${group.name}"?`}
          description="บิลทั้งหมดในกลุ่มจะถูกลบด้วย ไม่สามารถย้อนกลับได้"
          confirmLabel="ลบกลุ่ม"
          danger
          onConfirm={() => { setShowConfirmDelete(false); handleDelete(); }}
          onCancel={() => setShowConfirmDelete(false)}
        />
      )}

      {/* Edit Group Modal */}
      {showEditModal && group && (
        <CreateEntityModal
          type="group"
          mode="edit"
          initialData={{
            name: group.name,
            emoji: group.emoji,
            description: group.description ?? "",
            tags: group.tags ?? [],
          }}
          onClose={() => setShowEditModal(false)}
          onSave={handleSaveGroup}
        />
      )}
    </div>
  );
}
