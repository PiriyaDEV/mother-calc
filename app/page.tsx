"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import {
  IoReceiptOutline,
  IoPeopleOutline,
  IoBarChartOutline,
  IoLogoGoogle,
  IoArrowForward,
  IoCheckmarkCircle,
  IoSparkles,
} from "react-icons/io5";

export default function LandingPage() {
  const { user, loading, signInWithGoogle, configured } = useAuth();
  const router = useRouter();

  useEffect(() => {
    // Redirect to app only if already logged in
    if (!loading && user) {
      router.push("/app");
    }
  }, [user, loading, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f8f9fc] dark:bg-gray-950">
        <div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" />
      </div>
    );
  }

  const handleCTA = () => {
    if (configured) {
      router.push("/login");
    } else {
      router.push("/app");
    }
  };

  return (
    <div className="min-h-screen bg-[#f8f9fc] dark:bg-gray-950 flex flex-col">
      {/* Navbar */}
      <nav className="sticky top-0 z-40 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
        <div className="max-w-5xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-xl bg-[#4366f4] flex items-center justify-center">
              <span className="text-white text-sm font-bold">฿</span>
            </div>
            <span className="text-base font-bold text-gray-900 dark:text-white">
              Kidtang
            </span>
          </div>
          <button
            onClick={handleCTA}
            className="flex items-center gap-2 px-4 py-2 bg-[#4366f4] hover:bg-[#3355e0] text-white text-sm font-semibold rounded-xl transition-colors"
          >
            เริ่มใช้งาน
            <IoArrowForward size={14} />
          </button>
        </div>
      </nav>

      {/* Hero */}
      <section className="flex-1 flex flex-col items-center justify-center px-6 py-20 text-center">
        <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-blue-50 dark:bg-blue-900/20 text-[#4366f4] text-xs font-semibold rounded-full mb-6 border border-blue-100 dark:border-blue-800">
          <IoSparkles size={12} />
          หารบิลง่าย ไม่ต้องคิดเอง
        </div>

        <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 dark:text-white leading-tight mb-4 max-w-xl">
          หารบิลกับเพื่อน
          <br />
          <span className="text-[#4366f4]">ง่ายกว่าที่เคย</span>
        </h1>

        <p className="text-base text-gray-500 dark:text-gray-400 max-w-md mb-10 leading-relaxed">
          คำนวณค่าใช้จ่าย หารเท่า หรือไม่เท่า รองรับ VAT, Service Charge,
          ทิป และส่วนลด พร้อม QR PromptPay
        </p>

        <div className="flex flex-col sm:flex-row gap-3 items-center">
          <button
            onClick={handleCTA}
            className="flex items-center gap-2 px-6 py-3.5 bg-[#4366f4] hover:bg-[#3355e0] text-white text-sm font-semibold rounded-2xl shadow-sm hover:shadow-md transition-all hover:-translate-y-0.5"
          >
            เริ่มใช้งานเลย
            <IoArrowForward size={14} />
          </button>
        </div>

        {/* Trust badges */}
        <div className="flex items-center gap-6 mt-10 text-xs text-gray-400">
          <span className="flex items-center gap-1.5">
            <IoCheckmarkCircle size={14} className="text-emerald-500" />
            ฟรี 100%
          </span>
          <span className="flex items-center gap-1.5">
            <IoCheckmarkCircle size={14} className="text-emerald-500" />
            ไม่ต้องลงทะเบียน
          </span>
          <span className="flex items-center gap-1.5">
            <IoCheckmarkCircle size={14} className="text-emerald-500" />
            บันทึกอัตโนมัติ
          </span>
        </div>
      </section>

      {/* Features */}
      <section className="max-w-5xl mx-auto px-6 pb-20 w-full">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {[
            {
              icon: <IoPeopleOutline size={24} />,
              title: "จัดการสมาชิก",
              desc: "เพิ่มสมาชิกพร้อม PromptPay สำหรับโอนเงินได้เลย",
              color: "bg-blue-50 dark:bg-blue-900/20 text-[#4366f4]",
            },
            {
              icon: <IoReceiptOutline size={24} />,
              title: "รายการยืดหยุ่น",
              desc: "หารเท่าหรือกำหนดสัดส่วนเอง รองรับ VAT และ Service Charge",
              color: "bg-purple-50 dark:bg-purple-900/20 text-purple-500",
            },
            {
              icon: <IoBarChartOutline size={24} />,
              title: "สรุปชัดเจน",
              desc: "ดูกราฟสัดส่วน และ QR PromptPay สำหรับโอนเงินทันที",
              color: "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-500",
            },
          ].map((f) => (
            <div
              key={f.title}
              className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 hover:shadow-md transition-shadow"
            >
              <div
                className={`w-10 h-10 rounded-xl flex items-center justify-center mb-3 ${f.color}`}
              >
                {f.icon}
              </div>
              <h3 className="text-sm font-bold text-gray-900 dark:text-white mb-1">
                {f.title}
              </h3>
              <p className="text-xs text-gray-500 dark:text-gray-400 leading-relaxed">
                {f.desc}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-gray-100 dark:border-gray-800 py-6 text-center">
        <p className="text-xs text-gray-400">
          © 2025 Kidtang · หารบิลง่ายๆ สำหรับทุกคน
        </p>
      </footer>
    </div>
  );
}
