"use client";

import { useState, useEffect } from "react";
import {
  IoTrash,
  IoWarning,
  IoShareOutline,
  IoCopyOutline,
  IoCheckmark,
  IoLogOutOutline,
  IoPerson,
  IoLockClosedOutline,
  IoEyeOutline,
  IoEyeOffOutline,
  IoChevronForward,
  IoArrowBack,
} from "react-icons/io5";
import { User } from "@supabase/supabase-js";
import { CurrencyCode, RoundingMode, Settings } from "@/lib/types";
import Modal from "@/components/ui/Modal";
import Button from "@/components/ui/Button";
import Input from "@/components/ui/Input";
import Toggle from "@/components/ui/Toggle";
import { useAuth } from "@/hooks/useAuth";

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  settings: Settings;
  tip: number;
  discount: number;
  /** Called with (settings, tip, discount) when user saves */
  onSave: (settings: Settings, tip: number, discount: number) => void | Promise<void>;
  onReset?: () => void;
  onSignOut?: () => Promise<void>;
  shareUrl?: string;
  user?: User | null;
}

const CURRENCIES: { code: CurrencyCode; flag: string; symbol: string; label: string }[] = [
  { code: "THB", flag: "🇹🇭", symbol: "฿",  label: "บาทไทย" },
  { code: "USD", flag: "🇺🇸", symbol: "$",  label: "ดอลลาร์" },
  { code: "EUR", flag: "🇪🇺", symbol: "€",  label: "ยูโร" },
  { code: "JPY", flag: "🇯🇵", symbol: "¥",  label: "เยน" },
  { code: "SGD", flag: "🇸🇬", symbol: "S$", label: "สิงคโปร์" },
  { code: "GBP", flag: "🇬🇧", symbol: "£",  label: "ปอนด์" },
  { code: "CNY", flag: "🇨🇳", symbol: "¥",  label: "หยวน" },
  { code: "KRW", flag: "🇰🇷", symbol: "₩",  label: "วอน" },
];

const ROUNDING_OPTIONS: { value: RoundingMode; label: string }[] = [
  { value: "none", label: "ไม่ปัดเศษ" },
  { value: "nearest", label: "ปัดใกล้สุด" },
  { value: "up", label: "ปัดขึ้น" },
  { value: "down", label: "ปัดลง" },
];

type SubPage = "main" | "profile" | "password";

