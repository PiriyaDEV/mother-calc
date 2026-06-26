"use client";

import { useEffect, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import { getGroup, updateGroup, deleteGroup } from "@/lib/db";
import { Group } from "@/lib/types";
import {
  IoArrowBack,
  IoCheckmark,
  IoTrash,
  IoWarningOutline,
} from "react-icons/io5";

export default function GroupSettingsPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { user, loading } = useAuth();

  const [group, setGroup] = useState<Group | null>(null);
  const [dataLoading, setDataLoading] = useState(true);

  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!user || !id) return;
    setDataLoading(true);
    try {
      const grp = await getGroup(id);
      if (!grp) { router.push("/"); return; }
      setGroup(grp);
      setName(grp.name);
      setDescription(grp.description ?? "");
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

  const handleSave = async () => {
    if (!name.trim()) { setError("กรุณาใส่ชื่อกลุ่ม"); return; }
    setSaving(true);
    setError(null);
    try {
      await updateGroup(id, { name: name.trim(), description: description.trim() || null });
      setGroup((g) => g ? { ...g, name: name.trim(), description: description.trim() || null } : g);
      setSuccess(true);
      setTimeout(() => setSuccess(false), 2500);
    } catch {
      setError("เกิดข้อผิดพลาด กรุณาลองใหม่");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!confirm(`ลบกลุ่ม "${group?.name}" ? การกระทำนี้ไม่สามารถย้อนกลับได้`)) return;
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
          <div>
            <h1 className="text-sm font-bold text-gray-900 dark:text-white">ตั้งค่ากลุ่ม</h1>
            {group?.name && (
              <p className="text-xs text-gray-400 leading-tight">{group.name}</p>
            )}
          </div>
        </div>
      </nav>

      <main className="flex-1 max-w-2xl mx-auto w-full px-5 py-5 flex flex-col gap-4">
        {/* Success toast */}
        {success && (
          <div className="flex items-center gap-2 px-4 py-3 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-2xl text-sm text-green-700 dark:text-green-400 font-medium">
            <IoCheckmark size={16} />
            บันทึกแล้ว
          </div>
        )}
        {error && (
          <div className="px-4 py-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-2xl text-sm text-red-600 dark:text-red-400">
            {error}
          </div>
        )}

        {/* Group info form */}
        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 flex flex-col gap-4">
          <p className="text-sm font-semibold text-gray-900 dark:text-white">ข้อมูลกลุ่ม</p>

          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-medium text-gray-500 dark:text-gray-400">ชื่อกลุ่ม</label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              disabled={!isOwner}
              placeholder="ชื่อกลุ่ม"
              className="w-full px-3 py-2.5 text-sm rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white outline-none focus:border-[#4366f4] disabled:opacity-60 disabled:cursor-not-allowed transition-colors"
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-medium text-gray-500 dark:text-gray-400">คำอธิบาย (ไม่บังคับ)</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              disabled={!isOwner}
              placeholder="เช่น ทริปเที่ยวญี่ปุ่น 2025"
              rows={3}
              className="w-full px-3 py-2.5 text-sm rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white outline-none focus:border-[#4366f4] disabled:opacity-60 disabled:cursor-not-allowed resize-none transition-colors"
            />
          </div>

          {isOwner && (
            <button
              onClick={handleSave}
              disabled={saving || !name.trim()}
              className="w-full py-3 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 text-white text-sm font-semibold rounded-xl transition-colors"
            >
              {saving ? "กำลังบันทึก..." : "บันทึก"}
            </button>
          )}
        </div>

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
              onClick={handleDelete}
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
    </div>
  );
}
