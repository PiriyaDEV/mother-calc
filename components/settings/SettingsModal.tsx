"use client";

import { useState } from "react";
import {
  IoTrash,
  IoWarning,
  IoShareOutline,
  IoCopyOutline,
  IoCheckmark,
  IoLogOutOutline,
  IoPerson,
} from "react-icons/io5";
import { User } from "@supabase/supabase-js";
import { CurrencyCode, RoundingMode, Settings } from "@/lib/types";
import Modal from "@/components/ui/Modal";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Toggle from "@/components/ui/Toggle";

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  settings: Settings;
  tip: number;
  discount: number;
  onSave: (settings: Settings) => void;
  onTipDiscount: (tip: number, discount: number) => void;
  onReset: () => void;
  onSignOut?: () => Promise<void>;
  shareUrl?: string;
  user?: User | null;
}

const CURRENCIES: { code: CurrencyCode; label: string }[] = [
  { code: "THB", label: "฿ บาทไทย" },
  { code: "USD", label: "$ ดอลลาร์สหรัฐ" },
  { code: "EUR", label: "€ ยูโร" },
  { code: "JPY", label: "¥ เยนญี่ปุ่น" },
  { code: "SGD", label: "S$ ดอลลาร์สิงคโปร์" },
  { code: "GBP", label: "£ ปอนด์อังกฤษ" },
  { code: "CNY", label: "¥ หยวนจีน" },
  { code: "KRW", label: "₩ วอนเกาหลี" },
];

const ROUNDING_OPTIONS: { value: RoundingMode; label: string }[] = [
  { value: "none", label: "ไม่ปัดเศษ" },
  { value: "nearest", label: "ปัดใกล้สุด" },
  { value: "up", label: "ปัดขึ้น" },
  { value: "down", label: "ปัดลง" },
];

