"use client";

import { useState } from "react";
import { IoAdd, IoCheckmark, IoTrash, IoPencil, IoClose } from "react-icons/io5";
import { Bill } from "@/lib/types";

interface BillsDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  bills: Bill[];
  activeBillId: string | null;
  onSwitch: (id: string) => void;
  onCreate: (title?: string) => void;
  onDelete: (id: string) => void;
  onRename: (id: string, title: string) => void;
}

export default function BillsDrawer({
  isOpen,
  onClose,
  bills,
  activeBillId,
  onSwitch,
  onCreate,
  onDelete,
  onRename,
}: BillsDrawerProps) {
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editTitle, setEditTitle] = useState("");

  const startEdit = (bill: Bill) => {
    setEditingId(bill.id);
    setEditTitle(bill.title);
  };

  const commitEdit = () => {
    if (editingId) {
      onRename(editingId, editTitle);
      setEditingId(null);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Drawer */}
      <div className="relative ml-auto w-72 h-full bg-white dark:bg-gray-900 shadow-2xl flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100 dark:border-gray-800">
          <h2 className="text-base font-bold text-gray-900 dark:text-white">
            บิลทั้งหมด
          </h2>
          <button
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 transition-colors"
          >
            <IoClose size={18} />
          </button>
        </div>

        {/* Bill list */}
        <div className="flex-1 overflow-y-auto p-3 flex flex-col gap-2">
          {bills.map((bill) => {
            const isActive = bill.id === activeBillId;
            const isEditing = editingId === bill.id;

            return (
              <div
                key={bill.id}
                className={`flex items-center gap-2 p-3 rounded-xl border transition-all ${
                  isActive
                    ? "border-[#4366f4] bg-blue-50 dark:bg-blue-900/20"
                    : "border-gray-100 dark:border-gray-800 bg-white dark:bg-gray-800 hover:border-gray-200"
                }`}
              >
                {/* Active indicator */}
                {isActive && (
                  <div className="w-5 h-5 rounded-full bg-[#4366f4] flex items-center justify-center flex-shrink-0">
                    <IoCheckmark size={12} className="text-white" />
                  </div>
                )}

                {/* Title / Edit */}
                <div
                  className="flex-1 min-w-0 cursor-pointer"
                  onClick={() => {
                    if (!isEditing) {
                      onSwitch(bill.id);
                      onClose();
                    }
                  }}
                >
                  {isEditing ? (
                    <input
                      autoFocus
                      value={editTitle}
                      onChange={(e) => setEditTitle(e.target.value)}
                      onBlur={commitEdit}
                      onKeyDown={(e) => {
                        if (e.key === "Enter") commitEdit();
                        if (e.key === "Escape") setEditingId(null);
                      }}
                      className="w-full text-sm font-medium bg-transparent outline-none border-b border-[#4366f4] text-gray-900 dark:text-white"
                      onClick={(e) => e.stopPropagation()}
                    />
                  ) : (
                    <>
                      <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                        {bill.title}
                      </p>
                      <p className="text-[10px] text-gray-400">
                        {(bill.members ?? []).length} คน · {(bill.items ?? []).length} รายการ ·{" "}
                        {new Date(bill.updated_at).toLocaleDateString("th-TH")}
                      </p>
                    </>
                  )}
                </div>

                {/* Actions */}
                <div className="flex items-center gap-1 flex-shrink-0">
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      startEdit(bill);
                    }}
                    className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-400 hover:text-gray-600 transition-colors"
                  >
                    <IoPencil size={12} />
                  </button>
                  {bills.length > 1 && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        onDelete(bill.id);
                      }}
                      className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-400 hover:text-red-500 transition-colors"
                    >
                      <IoTrash size={12} />
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        {/* New bill button */}
        <div className="p-4 border-t border-gray-100 dark:border-gray-800">
          <button
            onClick={() => {
              onCreate();
              onClose();
            }}
            className="w-full flex items-center justify-center gap-2 py-2.5 bg-[#4366f4] hover:bg-[#3355e0] text-white text-sm font-medium rounded-xl transition-all active:scale-95"
          >
            <IoAdd size={18} />
            สร้างบิลใหม่
          </button>
        </div>
      </div>
    </div>
  );
}
