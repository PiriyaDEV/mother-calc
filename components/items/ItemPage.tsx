"use client";

import { useState } from "react";
import { IoAdd, IoPencil, IoTrash, IoReceipt } from "react-icons/io5";
import { BillItem, Member, Settings } from "@/lib/types";
import { formatCurrency, getItemNetAmount, getMemberAmountInItem } from "@/lib/utils";
import ItemFormModal from "./ItemFormModal";
import Button from "@/components/ui/Button";

interface ItemPageProps {
  items: BillItem[];
  members: Member[];
  settings: Settings;
  onAdd: (item: Omit<BillItem, "id">) => void;
  onUpdate: (id: string, item: Omit<BillItem, "id">) => void;
  onRemove: (id: string) => void;
}

export default function ItemPage({
  items,
  members,
  settings,
  onAdd,
  onUpdate,
  onRemove,
}: ItemPageProps) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<BillItem | null>(null);
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);

  const openAdd = () => {
    setEditingItem(null);
    setIsModalOpen(true);
  };

  const openEdit = (item: BillItem) => {
    setEditingItem(item);
    setIsModalOpen(true);
  };

  const getMemberById = (id: string) => members.find((m) => m.id === id);

  const totalBill = items.reduce((sum, item) => sum + getItemNetAmount(item), 0);

  return (
    <div className="flex flex-col gap-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-base font-semibold text-gray-900">รายการ</h2>
          <p className="text-xs text-gray-400 mt-0.5">{items.length} รายการ</p>
        </div>
        <Button
          size="sm"
          onClick={openAdd}
          disabled={members.length === 0}
        >
          <IoAdd size={16} />
          เพิ่มรายการ
        </Button>
      </div>

      {members.length === 0 && (
        <div className="bg-amber-50 border border-amber-200 rounded-2xl px-4 py-3">
          <p className="text-xs text-amber-700">⚠️ กรุณาเพิ่มสมาชิกก่อนเพิ่มรายการ</p>
        </div>
      )}

      {/* Empty state */}
      {items.length === 0 && members.length > 0 && (
        <div className="flex flex-col items-center justify-center py-16 gap-3">
          <div className="w-16 h-16 rounded-2xl bg-[#4366f4]/10 flex items-center justify-center">
            <IoReceipt size={32} className="text-[#4366f4]" />
          </div>
          <p className="text-sm text-gray-500 text-center">
            ยังไม่มีรายการ
            <br />
            <span className="text-gray-400">กดปุ่ม &quot;เพิ่มรายการ&quot; เพื่อเริ่มต้น</span>
          </p>
        </div>
      )}

      {/* Item list */}
      <div className="flex flex-col gap-2">
        {items.map((item) => {
          const paidByMember = getMemberById(item.paidBy);
          const netAmount = getItemNetAmount(item);

          return (
            <div
              key={item.id}
              className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden"
            >
              {/* Item header */}
              <div className="flex items-start gap-3 px-4 pt-3 pb-2">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <p className="text-sm font-semibold text-gray-900">{item.name}</p>
                    <span className="text-xs px-2 py-0.5 rounded-full bg-gray-100 text-gray-500">
                      {item.splitType === "equal" ? "หารเท่า" : "หารไม่เท่า"}
                    </span>
                    {item.isVat && (
                      <span className="text-xs px-2 py-0.5 rounded-full bg-blue-50 text-blue-600">
                        VAT {item.vat}%
                      </span>
                    )}
                    {item.isService && (
                      <span className="text-xs px-2 py-0.5 rounded-full bg-purple-50 text-purple-600">
                        SC {item.serviceCharge}%
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2 mt-1">
                    <p className="text-base font-bold text-gray-900">
                      ฿{formatCurrency(netAmount)}
                    </p>
                    {paidByMember && (
                      <span className="text-xs text-gray-400">
                        จ่ายโดย{" "}
                        <span
                          className="font-medium"
                          style={{ color: paidByMember.color }}
                        >
                          {paidByMember.name}
                        </span>
                      </span>
                    )}
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center gap-1 flex-shrink-0">
                  <button
                    onClick={() => openEdit(item)}
                    className="w-8 h-8 flex items-center justify-center rounded-xl hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors"
                  >
                    <IoPencil size={14} />
                  </button>
                  {deleteConfirmId === item.id ? (
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => {
                          onRemove(item.id);
                          setDeleteConfirmId(null);
                        }}
                        className="text-xs text-red-500 font-medium px-2 py-1 rounded-lg hover:bg-red-50"
                      >
                        ลบ
                      </button>
                      <button
                        onClick={() => setDeleteConfirmId(null)}
                        className="text-xs text-gray-400 px-2 py-1 rounded-lg hover:bg-gray-100"
                      >
                        ยกเลิก
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={() => setDeleteConfirmId(item.id)}
                      className="w-8 h-8 flex items-center justify-center rounded-xl hover:bg-red-50 text-gray-400 hover:text-red-500 transition-colors"
                    >
                      <IoTrash size={14} />
                    </button>
                  )}
                </div>
              </div>

              {/* Member shares */}
              <div className="px-4 pb-3 flex flex-wrap gap-1.5">
                {item.shares.map((share) => {
                  const member = getMemberById(share.memberId);
                  if (!member) return null;
                  const memberNet = getMemberAmountInItem(item, share.memberId);
                  return (
                    <div
                      key={share.memberId}
                      className="flex items-center gap-1 px-2 py-1 rounded-lg bg-gray-50 border border-gray-100"
                    >
                      <div
                        className="w-3 h-3 rounded-full flex-shrink-0"
                        style={{ backgroundColor: member.color }}
                      />
                      <span className="text-xs text-gray-600">{member.name}</span>
                      <span className="text-xs font-medium text-gray-800">
                        ฿{formatCurrency(memberNet)}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>

      {/* Total */}
      {items.length > 0 && (
        <div className="bg-[#4366f4] rounded-2xl px-4 py-3 flex items-center justify-between">
          <p className="text-sm text-white/80">ยอดรวมทั้งหมด</p>
          <p className="text-lg font-bold text-white">฿{formatCurrency(totalBill)}</p>
        </div>
      )}

      {/* Modal */}
      <ItemFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSave={editingItem ? (item) => onUpdate(editingItem.id, item) : onAdd}
        members={members}
        settings={settings}
        editingItem={editingItem}
      />
    </div>
  );
}
