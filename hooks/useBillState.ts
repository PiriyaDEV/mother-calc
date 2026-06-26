"use client";

import { useCallback, useEffect, useState } from "react";
import { BillItem, BillState, Member, Settings } from "@/lib/types";
import { DEFAULT_SETTINGS, MEMBER_COLORS } from "@/lib/constants";
import { decodeState, encodeState, generateId } from "@/lib/utils";

const STORAGE_KEY = "kidtang_state";

function getInitialState(): BillState {
  if (typeof window === "undefined") {
    return { members: [], items: [], settings: DEFAULT_SETTINGS };
  }
  // ลอง load จาก URL param ก่อน
  const params = new URLSearchParams(window.location.search);
  const encoded = params.get("state");
  if (encoded) {
    const decoded = decodeState(encoded);
    if (decoded) return decoded;
  }
  // ลอง load จาก localStorage
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) return JSON.parse(saved) as BillState;
  } catch {
    // ignore
  }
  return { members: [], items: [], settings: DEFAULT_SETTINGS };
}

export function useBillState() {
  const [state, setState] = useState<BillState>(getInitialState);

  // Persist to localStorage whenever state changes
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch {
      // ignore
    }
  }, [state]);

  // ============================================================
  // Member Actions
  // ============================================================

  const addMember = useCallback((name: string, promptpay?: string) => {
    setState((prev) => {
      const color = MEMBER_COLORS[prev.members.length % MEMBER_COLORS.length];
      const newMember: Member = {
        id: generateId(),
        name: name.trim(),
        color,
        promptpay: promptpay?.trim() || undefined,
      };
      return { ...prev, members: [...prev.members, newMember] };
    });
  }, []);

  const updateMember = useCallback(
    (id: string, name: string, promptpay?: string) => {
      setState((prev) => ({
        ...prev,
        members: prev.members.map((m) =>
          m.id === id
            ? { ...m, name: name.trim(), promptpay: promptpay?.trim() || undefined }
            : m
        ),
      }));
    },
    []
  );

  const removeMember = useCallback((id: string) => {
    setState((prev) => ({
      ...prev,
      members: prev.members.filter((m) => m.id !== id),
      // ลบ shares ของ member นี้ออกจากทุก item
      items: prev.items.map((item) => ({
        ...item,
        shares: item.shares.filter((s) => s.memberId !== id),
        paidBy: item.paidBy === id ? "" : item.paidBy,
      })),
    }));
  }, []);

  // ============================================================
  // Item Actions
  // ============================================================

  const addItem = useCallback((item: Omit<BillItem, "id">) => {
    setState((prev) => ({
      ...prev,
      items: [...prev.items, { ...item, id: generateId() }],
    }));
  }, []);

  const updateItem = useCallback((id: string, item: Omit<BillItem, "id">) => {
    setState((prev) => ({
      ...prev,
      items: prev.items.map((i) => (i.id === id ? { ...item, id } : i)),
    }));
  }, []);

  const removeItem = useCallback((id: string) => {
    setState((prev) => ({
      ...prev,
      items: prev.items.filter((i) => i.id !== id),
    }));
  }, []);

  // ============================================================
  // Settings Actions
  // ============================================================

  const updateSettings = useCallback((settings: Settings) => {
    setState((prev) => ({ ...prev, settings }));
  }, []);

  // ============================================================
  // Reset
  // ============================================================

  const resetAll = useCallback(() => {
    const fresh: BillState = {
      members: [],
      items: [],
      settings: DEFAULT_SETTINGS,
    };
    setState(fresh);
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      // ignore
    }
  }, []);

  // ============================================================
  // Share URL
  // ============================================================

  const getShareUrl = useCallback(
    (mode: "view" | "edit" = "edit") => {
      const encoded = encodeState(state);
      const url = new URL(window.location.href);
      url.searchParams.set("state", encoded);
      url.searchParams.set("mode", mode);
      return url.toString();
    },
    [state]
  );

  return {
    state,
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
    // misc
    resetAll,
    getShareUrl,
  };
}