export default function SettingsModal({
  isOpen,
  onClose,
  settings,
  tip,
  discount,
  onSave,
  onTipDiscount,
  onReset,
  onSignOut,
  shareUrl,
  user,
}: SettingsModalProps) {
  const [form, setForm] = useState(settings);
  const [tipVal, setTipVal] = useState(String(tip));
  const [discountVal, setDiscountVal] = useState(String(discount));
  const [confirmReset, setConfirmReset] = useState(false);
  const [copied, setCopied] = useState(false);
  const [confirmSignOut, setConfirmSignOut] = useState(false);

  // Sync when modal opens
  const handleOpen = () => {
    setForm(settings);
    setTipVal(String(tip));
    setDiscountVal(String(discount));
    setConfirmReset(false);
    setConfirmSignOut(false);
  };

  const handleSave = () => {
    onSave(form);
    onTipDiscount(parseFloat(tipVal) || 0, parseFloat(discountVal) || 0);
    onClose();
  };

  const handleCopyLink = async () => {
    if (!shareUrl) return;
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // fallback
    }
  };

  const handleShare = async () => {
    if (!shareUrl) return;
    if (navigator.share) {
      await navigator.share({ title: "Kidtang — หารบิล", url: shareUrl });
    } else {
      handleCopyLink();
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="ตั้งค่า" size="md">
      <div className="flex flex-col gap-5" onFocus={handleOpen}>
        {/* User info */}
        {user && (
          <div className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-2xl">
            {user.user_metadata?.avatar_url ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={user.user_metadata.avatar_url}
                alt="avatar"
                className="w-9 h-9 rounded-full"
              />
            ) : (
              <div className="w-9 h-9 rounded-full bg-[#4366f4] flex items-center justify-center">
                <IoPerson size={16} className="text-white" />
              </div>
            )}
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                {user.user_metadata?.full_name || user.email}
              </p>
              <p className="text-xs text-gray-400 truncate">{user.email}</p>
            </div>
          </div>
        )}

        {/* Share */}
        {shareUrl && (
          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
              แชร์บิล
            </label>
            <div className="flex gap-2">
              <div className="flex-1 px-3 py-2 bg-gray-50 dark:bg-gray-800 rounded-xl text-xs text-gray-500 dark:text-gray-400 truncate border border-gray-100 dark:border-gray-700">
                {shareUrl}
              </div>
              <button
                onClick={handleCopyLink}
                className="w-9 h-9 flex items-center justify-center rounded-xl bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors flex-shrink-0"
              >
                {copied ? (
                  <IoCheckmark size={16} className="text-emerald-500" />
                ) : (
                  <IoCopyOutline size={16} />
                )}
              </button>
              <button
                onClick={handleShare}
                className="w-9 h-9 flex items-center justify-center rounded-xl bg-[#4366f4] text-white hover:bg-[#3355e0] transition-colors flex-shrink-0"
              >
                <IoShareOutline size={16} />
              </button>
            </div>
          </div>
        )}

        {/* Currency */}
        <div className="flex flex-col gap-1.5">
          <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
            สกุลเงิน
          </label>
          <div className="grid grid-cols-2 gap-2">
            {CURRENCIES.map((c) => (
              <button
                key={c.code}
                type="button"
                onClick={() => setForm((f) => ({ ...f, currency: c.code }))}
                className={`px-3 py-2 rounded-xl text-xs font-medium text-left transition-all ${
                  form.currency === c.code
                    ? "bg-[#4366f4] text-white"
                    : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400"
                }`}
              >
                {c.label}
              </button>
            ))}
          </div>
        </div>

        {/* VAT */}
        <div className="flex flex-col gap-2">
          <div className="flex items-center justify-between">
            <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
              VAT (%)
            </label>
            <Toggle
              checked={form.isVat}
              onChange={(v) => setForm((f) => ({ ...f, isVat: v }))}
              size="sm"
            />
          </div>
          {form.isVat && (
            <Input
              type="number"
              inputMode="decimal"
              value={String(form.vat)}
              onChange={(e) =>
                setForm((f) => ({ ...f, vat: parseFloat(e.target.value) || 0 }))
              }
              suffix="%"
            />
          )}
        </div>

        {/* Service Charge */}
        <div className="flex flex-col gap-2">
          <div className="flex items-center justify-between">
            <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
              Service Charge (%)
            </label>
            <Toggle
              checked={form.isService}
              onChange={(v) => setForm((f) => ({ ...f, isService: v }))}
              size="sm"
            />
          </div>
          {form.isService && (
            <Input
              type="number"
              inputMode="decimal"
              value={String(form.serviceCharge)}
              onChange={(e) =>
                setForm((f) => ({
                  ...f,
                  serviceCharge: parseFloat(e.target.value) || 0,
                }))
              }
              suffix="%"
            />
          )}
        </div>

        {/* Tip & Discount */}
        <div className="grid grid-cols-2 gap-3">
          <Input
            label="ทิป (บาท)"
            type="number"
            inputMode="decimal"
            placeholder="0"
            value={tipVal}
            onChange={(e) => setTipVal(e.target.value)}
            prefix="฿"
          />
          <Input
            label="ส่วนลด (บาท)"
            type="number"
            inputMode="decimal"
            placeholder="0"
            value={discountVal}
            onChange={(e) => setDiscountVal(e.target.value)}
            prefix="฿"
          />
        </div>

        {/* Rounding */}
        <div className="flex flex-col gap-1.5">
          <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
            การปัดเศษ
          </label>
          <div className="grid grid-cols-2 gap-2">
            {ROUNDING_OPTIONS.map((r) => (
              <button
                key={r.value}
                type="button"
                onClick={() => setForm((f) => ({ ...f, roundingMode: r.value }))}
                className={`px-3 py-2 rounded-xl text-xs font-medium transition-all ${
                  form.roundingMode === r.value
                    ? "bg-[#4366f4] text-white"
                    : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400"
                }`}
              >
                {r.label}
              </button>
            ))}
          </div>
        </div>

        {/* Save */}
        <Button fullWidth onClick={handleSave}>
          บันทึก
        </Button>

        {/* Reset */}
        <div className="border-t border-gray-100 dark:border-gray-800 pt-4 flex flex-col gap-3">
          {!confirmReset ? (
            <button
              onClick={() => setConfirmReset(true)}
              className="flex items-center gap-2 text-xs text-red-500 hover:text-red-600 transition-colors"
            >
              <IoTrash size={14} />
              ล้างข้อมูลบิลนี้ทั้งหมด
            </button>
          ) : (
            <div className="flex flex-col gap-2">
              <div className="flex items-center gap-2 text-xs text-red-500">
                <IoWarning size={14} />
                ยืนยันการล้างข้อมูล? ไม่สามารถกู้คืนได้
              </div>
              <div className="flex gap-2">
                <Button
                  variant="secondary"
                  size="sm"
                  fullWidth
                  onClick={() => setConfirmReset(false)}
                >
                  ยกเลิก
                </Button>
                <Button
                  variant="danger"
                  size="sm"
                  fullWidth
                  onClick={() => {
                    onReset();
                    onClose();
                  }}
                >
                  ล้างข้อมูล
                </Button>
              </div>
            </div>
          )}

          {/* Sign out */}
          {onSignOut && (
            <>
              {!confirmSignOut ? (
                <button
                  onClick={() => setConfirmSignOut(true)}
                  className="flex items-center gap-2 text-xs text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
                >
                  <IoLogOutOutline size={14} />
                  ออกจากระบบ
                </button>
              ) : (
                <div className="flex flex-col gap-2">
                  <p className="text-xs text-gray-500">ยืนยันออกจากระบบ?</p>
                  <div className="flex gap-2">
                    <Button
                      variant="secondary"
                      size="sm"
                      fullWidth
                      onClick={() => setConfirmSignOut(false)}
                    >
                      ยกเลิก
                    </Button>
                    <Button
                      variant="danger"
                      size="sm"
                      fullWidth
                      onClick={async () => {
                        await onSignOut();
                        onClose();
                      }}
                    >
                      ออกจากระบบ
                    </Button>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </Modal>
  );
}
