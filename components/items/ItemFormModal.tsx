"use client";

import { useState, useEffect } from "react";
import { BillItem, Member, Settings, SplitType } from "@/lib/types";
import Modal from "@/components/ui/Modal";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Toggle from "@/components/ui/Toggle";
import { formatCurrency } from "@/lib/utils";

interface ItemFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (item: Omit<BillItem, "id">) => void;
  members: Member[];
  settings: Settings;
  editingItem?: BillItem | null;
}

export default function ItemFormModal({
  isOpen,
  onClose,
  onSave,
  members,
  settings,
  editingItem,
}: ItemFormModalProps) {
  const [name, setName] = useState("");
  const [splitType, setSplitType] = useState<SplitType>("equal");
  const [totalAmount, setTotalAmount] = useState("");
  const [shares, setShares] = useState<Record<string, string>>({});
  const [paidBy, setPaidBy] = useState("");
  const [isVat, setIsVat] = useState(settings.isVat);
  const [isService, setIsService] = useState(settings.isService);
  const [vat, setVat] = useState(settings.vat.toString());
  const [serviceCharge, setServiceCharge] = useState(settings.serviceCharge.toString());
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Reset form when modal opens
  useEffect(() => {
    if (!isOpen) return;
    if (editingItem) {
      setName(editingItem.name);
      setSplitType(editingItem.splitType);
      setTotalAmount(editingItem.totalAmount.toString());
      const sharesMap: Record<string, string> = {};
      editingItem.shares.forEach((s) => {
        sharesMap[s.memberId] = s.amount.toString();
      });
      setShares(sharesMap);
      setPaidBy(editingItem.paidBy);
      setIsVat(editingItem.isVat);
      setIsService(editingItem.isService);
      setVat(editingItem.vat.toString());
      setServiceCharge(editingItem.serviceCharge.toString());
    } else {
      setName("");
      setSplitType("equal");
      setTotalAmount("");
      const initShares: Record<string, string> = {};
      members.forEach((m) => (initShares[m.id] = ""));
      setShares(initShares);
      setPaidBy(members[0]?.id || "");
      setIsVat(settings.isVat);
      setIsService(settings.isService);
      setVat(settings.vat.toString());
      setServiceCharge(settings.serviceCharge.toString());
    }
    setErrors({});
  }, [isOpen, editingItem, members, settings]);

  // Auto-calculate equal split
  const equalAmount =
    splitType === "equal" && members.length > 0 && parseFloat(totalAmount) > 0
      ? parseFloat(totalAmount) / members.length
      : 0;

  const validate = (): boolean => {
    const errs: Record<string, string> = {};
    if (!name.trim()) errs.name = "กรุณาใส่ชื่อรายการ";
    if (!paidBy) errs.paidBy = "กรุณาเลือกคนจ่าย";

    if (splitType === "equal") {
      if (!totalAmount || parseFloat(totalAmount) <= 0)
        errs.totalAmount = "กรุณาใส่ราคา";
    } else {
      // unequal: ต้องมีอย่างน้อย 1 คนที่ใส่ราคา
      const hasAny = Object.values(shares).some((v) => parseFloat(v) > 0);
      if (!hasAny) errs.shares = "กรุณาใส่ราคาอย่างน้อย 1 คน";
    }
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSave = () => {
    if (!validate()) return;

    let itemShares: BillItem["shares"];
    if (splitType === "equal") {
      const amt = parseFloat(totalAmount) / members.length;
      itemShares = members.map((m) => ({ memberId: m.id, amount: amt }));
    } else {
      itemShares = members
        .map((m) => ({ memberId: m.id, amount: parseFloat(shares[m.id] || "0") || 0 }))
        .filter((s) => s.amount > 0);
    }

    const total =
      splitType === "equal"
        ? parseFloat(totalAmount)
        : itemShares.reduce((sum, s) => sum + s.amount, 0);

    onSave({
      name: name.trim(),
      splitType,
      totalAmount: total,
      shares: itemShares,
      paidBy,
      isVat,
      isService,
      vat: parseFloat(vat) || 0,
      serviceCharge: parseFloat(serviceCharge) || 0,
    });
    onClose();
  };

  const multiplier =
    (isService ? 1 + (parseFloat(serviceCharge) || 0) / 100 : 1) *
    (isVat ? 1 + (parseFloat(vat) || 0) / 100 : 1);

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={editingItem ? "แก้ไขรายการ" : "เพิ่มรายการ"}
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

        {/* Split type */}
        <div>
          <p className="text-sm font-medium text-gray-700 mb-2">วิธีหาร</p>
          <div className="flex gap-2">
            {(["equal", "unequal"] as SplitType[]).map((type) => (
              <button
                key={type}
                onClick={() => setSplitType(type)}
                className={`flex-1 py-2 text-sm rounded-xl border transition-all ${
                  splitType === type
                    ? "bg-[#4366f4] text-white border-[#4366f4]"
                    : "bg-white text-gray-600 border-gray-200 hover:border-[#4366f4]/40"
                }`}
              >
                {type === "equal" ? "หารเท่า" : "หารไม่เท่า"}
              </button>
            ))}
          </div>
        </div>

        {/* Equal split: total amount */}
        {splitType === "equal" && (
          <Input
            label="ราคารวม (บาท)"
            type="number"
            placeholder="0.00"
            value={totalAmount}
            onChange={(e) => setTotalAmount(e.target.value)}
            error={errors.totalAmount}
            onKeyDown={(e) => ["e", "-"].includes(e.key) && e.preventDefault()}
          />
        )}

        {/* Unequal split: per-member amounts */}
        {splitType === "unequal" && (
          <div>
            <p className="text-sm font-medium text-gray-700 mb-2">ราคาแต่ละคน (บาท)</p>
            {errors.shares && <p className="text-xs text-red-500 mb-2">{errors.shares}</p>}
            <div className="flex flex-col gap-2">
              {members.map((member) => (
                <div key={member.id} className="flex items-center gap-3">
                  <div
                    className="w-7 h-7 rounded-full flex items-center justify-center text-white text-xs font-semibold flex-shrink-0"
                    style={{ backgroundColor: member.color }}
                  >
                    {member.name.slice(0, 1).toUpperCase()}
                  </div>
                  <span className="text-sm text-gray-700 flex-1 min-w-0 truncate">
                    {member.name}
                  </span>
                  <input
                    type="number"
                    placeholder="0"
                    value={shares[member.id] || ""}
                    onChange={(e) =>
                      setShares((p) => ({ ...p, [member.id]: e.target.value }))
                    }
                    onKeyDown={(e) => ["e", "-"].includes(e.key) && e.preventDefault()}
                    className="w-24 h-9 px-3 text-sm text-right bg-white border border-gray-200 rounded-xl outline-none focus:border-[#4366f4] focus:ring-2 focus:ring-[#4366f4]/10"
                  />
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Paid by */}
        <div>
          <p className="text-sm font-medium text-gray-700 mb-2">คนจ่าย</p>
          {errors.paidBy && <p className="text-xs text-red-500 mb-1">{errors.paidBy}</p>}
          <div className="flex flex-wrap gap-2">
            {members.map((member) => (
              <button
                key={member.id}
                onClick={() => setPaidBy(member.id)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-sm border transition-all ${
                  paidBy === member.id
                    ? "border-[#4366f4] bg-[#4366f4]/5 text-[#4366f4] font-medium"
                    : "border-gray-200 text-gray-600 hover:border-gray-300"
                }`}
              >
                <div
                  className="w-4 h-4 rounded-full"
                  style={{ backgroundColor: member.color }}
                />
                {member.name}
              </button>
            ))}
          </div>
        </div>

        {/* VAT & Service Charge */}
        <div className="bg-gray-50 rounded-2xl p-4 flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-gray-700">VAT ({vat}%)</p>
            <Toggle checked={isVat} onChange={setIsVat} />
          </div>
          <div className="flex items-center justify-between">
            <p className="text-sm font-medium text-gray-700">Service Charge ({serviceCharge}%)</p>
            <Toggle checked={isService} onChange={setIsService} />
          </div>
          {(isVat || isService) && (
            <div className="pt-1 border-t border-gray-200">
              <p className="text-xs text-gray-500">
                ราคาสุทธิ ×{multiplier.toFixed(4)} ={" "}
                <span className="font-semibold text-gray-700">
                  {splitType === "equal" && parseFloat(totalAmount) > 0
                    ? `฿${formatCurrency(parseFloat(totalAmount) * multiplier)}`
                    : splitType === "unequal"
                    ? `฿${formatCurrency(
                        Object.values(shares).reduce((s, v) => s + (parseFloat(v) || 0), 0) *
                          multiplier
                      )}`
                    : "-"}
                </span>
              </p>
            </div>
          )}
        </div>

        {/* Equal split preview */}
        {splitType === "equal" && equalAmount > 0 && (
          <div className="bg-[#4366f4]/5 rounded-2xl p-3">
            <p className="text-xs text-[#4366f4]">
              แต่ละคนจ่าย:{" "}
              <span className="font-semibold">
                ฿{formatCurrency(equalAmount * multiplier)}
              </span>{" "}
              ({members.length} คน)
            </p>
          </div>
        )}

        {/* Actions */}
        <div className="flex gap-2 pt-1">
          <Button variant="secondary" fullWidth onClick={onClose}>
            ยกเลิก
          </Button>
          <Button fullWidth onClick={handleSave}>
            {editingItem ? "บันทึก" : "เพิ่ม"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