export default function SettingsModal({
  isOpen,
  onClose,
  settings,
  tip,
  discount,
  onSave,
  onReset,
  onSignOut,
  shareUrl,
  user,
}: SettingsModalProps) {
  const { updateDisplayName, updatePassword } = useAuth();

  const [form, setForm] = useState(settings);
  const [tipVal, setTipVal] = useState(String(tip));
  const [discountVal, setDiscountVal] = useState(String(discount));
  const [confirmReset, setConfirmReset] = useState(false);
  const [copied, setCopied] = useState(false);
  const [confirmSignOut, setConfirmSignOut] = useState(false);
  const [subPage, setSubPage] = useState<SubPage>("main");

  // Profile edit
  const [displayName, setDisplayName] = useState("");
  const [profileSaving, setProfileSaving] = useState(false);
  const [profileMsg, setProfileMsg] = useState<{ type: "ok" | "err"; text: string } | null>(null);

  // Password edit
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showNewPass, setShowNewPass] = useState(false);
  const [showConfirmPass, setShowConfirmPass] = useState(false);
  const [passwordSaving, setPasswordSaving] = useState(false);
  const [passwordMsg, setPasswordMsg] = useState<{ type: "ok" | "err"; text: string } | null>(null);

  // Sync form values when modal opens
  useEffect(() => {
    if (isOpen) {
      setForm(settings);
      setTipVal(String(tip));
      setDiscountVal(String(discount));
      setConfirmReset(false);
      setConfirmSignOut(false);
      setSubPage("main");
      setProfileMsg(null);
      setPasswordMsg(null);
      setNewPassword("");
      setConfirmPassword("");
      setDisplayName(user?.user_metadata?.full_name || "");
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isOpen]);

  const handleSave = () => {
    onSave(form, parseFloat(tipVal) || 0, parseFloat(discountVal) || 0);
    onClose();
  };

  const handleCopyLink = async () => {
    if (!shareUrl) return;
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch { /* fallback */ }
  };

  const handleShare = async () => {
    if (!shareUrl) return;
    if (navigator.share) {
      await navigator.share({ title: "Kidtang — หารบิล", url: shareUrl });
    } else {
      handleCopyLink();
    }
  };

  const handleSaveProfile = async () => {
    if (!displayName.trim()) return;
    setProfileSaving(true);
    setProfileMsg(null);
    const err = await updateDisplayName(displayName);
    setProfileSaving(false);
    if (err) {
      setProfileMsg({ type: "err", text: err });
    } else {
      setProfileMsg({ type: "ok", text: "บันทึกชื่อเรียบร้อยแล้ว" });
    }
  };

  const handleSavePassword = async () => {
    if (newPassword.length < 6) {
      setPasswordMsg({ type: "err", text: "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร" });
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordMsg({ type: "err", text: "รหัสผ่านไม่ตรงกัน" });
      return;
    }
    setPasswordSaving(true);
    setPasswordMsg(null);
    const err = await updatePassword(newPassword);
    setPasswordSaving(false);
    if (err) {
      setPasswordMsg({ type: "err", text: err });
    } else {
      setPasswordMsg({ type: "ok", text: "เปลี่ยนรหัสผ่านเรียบร้อยแล้ว" });
      setNewPassword("");
      setConfirmPassword("");
    }
  };

  // ── Sub-page: Profile ──────────────────────────────────────
  if (subPage === "profile") {
    return (
      <Modal isOpen={isOpen} onClose={onClose} size="md">
        <div className="flex flex-col gap-5">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setSubPage("main")}
              className="w-8 h-8 flex items-center justify-center rounded-xl hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 transition-colors"
            >
              <IoArrowBack size={16} />
            </button>
            <h2 className="text-base font-semibold text-gray-900 dark:text-white">แก้ไขโปรไฟล์</h2>
          </div>

          {/* Avatar */}
          <div className="flex flex-col items-center gap-3 py-2">
            {user?.user_metadata?.avatar_url ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={user.user_metadata.avatar_url} alt="avatar" className="w-16 h-16 rounded-full" />
            ) : (
              <div className="w-16 h-16 rounded-full bg-[#4366f4] flex items-center justify-center">
                <IoPerson size={28} className="text-white" />
              </div>
            )}
            <p className="text-xs text-gray-400">{user?.email}</p>
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-medium text-gray-600 dark:text-gray-400">ชื่อที่แสดง</label>
            <input
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              placeholder="ชื่อของคุณ"
              className="w-full px-4 py-3 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-2xl text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#4366f4]/30 focus:border-[#4366f4] transition-all"
            />
          </div>

          {profileMsg && (
            <div className={`px-4 py-3 rounded-2xl text-xs ${
              profileMsg.type === "ok"
                ? "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-800"
                : "bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 border border-red-100 dark:border-red-800"
            }`}>
              {profileMsg.text}
            </div>
          )}

          <Button fullWidth onClick={handleSaveProfile} disabled={profileSaving || !displayName.trim()}>
            {profileSaving ? "กำลังบันทึก..." : "บันทึก"}
          </Button>
        </div>
      </Modal>
    );
  }

  // ── Sub-page: Password ─────────────────────────────────────
  if (subPage === "password") {
    return (
      <Modal isOpen={isOpen} onClose={onClose} size="md">
        <div className="flex flex-col gap-5">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setSubPage("main")}
              className="w-8 h-8 flex items-center justify-center rounded-xl hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 transition-colors"
            >
              <IoArrowBack size={16} />
            </button>
            <h2 className="text-base font-semibold text-gray-900 dark:text-white">เปลี่ยนรหัสผ่าน</h2>
          </div>

          <div className="flex flex-col gap-3">
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-medium text-gray-600 dark:text-gray-400">รหัสผ่านใหม่</label>
              <div className="relative">
                <input
                  type={showNewPass ? "text" : "password"}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="อย่างน้อย 6 ตัวอักษร"
                  minLength={6}
                  className="w-full px-4 py-3 pr-11 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-2xl text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#4366f4]/30 focus:border-[#4366f4] transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowNewPass((v) => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  {showNewPass ? <IoEyeOffOutline size={18} /> : <IoEyeOutline size={18} />}
                </button>
              </div>
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-medium text-gray-600 dark:text-gray-400">ยืนยันรหัสผ่านใหม่</label>
              <div className="relative">
                <input
                  type={showConfirmPass ? "text" : "password"}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="กรอกรหัสผ่านอีกครั้ง"
                  className={`w-full px-4 py-3 pr-11 bg-gray-50 dark:bg-gray-800 border rounded-2xl text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#4366f4]/30 focus:border-[#4366f4] transition-all ${
                    confirmPassword && confirmPassword !== newPassword
                      ? "border-red-300 dark:border-red-700"
                      : "border-gray-100 dark:border-gray-700"
                  }`}
                />
                <button
                  type="button"
                  onClick={() => setShowConfirmPass((v) => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  {showConfirmPass ? <IoEyeOffOutline size={18} /> : <IoEyeOutline size={18} />}
                </button>
              </div>
              {confirmPassword && confirmPassword !== newPassword && (
                <p className="text-[11px] text-red-500">รหัสผ่านไม่ตรงกัน</p>
              )}
            </div>
          </div>

          {passwordMsg && (
            <div className={`px-4 py-3 rounded-2xl text-xs ${
              passwordMsg.type === "ok"
                ? "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-800"
                : "bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 border border-red-100 dark:border-red-800"
            }`}>
              {passwordMsg.text}
            </div>
          )}

          <Button
            fullWidth
            onClick={handleSavePassword}
            disabled={passwordSaving || !newPassword || !confirmPassword}
          >
            {passwordSaving ? "กำลังบันทึก..." : "เปลี่ยนรหัสผ่าน"}
          </Button>
        </div>
      </Modal>
    );
  }

  // ── Main Settings Page ─────────────────────────────────────
  return (
    <Modal isOpen={isOpen} onClose={onClose} title="ตั้งค่า" size="md">
      <div className="flex flex-col gap-6">

        {/* ── Account Section ── */}
        {user && (
          <div className="flex flex-col gap-2">
            <p className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider px-1">บัญชี</p>
            <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl overflow-hidden divide-y divide-gray-100 dark:divide-gray-700/50">
              {/* User info row */}
              <div className="flex items-center gap-3 px-4 py-3">
                {user.user_metadata?.avatar_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={user.user_metadata.avatar_url} alt="avatar" className="w-9 h-9 rounded-full flex-shrink-0" />
                ) : (
                  <div className="w-9 h-9 rounded-full bg-[#4366f4] flex items-center justify-center flex-shrink-0">
                    <IoPerson size={16} className="text-white" />
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">
                    {user.user_metadata?.full_name || "ผู้ใช้งาน"}
                  </p>
                  <p className="text-xs text-gray-400 truncate">{user.email}</p>
                </div>
              </div>

              {/* Edit profile */}
              <button
                onClick={() => setSubPage("profile")}
                className="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-100 dark:hover:bg-gray-700/50 transition-colors text-left"
              >
                <div className="w-7 h-7 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                  <IoPerson size={14} className="text-[#4366f4]" />
                </div>
                <span className="flex-1 text-sm text-gray-700 dark:text-gray-300">แก้ไขชื่อ</span>
                <IoChevronForward size={14} className="text-gray-400" />
              </button>

              {/* Change password */}
              <button
                onClick={() => setSubPage("password")}
                className="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-100 dark:hover:bg-gray-700/50 transition-colors text-left"
              >
                <div className="w-7 h-7 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center flex-shrink-0">
                  <IoLockClosedOutline size={14} className="text-purple-500" />
                </div>
                <span className="flex-1 text-sm text-gray-700 dark:text-gray-300">เปลี่ยนรหัสผ่าน</span>
                <IoChevronForward size={14} className="text-gray-400" />
              </button>
            </div>
          </div>
        )}

        {/* ── Share Section ── */}
        {shareUrl && (
          <div className="flex flex-col gap-2">
            <p className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider px-1">แชร์บิล</p>
            <div className="flex gap-2">
              <div className="flex-1 px-3 py-2.5 bg-gray-50 dark:bg-gray-800 rounded-xl text-xs text-gray-500 dark:text-gray-400 truncate border border-gray-100 dark:border-gray-700">
                {shareUrl}
              </div>
              <button
                onClick={handleCopyLink}
                className="w-9 h-9 flex items-center justify-center rounded-xl bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors flex-shrink-0"
              >
                {copied ? <IoCheckmark size={16} className="text-emerald-500" /> : <IoCopyOutline size={16} />}
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

        {/* ── Bill Settings ── */}
        <div className="flex flex-col gap-2">
          <p className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider px-1">ตั้งค่าบิล</p>
          <div className="flex flex-col gap-4">

            {/* Currency */}
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-medium text-gray-600 dark:text-gray-400 px-1">สกุลเงิน</label>
              <div className="grid grid-cols-2 gap-1.5">
                {CURRENCIES.map((c) => (
                  <button
                    key={c.code}
                    type="button"
                    onClick={() => setForm((f) => ({ ...f, currency: c.code }))}
                    className={`flex items-center gap-2 px-3 py-2.5 rounded-xl text-xs font-medium text-left transition-all ${
                      form.currency === c.code
                        ? "bg-[#4366f4] text-white shadow-sm ring-2 ring-[#4366f4]/30"
                        : "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-700"
                    }`}
                  >
                    <span className="text-base leading-none">{c.flag}</span>
                    <span className={`font-bold ${form.currency === c.code ? "text-white" : "text-gray-800 dark:text-gray-200"}`}>{c.symbol}</span>
                    <span className="truncate">{c.label}</span>
                    {form.currency === c.code && (
                      <IoCheckmark size={12} className="ml-auto flex-shrink-0" />
                    )}
                  </button>
                ))}
              </div>
            </div>

            {/* VAT + Service in a row */}
            <div className="grid grid-cols-2 gap-3">
              <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-3 flex flex-col gap-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-medium text-gray-700 dark:text-gray-300">VAT</span>
                  <Toggle checked={form.isVat} onChange={(v) => setForm((f) => ({ ...f, isVat: v }))} size="sm" />
                </div>
                {form.isVat && (
                  <Input
                    type="number"
                    inputMode="decimal"
                    value={String(form.vat)}
                    onChange={(e) => setForm((f) => ({ ...f, vat: parseFloat(e.target.value) || 0 }))}
                    suffix="%"
                  />
                )}
                {!form.isVat && <p className="text-[11px] text-gray-400">ปิดอยู่</p>}
              </div>

              <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-3 flex flex-col gap-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-medium text-gray-700 dark:text-gray-300">Service</span>
                  <Toggle checked={form.isService} onChange={(v) => setForm((f) => ({ ...f, isService: v }))} size="sm" />
                </div>
                {form.isService && (
                  <Input
                    type="number"
                    inputMode="decimal"
                    value={String(form.serviceCharge)}
                    onChange={(e) => setForm((f) => ({ ...f, serviceCharge: parseFloat(e.target.value) || 0 }))}
                    suffix="%"
                  />
                )}
                {!form.isService && <p className="text-[11px] text-gray-400">ปิดอยู่</p>}
              </div>
            </div>

            {/* Tip & Discount */}
            <div className="grid grid-cols-2 gap-3">
              <Input label="ทิป" type="number" inputMode="decimal" placeholder="0" value={tipVal} onChange={(e) => setTipVal(e.target.value)} prefix="฿" />
              <Input label="ส่วนลด" type="number" inputMode="decimal" placeholder="0" value={discountVal} onChange={(e) => setDiscountVal(e.target.value)} prefix="฿" />
            </div>

            {/* Rounding */}
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-medium text-gray-600 dark:text-gray-400 px-1">การปัดเศษ</label>
              <div className="grid grid-cols-4 gap-1.5">
                {ROUNDING_OPTIONS.map((r) => (
                  <button
                    key={r.value}
                    type="button"
                    onClick={() => setForm((f) => ({ ...f, roundingMode: r.value }))}
                    className={`px-2 py-2 rounded-xl text-xs font-medium text-center transition-all ${
                      form.roundingMode === r.value
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
        </div>

        {/* Save button */}
        <Button fullWidth onClick={handleSave}>
          บันทึกการตั้งค่า
        </Button>

        {/* ── Danger Zone ── */}
        <div className="flex flex-col gap-2">
          <p className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider px-1">อื่นๆ</p>
          <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl overflow-hidden divide-y divide-gray-100 dark:divide-gray-700/50">

            {/* Reset bill */}
            {!confirmReset ? (
              <button
                onClick={() => setConfirmReset(true)}
                className="w-full flex items-center gap-3 px-4 py-3 hover:bg-red-50 dark:hover:bg-red-900/10 transition-colors text-left"
              >
                <div className="w-7 h-7 rounded-lg bg-red-100 dark:bg-red-900/30 flex items-center justify-center flex-shrink-0">
                  <IoTrash size={14} className="text-red-500" />
                </div>
                <span className="text-sm text-red-500">ล้างข้อมูลบิลนี้</span>
              </button>
            ) : (
              <div className="px-4 py-3 flex flex-col gap-2">
                <div className="flex items-center gap-2 text-xs text-red-500">
                  <IoWarning size={14} />
                  ยืนยันการล้างข้อมูล? ไม่สามารถกู้คืนได้
                </div>
                <div className="flex gap-2">
                  <Button variant="secondary" size="sm" fullWidth onClick={() => setConfirmReset(false)}>ยกเลิก</Button>
                  <Button variant="danger" size="sm" fullWidth onClick={() => { onReset?.(); onClose(); }}>ล้างข้อมูล</Button>
                </div>
              </div>
            )}

            {/* Sign out */}
            {onSignOut && !confirmSignOut && (
              <button
                onClick={() => setConfirmSignOut(true)}
                className="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-100 dark:hover:bg-gray-700/50 transition-colors text-left"
              >
                <div className="w-7 h-7 rounded-lg bg-gray-200 dark:bg-gray-700 flex items-center justify-center flex-shrink-0">
                  <IoLogOutOutline size={14} className="text-gray-500" />
                </div>
                <span className="text-sm text-gray-600 dark:text-gray-400">ออกจากระบบ</span>
              </button>
            )}

            {onSignOut && confirmSignOut && (
              <div className="px-4 py-3 flex flex-col gap-2">
                <p className="text-xs text-gray-500">ยืนยันออกจากระบบ?</p>
                <div className="flex gap-2">
                  <Button variant="secondary" size="sm" fullWidth onClick={() => setConfirmSignOut(false)}>ยกเลิก</Button>
                  <Button variant="danger" size="sm" fullWidth onClick={async () => { await onSignOut(); onClose(); }}>ออกจากระบบ</Button>
                </div>
              </div>
            )}
          </div>
        </div>

      </div>
    </Modal>
  );
}
