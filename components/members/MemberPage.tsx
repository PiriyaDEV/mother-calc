"use client";

import { useState } from "react";
import { IoAdd, IoPencil, IoTrash, IoPersonCircle } from "react-icons/io5";
import { Member } from "@/lib/types";
import { validatePromptpay, maskPromptpay } from "@/lib/utils";
import Modal from "@/components/ui/Modal";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";

interface MemberPageProps {
  members: Member[];
  onAdd: (name: string, promptpay?: string) => void;
  onUpdate: (id: string, name: string, promptpay?: string) => void;
  onRemove: (id: string) => void;
}

interface MemberFormState {
  name: string;
  promptpay: string;
}

export default function MemberPage({
  members,
  onAdd,
  onUpdate,
  onRemove,
}: MemberPageProps) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingMember, setEditingMember] = useState<Member | null>(null);
  const [form, setForm] = useState<MemberFormState>({ name: "", promptpay: "" });
  const [errors, setErrors] = useState<Partial<MemberFormState>>({});
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);

  const openAdd = () => {
    setEditingMember(null);
    setForm({ name: "", promptpay: "" });
    setErrors({});
    setIsModalOpen(true);
  };

  const openEdit = (member: Member) => {
    setEditingMember(member);
    setForm({ name: member.name, promptpay: member.promptpay || "" });
    setErrors({});
    setIsModalOpen(true);
  };

  const validate = (): boolean => {
    const newErrors: Partial<MemberFormState> = {};
    if (!form.name.trim()) newErrors.name = "กรุณาใส่ชื่อ";
    if (form.promptpay && !validatePromptpay(form.promptpay)) {
      newErrors.promptpay = "เบอร์โทรหรือเลขบัตรประชาชนไม่ถูกต้อง";
    }
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = () => {
    if (!validate()) return;
    if (editingMember) {
      onUpdate(editingMember.id, form.name, form.promptpay || undefined);
    } else {
      onAdd(form.name, form.promptpay || undefined);
    }
    setIsModalOpen(false);
  };

  return (
    <div className="flex flex-col gap-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-base font-semibold text-gray-900">สมาชิก</h2>
          <p className="text-xs text-gray-400 mt-0.5">{members.length} คน</p>
        </div>
        <Button size="sm" onClick={openAdd}>
          <IoAdd size={16} />
          เพิ่มสมาชิก
        </Button>
      </div>

      {/* Empty state */}
      {members.length === 0 && (
        <div className="flex flex-col items-center justify-center py-16 gap-3">
          <div className="w-16 h-16 rounded-2xl bg-[#4366f4]/10 flex items-center justify-center">
            <IoPersonCircle size={32} className="text-[#4366f4]" />
          </div>
          <p className="text-sm text-gray-500 text-center">
            ยังไม่มีสมาชิก
            <br />
            <span className="text-gray-400">กดปุ่ม &quot;เพิ่มสมาชิก&quot; เพื่อเริ่มต้น</span>
          </p>
        </div>
      )}

      {/* Member list */}
      <div className="flex flex-col gap-2">
        {members.map((member) => (
          <div
            key={member.id}
            className="flex items-center gap-3 bg-white rounded-2xl px-4 py-3 border border-gray-100 shadow-sm"
          >
            {/* Avatar */}
            <div
              className="w-10 h-10 rounded-full flex items-center justify-center text-white font-semibold text-sm flex-shrink-0"
              style={{ backgroundColor: member.color }}
            >
              {member.name.slice(0, 1).toUpperCase()}
            </div>

            {/* Info */}
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 truncate">{member.name}</p>
              {member.promptpay && (
                <p className="text-xs text-gray-400 mt-0.5">
                  PromptPay: {maskPromptpay(member.promptpay)}
                </p>
              )}
            </div>

            {/* Actions */}
            <div className="flex items-center gap-1">
              <button
                onClick={() => openEdit(member)}
                className="w-8 h-8 flex items-center justify-center rounded-xl hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <IoPencil size={15} />
              </button>
              {deleteConfirmId === member.id ? (
                <div className="flex items-center gap-1">
                  <button
                    onClick={() => {
                      onRemove(member.id);
                      setDeleteConfirmId(null);
                    }}
                    className="text-xs text-red-500 font-medium px-2 py-1 rounded-lg hover:bg-red-50 transition-colors"
                  >
                    ลบ
                  </button>
                  <button
                    onClick={() => setDeleteConfirmId(null)}
                    className="text-xs text-gray-400 px-2 py-1 rounded-lg hover:bg-gray-100 transition-colors"
                  >
                    ยกเลิก
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => setDeleteConfirmId(member.id)}
                  className="w-8 h-8 flex items-center justify-center rounded-xl hover:bg-red-50 text-gray-400 hover:text-red-500 transition-colors"
                >
                  <IoTrash size={15} />
                </button>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Add/Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingMember ? "แก้ไขสมาชิก" : "เพิ่มสมาชิก"}
      >
        <div className="flex flex-col gap-4">
          <Input
            label="ชื่อ"
            placeholder="เช่น สมชาย"
            value={form.name}
            onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
            error={errors.name}
            autoFocus
            onKeyDown={(e) => e.key === "Enter" && handleSave()}
          />
          <Input
            label="PromptPay (ไม่บังคับ)"
            placeholder="เบอร์โทร หรือ เลขบัตรประชาชน"
            value={form.promptpay}
            onChange={(e) => setForm((p) => ({ ...p, promptpay: e.target.value }))}
            error={errors.promptpay}
            hint="ใช้สำหรับแสดง QR Code ชำระเงิน"
            inputMode="numeric"
          />
          <div className="flex gap-2 pt-2">
            <Button
              variant="secondary"
              fullWidth
              onClick={() => setIsModalOpen(false)}
            >
              ยกเลิก
            </Button>
            <Button fullWidth onClick={handleSave}>
              {editingMember ? "บันทึก" : "เพิ่ม"}
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
