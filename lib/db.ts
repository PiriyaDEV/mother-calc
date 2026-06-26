/**
 * lib/db.ts
 * Supabase database helpers for bills CRUD.
 * Each bill is stored as a single JSONB row in the `bills` table.
 */

import { createClient } from "@/lib/supabase";
import { Bill } from "@/lib/types";

// ── Row shape from Supabase ──────────────────────────────────
interface BillRow {
  id: string;
  user_id: string;
  title: string;
  data: Bill;
  created_at: string;
  updated_at: string;
}

// ── Fetch all bills for the current user ─────────────────────
export async function fetchBills(): Promise<Bill[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("bills")
    .select("data")
    .order("updated_at", { ascending: false });

  if (error) {
    console.error("[db] fetchBills error:", error.message);
    return [];
  }

  return (data as Pick<BillRow, "data">[]).map((row) => row.data as Bill);
}

// ── Upsert (insert or update) a single bill ──────────────────
export async function upsertBill(bill: Bill, userId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.from("bills").upsert(
    {
      id: bill.id,
      user_id: userId,
      title: bill.title,
      data: bill,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "id" }
  );

  if (error) {
    console.error("[db] upsertBill error:", error.message);
  }
}

// ── Delete a bill ─────────────────────────────────────────────
export async function deleteBillFromDB(billId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.from("bills").delete().eq("id", billId);

  if (error) {
    console.error("[db] deleteBill error:", error.message);
  }
}
