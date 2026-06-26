import { Settings } from "./types";

export const MEMBER_COLORS = [
  "#4366f4", // blue
  "#f43f5e", // rose
  "#10b981", // emerald
  "#f59e0b", // amber
  "#8b5cf6", // violet
  "#06b6d4", // cyan
  "#ec4899", // pink
  "#84cc16", // lime
  "#f97316", // orange
  "#6366f1", // indigo
  "#14b8a6", // teal
  "#ef4444", // red
  "#a855f7", // purple
  "#22c55e", // green
  "#eab308", // yellow
  "#3b82f6", // blue-500
  "#d946ef", // fuchsia
  "#0ea5e9", // sky
  "#78716c", // stone
  "#64748b", // slate
];

export const DEFAULT_SETTINGS: Settings = {
  vat: 7,
  serviceCharge: 10,
  isVat: false,
  isService: false,
  roundingMode: "none",
  currency: "THB",
};

export const THAI_PHONE_REGEX = /^(0[689]\d{8}|02\d{7})$/;
export const THAI_ID_REGEX = /^\d{13}$/;

export const STORAGE_KEY = "kidtang_app_state";

// ── Feature Flags ──────────────────────────────────────────
export const FEATURES = {
  /** Set to true to show Google sign-in button on login page */
  GOOGLE_LOGIN: false,
} as const;
