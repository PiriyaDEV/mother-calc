"use client";

import { IoWarningOutline, IoTrash } from "react-icons/io5";

interface ConfirmModalProps {
  title: string;
  description?: string;
  confirmLabel?: string;
  cancelLabel?: string;
  danger?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export default function ConfirmModal({
  title,
  description,
  confirmLabel = "ยืนยัน",
  cancelLabel = "ยกเลิก",
  danger = false,
  onConfirm,
  onCancel,
}: ConfirmModalProps) {
  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm animate-fade-in"
        onClick={onCancel}
      />

      {/* Modal */}
      <div className="relative w-full max-w-sm bg-white dark:bg-gray-900 rounded-3xl shadow-2xl p-6 flex flex-col gap-5 animate-fade-in-up">
        {/* Icon */}
        <div
          className={`w-14 h-14 rounded-2xl flex items-center justify-center mx-auto ${
            danger
              ? "bg-red-50 dark:bg-red-900/20"
              : "bg-amber-50 dark:bg-amber-900/20"
          }`}
        >
          {danger ? (
            <IoTrash size={24} className="text-red-500" />
          ) : (
            <IoWarningOutline size={24} className="text-amber-500" />
          )}
        </div>

        {/* Text */}
        <div className="text-center">
          <h3 className="text-base font-bold text-gray-900 dark:text-white leading-snug">
            {title}
          </h3>
          {description && (
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-2 leading-relaxed">
              {description}
            </p>
          )}
        </div>

        {/* Buttons */}
        <div className="flex gap-3">
          <button
            onClick={onCancel}
            className="flex-1 py-3 border border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 text-sm font-semibold rounded-2xl hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors active:scale-95"
          >
            {cancelLabel}
          </button>
          <button
            onClick={onConfirm}
            className={`flex-1 py-3 text-white text-sm font-semibold rounded-2xl transition-all active:scale-95 ${
              danger
                ? "bg-red-500 hover:bg-red-600 shadow-sm shadow-red-200/60 dark:shadow-none"
                : "bg-[#4366f4] hover:bg-[#3355e0] shadow-sm shadow-blue-200/60 dark:shadow-none"
            }`}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
