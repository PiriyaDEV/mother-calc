"use client";

import { useMemo } from "react";
import { Bill, BillMember } from "@/lib/types";
import { calculateBill, formatNumber, getTotalEmoji } from "@/lib/utils";
import MemberAvatar from "@/components/ui/MemberAvatar";

interface AnalyticsPageProps {
  bill: Bill;
  members?: BillMember[];
}

export default function AnalyticsPage({ bill, members: membersProp }: AnalyticsPageProps) {
  const calc = useMemo(() => calculateBill(bill), [bill]);
  const items = bill.items ?? [];
  const members = membersProp ?? bill.members ?? [];

  // Top items by price
  const topItems = useMemo(
    () => [...items].sort((a, b) => b.price - a.price).slice(0, 5),
    [items]
  );

  // Per-member totals
  const memberTotals = useMemo(
    () =>
      calc.memberSummaries
        .map((s) => ({ member: s.member, total: s.total, itemCount: s.items.length }))
        .sort((a, b) => b.total - a.total),
    [calc.memberSummaries]
  );

  const maxMemberTotal = memberTotals[0]?.total ?? 1;
  const maxItemPrice = topItems[0]?.price ?? 1;

  // Category breakdown (by first word of item name as rough category)
  const avgPerPerson = members.length > 0 ? calc.total / members.length : 0;

  // Who pays most vs least
  const biggestPayer = memberTotals[0];
  const smallestPayer = memberTotals[memberTotals.length - 1];

  if (items.length === 0 || members.length === 0) {
    return (
      <div className="flex flex-col items-center gap-3 py-10 text-center">
        <span className="text-4xl">📊</span>
        <p className="text-sm text-gray-500 dark:text-gray-400">เพิ่มสมาชิกและรายการก่อน</p>
        <p className="text-xs text-gray-400">Analytics จะแสดงเมื่อมีข้อมูล</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      {/* Summary stats row */}
      <div className="grid grid-cols-3 gap-2">
        <StatCard
          label="รายการทั้งหมด"
          value={items.length.toString()}
          sub="รายการ"
          emoji="🧾"
          color="blue"
        />
        <StatCard
          label="สมาชิก"
          value={members.length.toString()}
          sub="คน"
          emoji="👥"
          color="purple"
        />
        <StatCard
          label="เฉลี่ย/คน"
          value={formatNumber(avgPerPerson, 0)}
          sub="บาท"
          emoji={getTotalEmoji(avgPerPerson)}
          color="green"
        />
      </div>

      {/* Biggest spender highlight */}
      {biggestPayer && (
        <div className="bg-gradient-to-r from-amber-50 to-orange-50 dark:from-amber-900/20 dark:to-orange-900/20 border border-amber-100 dark:border-amber-800/30 rounded-2xl p-4">
          <p className="text-xs font-semibold text-amber-600 dark:text-amber-400 uppercase tracking-wide mb-2">
            🏆 จ่ายเยอะสุด
          </p>
          <div className="flex items-center gap-3">
            <MemberAvatar member={biggestPayer.member} size={40} />
            <div className="flex-1">
              <p className="text-sm font-bold text-gray-900 dark:text-white">{biggestPayer.member.name}</p>
              <p className="text-xs text-gray-500 dark:text-gray-400">{biggestPayer.itemCount} รายการ</p>
            </div>
            <div className="text-right">
              <p className="text-lg font-bold text-amber-600 dark:text-amber-400">
                {formatNumber(biggestPayer.total)} บาท
              </p>
              <p className="text-xs text-gray-400">
                {calc.total > 0 ? Math.round((biggestPayer.total / calc.total) * 100) : 0}% ของบิล
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Member spending bar chart */}
      <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-4 flex flex-col gap-3">
        <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">
          💸 ค่าใช้จ่ายแต่ละคน
        </h3>
        {memberTotals.map(({ member, total }, i) => {
          const pct = maxMemberTotal > 0 ? (total / maxMemberTotal) * 100 : 0;
          const billPct = calc.total > 0 ? Math.round((total / calc.total) * 100) : 0;
          return (
            <div key={member.id} className="flex flex-col gap-1">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  {i === 0 && <span className="text-xs">🥇</span>}
                  {i === 1 && <span className="text-xs">🥈</span>}
                  {i === 2 && <span className="text-xs">🥉</span>}
                  {i > 2 && (
                    <MemberAvatar member={member} size={16} />
                  )}
                  <span className="text-sm font-medium text-gray-700 dark:text-gray-300">{member.name}</span>
                </div>
                <div className="text-right">
                  <span className="text-sm font-bold text-gray-900 dark:text-white">
                    {formatNumber(total)} บาท
                  </span>
                  <span className="text-xs text-gray-400 ml-1">({billPct}%)</span>
                </div>
              </div>
              <div className="h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full transition-all duration-500"
                  style={{
                    width: `${pct}%`,
                    backgroundColor: member.color,
                  }}
                />
              </div>
            </div>
          );
        })}
      </div>

      {/* Top items */}
      {topItems.length > 0 && (
        <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-4 flex flex-col gap-3">
          <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">
            🔥 รายการแพงสุด
          </h3>
          {topItems.map((item, i) => {
            const pct = maxItemPrice > 0 ? (item.price / maxItemPrice) * 100 : 0;
            const sharedCount = Object.keys(item.shares).length;
            return (
              <div key={item.id} className="flex flex-col gap-1">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="text-xs w-4 text-center">
                      {i === 0 ? "🥇" : i === 1 ? "🥈" : i === 2 ? "🥉" : `${i + 1}.`}
                    </span>
                    <span className="text-sm font-medium text-gray-700 dark:text-gray-300 truncate max-w-[140px]">
                      {item.name}
                    </span>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <span className="text-sm font-bold text-gray-900 dark:text-white">
                      {formatNumber(item.price)} บาท
                    </span>
                    {sharedCount > 0 && (
                      <span className="text-xs text-gray-400 ml-1">
                        ({sharedCount} คน)
                      </span>
                    )}
                  </div>
                </div>
                <div className="h-1.5 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-[#4366f4] to-[#6b8aff] rounded-full transition-all duration-500"
                    style={{ width: `${pct}%` }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Fairness insight */}
      {memberTotals.length >= 2 && (
        <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-4 flex flex-col gap-2">
          <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-1">
            ⚖️ ความเท่าเทียม
          </h3>
          <div className="flex items-center justify-between">
            <div className="text-center flex-1">
              <p className="text-xs text-gray-400">จ่ายน้อยสุด</p>
              <p className="text-sm font-bold text-gray-900 dark:text-white mt-0.5">
                {smallestPayer?.member.name}
              </p>
              <p className="text-xs text-[#10b981] font-semibold">
                {formatNumber(smallestPayer?.total ?? 0)} บาท
              </p>
            </div>
            <div className="text-center px-3">
              <div className="text-2xl">
                {biggestPayer && smallestPayer && biggestPayer.total > 0
                  ? biggestPayer.total / (smallestPayer.total || 1) > 3
                    ? "😬"
                    : biggestPayer.total / (smallestPayer.total || 1) > 1.5
                    ? "🤔"
                    : "😊"
                  : "😊"}
              </div>
              <p className="text-[10px] text-gray-400 mt-0.5">
                {biggestPayer && smallestPayer && biggestPayer.total > 0
                  ? `${(biggestPayer.total / (smallestPayer.total || 1)).toFixed(1)}x`
                  : "1x"}
              </p>
            </div>
            <div className="text-center flex-1">
              <p className="text-xs text-gray-400">จ่ายเยอะสุด</p>
              <p className="text-sm font-bold text-gray-900 dark:text-white mt-0.5">
                {biggestPayer?.member.name}
              </p>
              <p className="text-xs text-amber-500 font-semibold">
                {formatNumber(biggestPayer?.total ?? 0)} บาท
              </p>
            </div>
          </div>
          <div className="mt-1 text-center">
            <p className="text-xs text-gray-400">
              เฉลี่ยต่อคน{" "}
              <span className="font-semibold text-gray-600 dark:text-gray-300">
                {formatNumber(avgPerPerson)} บาท
              </span>
            </p>
          </div>
        </div>
      )}

      {/* Items per member */}
      <div className="bg-gray-50 dark:bg-gray-800/60 rounded-2xl p-4 flex flex-col gap-2">
        <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-1">
          📋 รายการต่อคน
        </h3>
        <div className="grid grid-cols-2 gap-2">
          {memberTotals.map(({ member, itemCount }) => (
            <div
              key={member.id}
              className="flex items-center gap-2 bg-white dark:bg-gray-700/50 rounded-xl px-3 py-2"
            >
              <MemberAvatar member={member} size={24} />
              <div className="min-w-0">
                <p className="text-xs font-medium text-gray-700 dark:text-gray-300 truncate">{member.name}</p>
                <p className="text-[10px] text-gray-400">{itemCount} รายการ</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function StatCard({
  label,
  value,
  sub,
  emoji,
  color,
}: {
  label: string;
  value: string;
  sub: string;
  emoji: string;
  color: "blue" | "purple" | "green";
}) {
  const colorMap = {
    blue: "from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 border-blue-100 dark:border-blue-800/30",
    purple: "from-purple-50 to-violet-50 dark:from-purple-900/20 dark:to-violet-900/20 border-purple-100 dark:border-purple-800/30",
    green: "from-emerald-50 to-teal-50 dark:from-emerald-900/20 dark:to-teal-900/20 border-emerald-100 dark:border-emerald-800/30",
  };
  return (
    <div className={`bg-gradient-to-br ${colorMap[color]} border rounded-2xl p-3 flex flex-col gap-1`}>
      <span className="text-xl">{emoji}</span>
      <p className="text-lg font-bold text-gray-900 dark:text-white leading-none">{value}</p>
      <p className="text-[10px] text-gray-500 dark:text-gray-400">{sub}</p>
      <p className="text-[10px] text-gray-400 leading-tight">{label}</p>
    </div>
  );
}
