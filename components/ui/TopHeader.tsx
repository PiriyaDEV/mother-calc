"use client";

import { useRouter, usePathname } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";

// Pages where the header should NOT appear
const HIDDEN_PATHS = ["/", "/login", "/auth/callback"];

export default function TopHeader() {
  const router = useRouter();
  const pathname = usePathname();
  const { user } = useAuth();

  // Hide on public/auth pages or when not logged in
  if (!user || HIDDEN_PATHS.includes(pathname)) return null;

  const displayName =
    (user?.user_metadata?.full_name as string | undefined) ||
    user?.email?.split("@")[0] ||
    "";
  const avatarUrl = user?.user_metadata?.avatar_url as string | undefined;
  const initials = displayName.slice(0, 1).toUpperCase() || "?";

  return (
    <header className="sticky top-0 z-50 bg-white/90 dark:bg-gray-900/90 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
      <div className="max-w-lg mx-auto px-4 h-14 flex items-center justify-between">
        {/* Logo */}
        <button
          onClick={() => router.push("/home")}
          className="flex items-center gap-2.5"
        >
          <div className="w-7 h-7 rounded-xl bg-[#4366f4] flex items-center justify-center shadow-sm">
            <span className="text-white text-xs font-bold">฿</span>
          </div>
          <span className="text-lg font-bold text-gray-900 dark:text-white tracking-tight">
            Kidtang
          </span>
        </button>

        {/* Avatar → /me */}
        <button
          onClick={() => router.push("/me")}
          className="w-8 h-8 rounded-full overflow-hidden flex items-center justify-center bg-[#4366f4] text-white text-xs font-bold flex-shrink-0 ring-2 ring-white dark:ring-gray-900"
        >
          {avatarUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={avatarUrl}
              alt={displayName}
              className="w-full h-full object-cover"
            />
          ) : (
            initials
          )}
        </button>
      </div>
    </header>
  );
}
