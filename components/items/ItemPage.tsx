"use client";

import { useState } from "react";
import { IoAdd, IoPencil, IoTrash, IoReceipt } from "react-icons/io5";
import { BillItem, Member, Settings } from "@/lib/types";
import { formatCurrency, getItemNetAmount } from "@/lib/utils";
import ItemFormModal from "./ItemFormModal";

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
  const [modalOpen, setModalOpen] = useState(false);
  const [editItem, setEditItem] = useState<BillItem | null>(null);

  const openAdd = () => {
    setEditItem(null);
    setModalOpen(true);
  };

  const openEdit = (item: BillItem) => {
    setEditItem(item);
    setModalOpen(true);
  };

  const handleSave = (data: Omit<BillItem, "id">) => {
    if (editItem) {
      onUpdate(editItem.id, data);
    } else {
      onAdd(data);
    }
  };

  const getMemberName = (id: string) =>
    members.find((m) => m.id === id)?.name || "ไม่ระบุ";

  const getMemberColor = (id: string) =>
    members.find((m) => m.id === id)?.color || "#9ca3af";

  return (
    <div className="flex flex-col gap-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-lg font-bold text-gray-900 dark:text-white">รายการ</h1>
          <p className="text-xs text-gray-400 mt-0.5">
            {items.length > 0
              ? `${items.length} รายการ`
              : "เพิ่มรายการเพื่อคำนวณ"}
          </p>
        </div>
        <button
          onClick={openAdd}
          disabled={members.length === 0}
          className="flex items-center gap-1.5 px-3 py-1.5 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-40 disabled:cursor-not-allowed text-white text-xs font-medium rounded-xl transition-all active:scale-95"
        >
          <IoAdd size={16} />
          เพิ่มรายการ
        </button>
      </div>

      {/* No members warning */}
      {members.length === 0 && (
        <div className="p-3 bg-amber-50 dark:bg-amber-900/20 rounded-xl border border-amber-200 dark:border-amber-800">
          <p className="text-xs text-amber-700 dark:text-amber-400">
            กรุณาเพิ่มสมาชิกก่อนเพิ่มรายการ
          </p>
        </div>
      )}

      {/* Empty state */}
      {items.length === 0 && members.length > 0 && (
        <div className="flex flex-col items-center justify-center py-16 gap-3">
          <div className="w-16 h-16 rounded-2xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center">
            <IoReceipt size={32} className="text-[#4366f4]" />
          </div>
          <p className="text-sm text-gray-500 dark:text-gray-400 text-center">
            ยังไม่มีรายการ
            <br />
            กดปุ่ม &quot;เพิ่มรายการ&quot; เพื่อเริ่มต้น
          </p>
        </div>
      )}

      {/* Item list */}
      <div className="flex flex-col gap-2">
        {items.map((item, idx) => {
          const netAmount = getItemNetAmount(item);
          const paidByMember = members.find((m) => m.id === item.paidBy);
          const participantIds =
            item.selectedMemberIds.length > 0
              ? item.selectedMemberIds
              : item.shares.map((s) => s.memberId);

          return (
            <div
              key={item.id}
              className="p-3.5 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm transition-all duration-200 hover:shadow-md"
              style={{ animationDelay: `${idx * 40}ms` }}
            >
              <div className="flex items-start gap-3">
                {/* Icon */}
                <div className="w-9 h-9 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <IoReceipt size={16} className="text-[#4366f4]" />
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                      {item.name}
                    </p>
                    <p className="text-sm font-bold text-gray-900 dark:text-white flex-shrink-0">
                      {formatCurrency(netAmount, settings.currency)}
                    </p>
                  </div>

                  {/* Tags */}
                  <div className="flex flex-wrap items-center gap-1.5 mt-1.5">
                    {/* Split type */}
                    <span className="px-2 py-0.5 bg-gray-100 dark:bg-gray-800 text-gray-500 dark:text-gray-400 text-[10px] rounded-lg">
                      {item.splitType === "equal" ? "หารเท่า" : "หารไม่เท่า"}
                    </span>

                    {/* VAT/SC */}
                    {item.isVat && (
                      <span className="px-2 py-0.5 bg-purple-50 dark:bg-purple-900/20 text-purple-600 dark:text-purple-400 text-[10px] rounded-lg">
                        VAT {item.vat}%
                      </span>
                    )}
                    {item.isService && (
                      <span className="px-2 py-0.5 bg-indigo-50 dark:bg-indigo-900/20 text-indigo-600 dark:text-indigo-400 text-[10px] rounded-lg">
                        SC {item.serviceCharge}%
                      </span>
                    )}

                    {/* Paid by */}
                    {paidByMember && (
                      <span
                        className="px-2 py-0.5 text-white text-[10px] rounded-lg"
                        style={{ backgroundColor: paidByMember.color }}
                      >
                        {paidByMember.name} จ่าย
                      </span>
                    )}
                  </div>

                  {/* Participants */}
                  <div className="flex items-center gap-1 mt-2">
                    {participantIds.slice(0, 6).map((id) => (
                      <div
                        key={id}
                        title={getMemberName(id)}
                        className="w-5 h-5 rounded-md flex items-center justify-center text-white text-[9px] font-bold"
                        style={{ backgroundColor: getMemberColor(id) }}
                      >
                        {getMemberName(id).slice(0, 1).toUpperCase()}
                      </div>
                    ))}
                    {participantIds.length > 6 && (
                      <span className="text-[10px] text-gray-400">
                        +{participantIds.length - 6}
                      </span>
                    )}
                  </div>
                </div>

                {/* Actions */}
                <div className="flex flex-col gap-1 flex-shrink-0">
                  <button
                    onClick={() => openEdit(item)}
                    className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-400 hover:text-gray-600 transition-colors"
                  >
                    <IoPencil size={13} />
                  </button>
                  <button
                    onClick={() => onRemove(item.id)}
                    className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 transition-colors"
                  >
                    <IoTrash size={13} />
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Item Form Modal */}
      <ItemFormModal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        onSave={handleSave}
        members={members}
        settings={settings}
        editItem={editItem}
      />
    </div>
  );
}
