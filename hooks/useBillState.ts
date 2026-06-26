"use client";

import { useState, useEffect, useCallback } from "react";
import { User } from "@supabase/supabase-js";
import { Bill, BillMember, BillItem, Settings } from "@/lib/types";
import {
  getBill,
  getBillMembers,
  getBillItems,
  addBillMember,
  updateBillMember,
  removeBillMember,
  addBillItem,
  updateBillItem,
  removeBillItem,
  updateBill,
  updateBillSettings,
  getMyProfile,
} from "@/lib/db";
import { DEFAULT_SETTINGS, MEMBER_COLORS } from "@/lib/constants";

export function useBillState(billId: string, currentUser?: User | null) {
  const [bill, setBill] = useState<Bill | null>(null);
  const [members, setMembers] = useState<BillMember[]>([]);
  const [items, setItems] = useState<BillItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!billId) return;
    setLoading(true);
    setError(null);
    try {
      const [billData, membersData, itemsData] = await Promise.all([
        getBill(billId),
        getBillMembers(billId),
        getBillItems(billId),
      ]);
      if (!billData) {
        setError("ไม่พบบิล");
        return;
      }
      setBill(billData);

      // Auto-add current user as first member if no members yet
      let finalMembers = membersData;
      if (membersData.length === 0 && currentUser) {
        try {
          const profile = await getMyProfile();
          const displayName =
            profile?.display_name ||
            (currentUser.user_metadata?.full_name as string | undefined) ||
            currentUser.email?.split("@")[0] ||
            "ฉัน";
          const color = MEMBER_COLORS[0];
          const selfMember = await addBillMember({
            bill_id: billId,
            name: displayName,
            color,
            promptpay: undefined,
            user_id: currentUser.id,
            is_external: false,
          });
          finalMembers = [selfMember];
        } catch {
          // silently ignore — user can add manually
        }
      }

      setMembers(finalMembers);
      setItems(itemsData);
    } catch (e) {
      setError(e instanceof Error ? e.message : "เกิดข้อผิดพลาด");
    } finally {
      setLoading(false);
    }
  }, [billId, currentUser]);

  useEffect(() => {
    load();
  }, [load]);

  // ── Bill title ────────────────────────────────────────────
  const updateTitle = async (title: string) => {
    if (!bill) return;
    await updateBill(billId, { title });
    setBill((b) => b ? { ...b, title } : b);
  };

  // ── Bill meta (title + emoji + tags + settings together) ──
  const updateBillMeta = async (opts: {
    title?: string;
    emoji?: string | null;
    tags?: string[];
    settings?: Settings;
  }) => {
    if (!bill) return;
    const updates: Parameters<typeof updateBill>[1] = {};
    if (opts.title !== undefined) updates.title = opts.title;
    if (opts.emoji !== undefined) updates.emoji = opts.emoji;
    if (opts.tags !== undefined) updates.tags = opts.tags;
    if (opts.settings !== undefined) updates.settings = opts.settings;
    await updateBill(billId, updates);
    setBill((b) => b ? { ...b, ...updates } : b);
  };

  // ── Settings ──────────────────────────────────────────────
  const saveSettings = async (settings: Settings, tip: number, discount: number) => {
    await updateBillSettings(billId, settings, tip, discount);
    setBill((b) => b ? { ...b, settings, tip, discount } : b);
  };

  // ── Members ───────────────────────────────────────────────
  const addMember = async (input: {
    name: string;
    color: string;
    promptpay?: string;
    user_id?: string | null;
    is_external?: boolean;
  }) => {
    const member = await addBillMember({
      bill_id: billId,
      name: input.name,
      color: input.color,
      promptpay: input.promptpay,
      user_id: input.user_id ?? null,
      is_external: input.is_external ?? true,
    });
    setMembers((prev) => [...prev, member]);
    return member;
  };

  const editMember = async (
    memberId: string,
    updates: Partial<Pick<BillMember, "name" | "color" | "promptpay">>
  ) => {
    await updateBillMember(memberId, updates);
    setMembers((prev) =>
      prev.map((m) => (m.id === memberId ? { ...m, ...updates } : m))
    );
  };

  const deleteMember = async (memberId: string) => {
    await removeBillMember(memberId);
    setMembers((prev) => prev.filter((m) => m.id !== memberId));
    // Remove member from all item shares
    setItems((prev) =>
      prev.map((item) => {
        const shares = { ...item.shares };
        delete shares[memberId];
        return { ...item, shares };
      })
    );
  };

  // ── Items ─────────────────────────────────────────────────
  const addItem = async (input: {
    name: string;
    price: number;
    shares: Record<string, number>;
    paid_by?: string | null;
  }) => {
    const item = await addBillItem({
      bill_id: billId,
      name: input.name,
      price: input.price,
      shares: input.shares,
      paid_by: input.paid_by ?? null,
    });
    setItems((prev) => [...prev, item]);
    return item;
  };

  const editItem = async (
    itemId: string,
    updates: Partial<Pick<BillItem, "name" | "price" | "shares" | "paid_by">>
  ) => {
    await updateBillItem(itemId, updates);
    setItems((prev) =>
      prev.map((i) => (i.id === itemId ? { ...i, ...updates } : i))
    );
  };

  const deleteItem = async (itemId: string) => {
    await removeBillItem(itemId);
    setItems((prev) => prev.filter((i) => i.id !== itemId));
  };

  // ── Reset ─────────────────────────────────────────────────
  const resetBill = async () => {
    // Delete all members and items, reset settings
    await Promise.all([
      ...members.map((m) => removeBillMember(m.id)),
      ...items.map((i) => removeBillItem(i.id)),
    ]);
    await updateBillSettings(billId, DEFAULT_SETTINGS, 0, 0);
    setMembers([]);
    setItems([]);
    setBill((b) => b ? { ...b, settings: DEFAULT_SETTINGS, tip: 0, discount: 0 } : b);
  };

  const billWithData: Bill | null = bill
    ? { ...bill, members, items }
    : null;

  return {
    bill: billWithData,
    members,
    items,
    loading,
    error,
    reload: load,
    updateTitle,
    updateBillMeta,
    saveSettings,
    addMember,
    editMember,
    deleteMember,
    addItem,
    editItem,
    deleteItem,
    resetBill,
    setBill,
  };
}
