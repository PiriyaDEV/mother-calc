"use client";

import { useState } from "react";
import { IoPencil, IoTrash, IoPersonOutline, IoCheckmark, IoClose } from "react-icons/io5";
import { BillMember } from "@/lib/types";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";

const MEMBER_COLORS = [
  "#4366f4", "#f43f5e", "#10b981", "#f59e0b",
  "#8b5cf6", "#06b6d4", "#ec4899", "#84cc16",
  "#f97316", "#6366f1",
];

interface MemberPageProps {
  members: BillMember[];
  onAdd: (input: { name: string; color: string; promptpay?: string }) => Promise<void>;
  onEdit: (memberId: string, updates: Partial<Pick<BillMember, "name" | "color" | "promptpay">>) => Promise<void>;
  onDelete: (memberId: string) => Promise<void>;
}

export default function MemberPage({ members, onAdd, onEdit, onDelete }: MemberPageProps) {
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  // Add form state
  const [name, setName] = useState("");
  const [promptpay, setPromptpay] = useState("");
  const [color, setColor] = useState(MEMBER_COLORS[0]);
  const [saving, setSaving] = useState(false);

  // Edit form state
  const [editName, setEditName] = useState("");
  const [editPromptpay, setEditPromptpay] = useState("");
  const [editColor, setEditColor] = useState("");

  const handleAdd = async () => {
    if (!name.trim()) return;
    setSaving(true);
    try {
      await onAdd({ name: name.trim(), color, promptpay: promptpay.trim() || undefined });
      setName("");
      setPromptpay("");
      setColor(MEMBER_COLORS[members.length % MEMBER_COLORS.length]);
      setShowForm(false);
    } finally {
      setSaving(false);
    }
  };

  const startEdit = (member: BillMember) => {
    setEditingId(member.id);
    setEditName(member.name);
    setEditPromptpay(member.promptpay ?? "");
    setEditColor(member.color);
  };

  const handleEdit = async (memberId: string) => {
    setSaving(true);
    try {
      await onEdit(memberId, {
        name: editName.trim(),
        color: editColor,
        promptpay: editPromptpay.trim() || null,
      });
      setEditingId(null);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="flex flex-col gap-3">
      {/* Sticky pill add-button */}
      {!showForm && (
        <div className="sticky top-0 z-10 pt-1 pb-2 bg-white dark:bg-gray-950">
          <button
            onClick={() => {
              setColor(MEMBER_COLORS[members.length % MEMBER_COLORS.length]);
              setShowForm(true);
            }}
            className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-2xl bg-[#4366f4] hover:bg-[#3355e0] text-white text-sm font-semibold shadow-sm shadow-blue-200/60 dark:shadow-none transition-all active:scale-95"
          >
            เพิ่มสมาชิก
          </button>
        </div>
      )}

      {/* Member list */}
      {members.length === 0 && !showForm && (
        <div className="flex flex-col items-center gap-3 py-10 text-center">
          <div className="w-14 h-14 rounded-2xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center">
            <IoPersonOutline size={24} className="text-gray-400" />
          </div>
          <p className="text-sm text-gray-500 dark:text-gray-400">ยังไม่มีสมาชิก</p>
          <p className="text-xs text-gray-400">เพิ่มสมาชิกเพื่อเริ่มหารบิล</p>
        </div>
      )}

      <div className="flex flex-col gap-2">
        {members.map((member) =>
          editingId === member.id ? (
            // Edit row
            <div key={member.id} className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-3 flex flex-col gap-3">
              <div className="flex gap-2">
                <Input
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  placeholder="ชื่อ"
                  className="flex-1"
                />
                <Input
                  value={editPromptpay}
                  onChange={(e) => setEditPromptpay(e.target.value)}
                  placeholder="พร้อมเพย์ (ไม่บังคับ)"
                  className="flex-1"
                />
              </div>
              {/* Color picker */}
              <div className="flex gap-1.5 flex-wrap">
                {MEMBER_COLORS.map((c) => (
                  <button
                    key={c}
                    type="button"
                    onClick={() => setEditColor(c)}
                    className={`w-6 h-6 rounded-full transition-transform ${editColor === c ? "scale-125 ring-2 ring-offset-1 ring-gray-400" : ""}`}
                    style={{ backgroundColor: c }}
                  />
                ))}
              </div>
              <div className="flex gap-2">
                <Button size="sm" onClick={() => handleEdit(member.id)} disabled={saving || !editName.trim()}>
                  <IoCheckmark size={14} /> บันทึก
                </Button>
                <Button size="sm" variant="secondary" onClick={() => setEditingId(null)}>
                  <IoClose size={14} /> ยกเลิก
                </Button>
              </div>
            </div>
          ) : (
            // Display row
            <div key={member.id} className="flex items-center gap-3 bg-gray-50 dark:bg-gray-800/60 rounded-2xl px-4 py-3">
              <div
                className="w-9 h-9 rounded-full flex items-center justify-center text-white text-sm font-bold flex-shrink-0"
                style={{ backgroundColor: member.color }}
              >
                {member.name.charAt(0).toUpperCase()}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1.5">
                  <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{member.name}</p>
                  {member.is_external && (
                    <span className="text-[10px] px-1.5 py-0.5 bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400 rounded-full flex-shrink-0">
                      ภายนอก
                    </span>
                  )}
                  {!member.is_external && member.profile && (
                    <span className="text-[10px] text-[#4366f4] font-medium flex-shrink-0">
                      @{member.profile.username}
                    </span>
                  )}
                </div>
                {member.promptpay && (
                  <p className="text-xs text-gray-400 truncate">พร้อมเพย์: {member.promptpay}</p>
                )}
              </div>
              <div className="flex gap-1">
                <button
                  onClick={() => startEdit(member)}
                  className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:text-gray-600 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                >
                  <IoPencil size={14} />
                </button>
                <button
                  onClick={() => onDelete(member.id)}
                  className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                >
                  <IoTrash size={14} />
                </button>
              </div>
            </div>
          )
        )}
      </div>

      {/* Add form */}
      {showForm && (
        <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-3 flex flex-col gap-3">
          <div className="flex gap-2">
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="ชื่อสมาชิก *"
              className="flex-1"
              autoFocus
              onKeyDown={(e) => e.key === "Enter" && handleAdd()}
            />
            <Input
              value={promptpay}
              onChange={(e) => setPromptpay(e.target.value)}
              placeholder="พร้อมเพย์ (ไม่บังคับ)"
              className="flex-1"
            />
          </div>
          {/* Color picker */}
          <div className="flex gap-1.5 flex-wrap">
            {MEMBER_COLORS.map((c) => (
              <button
                key={c}
                type="button"
                onClick={() => setColor(c)}
                className={`w-6 h-6 rounded-full transition-transform ${color === c ? "scale-125 ring-2 ring-offset-1 ring-gray-400" : ""}`}
                style={{ backgroundColor: c }}
              />
            ))}
          </div>
          <div className="flex gap-2">
            <Button size="sm" onClick={handleAdd} disabled={saving || !name.trim()}>
              <IoCheckmark size={14} /> เพิ่ม
            </Button>
            <Button size="sm" variant="secondary" onClick={() => { setShowForm(false); setName(""); setPromptpay(""); }}>
              <IoClose size={14} /> ยกเลิก
            </Button>
          </div>
        </div>
      )}

    </div>
  );
}
