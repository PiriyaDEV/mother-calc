"use client";

import { useState } from "react";
import { IoAdd, IoPencil, IoTrash, IoReceiptOutline } from "react-icons/io5";
import { BillItem, BillMember } from "@/lib/types";
import ItemFormModal from "./ItemFormModal";

interface ItemPageProps {
  items: BillItem[];
  members: BillMember[];
  onAdd: (data: { name: string; price: number; shares: Record<string, number> }) => Promise<void>;
  onEdit: (itemId: string, updates: Partial<Pick<BillItem, "name" | "price" | "shares">>) => Promise<void>;
  onDelete: (itemId: string) => Promise<void>;
}

export default function ItemPage({ items, members, onAdd, onEdit, onDelete }: ItemPageProps) {
  const [showModal, setShowModal] = useState(false);
  const [editItem, setEditItem] = useState<BillItem | null>(null);

  const handleSave = async (data: { name: string; price: number; shares: Record<string, number> }) => {
    if (editItem) {
      await onEdit(editItem.id, data);
    } else {
      await onAdd(data);
    }
  };

  const openEdit = (item: BillItem) => {
    setEditItem(item);
    setShowModal(true);
  };

  const openAdd = () => {
    setEditItem(null);
    setShowModal(true);
  };

  const total = items.reduce((sum, item) => sum + item.price, 0);

  return (
    <div className="flex flex-col gap-4">
      {/* Empty state */}
      {items.length === 0 && (
        <div className="flex flex-col items-center gap-3 py-10 text-center">
          <div className="w-14 h-14 rounded-2xl bg-gray-100 dark:bg-gray-800 flex items-center justify-center">
            <IoReceiptOutline size={24} className="text-gray-400" />
          </div>
          <p className="text-sm text-gray-500 dark:text-gray-400">ยังไม่มีรายการ</p>
          <p className="text-xs text-gray-400">เพิ่มรายการอาหารหรือสินค้าที่ต้องหาร</p>
        </div>
      )}

      {/* Item list */}
      <div className="flex flex-col gap-2">
        {items.map((item) => {
          const sharedWith = Object.keys(item.shares)
            .map((id) => members.find((m) => m.id === id))
            .filter(Boolean) as BillMember[];

          return (
            <div key={item.id} className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl px-4 py-3">
              <div className="flex items-start gap-3">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{item.name}</p>
                    <p className="text-sm font-bold text-gray-900 dark:text-white flex-shrink-0">
                      ฿{item.price.toFixed(2)}
                    </p>
                  </div>
                  {/* Shared with avatars */}
                  {sharedWith.length > 0 && (
                    <div className="flex items-center gap-1 mt-1.5">
                      <div className="flex -space-x-1">
                        {sharedWith.slice(0, 5).map((m) => (
                          <div
                            key={m.id}
                            title={m.name}
                            className="w-5 h-5 rounded-full border-2 border-white dark:border-gray-800 flex items-center justify-center text-white text-[9px] font-bold"
                            style={{ backgroundColor: m.color }}
                          >
                            {m.name.charAt(0).toUpperCase()}
                          </div>
                        ))}
                        {sharedWith.length > 5 && (
                          <div className="w-5 h-5 rounded-full border-2 border-white dark:border-gray-800 bg-gray-300 dark:bg-gray-600 flex items-center justify-center text-[9px] font-bold text-gray-600 dark:text-gray-300">
                            +{sharedWith.length - 5}
                          </div>
                        )}
                      </div>
                      <span className="text-[10px] text-gray-400">
                        {sharedWith.length === members.length ? "ทุกคน" : `${sharedWith.length} คน`}
                        {sharedWith.length > 0 && ` · ฿${(item.price / sharedWith.length).toFixed(2)}/คน`}
                      </span>
                    </div>
                  )}
                </div>
                <div className="flex gap-1 flex-shrink-0">
                  <button
                    onClick={() => openEdit(item)}
                    className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:text-gray-600 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                  >
                    <IoPencil size={14} />
                  </button>
                  <button
                    onClick={() => onDelete(item.id)}
                    className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                  >
                    <IoTrash size={14} />
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Total */}
      {items.length > 0 && (
        <div className="flex items-center justify-between px-4 py-3 bg-gray-100 dark:bg-gray-800 rounded-2xl">
          <span className="text-sm font-medium text-gray-600 dark:text-gray-400">รวมทั้งหมด</span>
          <span className="text-base font-bold text-gray-900 dark:text-white">฿{total.toFixed(2)}</span>
        </div>
      )}

      {/* Add button */}
      <button
        onClick={openAdd}
        className="flex items-center gap-2 px-4 py-3 rounded-2xl border-2 border-dashed border-gray-200 dark:border-gray-700 text-gray-500 dark:text-gray-400 hover:border-[#4366f4] hover:text-[#4366f4] transition-colors text-sm font-medium"
      >
        <IoAdd size={18} />
        เพิ่มรายการ
      </button>

      <ItemFormModal
        isOpen={showModal}
        onClose={() => { setShowModal(false); setEditItem(null); }}
        members={members}
        editItem={editItem}
        onSave={handleSave}
      />
    </div>
  );
}
