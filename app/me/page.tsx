"use client";

import { useEffect, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import { getMyProfile, upsertProfile, isUsernameTaken, ensureMyProfile } from "@/lib/db";
import { Profile } from "@/lib/types";
import { isValidUsername } from "@/lib/utils";
import { useTheme } from "@/hooks/useTheme";
import {
  IoPersonOutline,
  IoLogOutOutline,
  IoPencil,
  IoCheckmark,
  IoClose,
  IoCamera,
  IoMoonOutline,
  IoSunnyOutline,
} from "react-icons/io5";
import BottomNav from "@/components/ui/BottomNav";

export default function MePage() {
  const router = useRouter();
  const { user, loading, signOut, updateDisplayName, updatePassword } = useAuth();
  const { theme, toggle: toggleTheme } = useTheme();

  const [profile, setProfile] = useState<Profile | null>(null);
  const [dataLoading, setDataLoading] = useState(true);

  const [editingName, setEditingName] = useState(false);
  const [editingUsername, setEditingUsername] = useState(false);
  const [editingPassword, setEditingPassword] = useState(false);
  const [editingPromptpay, setEditingPromptpay] = useState(false);

  const [nameVal, setNameVal] = useState("");
  const [usernameVal, setUsernameVal] = useState("");
  const [promptpayVal, setPromptpayVal] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const [saving, setSaving] = useState(false);
  const [uploadingAvatar, setUploadingAvatar] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const avatarInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => { if (!loading && !user) router.push("/login"); }, [loading, user, router]);

  useEffect(() => {
    if (!user) return;
    ensureMyProfile().then(() => getMyProfile()).then((p) => {
      setProfile(p);
      setNameVal(p?.display_name ?? "");
      setUsernameVal(p?.username ?? "");
      setPromptpayVal(p?.promptpay ?? "");
      setDataLoading(false);
    });
  }, [user]);

  const showSuccess = (msg: string) => { setSuccess(msg); setTimeout(() => setSuccess(null), 3000); };

  const handleSaveName = async () => {
    if (!profile || !nameVal.trim()) return;
    setSaving(true); setError(null);
    try {
      await upsertProfile({ id: profile.id, display_name: nameVal.trim() });
      await updateDisplayName(nameVal.trim());
      setProfile((p) => p ? { ...p, display_name: nameVal.trim() } : p);
      setEditingName(false); showSuccess("อัปเดตชื่อแล้ว");
    } catch { setError("เกิดข้อผิดพลาด กรุณาลองใหม่"); }
    finally { setSaving(false); }
  };

  const handleSaveUsername = async () => {
    if (!profile || !usernameVal.trim()) return;
    if (!isValidUsername(usernameVal)) { setError("username ต้องเป็นตัวอักษรภาษาอังกฤษ ตัวเลข หรือ _ (3-30 ตัว)"); return; }
    setSaving(true); setError(null);
    try {
      if (usernameVal !== profile.username) {
        const taken = await isUsernameTaken(usernameVal);
        if (taken) { setError("username นี้ถูกใช้งานแล้ว"); return; }
      }
      await upsertProfile({ id: profile.id, username: usernameVal });
      setProfile((p) => p ? { ...p, username: usernameVal } : p);
      setEditingUsername(false); showSuccess("อัปเดต username แล้ว");
    } catch { setError("เกิดข้อผิดพลาด กรุณาลองใหม่"); }
    finally { setSaving(false); }
  };

  const handleSavePassword = async () => {
    if (newPassword.length < 6) { setError("รหัสผ่านต้องมีอย่างน้อย 6 ตัว"); return; }
    if (newPassword !== confirmPassword) { setError("รหัสผ่านไม่ตรงกัน"); return; }
    setSaving(true); setError(null);
    try {
      const err = await updatePassword(newPassword);
      if (err) { setError(err); return; }
      setEditingPassword(false); setNewPassword(""); setConfirmPassword(""); showSuccess("เปลี่ยนรหัสผ่านแล้ว");
    } finally { setSaving(false); }
  };

  const resizeToBase64 = (file: File): Promise<string> =>
    new Promise((resolve, reject) => {
      const img = new Image();
      const url = URL.createObjectURL(file);
      img.onload = () => {
        const MAX = 256;
        let { width, height } = img;
        if (width > height) {
          if (width > MAX) { height = Math.round((height * MAX) / width); width = MAX; }
        } else {
          if (height > MAX) { width = Math.round((width * MAX) / height); height = MAX; }
        }
        const canvas = document.createElement("canvas");
        canvas.width = width; canvas.height = height;
        const ctx = canvas.getContext("2d");
        if (!ctx) { reject(new Error("canvas error")); return; }
        ctx.drawImage(img, 0, 0, width, height);
        URL.revokeObjectURL(url);
        resolve(canvas.toDataURL("image/jpeg", 0.8));
      };
      img.onerror = () => { URL.revokeObjectURL(url); reject(new Error("load error")); };
      img.src = url;
    });

  const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !profile) return;
    if (!file.type.startsWith("image/")) { setError("กรุณาเลือกไฟล์รูปภาพ"); return; }
    setUploadingAvatar(true); setError(null);
    try {
      const base64 = await resizeToBase64(file);
      await upsertProfile({ id: profile.id, avatar_url: base64 });
      setProfile((p) => p ? { ...p, avatar_url: base64 } : p);
      showSuccess("อัปเดตรูปโปรไฟล์แล้ว");
    } catch { setError("อัปโหลดรูปไม่สำเร็จ กรุณาลองใหม่"); }
    finally { setUploadingAvatar(false); e.target.value = ""; }
  };

  const handleSavePromptpay = async () => {
    if (!profile) return;
    setSaving(true); setError(null);
    try {
      const val = promptpayVal.trim() || null;
      await upsertProfile({ id: profile.id, promptpay: val });
      setProfile((p) => p ? { ...p, promptpay: val } : p);
      setEditingPromptpay(false); showSuccess("อัปเดตพร้อมเพย์แล้ว");
    } catch { setError("เกิดข้อผิดพลาด กรุณาลองใหม่"); }
    finally { setSaving(false); }
  };

  const handleSignOut = async () => { await signOut(); router.push("/login"); };
  const isGoogleUser = user?.app_metadata?.provider === "google";

  if (loading || dataLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white dark:bg-gray-950">
        <div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#f4f6fb] dark:bg-gray-950 flex flex-col pb-20">
      <main className="flex-1 max-w-lg mx-auto w-full px-4 py-5 flex flex-col gap-4">
        {/* Page title */}
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">สวัสดี!, คุณ {profile?.display_name}</h1>
          <button
            onClick={toggleTheme}
            className="w-9 h-9 flex items-center justify-center rounded-xl text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
            title={theme === "dark" ? "Light mode" : "Dark mode"}
          >
            {theme === "dark" ? <IoSunnyOutline size={18} /> : <IoMoonOutline size={18} />}
          </button>
        </div>
        {/* Toast */}
        {success && <div className="px-4 py-3 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-2xl text-sm text-green-700 dark:text-green-400 font-medium">{success}</div>}
        {error && <div className="px-4 py-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-2xl text-sm text-red-600 dark:text-red-400">{error}</div>}

        {/* Avatar card */}
        <div className="flex flex-col items-center gap-3 py-6 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800">
          <div className="relative">
            <div className="w-20 h-20 rounded-2xl bg-[#4366f4] flex items-center justify-center text-white text-2xl font-bold overflow-hidden">
              {profile?.avatar_url ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={profile.avatar_url} alt="" className="w-full h-full object-cover" />
              ) : <IoPersonOutline size={32} />}
              {uploadingAvatar && (
                <div className="absolute inset-0 bg-black/40 flex items-center justify-center rounded-2xl">
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                </div>
              )}
            </div>
            <button
              onClick={() => avatarInputRef.current?.click()}
              disabled={uploadingAvatar}
              className="absolute -bottom-1.5 -right-1.5 w-7 h-7 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 rounded-xl flex items-center justify-center text-white shadow-md transition-colors"
            >
              <IoCamera size={13} />
            </button>
            <input ref={avatarInputRef} type="file" accept="image/*" className="hidden" onChange={handleAvatarChange} />
          </div>
          <div className="text-center">
            <p className="text-base font-bold text-gray-900 dark:text-white">{profile?.display_name ?? "ไม่มีชื่อ"}</p>
            <p className="text-xs text-gray-400 mt-0.5">@{profile?.username}</p>
            <p className="text-xs text-gray-400">{user?.email}</p>
          </div>
        </div>

        {/* Fields */}
        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 overflow-hidden divide-y divide-gray-100 dark:divide-gray-800">
          {/* Display name */}
          <div className="px-4 py-3 flex items-center justify-between">
            <div className="flex-1 min-w-0">
              <p className="text-xs text-gray-400">ชื่อที่แสดง</p>
              {editingName ? (
                <input autoFocus value={nameVal} onChange={(e) => setNameVal(e.target.value)} className="mt-1 text-sm font-medium text-gray-900 dark:text-white bg-transparent border-b border-[#4366f4] outline-none w-full" onKeyDown={(e) => e.key === "Enter" && handleSaveName()} />
              ) : (
                <p className="text-sm font-medium text-gray-900 dark:text-white mt-0.5">{profile?.display_name ?? "—"}</p>
              )}
            </div>
            <div className="flex gap-1 flex-shrink-0">
              {editingName ? (
                <>
                  <button onClick={handleSaveName} disabled={saving} className="w-8 h-8 flex items-center justify-center rounded-xl bg-[#4366f4] text-white"><IoCheckmark size={14} /></button>
                  <button onClick={() => { setEditingName(false); setNameVal(profile?.display_name ?? ""); setError(null); }} className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"><IoClose size={14} /></button>
                </>
              ) : (
                <button onClick={() => { setEditingName(true); setError(null); }} className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"><IoPencil size={14} /></button>
              )}
            </div>
          </div>

          {/* Username */}
          <div className="px-4 py-3 flex items-center justify-between">
            <div className="flex-1 min-w-0">
              <p className="text-xs text-gray-400">Username</p>
              {editingUsername ? (
                <div className="flex items-center gap-1 mt-1">
                  <span className="text-sm text-gray-400">@</span>
                  <input autoFocus value={usernameVal} onChange={(e) => setUsernameVal(e.target.value.toLowerCase())} className="text-sm font-medium text-gray-900 dark:text-white bg-transparent border-b border-[#4366f4] outline-none flex-1" onKeyDown={(e) => e.key === "Enter" && handleSaveUsername()} />
                </div>
              ) : (
                <p className="text-sm font-medium text-gray-900 dark:text-white mt-0.5">@{profile?.username ?? "—"}</p>
              )}
            </div>
            <div className="flex gap-1 flex-shrink-0">
              {editingUsername ? (
                <>
                  <button onClick={handleSaveUsername} disabled={saving} className="w-8 h-8 flex items-center justify-center rounded-xl bg-[#4366f4] text-white"><IoCheckmark size={14} /></button>
                  <button onClick={() => { setEditingUsername(false); setUsernameVal(profile?.username ?? ""); setError(null); }} className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"><IoClose size={14} /></button>
                </>
              ) : (
                <button onClick={() => { setEditingUsername(true); setError(null); }} className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"><IoPencil size={14} /></button>
              )}
            </div>
          </div>

          {/* PromptPay */}
          <div className="px-4 py-3 flex items-center justify-between">
            <div className="flex-1 min-w-0">
              <p className="text-xs text-gray-400">พร้อมเพย์ (ใช้เป็น default ในบิล)</p>
              {editingPromptpay ? (
                <input autoFocus value={promptpayVal} onChange={(e) => setPromptpayVal(e.target.value)} placeholder="เบอร์โทร หรือ เลขบัตรประชาชน" className="mt-1 text-sm font-medium text-gray-900 dark:text-white bg-transparent border-b border-[#4366f4] outline-none w-full" onKeyDown={(e) => e.key === "Enter" && handleSavePromptpay()} />
              ) : (
                <p className="text-sm font-medium text-gray-900 dark:text-white mt-0.5">
                  {profile?.promptpay ? <span className="flex items-center gap-1.5"><span>📱</span>{profile.promptpay}</span> : <span className="text-gray-400">ยังไม่ได้ตั้งค่า</span>}
                </p>
              )}
            </div>
            <div className="flex gap-1 flex-shrink-0">
              {editingPromptpay ? (
                <>
                  <button onClick={handleSavePromptpay} disabled={saving} className="w-8 h-8 flex items-center justify-center rounded-xl bg-[#4366f4] text-white"><IoCheckmark size={14} /></button>
                  <button onClick={() => { setEditingPromptpay(false); setPromptpayVal(profile?.promptpay ?? ""); setError(null); }} className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"><IoClose size={14} /></button>
                </>
              ) : (
                <button onClick={() => { setEditingPromptpay(true); setError(null); }} className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"><IoPencil size={14} /></button>
              )}
            </div>
          </div>
        </div>

        {/* Change password */}
        {!isGoogleUser && (
          <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 overflow-hidden">
            <div className="px-4 py-3">
              <div className="flex items-center justify-between">
                <p className="text-sm font-medium text-gray-900 dark:text-white">เปลี่ยนรหัสผ่าน</p>
                <button onClick={() => { setEditingPassword(!editingPassword); setError(null); setNewPassword(""); setConfirmPassword(""); }} className="w-8 h-8 flex items-center justify-center rounded-xl text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800">
                  {editingPassword ? <IoClose size={14} /> : <IoPencil size={14} />}
                </button>
              </div>
              {editingPassword && (
                <div className="flex flex-col gap-3 mt-3">
                  <input type="password" placeholder="รหัสผ่านใหม่" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} className="w-full px-3 py-2 text-sm rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white outline-none focus:border-[#4366f4]" />
                  <input type="password" placeholder="ยืนยันรหัสผ่านใหม่" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} className="w-full px-3 py-2 text-sm rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white outline-none focus:border-[#4366f4]" />
                  <button onClick={handleSavePassword} disabled={saving} className="w-full py-2.5 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 text-white text-sm font-semibold rounded-xl transition-colors">
                    {saving ? "กำลังบันทึก..." : "บันทึก"}
                  </button>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Sign out */}
        <button onClick={handleSignOut} className="flex items-center justify-center gap-2 w-full py-3.5 bg-white dark:bg-gray-900 border border-red-100 dark:border-red-900/30 rounded-2xl text-sm font-semibold text-red-500 hover:bg-red-50 dark:hover:bg-red-900/10 transition-colors">
          <IoLogOutOutline size={18} /> ออกจากระบบ
        </button>
      </main>

      <BottomNav />
    </div>
  );
}
