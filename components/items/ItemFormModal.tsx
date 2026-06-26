"use client";

import { useEffect, useState } from "react";
import { BillItem, Member, Settings, SplitType } from "@/lib/types";
import Modal from "@/components/ui/Modal";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Toggle from "@/components/ui/Toggle";

interface ItemFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (item: Omit<BillItem, "id">) => void;
  members: Member[];
  settings: Settings;
  editItem?: BillItem | null;
}

export default function ItemFormModal({
  isOpen,
  onClose,
  onSave,
  members,
  settings,
  editItem,
}: ItemFormModalProps) {
  const [name, setName] = useState("");
  const [amount, setAmount] = useState("");
  const [splitType, setSplitType] = useState<SplitType>("equal");
  const [selectedMemberIds, setSelectedMemberIds] = useState<string[]>([]);
  const [unequalAmounts, setUnequalAmounts] = useState<Record<string, string>>({});
  const [paidBy, setPaidBy] = useState("");
  const [isVat, setIsVat] = useState(settings.isVat);
  const [isService, setIsService] = useState(settings.isService);
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Reset form when modal opens
  useEffect(() => {
    if (!isOpen) return;
    if (editItem) {
      setName(editItem.name);
      setAmount(String(editItem.totalAmount));
      setSplitType(editItem.splitType);
      setSelectedMemberIds(
        editItem.selectedMemberIds.length > 0
          ? editItem.selectedMemberIds
          : editItem.shares.map((s) => s.memberId)
      );
      const ua: Record<string, string> = {};
      editItem.shares.forEach((s) => {
        ua[s.memberId] = String(s.amount);
      });
      setUnequalAmounts(ua);
      setPaidBy(editItem.paidBy);
      setIsVat(editItem.isVat);
      setIsService(editItem.isService);
    } else {
      setName("");
      setAmount("");
      setSplitType("equal");
      setSelectedMemberIds(members.map((m) => m.id));
      setUnequalAmounts({});
      setPaidBy(members[0]?.id || "");
      setIsVat(settings.isVat);
      setIsService(settings.isService);
    }
    setErrors({});
  }, [isOpen, editItem, members, settings]);

  const toggleMember = (id: string) => {
    setSelectedMemberIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  };

  const totalAmount = parseFloat(amount) || 0;

  const validate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!name.trim()) errs.name = "กรุณาใส่ชื่อรายการ";
    if (!amount || totalAmount <= 0) errs.amount = "กรุณาใส่ราคา";
    if (selectedMemberIds.length === 0) errs.members = "เลือกสมาชิกอย่างน้อย 1 คน";
    if (splitType === "unequal") {
      const total = selectedMemberIds.reduce(
        (s, id) => s + (parseFloat(unequalAmounts[id] || "0") || 0),
        0
      );
      if (Math.abs(total - totalAmount) > 0.01)
        errs.unequal = `ยอดรวมต้องเท่ากับ ${totalAmount} (ตอนนี้ ${total.toFixed(2)})`;
    }
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const buildShares = () => {
    if (splitType === "equal") {
      const perPerson = totalAmount / selectedMemberIds.length;
      return selectedMemberIds.map((id) => ({ memberId: id, amount: perPerson }));
    }
    return selectedMemberIds.map((id) => ({
      memberId: id,
      amount: parseFloat(unequalAmounts[id] || "0") || 0,
    }));
  };

  const handleSave = () => {
    if (!validate()) return;
    onSave({
      name: name.trim(),
      splitType,
      totalAmount,
      shares: buildShares(),
      selectedMemberIds,
      paidBy,
      vat: settings.vat,
      serviceCharge: settings.serviceCharge,
      isVat,
      isService,
    });
    onClose();
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={editItem ? "แก้ไขรายการ" : "เพิ่มรายการ"}
      size="lg"
    >
      <div className="flex flex-col gap-4">
        {/* Name */}
        <Input
          label="ชื่อรายการ"
          placeholder="เช่น ข้าวผัด, เบียร์"
          value={name}
          onChange={(e) => setName(e.target.value)}
          error={errors.name}
          autoFocus
        />

        {/* Amount */}
        <Input
          label="ราคารวม (บาท)"
          placeholder="0.00"
          type="number"
          inputMode="decimal"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          error={errors.amount}
          prefix="฿"
        />

        {/* Paid by */}
        {members.length > 0 && (
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
              ใครจ่ายไปก่อน
            </label>
            <div className="flex flex-wrap gap-2">
              {members.map((m) => (
                <button
                  key={m.id}
                  type="button"
                  onClick={() => setPaidBy(m.id)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-medium transition-all ${
                    paidBy === m.id
                      ? "text-white shadow-sm"
                      : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400"
                  }`}
                  style={paidBy === m.id ? { backgroundColor: m.color } : {}}
                >
                  {m.name}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Split type */}
        <div className="flex flex-col gap-1.5">
          <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
            วิธีหาร
          </label>
          <div className="flex gap-2">
            {(["equal", "unequal"] as SplitType[]).map((t) => (
              <button
                key={t}
                type="button"
                onClick={() => setSplitType(t)}
                className={`flex-1 py-2 rounded-xl text-xs font-medium transition-all ${
                  splitType === t
                    ? "bg-[#4366f4] text-white"
                    : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400"
                }`}
              >
                {t === "equal" ? "หารเท่า" : "หารไม่เท่า"}
              </button>
            ))}
          </div>
        </div>

        {/* Member selection */}
        {members.length > 0 && (
          <div className="flex flex-col gap-1.5">
            <div className="flex items-center justify-between">
              <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
                สมาชิกที่ร่วม
              </label>
              {errors.members && (
                <span className="text-xs text-red-500">{errors.members}</span>
              )}
            </div>
            <div className="flex flex-col gap-2">
              {members.map((m) => {
                const selected = selectedMemberIds.includes(m.id);
                return (
                  <div key={m.id} className="flex items-center gap-3">
                    <button
                      type="button"
                      onClick={() => toggleMember(m.id)}
                      className={`flex items-center gap-2 flex-1 px-3 py-2 rounded-xl border transition-all text-left ${
                        selected
                          ? "border-[#4366f4] bg-blue-50 dark:bg-blue-900/20"
                          : "border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800"
                      }`}
                    >
                      <div
                        className="w-6 h-6 rounded-lg flex items-center justify-center text-white text-xs font-bold flex-shrink-0"
                        style={{ backgroundColor: m.color }}
                      >
                        {m.name.slice(0, 1).toUpperCase()}
                      </div>
                      <span className="text-sm text-gray-800 dark:text-gray-200">
                        {m.name}
                      </span>
                      {splitType === "equal" && selected && totalAmount > 0 && (
                        <span className="ml-auto text-xs text-[#4366f4] font-medium">
                          ฿{(totalAmount / selectedMemberIds.length).toFixed(2)}
                        </span>
                      )}
                    </button>

                    {/* Unequal amount input */}
                    {splitType === "unequal" && selected && (
                      <div className="w-24">
                        <Input
                          type="number"
                          inputMode="decimal"
                          placeholder="0.00"
                          value={unequalAmounts[m.id] || ""}
                          onChange={(e) =>
                            setUnequalAmounts((prev) => ({
                              ...prev,
                              [m.id]: e.target.value,
                            }))
                          }
                          prefix="฿"
                        />
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
            {errors.unequal && (
              <p className="text-xs text-red-500">{errors.unequal}</p>
            )}
          </div>
        )}

        {/* VAT / Service */}
        <div className="flex flex-col gap-2 p-3 bg-gray-50 dark:bg-gray-800/50 rounded-xl">
          <p className="text-xs font-medium text-gray-500 dark:text-gray-400">
            ภาษีและค่าบริการ
          </p>
          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-700 dark:text-gray-300">
              VAT {settings.vat}%
            </span>
            <Toggle checked={isVat} onChange={setIsVat} size="sm" />
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-700 dark:text-gray-300">
              Service Charge {settings.serviceCharge}%
            </span>
            <Toggle checked={isService} onChange={setIsService} size="sm" />
          </div>
        </div>

        {/* Actions */}
        <div className="flex gap-2 pt-1">
          <Button variant="secondary" fullWidth onClick={onClose}>
            ยกเลิก
          </Button>
          <Button fullWidth onClick={handleSave}>
            {editItem ? "บันทึก" : "เพิ่ม"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
