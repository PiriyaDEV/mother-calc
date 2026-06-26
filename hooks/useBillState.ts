"use client";

import { useCallback, useEffect, useState } from "react";
import { AppState, Bill, BillItem, Member, Settings } from "@/lib/types";
import { DEFAULT_SETTINGS, MEMBER_COLORS, STORAGE_KEY } from "@/lib/constants";
import { decodeState, encodeState, generateId } from "@/lib/utils";

// ============================================================
// Helpers
// ============================================================

function createNewBill(title = "บิลใหม่"): Bill {
  const now = Date.now();
  return {
    id: generateId(),
    title,
    createdAt: now,
    updatedAt: now,
    members: [],
    items: [],
    settings: { ...DEFAULT_SETTINGS },
    tip: 0,
    discount: 0,
  };
}

const EMPTY_APP_STATE: AppState = {
  bills: [],
  activeBillId: null,
};

// ============================================================
// Hook
// ============================================================

export function useBillState() {
  const [appState, setAppState] = useState<AppState>(EMPTY_APP_STATE);
  const [hydrated, setHydrated] = useState(false);

  // ── Load from URL or localStorage after mount ──────────────
  useEffect(() => {
    // Check URL for shared bill
    const params = new URLSearchParams(window.location.search);
    const encoded = params.get("state");
    if (encoded) {
      const decoded = decodeState(encoded);
      if (decoded) {
        setAppState({ bills: [decoded], activeBillId: decoded.id });
        setHydrated(true);
        return;
      }
    }

    // Load from localStorage
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        const parsed = JSON.parse(saved) as AppState;
        // Migrate: if no bills, create one
        if (!parsed.bills || parsed.bills.length === 0) {
          const bill = createNewBill();
          setAppState({ bills: [bill], activeBillId: bill.id });
        } else {
          setAppState(parsed);
        }
      } else {
        // First time — create default bill
        const bill = createNewBill();
        setAppState({ bills: [bill], activeBillId: bill.id });
      }
    } catch {
      const bill = createNewBill();
      setAppState({ bills: [bill], activeBillId: bill.id });
    }
    setHydrated(true);
  }, []);

  // ── Persist to localStorage ────────────────────────────────
  useEffect(() => {
    if (!hydrated) return;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(appState));
    } catch {
      // ignore
    }
  }, [appState, hydrated]);

  // ── Active bill helper ─────────────────────────────────────
  const activeBill: Bill | null =
    appState.bills.find((b) => b.id === appState.activeBillId) ?? null;

  const updateActiveBill = useCallback((updater: (bill: Bill) => Bill) => {
    setAppState((prev) => ({
      ...prev,
      bills: prev.bills.map((b) =>
        b.id === prev.activeBillId
          ? { ...updater(b), updatedAt: Date.now() }
          : b
      ),
    }));
  }, []);

  // ============================================================
  // Bill Management
  // ============================================================

  const createBill = useCallback((title?: string) => {
    const bill = createNewBill(title);
    setAppState((prev) => ({
      bills: [...prev.bills, bill],
      activeBillId: bill.id,
    }));
    return bill.id;
  }, []);

  const switchBill = useCallback((id: string) => {
    setAppState((prev) => ({ ...prev, activeBillId: id }));
  }, []);

  const deleteBill = useCallback((id: string) => {
    setAppState((prev) => {
      const remaining = prev.bills.filter((b) => b.id !== id);
      if (remaining.length === 0) {
        const newBill = createNewBill();
        return { bills: [newBill], activeBillId: newBill.id };
      }
      const newActive =
        prev.activeBillId === id
          ? remaining[remaining.length - 1].id
          : prev.activeBillId;
      return { bills: remaining, activeBillId: newActive };
    });
  }, []);

  const renameBill = useCallback((id: string, title: string) => {
    setAppState((prev) => ({
      ...prev,
      bills: prev.bills.map((b) =>
        b.id === id ? { ...b, title: title.trim() || "บิลใหม่", updatedAt: Date.now() } : b
      ),
    }));
  }, []);

  // ============================================================
  // Member Actions
  // ============================================================

  const addMember = useCallback((name: string, promptpay?: string) => {
    updateActiveBill((bill) => {
      const color = MEMBER_COLORS[bill.members.length % MEMBER_COLORS.length];
      const newMember: Member = {
        id: generateId(),
        name: name.trim(),
        color,
        promptpay: promptpay?.trim() || undefined,
      };
      return { ...bill, members: [...bill.members, newMember] };
    });
  }, [updateActiveBill]);

  const updateMember = useCallback(
    (id: string, name: string, promptpay?: string) => {
      updateActiveBill((bill) => ({
        ...bill,
        members: bill.members.map((m) =>
          m.id === id
            ? { ...m, name: name.trim(), promptpay: promptpay?.trim() || undefined }
            : m
        ),
      }));
    },
    [updateActiveBill]
  );

  const removeMember = useCallback(
    (id: string) => {
      updateActiveBill((bill) => ({
        ...bill,
        members: bill.members.filter((m) => m.id !== id),
        items: bill.items.map((item) => ({
          ...item,
          shares: item.shares.filter((s) => s.memberId !== id),
          selectedMemberIds: item.selectedMemberIds.filter((mid) => mid !== id),
          paidBy: item.paidBy === id ? "" : item.paidBy,
        })),
      }));
    },
    [updateActiveBill]
  );

  // ============================================================
  // Item Actions
  // ============================================================

  const addItem = useCallback(
    (item: Omit<BillItem, "id">) => {
      updateActiveBill((bill) => ({
        ...bill,
        items: [...bill.items, { ...item, id: generateId() }],
      }));
    },
    [updateActiveBill]
  );

  const updateItem = useCallback(
    (id: string, item: Omit<BillItem, "id">) => {
      updateActiveBill((bill) => ({
        ...bill,
        items: bill.items.map((i) => (i.id === id ? { ...item, id } : i)),
      }));
    },
    [updateActiveBill]
  );

  const removeItem = useCallback(
    (id: string) => {
      updateActiveBill((bill) => ({
        ...bill,
        items: bill.items.filter((i) => i.id !== id),
      }));
    },
    [updateActiveBill]
  );

  // ============================================================
  // Settings / Tip / Discount
  // ============================================================

  const updateSettings = useCallback(
    (settings: Settings) => {
      updateActiveBill((bill) => ({ ...bill, settings }));
    },
    [updateActiveBill]
  );

  const updateTipDiscount = useCallback(
    (tip: number, discount: number) => {
      updateActiveBill((bill) => ({ ...bill, tip, discount }));
    },
    [updateActiveBill]
  );

  // ============================================================
  // Reset
  // ============================================================

  const resetAll = useCallback(() => {
    const bill = createNewBill();
    setAppState({ bills: [bill], activeBillId: bill.id });
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      // ignore
    }
  }, []);

  // ============================================================
  // Share URL
  // ============================================================

  const getShareUrl = useCallback(() => {
    if (!activeBill) return window.location.href;
    const encoded = encodeState(activeBill);
    const url = new URL(window.location.href);
    url.searchParams.set("state", encoded);
    return url.toString();
  }, [activeBill]);

  // ============================================================
  // Return
  // ============================================================

  return {
    // app-level
    appState,
    hydrated,
    activeBill,
    // bill management
    createBill,
    switchBill,
    deleteBill,
    renameBill,
    // member
    addMember,
    updateMember,
    removeMember,
    // item
    addItem,
    updateItem,
    removeItem,
    // settings
    updateSettings,
    updateTipDiscount,
    // misc
    resetAll,
    getShareUrl,
  };
}
