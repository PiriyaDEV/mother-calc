"use client";

import { useEffect, useState } from "react";
import {
  IoPeople,
  IoReceipt,
  IoBarChart,
  IoSettings,
  IoList,
  IoMoon,
  IoSunny,
} from "react-icons/io5";
import { AppTab } from "@/lib/types";
import { useBillState } from "@/hooks/useBillState";
import { formatCurrency, getBillTotal } from "@/lib/utils";
import MemberPage from "@/components/members/MemberPage";
import ItemPage from "@/components/items/ItemPage";
import SummaryPage from "@/components/summary/SummaryPage";
import SettingsModal from "@/components/settings/SettingsModal";
import BillsDrawer from "@/components/bills/BillsDrawer";

const TABS: { id: AppTab; label: string; icon: React.ReactNode }[] = [
  { id: "members", label: "สมาชิก", icon: <IoPeople size={20} /> },
  { id: "items", label: "รายการ", icon: <IoReceipt size={20} /> },
  { id: "summary", label: "สรุป", icon: <IoBarChart size={20} /> },
];

export default function Home() {
  const [activeTab, setActiveTab] = useState<AppTab>("members");
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [billsOpen, setBillsOpen] = useState(false);
  const [darkMode, setDarkMode] = useState(false);

  const {
    appState,
    hydrated,
    activeBill,
    createBill,
    switchBill,
    deleteBill,
    renameBill,
    addMember,
    updateMember,
    removeMember,
    addItem,
    updateItem,
    removeItem,
    updateSettings,
    updateTipDiscount,
    resetAll,
    getShareUrl,
  } = useBillState();

  // Dark mode: sync with system preference on first load
  useEffect(() => {
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    const saved = localStorage.getItem("kidtang_dark");
    const isDark = saved !== null ? saved === "true" : prefersDark;
    setDarkMode(isDark);
    document.documentElement.classList.toggle("dark", isDark);
  }, []);

  const toggleDark = () => {
    const next = !darkMode;
    setDarkMode(next);
    document.documentElement.classList.toggle("dark", next);
    localStorage.setItem("kidtang_dark", String(next));
  };

  const bill = activeBill;
  const total = bill ? getBillTotal(bill) : 0;
  const memberCount = bill?.members.length ?? 0;
  const itemCount = bill?.items.length ?? 0;

  const getBadge = (tab: AppTab) => {
    if (!bill) return 0;
    if (tab === "members") return memberCount;
    if (tab === "items") return itemCount;
    return 0;
  };

  return (
    <div className="min-h-screen flex flex-col bg-[#f8f9fc] dark:bg-gray-950">
      {/* Top bar */}
      <header className="sticky top-0 z-40 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
        <div className="max-w-lg mx-auto px-4 h-14 flex items-center gap-3">
          {/* Bills button */}
          <button
            onClick={() => setBillsOpen(true)}
            className="w-9 h-9 flex items-center justify-center rounded-xl hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400 transition-colors"
          >
            <IoList size={18} />
          </button>

          {/* Logo + Bill title */}
          <div className="flex-1 flex items-center gap-2 min-w-0">
            <div className="w-7 h-7 rounded-lg bg-[#4366f4] flex items-center justify-center flex-shrink-0">
              <span className="text-white text-xs font-bold">฿</span>
            </div>
            <div className="min-w-0">
              <p className="text-sm font-bold text-gray-900 dark:text-white truncate leading-tight">
                {bill?.title || "Kidtang"}
              </p>
              {appState.bills.length > 1 && (
                <p className="text-[10px] text-gray-400 leading-tight">
                  {appState.bills.length} บิล
                </p>
              )}
            </div>
          </div>

          {/* Dark mode toggle */}
          <button
            onClick={toggleDark}
            className="w-9 h-9 flex items-center justify-center rounded-xl hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400 transition-colors"
          >
            {darkMode ? <IoSunny size={18} /> : <IoMoon size={18} />}
          </button>

          {/* Settings */}
          <button
            onClick={() => setSettingsOpen(true)}
            className="w-9 h-9 flex items-center justify-center rounded-xl hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400 transition-colors"
          >
            <IoSettings size={18} />
          </button>
        </div>
      </header>

      {/* Content */}
      <main className="flex-1 max-w-lg mx-auto w-full px-4 py-5 pb-36">
        {!hydrated ? (
          /* Skeleton */
          <div className="flex flex-col gap-3 animate-pulse">
            <div className="h-8 w-32 bg-gray-200 dark:bg-gray-800 rounded-xl" />
            <div className="h-16 bg-gray-100 dark:bg-gray-800 rounded-2xl" />
            <div className="h-16 bg-gray-100 dark:bg-gray-800 rounded-2xl" />
          </div>
        ) : bill ? (
          <>
            {activeTab === "members" && (
              <MemberPage
                members={bill.members}
                onAdd={addMember}
                onUpdate={updateMember}
                onRemove={removeMember}
              />
            )}
            {activeTab === "items" && (
              <ItemPage
                items={bill.items}
                members={bill.members}
                settings={bill.settings}
                onAdd={addItem}
                onUpdate={updateItem}
                onRemove={removeItem}
              />
            )}
            {activeTab === "summary" && (
              <SummaryPage bill={bill} getShareUrl={getShareUrl} />
            )}
          </>
        ) : null}
      </main>

      {/* Total summary bar (sticky above bottom nav) */}
      {hydrated && bill && itemCount > 0 && (
        <div className="fixed bottom-16 left-0 right-0 z-30">
          <div className="max-w-lg mx-auto px-4 pb-1">
            <div className="bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 rounded-2xl shadow-lg px-4 py-2.5 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="flex -space-x-1.5">
                  {bill.members.slice(0, 4).map((m) => (
                    <div
                      key={m.id}
                      className="w-6 h-6 rounded-full border-2 border-white dark:border-gray-900 flex items-center justify-center text-white text-[9px] font-bold"
                      style={{ backgroundColor: m.color }}
                    >
                      {m.name.slice(0, 1).toUpperCase()}
                    </div>
                  ))}
                  {memberCount > 4 && (
                    <div className="w-6 h-6 rounded-full border-2 border-white dark:border-gray-900 bg-gray-200 dark:bg-gray-700 flex items-center justify-center text-[9px] text-gray-600 dark:text-gray-300 font-bold">
                      +{memberCount - 4}
                    </div>
                  )}
                </div>
                <span className="text-xs text-gray-500 dark:text-gray-400">
                  {itemCount} รายการ
                </span>
              </div>
              <div className="text-right">
                <p className="text-xs text-gray-400">รวม</p>
                <p className="text-sm font-bold text-gray-900 dark:text-white">
                  {formatCurrency(total, bill.settings.currency)}
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Bottom navigation */}
      <nav className="fixed bottom-0 left-0 right-0 z-40 bg-white/90 dark:bg-gray-900/90 backdrop-blur-md border-t border-gray-100 dark:border-gray-800">
        <div className="max-w-lg mx-auto px-2 h-16 flex items-center">
          {TABS.map((tab) => {
            const isActive = activeTab === tab.id;
            const badge = getBadge(tab.id);
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`relative flex-1 flex flex-col items-center justify-center gap-0.5 h-full transition-colors ${
                  isActive
                    ? "text-[#4366f4]"
                    : "text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-400"
                }`}
              >
                <span
                  className={`relative transition-transform duration-150 ${
                    isActive ? "scale-110" : "scale-100"
                  }`}
                >
                  {tab.icon}
                  {/* Badge */}
                  {badge > 0 && (
                    <span className="absolute -top-1.5 -right-2 min-w-[16px] h-4 px-1 bg-[#4366f4] text-white text-[9px] font-bold rounded-full flex items-center justify-center">
                      {badge}
                    </span>
                  )}
                </span>
                <span
                  className={`text-[10px] font-medium ${
                    isActive ? "text-[#4366f4]" : "text-gray-400 dark:text-gray-500"
                  }`}
                >
                  {tab.label}
                </span>
                {isActive && (
                  <span className="absolute bottom-1 w-1 h-1 rounded-full bg-[#4366f4]" />
                )}
              </button>
            );
          })}
        </div>
      </nav>

      {/* Settings Modal */}
      {bill && (
        <SettingsModal
          isOpen={settingsOpen}
          settings={bill.settings}
          tip={bill.tip}
          discount={bill.discount}
          onSave={updateSettings}
          onTipDiscount={updateTipDiscount}
          onClose={() => setSettingsOpen(false)}
          onReset={resetAll}
        />
      )}

      {/* Bills Drawer */}
      <BillsDrawer
        isOpen={billsOpen}
        onClose={() => setBillsOpen(false)}
        bills={appState.bills}
        activeBillId={appState.activeBillId}
        onSwitch={switchBill}
        onCreate={createBill}
        onDelete={deleteBill}
        onRename={renameBill}
      />
    </div>
  );
}
