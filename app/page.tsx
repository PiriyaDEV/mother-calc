"use client";

import { useState } from "react";
import {
  IoPeople,
  IoReceipt,
  IoBarChart,
  IoWallet,
  IoSettings,
} from "react-icons/io5";
import { AppTab } from "@/lib/types";
import { useBillState } from "@/hooks/useBillState";
import MemberPage from "@/components/members/MemberPage";
import ItemPage from "@/components/items/ItemPage";
import SummaryPage from "@/components/summary/SummaryPage";
import PaymentPage from "@/components/payment/PaymentPage";
import SettingsModal from "@/components/settings/SettingsModal";

const TABS: { id: AppTab; label: string; icon: React.ReactNode }[] = [
  { id: "members", label: "สมาชิก", icon: <IoPeople size={20} /> },
  { id: "items", label: "รายการ", icon: <IoReceipt size={20} /> },
  { id: "summary", label: "สรุป", icon: <IoBarChart size={20} /> },
  { id: "payment", label: "ชำระ", icon: <IoWallet size={20} /> },
];

export default function Home() {
  const [activeTab, setActiveTab] = useState<AppTab>("members");
  const [settingsOpen, setSettingsOpen] = useState(false);

  const {
    state,
    addMember,
    updateMember,
    removeMember,
    addItem,
    updateItem,
    removeItem,
    updateSettings,
    resetAll,
    getShareUrl,
  } = useBillState();

  return (
    <div className="min-h-screen flex flex-col bg-[#f8f9fc]">
      {/* Top bar */}
      <header className="sticky top-0 z-40 bg-white/80 backdrop-blur-md border-b border-gray-100">
        <div className="max-w-lg mx-auto px-4 h-14 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded-lg bg-[#4366f4] flex items-center justify-center">
              <span className="text-white text-xs font-bold">฿</span>
            </div>
            <span className="text-base font-bold text-gray-900">Kidtang</span>
          </div>
          <button
            onClick={() => setSettingsOpen(true)}
            className="w-9 h-9 flex items-center justify-center rounded-xl hover:bg-gray-100 text-gray-500 transition-colors"
          >
            <IoSettings size={18} />
          </button>
        </div>
      </header>

      {/* Content */}
      <main className="flex-1 max-w-lg mx-auto w-full px-4 py-5 pb-28">
        {activeTab === "members" && (
          <MemberPage
            members={state.members}
            onAdd={addMember}
            onUpdate={updateMember}
            onRemove={removeMember}
          />
        )}
        {activeTab === "items" && (
          <ItemPage
            items={state.items}
            members={state.members}
            settings={state.settings}
            onAdd={addItem}
            onUpdate={updateItem}
            onRemove={removeItem}
          />
        )}
        {activeTab === "summary" && <SummaryPage state={state} />}
        {activeTab === "payment" && (
          <PaymentPage state={state} getShareUrl={getShareUrl} />
        )}
      </main>

      {/* Bottom navigation */}
      <nav className="fixed bottom-0 left-0 right-0 z-40 bg-white/90 backdrop-blur-md border-t border-gray-100">
        <div className="max-w-lg mx-auto px-2 h-16 flex items-center">
          {TABS.map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex-1 flex flex-col items-center justify-center gap-0.5 h-full transition-colors ${
                  isActive ? "text-[#4366f4]" : "text-gray-400 hover:text-gray-600"
                }`}
              >
                <span
                  className={`transition-transform duration-150 ${
                    isActive ? "scale-110" : "scale-100"
                  }`}
                >
                  {tab.icon}
                </span>
                <span
                  className={`text-[10px] font-medium ${
                    isActive ? "text-[#4366f4]" : "text-gray-400"
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
      <SettingsModal
        isOpen={settingsOpen}
        settings={state.settings}
        onSave={updateSettings}
        onClose={() => setSettingsOpen(false)}
        onReset={resetAll}
      />
    </div>
  );
}
