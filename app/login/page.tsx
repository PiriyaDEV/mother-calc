"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import { IoLogoGoogle, IoEyeOutline, IoEyeOffOutline, IoArrowBack, IoMailOutline } from "react-icons/io5";
import Link from "next/link";

type Mode = "login" | "register" | "otp";

export default function LoginPage() {
  const { user, loading, signInWithGoogle, signInWithEmail, signUpWithEmail, verifyOTP, configured } =
    useAuth();
  const router = useRouter();

  const [mode, setMode] = useState<Mode>("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [showPass, setShowPass] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  // OTP state — 6 digits
  const [otp, setOtp] = useState(["", "", "", "", "", ""]);
  const otpRefs = useRef<(HTMLInputElement | null)[]>([]);

  useEffect(() => {
    if (!loading && user) {
      router.push("/app");
    }
  }, [user, loading, router]);

  // If Supabase not configured, redirect to app directly
  useEffect(() => {
    if (!loading && !configured) {
      router.push("/app");
    }
  }, [loading, configured, router]);

  if (loading || !configured) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f8f9fc]">
        <div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" />
      </div>
    );
  }

  // ── Submit login/register ──────────────────────────────────
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setSubmitting(true);

    try {
      if (mode === "login") {
        const err = await signInWithEmail(email, password);
        if (err) setError(err);
      } else {
        const err = await signUpWithEmail(email, password, name);
        if (err) {
          setError(err);
        } else {
          // Switch to OTP verification screen
          setMode("otp");
          setOtp(["", "", "", "", "", ""]);
          setTimeout(() => otpRefs.current[0]?.focus(), 100);
        }
      }
    } finally {
      setSubmitting(false);
    }
  };

  // ── OTP input handlers ─────────────────────────────────────
  const handleOtpChange = (index: number, value: string) => {
    // Allow only digits
    const digit = value.replace(/\D/g, "").slice(-1);
    const next = [...otp];
    next[index] = digit;
    setOtp(next);
    setError("");

    // Auto-focus next
    if (digit && index < 5) {
      otpRefs.current[index + 1]?.focus();
    }

    // Auto-submit when all 6 filled
    if (digit && index === 5) {
      const code = [...next].join("");
      if (code.length === 6) handleVerifyOTP(code);
    }
  };

  const handleOtpKeyDown = (index: number, e: React.KeyboardEvent) => {
    if (e.key === "Backspace" && !otp[index] && index > 0) {
      otpRefs.current[index - 1]?.focus();
    }
  };

  const handleOtpPaste = (e: React.ClipboardEvent) => {
    e.preventDefault();
    const pasted = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, 6);
    if (!pasted) return;
    const next = [...otp];
    pasted.split("").forEach((ch, i) => { next[i] = ch; });
    setOtp(next);
    if (pasted.length === 6) {
      handleVerifyOTP(pasted);
    } else {
      otpRefs.current[pasted.length]?.focus();
    }
  };

  const handleVerifyOTP = async (code?: string) => {
    const token = code ?? otp.join("");
    if (token.length < 6) return;
    setError("");
    setSubmitting(true);
    try {
      const err = await verifyOTP(email, token);
      if (err) {
        setError(err);
        setOtp(["", "", "", "", "", ""]);
        setTimeout(() => otpRefs.current[0]?.focus(), 50);
      }
      // On success, useAuth listener will set user → redirect to /app
    } finally {
      setSubmitting(false);
    }
  };

  // ── Render ─────────────────────────────────────────────────
  return (
    <div className="min-h-screen bg-[#f8f9fc] dark:bg-gray-950 flex flex-col items-center justify-center px-4 py-12">
      {/* Back */}
      <div className="w-full max-w-sm mb-4">
        {mode === "otp" ? (
          <button
            onClick={() => { setMode("register"); setError(""); }}
            className="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
          >
            <IoArrowBack size={14} />
            กลับ
          </button>
        ) : (
          <Link
            href="/"
            className="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
          >
            <IoArrowBack size={14} />
            กลับหน้าหลัก
          </Link>
        )}
      </div>

      <div className="w-full max-w-sm bg-white dark:bg-gray-900 rounded-3xl border border-gray-100 dark:border-gray-800 shadow-sm p-8">
        {/* Logo */}
        <div className="flex flex-col items-center mb-8">
          <div className="w-12 h-12 rounded-2xl bg-[#4366f4] flex items-center justify-center mb-3">
            <span className="text-white text-xl font-bold">฿</span>
          </div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">Kidtang</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
            {mode === "login" ? "เข้าสู่ระบบ" : mode === "register" ? "สมัครสมาชิก" : "ยืนยันอีเมล"}
          </p>
        </div>

        {/* ── OTP Screen ── */}
        {mode === "otp" ? (
          <div className="flex flex-col items-center gap-5">
            <div className="w-14 h-14 rounded-2xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center">
              <IoMailOutline size={28} className="text-[#4366f4]" />
            </div>
            <div className="text-center">
              <p className="text-sm font-semibold text-gray-900 dark:text-white mb-1">
                ตรวจสอบอีเมลของคุณ
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                เราส่งรหัส 6 หลักไปที่
              </p>
              <p className="text-xs font-semibold text-[#4366f4] mt-0.5">{email}</p>
            </div>

            {/* 6-digit OTP boxes */}
            <div className="flex gap-2" onPaste={handleOtpPaste}>
              {otp.map((digit, i) => (
                <input
                  key={i}
                  ref={(el) => { otpRefs.current[i] = el; }}
                  type="text"
                  inputMode="numeric"
                  maxLength={1}
                  value={digit}
                  onChange={(e) => handleOtpChange(i, e.target.value)}
                  onKeyDown={(e) => handleOtpKeyDown(i, e)}
                  disabled={submitting}
                  className={`w-11 h-13 text-center text-lg font-bold rounded-2xl border-2 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none transition-all
                    ${digit ? "border-[#4366f4] bg-blue-50 dark:bg-blue-900/20" : "border-gray-200 dark:border-gray-700"}
                    focus:border-[#4366f4] focus:bg-blue-50 dark:focus:bg-blue-900/20
                    disabled:opacity-50`}
                  style={{ height: "52px" }}
                />
              ))}
            </div>

            {/* Error */}
            {error && (
              <div className="w-full px-4 py-3 bg-red-50 dark:bg-red-900/20 border border-red-100 dark:border-red-800 rounded-2xl text-xs text-red-600 dark:text-red-400 text-center">
                {error}
              </div>
            )}

            {/* Verify button */}
            <button
              onClick={() => handleVerifyOTP()}
              disabled={submitting || otp.join("").length < 6}
              className="w-full py-3 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-50 text-white text-sm font-semibold rounded-2xl transition-colors"
            >
              {submitting ? "กำลังยืนยัน..." : "ยืนยันรหัส"}
            </button>

            <p className="text-xs text-gray-400 text-center">
              ไม่ได้รับรหัส?{" "}
              <button
                onClick={() => signUpWithEmail(email, password, name)}
                className="text-[#4366f4] font-semibold hover:underline"
              >
                ส่งใหม่
              </button>
            </p>
          </div>
        ) : (
          /* ── Login / Register Screen ── */
          <>
            {/* Google */}
            <button
              onClick={signInWithGoogle}
              className="w-full flex items-center justify-center gap-3 px-4 py-3 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 text-gray-800 dark:text-white text-sm font-semibold rounded-2xl hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors mb-4"
            >
              <IoLogoGoogle size={18} className="text-[#4285f4]" />
              {mode === "login" ? "เข้าสู่ระบบ" : "สมัครสมาชิก"} ด้วย Google
            </button>

            {/* Divider */}
            <div className="flex items-center gap-3 mb-4">
              <div className="flex-1 h-px bg-gray-100 dark:bg-gray-800" />
              <span className="text-xs text-gray-400">หรือ</span>
              <div className="flex-1 h-px bg-gray-100 dark:bg-gray-800" />
            </div>

            {/* Form */}
            <form onSubmit={handleSubmit} className="flex flex-col gap-3">
              {mode === "register" && (
                <div className="flex flex-col gap-1">
                  <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
                    ชื่อ
                  </label>
                  <input
                    type="text"
                    placeholder="ชื่อของคุณ"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    required
                    className="w-full px-4 py-3 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-2xl text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#4366f4]/30 focus:border-[#4366f4] transition-all"
                  />
                </div>
              )}

              <div className="flex flex-col gap-1">
                <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
                  อีเมล
                </label>
                <input
                  type="email"
                  placeholder="email@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  className="w-full px-4 py-3 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-2xl text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#4366f4]/30 focus:border-[#4366f4] transition-all"
                />
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-xs font-medium text-gray-600 dark:text-gray-400">
                  รหัสผ่าน
                </label>
                <div className="relative">
                  <input
                    type={showPass ? "text" : "password"}
                    placeholder="รหัสผ่าน (อย่างน้อย 6 ตัว)"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    minLength={6}
                    className="w-full px-4 py-3 pr-11 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-2xl text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#4366f4]/30 focus:border-[#4366f4] transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPass((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                  >
                    {showPass ? <IoEyeOffOutline size={18} /> : <IoEyeOutline size={18} />}
                  </button>
                </div>
              </div>

              {/* Error */}
              {error && (
                <div className="px-4 py-3 bg-red-50 dark:bg-red-900/20 border border-red-100 dark:border-red-800 rounded-2xl text-xs text-red-600 dark:text-red-400">
                  {error}
                </div>
              )}

              <button
                type="submit"
                disabled={submitting}
                className="w-full py-3 bg-[#4366f4] hover:bg-[#3355e0] disabled:opacity-60 text-white text-sm font-semibold rounded-2xl transition-colors mt-1"
              >
                {submitting
                  ? "กำลังดำเนินการ..."
                  : mode === "login"
                  ? "เข้าสู่ระบบ"
                  : "สมัครสมาชิก"}
              </button>
            </form>

            {/* Toggle mode */}
            <p className="text-center text-xs text-gray-500 dark:text-gray-400 mt-5">
              {mode === "login" ? "ยังไม่มีบัญชี?" : "มีบัญชีแล้ว?"}{" "}
              <button
                onClick={() => {
                  setMode(mode === "login" ? "register" : "login");
                  setError("");
                }}
                className="text-[#4366f4] font-semibold hover:underline"
              >
                {mode === "login" ? "สมัครสมาชิก" : "เข้าสู่ระบบ"}
              </button>
            </p>
          </>
        )}
      </div>
    </div>
  );
}
