"use client";

import { useState, useRef, useEffect } from "react";
import { IoClose, IoAdd, IoCheckmark, IoTrash } from "react-icons/io5";
import { EMOJI_PRESETS, DEFAULT_TAGS } from "@/lib/constants";
import Toggle from "@/components/ui/Toggle";
import { CurrencyCode, RoundingMode, Settings } from "@/lib/types";

// ── Types ──────────────────────────────────────────────────────

export interface EntityFormData {
  name: string;
  emoji: string | null;
  description: string;
  tags: string[];
  // bill-only
  settings?: Settings;
}

export interface EntityInitialData {
  name?: string;
  emoji?: string | null;
  description?: string;
  tags?: string[];
  settings?: Settings;
}

interface CreateEntityModalProps {
  type: "bill" | "group";
  mode?: "create" | "edit";
  initialData?: EntityInitialData;
  onClose: () => void;
  onSave: (data: EntityFormData) => Promise<void>;
  /** If provided, shows a delete button at the bottom (edit mode only) */
  onDelete?: () => void;
}

// ── Constants ──────────────────────────────────────────────────

const CURRENCIES: { code: CurrencyCode; label: string }[] = [
  { code: "THB", label: "฿ THB" },
  { code: "USD", label: "$ USD" },
  { code: "EUR", label: "€ EUR" },
  { code: "JPY", label: "¥ JPY" },
  { code: "SGD", label: "S$ SGD" },
  { code: "GBP", label: "£ GBP" },
  { code: "CNY", label: "¥ CNY" },
  { code: "KRW", label: "₩ KRW" },
];

const ROUNDING_OPTIONS: { value: RoundingMode; label: string }[] = [
  { value: "none", label: "ไม่ปัด" },
  { value: "nearest", label: "ใกล้สุด" },
  { value: "up", label: "ขึ้น" },
  { value: "down", label: "ลง" },
];

const DEFAULT_BILL_SETTINGS: Settings = {
  vat: 7,
  serviceCharge: 10,
  isVat: false,
  isService: false,
  roundingMode: "none",
  currency: "THB",
};

// ── Component ──────────────────────────────────────────────────

