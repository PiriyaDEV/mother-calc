"use client";

import { useState, useEffect, useCallback } from "react";
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
} from "@/lib/db";
import { DEFAULT_SETTINGS } from "@/lib/constants";

export function useBillState(billId: string) {
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
      setMembers(membersData);
      setItems(itemsData);
    } catch (e) {
      setError(e instanceof Error ? e.message : "เกิดข้อผิดพลาด");
    } finally {
      setLoading(false);
    }
  }, [billId]);

  useEffect(() => {
    load();
  }, [load]);

  // ── Bill title ────────────────────────────────────────────
  const updateTitle = async (title: string) => {
    if (!bill) return;
    await updateBill(billId, { title });
    setBill((b) => b ? { ...b, title } : b);
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
  }) => {
    const item = await addBillItem({
      bill_id: billId,
      name: input.name,
      price: input.price,
      shares: input.shares,
    });
    setItems((prev) => [...prev, item]);
    return item;
  };

  const editItem = async (
    itemId: string,
    updates: Partial<Pick<BillItem, "name" | "price" | "shares">>
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
    saveSettings,
    addMember,
    editMember,
    deleteMember,
    addItem,
    editItem,
    deleteItem,
    resetBill,
  };
}
