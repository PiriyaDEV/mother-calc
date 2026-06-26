"use client";

import Image from "next/image";
import { useRouter, usePathname } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";

// Pages where the header should NOT appear at all
const HIDDEN_PATHS = ["/", "/auth/callback"];

// Pages where only the logo is shown (no avatar)
const LOGO_ONLY_PATHS = ["/login"];

export default function TopHeader() {
  const router = useRouter();
  const pathname = usePathname();
  const { user } = useAuth();

  // Hide completely on certain paths
  if (HIDDEN_PATHS.includes(pathname)) return null;

  // Logo-only header for login page
  if (LOGO_ONLY_PATHS.includes(pathname)) {
    return (
      <header className="sticky top-0 z-50 bg-white/90 dark:bg-gray-900/90 backdrop-blur-md border-b border-gray-100 dark:border-gray-800">
        <div className="max-w-lg mx-auto px-4 h-14 flex items-center">
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded-xl bg-[#286bfe] flex items-center justify-center flex-shrink-0">
              <Image
                src="/logo.png"
                alt="Kidtang logo"
                width={20}
                height={20}
                priority
              />
            </div>
            <span className="text-lg font-bold text-gray-900 dark:text-white tracking-tight">
              Kidtang!
            </span>
          </div>
        </div>
      </header>
    );
  }

  // Hide when not logged in on other pages
  if (!user) return null;

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
          className="flex items-center gap-2"
        >
          <div className="w-7 h-7 rounded-xl bg-[#286bfe] flex items-center justify-center flex-shrink-0">
            <Image
              src="/logo.png"
              alt="Kidtang logo"
              width={20}
              height={20}
              priority
            />
          </div>
          <span className="text-lg font-bold text-gray-900 dark:text-white tracking-tight">
            Kidtang!
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
