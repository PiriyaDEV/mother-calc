"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { User } from "@supabase/supabase-js";
import { AppState, Bill, BillItem, Member, Settings } from "@/lib/types";
import { DEFAULT_SETTINGS, MEMBER_COLORS } from "@/lib/constants";
import { decodeState, encodeState, generateId } from "@/lib/utils";
import { fetchBills, upsertBill, deleteBillFromDB } from "@/lib/db";

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

export function useBillState(user: User | null = null) {
  const [appState, setAppState] = useState<AppState>(EMPTY_APP_STATE);
  const [hydrated, setHydrated] = useState(false);
  const [syncing, setSyncing] = useState(false);

  // Debounce timer ref for DB writes
  const syncTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  // Track which bills need to be upserted
  const pendingUpsert = useRef<Set<string>>(new Set());

  // ── Load: from URL or Supabase ─────────────────────────────
  useEffect(() => {
    if (!user) {
      // Not logged in — reset state
      setAppState(EMPTY_APP_STATE);
      setHydrated(false);
      return;
    }

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

    // Load from Supabase
    setSyncing(true);
    fetchBills()
      .then((bills) => {
        if (bills.length === 0) {
          const bill = createNewBill();
          setAppState({ bills: [bill], activeBillId: bill.id });
          pendingUpsert.current.add(bill.id);
        } else {
          setAppState({ bills, activeBillId: bills[0].id });
        }
      })
      .catch(() => {
        const bill = createNewBill();
        setAppState({ bills: [bill], activeBillId: bill.id });
      })
      .finally(() => {
        setSyncing(false);
        setHydrated(true);
      });
  }, [user]);

  // ── Persist: Supabase only (debounced) ────────────────────
  useEffect(() => {
    if (!hydrated || !user) return;

    if (syncTimer.current) clearTimeout(syncTimer.current);
    syncTimer.current = setTimeout(() => {
      const ids = Array.from(pendingUpsert.current);
      if (ids.length === 0) return;
      pendingUpsert.current.clear();
      const billsToSync = appState.bills.filter((b) => ids.includes(b.id));
      billsToSync.forEach((bill) => upsertBill(bill, user.id));
    }, 800);
  }, [appState, hydrated, user]);

  // ── Active bill helper ─────────────────────────────────────
  const activeBill: Bill | null =
    appState.bills.find((b) => b.id === appState.activeBillId) ?? null;

  const updateActiveBill = useCallback(
    (updater: (bill: Bill) => Bill) => {
      setAppState((prev) => {
        const updated = prev.bills.map((b) => {
          if (b.id !== prev.activeBillId) return b;
          const next = { ...updater(b), updatedAt: Date.now() };
          pendingUpsert.current.add(next.id);
          return next;
        });
        return { ...prev, bills: updated };
      });
    },
    []
  );

  // ============================================================
  // Bill Management
  // ============================================================

  const createBill = useCallback(
    (title?: string) => {
      const bill = createNewBill(title);
      pendingUpsert.current.add(bill.id);
      setAppState((prev) => ({
        bills: [...prev.bills, bill],
        activeBillId: bill.id,
      }));
      return bill.id;
    },
    []
  );

  const switchBill = useCallback((id: string) => {
    setAppState((prev) => ({ ...prev, activeBillId: id }));
  }, []);

  const deleteBill = useCallback(
    (id: string) => {
      deleteBillFromDB(id);
      setAppState((prev) => {
        const remaining = prev.bills.filter((b) => b.id !== id);
        if (remaining.length === 0) {
          const newBill = createNewBill();
          pendingUpsert.current.add(newBill.id);
          return { bills: [newBill], activeBillId: newBill.id };
        }
        const newActive =
          prev.activeBillId === id
            ? remaining[remaining.length - 1].id
            : prev.activeBillId;
        return { bills: remaining, activeBillId: newActive };
      });
    },
    []
  );

  const renameBill = useCallback((id: string, title: string) => {
    setAppState((prev) => ({
      ...prev,
      bills: prev.bills.map((b) => {
        if (b.id !== id) return b;
        const next = { ...b, title: title.trim() || "บิลใหม่", updatedAt: Date.now() };
        pendingUpsert.current.add(next.id);
        return next;
      }),
    }));
  }, []);

  // ============================================================
  // Member Actions
  // ============================================================

  const addMember = useCallback(
    (name: string, promptpay?: string) => {
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
    },
    [updateActiveBill]
  );

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
    pendingUpsert.current.add(bill.id);
    setAppState({ bills: [bill], activeBillId: bill.id });
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
    syncing,
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
