"use client";

import { useState, useEffect } from "react";
import { IoClose, IoCheckmark } from "react-icons/io5";
import { BillItem, BillMember } from "@/lib/types";
import Modal from "@/components/ui/Modal";
import Input from "@/components/ui/Input";
import Button from "@/components/ui/Button";

type SplitMode = "equal" | "unequal";

interface ItemFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  members: BillMember[];
  editItem?: BillItem | null;
  onSave: (data: { name: string; price: number; shares: Record<string, number>; paid_by: string | null }) => Promise<void>;
}

export default function ItemFormModal({ isOpen, onClose, members, editItem, onSave }: ItemFormModalProps) {
  const [name, setName] = useState("");
  const [price, setPrice] = useState("");
  const [splitMode, setSplitMode] = useState<SplitMode>("equal");
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [unequalAmounts, setUnequalAmounts] = useState<Record<string, string>>({});
  const [paidById, setPaidById] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Default paid_by = first member (bill owner)
  const defaultPaidById = members[0]?.id ?? null;

  useEffect(() => {
    if (!isOpen) return;
    if (editItem) {
      setName(editItem.name);
      setPrice(String(editItem.price));
      const ids = new Set(Object.keys(editItem.shares));
      setSelectedIds(ids);
      // If item has no paid_by, fall back to first member
      setPaidById(editItem.paid_by ?? defaultPaidById);

      const weights = Object.values(editItem.shares);
      const allEqual = weights.every((w) => w === 1);
      if (allEqual) {
        setSplitMode("equal");
        setUnequalAmounts({});
      } else {
        const total = weights.reduce((s, w) => s + w, 0);
        const ua: Record<string, string> = {};
        for (const [id, w] of Object.entries(editItem.shares)) {
          ua[id] = ((w / total) * editItem.price).toFixed(2);
        }
        setSplitMode("unequal");
        setUnequalAmounts(ua);
      }
    } else {
      setName("");
      setPrice("");
      setSplitMode("equal");
      setSelectedIds(new Set(members.map((m) => m.id)));
      setUnequalAmounts({});
      // Default to first member
      setPaidById(defaultPaidById);
    }
    setErrors({});
  }, [isOpen, editItem, members]);

  const toggleMember = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const totalAmount = parseFloat(price) || 0;
  const selectedArr = Array.from(selectedIds);

  const unequalTotal = selectedArr.reduce(
    (s, id) => s + (parseFloat(unequalAmounts[id] || "0") || 0),
    0
  );

  const validate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!name.trim()) errs.name = "กรุณาใส่ชื่อรายการ";
    if (!price || totalAmount <= 0) errs.price = "กรุณาใส่ราคา";
    if (selectedIds.size === 0) errs.members = "เลือกสมาชิกอย่างน้อย 1 คน";
    if (splitMode === "unequal") {
      if (Math.abs(unequalTotal - totalAmount) > 0.01) {
        errs.unequal = `ยอดรวมต้องเท่ากับ ฿${totalAmount.toFixed(2)} (ตอนนี้ ฿${unequalTotal.toFixed(2)})`;
      }
    }
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const buildShares = (): Record<string, number> => {
    if (splitMode === "equal") {
      const shares: Record<string, number> = {};
      for (const id of selectedIds) shares[id] = 1;
      return shares;
    }
    const shares: Record<string, number> = {};
    for (const id of selectedArr) {
      shares[id] = parseFloat(unequalAmounts[id] || "0") || 0;
    }
    return shares;
  };

  const handleSave = async () => {
    if (!validate()) return;
    setSaving(true);
    try {
      await onSave({ name: name.trim(), price: totalAmount, shares: buildShares(), paid_by: paidById });
      onClose();
    } finally {
      setSaving(false);
    }
  };

  const perPerson =
    splitMode === "equal" && selectedIds.size > 0 && totalAmount > 0
      ? totalAmount / selectedIds.size
      : 0;

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={editItem ? "แก้ไขรายการ" : "เพิ่มรายการ"}>
      <div className="flex flex-col gap-4">
        {/* Name */}
        <Input
          label="ชื่อรายการ"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="เช่น ข้าวผัด, เบียร์"
          autoFocus
          error={errors.name}
        />

        {/* Price */}
        <Input
          label="ราคารวม (บาท)"
          type="number"
          inputMode="decimal"
          value={price}
          onChange={(e) => setPrice(e.target.value)}
          placeholder="0.00"
          error={errors.price}
        />

        {/* Paid by selector — required */}
        <div className="flex flex-col gap-1.5">
          <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
            ใครจ่ายไปก่อน <span className="text-red-400">*</span>
          </label>
          <div className="flex flex-wrap gap-2">
            {members.map((m) => (
              <button
                key={m.id}
                type="button"
                onClick={() => setPaidById(m.id)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium transition-all border ${
                  paidById === m.id
                    ? "border-[#4366f4] bg-blue-50 dark:bg-blue-900/20 text-[#4366f4]"
                    : "border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-400 hover:border-gray-300"
                }`}
              >
                <div
                  className="w-4 h-4 rounded-full flex items-center justify-center text-white text-[8px] font-bold flex-shrink-0"
                  style={{ backgroundColor: m.color }}
                >
                  {paidById === m.id ? <IoCheckmark size={8} /> : m.name.charAt(0).toUpperCase()}
                </div>
                {m.name}
              </button>
            ))}
          </div>
        </div>

        {/* Split mode toggle */}
        <div className="flex flex-col gap-1.5">
          <label className="text-xs font-medium text-gray-600 dark:text-gray-400">วิธีหาร</label>
          <div className="flex gap-2">
            {(["equal", "unequal"] as SplitMode[]).map((mode) => (
              <button
                key={mode}
                type="button"
                onClick={() => setSplitMode(mode)}
                className={`flex-1 py-2 rounded-xl text-xs font-semibold transition-all ${
                  splitMode === mode
                    ? "bg-[#4366f4] text-white shadow-sm"
                    : "bg-gray-100 dark:bg-gray-800 text-gray-500 dark:text-gray-400"
                }`}
              >
                {mode === "equal" ? "หารเท่า" : "หารไม่เท่า"}
              </button>
            ))}
          </div>
        </div>

        {/* Member selection */}
        <div>
          <div className="flex items-center justify-between mb-2">
            <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
              เลือกสมาชิก
            </label>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => setSelectedIds(new Set(members.map((m) => m.id)))}
                className="text-xs text-[#4366f4] hover:underline"
              >
                เลือกทั้งหมด
              </button>
              <span className="text-gray-300">|</span>
              <button
                type="button"
                onClick={() => setSelectedIds(new Set())}
                className="text-xs text-gray-400 hover:underline"
              >
                ล้าง
              </button>
            </div>
          </div>

          {errors.members && (
            <p className="text-xs text-red-500 mb-2">{errors.members}</p>
          )}

          <div className="flex flex-col gap-2">
            {members.map((member) => {
              const selected = selectedIds.has(member.id);
              return (
                <div key={member.id} className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => toggleMember(member.id)}
                    className={`flex items-center gap-2 flex-1 px-3 py-2 rounded-xl border transition-all text-left ${
                      selected
                        ? "border-[#4366f4] bg-blue-50 dark:bg-blue-900/20"
                        : "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800"
                    }`}
                  >
                    <div
                      className="w-6 h-6 rounded-lg flex items-center justify-center text-white text-xs font-bold flex-shrink-0"
                      style={{ backgroundColor: member.color }}
                    >
                      {selected ? <IoCheckmark size={12} /> : member.name.charAt(0).toUpperCase()}
                    </div>
                    <span className="text-sm text-gray-800 dark:text-gray-200 flex-1">
                      {member.name}
                    </span>
                    {splitMode === "equal" && selected && perPerson > 0 && (
                      <span className="text-xs text-[#4366f4] font-semibold">
                        ฿{perPerson.toFixed(2)}
                      </span>
                    )}
                  </button>

                  {splitMode === "unequal" && selected && (
                    <div className="w-28 flex-shrink-0">
                      <Input
                        type="number"
                        inputMode="decimal"
                        placeholder="0.00"
                        value={unequalAmounts[member.id] || ""}
                        onChange={(e) =>
                          setUnequalAmounts((prev) => ({
                            ...prev,
                            [member.id]: e.target.value,
                          }))
                        }
                      />
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {splitMode === "unequal" && selectedIds.size > 0 && (
            <div className={`mt-2 text-xs font-medium ${
              errors.unequal ? "text-red-500" : "text-gray-400"
            }`}>
              {errors.unequal
                ? errors.unequal
                : `รวม ฿${unequalTotal.toFixed(2)} / ฿${totalAmount.toFixed(2)}`}
            </div>
          )}
        </div>

        {/* Actions */}
        <div className="flex gap-2 pt-1">
          <Button
            onClick={handleSave}
            disabled={saving || !name.trim() || !price || selectedIds.size === 0}
            className="flex-1"
          >
            {saving ? "กำลังบันทึก..." : editItem ? "บันทึก" : "เพิ่มรายการ"}
          </Button>
          <Button variant="secondary" onClick={onClose} disabled={saving}>
            <IoClose size={16} />
          </Button>
        </div>
      </div>
    </Modal>
  );
}
