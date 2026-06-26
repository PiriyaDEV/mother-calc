"use client";

import React from "react";

interface InputProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, "prefix"> {
  label?: string;
  error?: string;
  hint?: string;
  prefix?: React.ReactNode;
  suffix?: React.ReactNode;
}

export default function Input({
  label,
  error,
  hint,
  prefix,
  suffix,
  className = "",
  id,
  ...props
}: InputProps) {
  const inputId = id || label?.toLowerCase().replace(/\s+/g, "-");

  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label
          htmlFor={inputId}
          className="text-xs font-medium text-gray-600 dark:text-gray-400"
        >
          {label}
        </label>
      )}
      <div
        className={`flex items-center gap-2 px-3 py-2.5 rounded-xl border transition-colors bg-white dark:bg-gray-800 ${
          error
            ? "border-red-400 focus-within:border-red-500"
            : "border-gray-200 dark:border-gray-700 focus-within:border-[#4366f4]"
        }`}
      >
        {prefix && (
          <span className="text-gray-400 text-sm flex-shrink-0">{prefix}</span>
        )}
        <input
          id={inputId}
          className={`flex-1 text-sm bg-transparent outline-none text-gray-900 dark:text-white placeholder:text-gray-400 ${className}`}
          {...props}
        />
        {suffix && (
          <span className="text-gray-400 text-sm flex-shrink-0">{suffix}</span>
        )}
      </div>
      {error && <p className="text-xs text-red-500">{error}</p>}
      {hint && !error && <p className="text-xs text-gray-400">{hint}</p>}
    </div>
  );
}
