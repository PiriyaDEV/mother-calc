"use client";

import { useEffect, useState, useCallback, useMemo } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import {
  getMyGroups,
  getIndividualBills,
  getBills,
  ensureMyProfile,
} from "@/lib/db";
import { Group, Bill } from "@/lib/types";
import {
  IoReceiptOutline,
  IoPeopleOutline,
  IoWalletOutline,
  IoTrendingUpOutline,
  IoFlameOutline,
  IoStarOutline,
  IoRefreshOutline,
  IoArrowUpOutline,
  IoArrowDownOutline,
  IoAddOutline,
} from "react-icons/io5";
import BottomNav from "@/components/ui/BottomNav";
import BillStatusPill from "@/components/ui/BillStatusPill";

function getBillTotal(bill: Bill): number {
  return (bill.items ?? []).reduce((s, i) => s + i.price, 0);
}
function formatBaht(n: number): string {
  return n.toLocaleString("th-TH", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

// Currency config
const CURRENCIES = [
  { code: "USD", name: "ดอลลาร์สหรัฐ", flag: "🇺🇸", color: "from-green-400 to-emerald-500" },
  { code: "EUR", name: "ยูโร", flag: "🇪🇺", color: "from-blue-400 to-blue-600" },
  { code: "JPY", name: "เยนญี่ปุ่น", flag: "🇯🇵", color: "from-red-400 to-rose-500" },
  { code: "CNY", name: "หยวนจีน", flag: "🇨🇳", color: "from-red-500 to-orange-500" },
  { code: "GBP", name: "ปอนด์อังกฤษ", flag: "🇬🇧", color: "from-indigo-400 to-purple-500" },
  { code: "KRW", name: "วอนเกาหลี", flag: "🇰🇷", color: "from-sky-400 to-cyan-500" },
  { code: "SGD", name: "ดอลลาร์สิงคโปร์", flag: "🇸🇬", color: "from-red-400 to-pink-500" },
  { code: "AUD", name: "ดอลลาร์ออสเตรเลีย", flag: "🇦🇺", color: "from-yellow-400 to-amber-500" },
  { code: "HKD", name: "ดอลลาร์ฮ่องกง", flag: "🇭🇰", color: "from-rose-400 to-red-500" },
  { code: "MYR", name: "ริงกิตมาเลเซีย", flag: "🇲🇾", color: "from-yellow-500 to-orange-400" },
];

interface RateData {
  code: string;
  rate: number; // THB per 1 unit of currency
  change: number; // % change (mock for now)
}

export default function HomePage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  const [groups, setGroups] = useState<Group[]>([]);
  const [personalBills, setPersonalBills] = useState<Bill[]>([]);
  const [groupBills, setGroupBills] = useState<Record<string, Bill[]>>({});
  const [dataLoading, setDataLoading] = useState(true);

  // Currency state
  const [rates, setRates] = useState<RateData[]>([]);
  const [ratesLoading, setRatesLoading] = useState(true);
  const [ratesUpdated, setRatesUpdated] = useState<string>("");

  const loadData = useCallback(async () => {
    if (!user) return;
    setDataLoading(true);
    try {
      await ensureMyProfile();
      const [grps, bills] = await Promise.all([getMyGroups(), getIndividualBills()]);
      setGroups(grps);
      setPersonalBills(bills);
      const billMap: Record<string, Bill[]> = {};
      await Promise.all(grps.map(async (g) => { billMap[g.id] = await getBills({ groupId: g.id }); }));
      setGroupBills(billMap);
    } finally {
      setDataLoading(false);
    }
  }, [user]);

  const loadRates = useCallback(async () => {
    setRatesLoading(true);
    try {
      // Using open.er-api.com (free, no key needed)
      const res = await fetch("https://open.er-api.com/v6/latest/THB");
      if (!res.ok) throw new Error("fetch failed");
      const data = await res.json();
      const thbRates = data.rates as Record<string, number>;
      // thbRates[X] = how many X per 1 THB → invert to get THB per 1 X
      const parsed: RateData[] = CURRENCIES.map((c) => ({
        code: c.code,
        rate: thbRates[c.code] ? 1 / thbRates[c.code] : 0,
        change: 0,
      }));
      setRates(parsed);
      setRatesUpdated(new Date().toLocaleTimeString("th-TH", { hour: "2-digit", minute: "2-digit" }));
    } catch {
      // Fallback approximate rates (THB per 1 unit)
      const fallback: Record<string, number> = {
        USD: 33.5, EUR: 36.2, JPY: 0.22, CNY: 4.6, GBP: 42.5,
        KRW: 0.025, SGD: 24.8, AUD: 21.5, HKD: 4.3, MYR: 7.2,
      };
      setRates(CURRENCIES.map((c) => ({ code: c.code, rate: fallback[c.code] ?? 0, change: 0 })));
      setRatesUpdated("ข้อมูลสำรอง");
    } finally {
      setRatesLoading(false);
    }
  }, []);

  useEffect(() => { if (user) loadData(); }, [user, loadData]);
  useEffect(() => { if (!loading && !user) router.push("/login"); }, [loading, user, router]);
  useEffect(() => { loadRates(); }, [loadRates]);

  const allBills = useMemo(() => [...personalBills, ...Object.values(groupBills).flat()], [personalBills, groupBills]);
  const grandTotal = useMemo(() => allBills.reduce((s, b) => s + getBillTotal(b), 0), [allBills]);
  const totalItems = useMemo(() => allBills.reduce((s, b) => s + (b.items ?? []).length, 0), [allBills]);
  const avgBill = allBills.length > 0 ? grandTotal / allBills.length : 0;
  const biggestBill = useMemo(() => [...allBills].sort((a, b) => getBillTotal(b) - getBillTotal(a))[0], [allBills]);
  const recentBills = useMemo(() => [...allBills].sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()).slice(0, 3), [allBills]);

  if (loading || (!user && !loading)) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-white dark:bg-gray-950">
        <div className="w-8 h-8 rounded-full border-2 border-[#4366f4] border-t-transparent animate-spin" />
      </div>
    );
  }

  const displayName = (user?.user_metadata?.full_name as string | undefined) || user?.email?.split("@")[0] || "คุณ";
  const firstName = displayName.split(" ")[0];

  return (
    <div className="min-h-screen bg-[#f4f6fb] dark:bg-gray-950 flex flex-col pb-20">
      <main className="flex-1 max-w-lg mx-auto w-full px-4 py-5 flex flex-col gap-5">

        {/* Hero */}
        <div className="bg-gradient-to-br from-[#286bfe] to-[#6b8aff] rounded-3xl p-5 text-white shadow-lg shadow-blue-200/40 dark:shadow-none">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm font-medium opacity-80">สวัสดี, {firstName} 👋</p>
              <p className="text-xs opacity-60 mt-0.5">ยอดรวมทั้งหมดของคุณ</p>
            </div>
            <div className="w-9 h-9 rounded-xl bg-white/20 flex items-center justify-center">
              <IoWalletOutline size={18} className="text-white" />
            </div>
          </div>
          <div className="mt-4">
            {dataLoading ? (
              <div className="w-6 h-6 border-2 border-white/40 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                <p className="text-3xl font-bold tracking-tight">{formatBaht(grandTotal)} บาท</p>
                <div className="flex items-center gap-3 mt-2">
                  <span className="text-xs opacity-70">{groups.length} กลุ่ม</span>
                  <span className="text-xs opacity-40">·</span>
                  <span className="text-xs opacity-70">{personalBills.length} บิลส่วนตัว</span>
                  <span className="text-xs opacity-40">·</span>
                  <span className="text-xs opacity-70">{totalItems} รายการ</span>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Quick actions */}
        <div className="grid grid-cols-3 gap-3">
          <button
            onClick={() => router.push("/groups")}
            className="flex flex-col items-center gap-2 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 hover:border-purple-200 hover:shadow-sm transition-all"
          >
            <div className="w-10 h-10 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center">
              <IoPeopleOutline size={20} className="text-purple-500" />
            </div>
            <p className="text-xs font-semibold text-gray-700 dark:text-gray-300">กลุ่ม</p>
            <p className="text-[10px] text-gray-400">{groups.length} กลุ่ม</p>
          </button>
          <button
            onClick={() => router.push("/bills")}
            className="flex flex-col items-center gap-2 p-4 bg-[#286bfe] hover:bg-[#1a5ce0] rounded-2xl shadow-sm hover:shadow-md transition-all"
          >
            <div className="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
              <IoReceiptOutline size={20} className="text-white" />
            </div>
            <p className="text-xs font-semibold text-white">บิล</p>
            <p className="text-[10px] text-white/70">{personalBills.length} บิล</p>
          </button>
          <button
            onClick={() => router.push("/friends")}
            className="flex flex-col items-center gap-2 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 hover:border-green-200 hover:shadow-sm transition-all"
          >
            <div className="w-10 h-10 rounded-xl bg-green-50 dark:bg-green-900/20 flex items-center justify-center">
              <IoAddOutline size={20} className="text-green-500" />
            </div>
            <p className="text-xs font-semibold text-gray-700 dark:text-gray-300">เพื่อน</p>
            <p className="text-[10px] text-gray-400">จัดการ</p>
          </button>
        </div>

        {/* Currency Exchange Rates */}
        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-sm font-bold text-gray-900 dark:text-white">อัตราแลกเปลี่ยน</h2>
              {ratesUpdated && (
                <p className="text-[10px] text-gray-400 mt-0.5">อัปเดต {ratesUpdated}</p>
              )}
            </div>
            <button
              onClick={loadRates}
              disabled={ratesLoading}
              className="w-7 h-7 rounded-lg bg-gray-100 dark:bg-gray-800 flex items-center justify-center text-gray-500 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors disabled:opacity-50"
            >
              <IoRefreshOutline size={14} className={ratesLoading ? "animate-spin" : ""} />
            </button>
          </div>

          {/* Horizontal scroll */}
          <div className="flex gap-3 overflow-x-auto pb-1 -mx-4 px-4 scrollbar-hide" style={{ scrollbarWidth: "none" }}>
            {ratesLoading
              ? Array.from({ length: 5 }).map((_, i) => (
                  <div key={i} className="flex-shrink-0 w-32 h-24 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 animate-pulse" />
                ))
              : rates.map((r) => {
                  const cfg = CURRENCIES.find((c) => c.code === r.code)!;
                  const isUp = r.change >= 0;
                  const rateDisplay = r.code === "JPY" || r.code === "KRW"
                    ? r.rate.toFixed(4)
                    : r.rate.toFixed(2);
                  return (
                    <div
                      key={r.code}
                      className="relative flex-shrink-0 w-36 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-3.5 flex flex-col gap-2 overflow-hidden"
                    >
                      {/* Flag background */}
                      <span className="absolute -right-2 -bottom-2 text-6xl opacity-20 select-none pointer-events-none leading-none">
                        {cfg.flag}
                      </span>
                      <div className="flex items-center justify-between relative">
                        {/* <span className="text-xl">{cfg.flag}</span> */}
                        {r.change !== 0 && (
                          <span className={`flex items-center gap-0.5 text-[10px] font-semibold ${isUp ? "text-green-500" : "text-red-500"}`}>
                            {isUp ? <IoArrowUpOutline size={10} /> : <IoArrowDownOutline size={10} />}
                            {Math.abs(r.change).toFixed(2)}%
                          </span>
                        )}
                      </div>
                      <div className="relative">
                        <p className="text-base font-bold text-gray-900 dark:text-white leading-tight">
                          ฿{rateDisplay}
                        </p>
                        <p className="text-[10px] text-gray-400 mt-0.5">1 {r.code}</p>
                      </div>
                      <p className="text-[10px] text-gray-500 dark:text-gray-400 truncate relative">{cfg.name}</p>
                    </div>
                  );
                })}
          </div>
        </div>

        {dataLoading ? (
          <div className="flex items-center justify-center py-10">
            <div className="w-6 h-6 border-2 border-[#286bfe] border-t-transparent rounded-full animate-spin" />
          </div>
        ) : (
          <>
            {/* Stats */}
            {allBills.length > 0 && (
              <div className="flex flex-col gap-3">
                <h2 className="text-sm font-bold text-gray-900 dark:text-white">สถิติของคุณ</h2>
                <div className="grid grid-cols-2 gap-3">
                  <FactCard icon={<IoTrendingUpOutline size={18} />} label="เฉลี่ยต่อบิล" value={`${formatBaht(avgBill)} ฿`} color="text-[#286bfe]" bg="bg-blue-50 dark:bg-blue-900/20" />
                  <FactCard icon={<IoReceiptOutline size={18} />} label="บิลทั้งหมด" value={`${allBills.length} บิล`} color="text-purple-500" bg="bg-purple-50 dark:bg-purple-900/20" />
                  <FactCard icon={<IoFlameOutline size={18} />} label="รายการทั้งหมด" value={`${totalItems} รายการ`} color="text-orange-500" bg="bg-orange-50 dark:bg-orange-900/20" />
                  <FactCard icon={<IoStarOutline size={18} />} label="บิลใหญ่สุด" value={biggestBill ? `${formatBaht(getBillTotal(biggestBill))} ฿` : "—"} color="text-amber-500" bg="bg-amber-50 dark:bg-amber-900/20" />
                </div>
              </div>
            )}

            {/* Recent Bills */}
            {recentBills.length > 0 && (
              <div className="flex flex-col gap-3">
                <div className="flex items-center justify-between">
                  <h2 className="text-sm font-bold text-gray-900 dark:text-white">บิลล่าสุด</h2>
                  <button onClick={() => router.push("/bills")} className="text-xs text-[#286bfe] font-semibold">ดูทั้งหมด</button>
                </div>
                <div className="flex flex-col gap-2">
                  {recentBills.map((bill) => (
                    <button
                      key={bill.id}
                      onClick={() => router.push(`/app?id=${bill.id}`)}
                      className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 flex items-center gap-3 hover:border-[#286bfe]/30 hover:shadow-sm transition-all text-left w-full"
                    >
                      <div className="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center text-xl flex-shrink-0">
                        {bill.emoji ?? "🧾"}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{bill.title}</p>
                        <div className="flex items-center gap-1.5 mt-0.5 flex-wrap">
                          <BillStatusPill bill={bill} />
                          <p className="text-[10px] text-gray-400">{(bill.items ?? []).length} รายการ · {new Date(bill.updated_at).toLocaleDateString("th-TH", { day: "numeric", month: "short" })}</p>
                        </div>
                      </div>
                      <p className="text-sm font-bold text-[#286bfe] flex-shrink-0">{formatBaht(getBillTotal(bill))} ฿</p>
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Biggest bill highlight */}
            {biggestBill && (
              <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4">
                <div className="flex items-center gap-2 mb-3">
                  <IoStarOutline size={14} className="text-amber-500" />
                  <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">บิลที่ใหญ่ที่สุด</p>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-amber-50 dark:bg-amber-900/20 flex items-center justify-center text-xl flex-shrink-0">
                    {biggestBill.emoji ?? "🧾"}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{biggestBill.title}</p>
                    <p className="text-xs text-gray-400">{(biggestBill.items ?? []).length} รายการ</p>
                  </div>
                  <p className="text-base font-bold text-amber-500 flex-shrink-0">{formatBaht(getBillTotal(biggestBill))} ฿</p>
                </div>
              </div>
            )}

            {/* Empty state */}
            {allBills.length === 0 && (
              <div className="flex flex-col items-center gap-4 py-10 text-center">
                <div className="w-16 h-16 rounded-2xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center">
                  <IoReceiptOutline size={28} className="text-[#286bfe]" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-gray-700 dark:text-gray-300">ยังไม่มีบิล</p>
                  <p className="text-xs text-gray-400 mt-1">สร้างบิลแรกหรือเข้าร่วมกลุ่มเพื่อเริ่มต้น</p>
                </div>
                <div className="flex gap-2">
                  <button onClick={() => router.push("/bills")} className="px-4 py-2 bg-[#286bfe] text-white text-xs font-semibold rounded-xl">สร้างบิล</button>
                  <button onClick={() => router.push("/groups")} className="px-4 py-2 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 text-xs font-semibold rounded-xl">สร้างกลุ่ม</button>
                </div>
              </div>
            )}
          </>
        )}
      </main>

      <BottomNav />
    </div>
  );
}

function FactCard({ icon, label, value, color, bg }: { icon: React.ReactNode; label: string; value: string; color: string; bg: string }) {
  return (
    <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 flex items-center gap-3">
      <div className={`w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 ${bg} ${color}`}>{icon}</div>
      <div className="min-w-0">
        <p className="text-[10px] text-gray-400 font-medium">{label}</p>
        <p className="text-sm font-bold text-gray-900 dark:text-white truncate">{value}</p>
      </div>
    </div>
  );
}