export default function CreateEntityModal({
  type,
  mode = "create",
  initialData,
  onClose,
  onSave,
  onDelete,
}: CreateEntityModalProps) {
  const [name, setName] = useState(initialData?.name ?? "");
  const [emoji, setEmoji] = useState<string | null>(initialData?.emoji ?? "💰");
  const [description, setDescription] = useState(initialData?.description ?? "");
  const [selectedTags, setSelectedTags] = useState<string[]>(initialData?.tags ?? []);
  const [customTag, setCustomTag] = useState("");
  const [customTags, setCustomTags] = useState<string[]>(
    (initialData?.tags ?? []).filter((t) => !(DEFAULT_TAGS as readonly string[]).includes(t))
  );
  const [settings, setSettings] = useState<Settings>(
    initialData?.settings ?? DEFAULT_BILL_SETTINGS
  );
  const [loading, setLoading] = useState(false);
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);
  const nameRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    setTimeout(() => nameRef.current?.focus(), 100);
  }, []);

  const allTags = [...DEFAULT_TAGS, ...customTags];

  const toggleTag = (tag: string) => {
    setSelectedTags((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]
    );
  };

  const addCustomTag = () => {
    const t = customTag.trim();
    if (!t || allTags.includes(t)) return;
    setCustomTags((prev) => [...prev, t]);
    setSelectedTags((prev) => [...prev, t]);
    setCustomTag("");
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    setLoading(true);
    try {
      await onSave({
        name: name.trim(),
        emoji,
        description: description.trim(),
        tags: selectedTags,
        ...(type === "bill" ? { settings } : {}),
      });
      onClose();
    } finally {
      setLoading(false);
    }
  };

  const label = type === "bill" ? "บิล" : "กลุ่ม";
  const isEdit = mode === "edit";

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4 bg-black/40 backdrop-blur-sm"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
    >
      <div className="w-full max-w-sm bg-white dark:bg-gray-900 rounded-3xl border border-gray-100 dark:border-gray-800 shadow-xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-6 pt-6 pb-4">
          <h2 className="text-base font-bold text-gray-900 dark:text-white">
            {isEdit ? `แก้ไข${label}` : `สร้าง${label}ใหม่`}
          </h2>
          <button
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
          >
            <IoClose size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="px-6 pb-6 flex flex-col gap-4 max-h-[80vh] overflow-y-auto">

          {/* ── Emoji + Name ── */}
          <div className="flex gap-3 items-start">
            {/* Emoji button */}
            <div className="relative flex-shrink-0">
              <button
                type="button"
                onClick={() => setShowEmojiPicker((v) => !v)}
                className="w-14 h-14 rounded-2xl bg-gray-50 dark:bg-gray-800 border-2 border-dashed border-gray-200 dark:border-gray-700 hover:border-[#4366f4] transition-colors flex items-center justify-center text-2xl"
              >
                {emoji ?? <span className="text-gray-300 text-xl">💰</span>}
              </button>

              {showEmojiPicker && (
                <div className="absolute top-16 left-0 z-10 bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 rounded-2xl shadow-xl p-3 w-64">
                  <div className="grid grid-cols-8 gap-1 max-h-48 overflow-y-auto">
                    <button
                      type="button"
                      onClick={() => { setEmoji(null); setShowEmojiPicker(false); }}
                      className="w-7 h-7 flex items-center justify-center rounded-lg text-xs text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors border border-dashed border-gray-200 dark:border-gray-700"
                      title="ไม่มี emoji"
                    >
                      ✕
                    </button>
                    {EMOJI_PRESETS.map((e) => (
                      <button
                        key={e}
                        type="button"
                        onClick={() => { setEmoji(e); setShowEmojiPicker(false); }}
                        className={`w-7 h-7 flex items-center justify-center rounded-lg text-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors ${emoji === e ? "bg-blue-50 dark:bg-blue-900/20 ring-2 ring-[#4366f4]" : ""}`}
                      >
                        {e}
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Name */}
            <div className="flex-1 flex flex-col gap-1">
              <label className="text-xs font-medium text-gray-500 dark:text-gray-400">
                ชื่อ{label} *
              </label>
              <input
                ref={nameRef}
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder={type === "bill" ? "เช่น ข้าวเย็น, ทริปเชียงใหม่" : "เช่น Family, เพื่อนสนิท"}
                required
                maxLength={60}
                className="w-full px-4 py-3 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-2xl text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#4366f4]/30 focus:border-[#4366f4] transition-all"
              />
            </div>
          </div>

          {/* ── Description ── */}
          <div className="flex flex-col gap-1">
            <label className="text-xs font-medium text-gray-500 dark:text-gray-400">
              คำอธิบาย (ไม่บังคับ)
            </label>
            <input
              type="text"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder={type === "bill" ? "เช่น ร้านอาหารกับเพื่อน 4 คน" : "เช่น กลุ่มครอบครัว"}
              maxLength={120}
              className="w-full px-4 py-3 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-2xl text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#4366f4]/30 focus:border-[#4366f4] transition-all"
            />
          </div>

          {/* ── Tags ── */}
          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-gray-500 dark:text-gray-400">แท็ก</label>
            <div className="flex flex-wrap gap-1.5">
              {allTags.map((tag) => (
                <button
                  key={tag}
                  type="button"
                  onClick={() => toggleTag(tag)}
                  className={`px-3 py-1.5 rounded-full text-xs font-medium transition-all ${
                    selectedTags.includes(tag)
                      ? "bg-[#4366f4] text-white shadow-sm"
                      : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700"
                  }`}
                >
                  {selectedTags.includes(tag) && <IoCheckmark size={10} className="inline mr-1" />}
                  {tag}
                </button>
              ))}
            </div>
            <div className="flex gap-2">
              <input
                type="text"
                value={customTag}
                onChange={(e) => setCustomTag(e.target.value)}
                onKeyDown={(e) => { if (e.key === "Enter") { e.preventDefault(); addCustomTag(); } }}
                placeholder="เพิ่มแท็กเอง..."
                maxLength={20}
                className="flex-1 px-3 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-xl text-xs text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#4366f4]/30 focus:border-[#4366f4] transition-all"
              />
              <button
                type="button"
                onClick={addCustomTag}
                disabled={!customTag.trim() || allTags.includes(customTag.trim())}
                className="w-9 h-9 flex items-center justify-center rounded-xl bg-gray-100 dark:bg-gray-800 text-gray-500 hover:bg-[#4366f4] hover:text-white disabled:opacity-40 transition-colors"
              >
                <IoAdd size={16} />
              </button>
            </div>
          </div>

          {/* ── Bill Settings (bill only) ── */}
          {type === "bill" && (
            <div className="flex flex-col gap-3 pt-1">
              <div className="h-px bg-gray-100 dark:bg-gray-800" />
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">ตั้งค่าบิล</p>

              {/* VAT + Service */}
              <div className="grid grid-cols-2 gap-2">
                {/* VAT */}
                <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-3 flex flex-col gap-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-gray-700 dark:text-gray-300">VAT</span>
                    <Toggle
                      checked={settings.isVat}
                      onChange={(v) => setSettings((s) => ({ ...s, isVat: v, vat: v ? 7 : s.vat }))}
                      size="sm"
                    />
                  </div>
                  {settings.isVat ? (
                    <div className="flex items-center gap-1">
                      <input
                        type="number"
                        inputMode="decimal"
                        value={settings.vat}
                        onChange={(e) => setSettings((s) => ({ ...s, vat: parseFloat(e.target.value) || 0 }))}
                        className="w-full px-2 py-1.5 bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-xl text-xs text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#4366f4]/30"
                      />
                      <span className="text-xs text-gray-400 flex-shrink-0">%</span>
                    </div>
                  ) : (
                    <p className="text-[11px] text-gray-400">ปิดอยู่</p>
                  )}
                </div>

                {/* Service Charge */}
                <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-3 flex flex-col gap-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium text-gray-700 dark:text-gray-300">Service</span>
                    <Toggle
                      checked={settings.isService}
                      onChange={(v) => setSettings((s) => ({ ...s, isService: v, serviceCharge: v ? 10 : s.serviceCharge }))}
                      size="sm"
                    />
                  </div>
                  {settings.isService ? (
                    <div className="flex items-center gap-1">
                      <input
                        type="number"
                        inputMode="decimal"
                        value={settings.serviceCharge}
                        onChange={(e) => setSettings((s) => ({ ...s, serviceCharge: parseFloat(e.target.value) || 0 }))}
                        className="w-full px-2 py-1.5 bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-xl text-xs text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#4366f4]/30"
                      />
                      <span className="text-xs text-gray-400 flex-shrink-0">%</span>
                    </div>
                  ) : (
                    <p className="text-[11px] text-gray-400">ปิดอยู่</p>
                  )}
                </div>
              </div>

              {/* Currency */}
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-medium text-gray-500 dark:text-gray-400">สกุลเงิน</label>
                <div className="grid grid-cols-4 gap-1.5">
                  {CURRENCIES.map((c) => (
                    <button
                      key={c.code}
                      type="button"
                      onClick={() => setSettings((s) => ({ ...s, currency: c.code }))}
                      className={`px-1.5 py-2 rounded-xl text-[11px] font-medium text-center transition-all ${
                        settings.currency === c.code
                          ? "bg-[#4366f4] text-white shadow-sm"
                          : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700"
                      }`}
                    >
                      {c.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Rounding */}
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-medium text-gray-500 dark:text-gray-400">การปัดเศษ</label>
                <div className="grid grid-cols-4 gap-1.5">
                  {ROUNDING_OPTIONS.map((r) => (
                    <button
                      key={r.value}
                      type="button"
                      onClick={() => setSettings((s) => ({ ...s, roundingMode: r.value }))}
                      className={`px-1.5 py-2 rounded-xl text-[11px] font-medium text-center transition-all ${
                        settings.roundingMode === r.value
                          ? "bg-[#4366f4] text-white shadow-sm"
                          : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700"
                      }`}
                    >
                      {r.label}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ── Submit ── */}
          <button
            type="submit"
            disabled={loading || !name.trim()}
            className="w-full py-3.5 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-50 text-white text-sm font-semibold rounded-2xl transition-colors mt-1"
          >
            {loading
              ? (isEdit ? "กำลังบันทึก..." : "กำลังสร้าง...")
              : (isEdit ? `บันทึก${label}` : `สร้าง${label}`)}
          </button>

          {/* ── Delete (edit mode only) ── */}
          {isEdit && onDelete && (
            <button
              type="button"
              onClick={onDelete}
              className="w-full py-3 flex items-center justify-center gap-2 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/10 text-sm font-medium rounded-2xl transition-colors border border-red-100 dark:border-red-900/30"
            >
              <IoTrash size={14} />
              ลบ{label}นี้
            </button>
          )}
        </form>
      </div>
    </div>
  );
}
