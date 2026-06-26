"use client";

interface ToggleProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label?: string;
  size?: "sm" | "md";
}

export default function Toggle({
  checked,
  onChange,
  label,
  size = "md",
}: ToggleProps) {
  const trackSize = size === "sm" ? "w-8 h-4" : "w-10 h-5";
  const thumbSize = size === "sm" ? "w-3 h-3" : "w-4 h-4";
  const thumbTranslate = size === "sm" ? "translate-x-4" : "translate-x-5";

  return (
    <label className="flex items-center gap-2 cursor-pointer select-none">
      {label && (
        <span className="text-sm text-gray-700 dark:text-gray-300">{label}</span>
      )}
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        onClick={() => onChange(!checked)}
        className={`relative inline-flex items-center ${trackSize} rounded-full transition-colors duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#4366f4] ${
          checked ? "bg-[#4366f4]" : "bg-gray-200 dark:bg-gray-700"
        }`}
      >
        <span
          className={`${thumbSize} bg-white rounded-full shadow-sm transition-transform duration-200 ml-0.5 ${
            checked ? thumbTranslate : "translate-x-0"
          }`}
        />
      </button>
    </label>
  );
}
