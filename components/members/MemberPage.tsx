"use client";

import { useState } from "react";
import { IoAdd, IoPencil, IoTrash, IoPersonCircle } from "react-icons/io5";
import { Member } from "@/lib/types";
import { validatePromptpay } from "@/lib/utils";
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
  const [modalOpen, setModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<MemberFormState>({ name: "", promptpay: "" });
  const [errors, setErrors] = useState<Partial<MemberFormState>>({});

  const openAdd = () => {
    setEditingId(null);
    setForm({ name: "", promptpay: "" });
    setErrors({});
    setModalOpen(true);
  };

  const openEdit = (member: Member) => {
    setEditingId(member.id);
    setForm({ name: member.name, promptpay: member.promptpay || "" });
    setErrors({});
    setModalOpen(true);
  };

  const validate = (): boolean => {
    const errs: Partial<MemberFormState> = {};
    if (!form.name.trim()) errs.name = "กรุณาใส่ชื่อ";
    if (form.promptpay && !validatePromptpay(form.promptpay))
      errs.promptpay = "เบอร์โทรหรือเลขบัตรประชาชนไม่ถูกต้อง";
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = () => {
    if (!validate()) return;
    if (editingId) {
      onUpdate(editingId, form.name, form.promptpay || undefined);
    } else {
      onAdd(form.name, form.promptpay || undefined);
    }
    setModalOpen(false);
  };

  return (
    <div className="flex flex-col gap-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-lg font-bold text-gray-900 dark:text-white">สมาชิก</h1>
          <p className="text-xs text-gray-400 mt-0.5">
            {members.length > 0
              ? `${members.length} คน`
              : "เพิ่มสมาชิกเพื่อเริ่มหารบิล"}
          </p>
        </div>
        <Button onClick={openAdd} size="sm">
          <IoAdd size={16} />
          เพิ่มสมาชิก
        </Button>
      </div>

      {/* Empty state */}
      {members.length === 0 && (
        <div className="flex flex-col items-center justify-center py-16 gap-3">
          <div className="w-16 h-16 rounded-2xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center">
            <IoPersonCircle size={32} className="text-[#4366f4]" />
          </div>
          <p className="text-sm text-gray-500 dark:text-gray-400 text-center">
            ยังไม่มีสมาชิก
            <br />
            กดปุ่ม &quot;เพิ่มสมาชิก&quot; เพื่อเริ่มต้น
          </p>
        </div>
      )}

      {/* Member list */}
      <div className="flex flex-col gap-2">
        {members.map((member, idx) => (
          <div
            key={member.id}
            className="flex items-center gap-3 p-3.5 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm transition-all duration-200 hover:shadow-md"
            style={{ animationDelay: `${idx * 40}ms` }}
          >
            {/* Avatar */}
            <div
              className="w-10 h-10 rounded-xl flex items-center justify-center text-white font-bold text-sm flex-shrink-0"
              style={{ backgroundColor: member.color }}
            >
              {member.name.slice(0, 1).toUpperCase()}
            </div>

            {/* Info */}
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                {member.name}
              </p>
              {member.promptpay && (
                <p className="text-xs text-gray-400 truncate">
                  PromptPay: {member.promptpay}
                </p>
              )}
            </div>

            {/* Actions */}
            <div className="flex items-center gap-1">
              <button
                onClick={() => openEdit(member)}
                className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <IoPencil size={14} />
              </button>
              <button
                onClick={() => onRemove(member.id)}
                className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 transition-colors"
              >
                <IoTrash size={14} />
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Modal */}
      <Modal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editingId ? "แก้ไขสมาชิก" : "เพิ่มสมาชิก"}
      >
        <div className="flex flex-col gap-4">
          <Input
            label="ชื่อ"
            placeholder="เช่น สมชาย"
            value={form.name}
            onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
            error={errors.name}
            autoFocus
          />
          <Input
            label="PromptPay (ไม่บังคับ)"
            placeholder="เบอร์โทร หรือ เลขบัตรประชาชน"
            value={form.promptpay}
            onChange={(e) =>
              setForm((f) => ({ ...f, promptpay: e.target.value }))
            }
            error={errors.promptpay}
            hint="ใช้สำหรับสร้าง QR Code ชำระเงิน"
            inputMode="numeric"
          />
          <div className="flex gap-2 pt-1">
            <Button
              variant="secondary"
              fullWidth
              onClick={() => setModalOpen(false)}
            >
              ยกเลิก
            </Button>
            <Button fullWidth onClick={handleSubmit}>
              {editingId ? "บันทึก" : "เพิ่ม"}
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
