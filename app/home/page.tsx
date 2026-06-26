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
  IoCalendarOutline,
} from "react-icons/io5";
import BottomNav from "@/components/ui/BottomNav";

function getBillTotal(bill: Bill): number {
  return (bill.items ?? []).reduce((s, i) => s + i.price, 0);
}
function formatBaht(n: number): string {
  return n.toLocaleString("th-TH", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

export default function HomePage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  const [groups, setGroups] = useState<Group[]>([]);
  const [personalBills, setPersonalBills] = useState<Bill[]>([]);
  const [groupBills, setGroupBills] = useState<Record<string, Bill[]>>({});
  const [dataLoading, setDataLoading] = useState(true);

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

  useEffect(() => { if (user) loadData(); }, [user, loadData]);
  useEffect(() => { if (!loading && !user) router.push("/login"); }, [loading, user, router]);

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
  const avatarUrl = user?.user_metadata?.avatar_url as string | undefined;
  const initials = displayName.slice(0, 1).toUpperCase();

  return (
    <div className="min-h-screen bg-[#f4f6fb] dark:bg-gray-950 flex flex-col pb-20">
      <main className="flex-1 max-w-lg mx-auto w-full px-4 py-5 flex flex-col gap-5">
        {/* Hero */}
        <div className="bg-gradient-to-br from-[#4366f4] to-[#6b8aff] rounded-3xl p-5 text-white shadow-lg shadow-blue-200/40 dark:shadow-none">
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
        <div className="grid grid-cols-2 gap-3">
          <button
            onClick={() => router.push("/groups")}
            className="flex items-center gap-3 p-4 bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 hover:border-purple-200 hover:shadow-sm transition-all"
          >
            <div className="w-9 h-9 rounded-xl bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center flex-shrink-0">
              <IoPeopleOutline size={18} className="text-purple-500" />
            </div>
            <div className="text-left">
              <p className="text-sm font-semibold text-gray-800 dark:text-white">กลุ่ม</p>
              <p className="text-[10px] text-gray-400 mt-0.5">{groups.length} กลุ่ม</p>
            </div>
          </button>
          <button
            onClick={() => router.push("/bills")}
            className="flex items-center gap-3 p-4 bg-[#4366f4] hover:bg-[#3355e0] rounded-2xl shadow-sm hover:shadow-md transition-all"
          >
            <div className="w-9 h-9 rounded-xl bg-white/20 flex items-center justify-center flex-shrink-0">
              <IoReceiptOutline size={18} className="text-white" />
            </div>
            <div className="text-left">
              <p className="text-sm font-semibold text-white">บิลของฉัน</p>
              <p className="text-[10px] text-white/70 mt-0.5">{personalBills.length} บิล</p>
            </div>
          </button>
        </div>

        {dataLoading ? (
          <div className="flex items-center justify-center py-10">
            <div className="w-6 h-6 border-2 border-[#4366f4] border-t-transparent rounded-full animate-spin" />
          </div>
        ) : (
          <>
            {/* Stats */}
            {allBills.length > 0 && (
              <div className="flex flex-col gap-3">
                <h2 className="text-sm font-bold text-gray-900 dark:text-white">สถิติของคุณ</h2>
                <div className="grid grid-cols-2 gap-3">
                  <FactCard icon={<IoTrendingUpOutline size={18} />} label="เฉลี่ยต่อบิล" value={`${formatBaht(avgBill)} บาท`} color="text-[#4366f4]" bg="bg-blue-50 dark:bg-blue-900/20" />
                  <FactCard icon={<IoReceiptOutline size={18} />} label="บิลทั้งหมด" value={`${allBills.length} บิล`} color="text-purple-500" bg="bg-purple-50 dark:bg-purple-900/20" />
                  <FactCard icon={<IoFlameOutline size={18} />} label="รายการทั้งหมด" value={`${totalItems} รายการ`} color="text-orange-500" bg="bg-orange-50 dark:bg-orange-900/20" />
                  <FactCard icon={<IoStarOutline size={18} />} label="บิลใหญ่สุด" value={biggestBill ? `${formatBaht(getBillTotal(biggestBill))} บาท` : "—"} color="text-amber-500" bg="bg-amber-50 dark:bg-amber-900/20" />
                </div>
                {biggestBill && (
                  <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <IoStarOutline size={14} className="text-amber-500" />
                      <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">บิลที่ใหญ่ที่สุด</p>
                    </div>
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-amber-50 dark:bg-amber-900/20 flex items-center justify-center text-xl flex-shrink-0">
                        {biggestBill.emoji ?? <IoReceiptOutline size={18} className="text-amber-500" />}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold text-gray-900 dark:text-white truncate">{biggestBill.title}</p>
                        <p className="text-xs text-gray-400">{(biggestBill.items ?? []).length} รายการ</p>
                      </div>
                      <p className="text-base font-bold text-amber-500 flex-shrink-0">{formatBaht(getBillTotal(biggestBill))} บาท</p>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Empty state */}
            {allBills.length === 0 && (
              <div className="flex flex-col items-center gap-4 py-10 text-center">
                <div className="w-16 h-16 rounded-2xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center">
                  <IoReceiptOutline size={28} className="text-[#4366f4]" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-gray-700 dark:text-gray-300">ยังไม่มีบิล</p>
                  <p className="text-xs text-gray-400 mt-1">สร้างบิลแรกหรือเข้าร่วมกลุ่มเพื่อเริ่มต้น</p>
                </div>
                <div className="flex gap-2">
                  <button onClick={() => router.push("/bills")} className="px-4 py-2 bg-[#4366f4] text-white text-xs font-semibold rounded-xl">สร้างบิล</button>
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
