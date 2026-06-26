"use client";

import { usePathname, useRouter } from "next/navigation";
import {
  IoHomeOutline,
  IoHome,
  IoReceiptOutline,
  IoReceipt,
  IoPeopleOutline,
  IoPeopleSharp,
  IoPeopleCircleOutline,
  IoPeople,
  IoPersonOutline,
  IoPerson,
} from "react-icons/io5";

type HomeTab = "home" | "bills" | "groups" | "friends" | "me";

interface BottomNavProps {
  friendBadge?: number;
}

const ITEMS: { id: HomeTab; label: string; path: string; icon: React.ReactNode; activeIcon: React.ReactNode }[] = [
  { id: "home", label: "หน้าหลัก", path: "/home", icon: <IoHomeOutline size={22} />, activeIcon: <IoHome size={22} /> },
  { id: "bills", label: "บิลของฉัน", path: "/bills", icon: <IoReceiptOutline size={22} />, activeIcon: <IoReceipt size={22} /> },
  { id: "groups", label: "กลุ่ม", path: "/groups", icon: <IoPeopleOutline size={22} />, activeIcon: <IoPeopleSharp size={22} /> },
  { id: "friends", label: "เพื่อน", path: "/friends", icon: <IoPeopleCircleOutline size={22} />, activeIcon: <IoPeople size={22} /> },
  { id: "me", label: "ฉัน", path: "/me", icon: <IoPersonOutline size={22} />, activeIcon: <IoPerson size={22} /> },
];

export default function BottomNav({ friendBadge = 0 }: BottomNavProps) {
  const router = useRouter();
  const pathname = usePathname();

  // Determine active tab from pathname
  const resolvedActive: HomeTab =
    pathname === "/home" || pathname === "/" ? "home" :
    pathname.startsWith("/bills") ? "bills" :
    pathname.startsWith("/groups") ? "groups" :
    pathname.startsWith("/friends") ? "friends" :
    pathname.startsWith("/me") || pathname.startsWith("/profile") ? "me" :
    pathname.startsWith("/app") ? "bills" :
    "home";

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-white/95 dark:bg-gray-900/95 backdrop-blur-md border-t border-gray-100 dark:border-gray-800 safe-area-pb">
      <div className="max-w-lg mx-auto flex items-center">
        {ITEMS.map((item) => {
          const isActive = item.id === resolvedActive;
          return (
            <button
              key={item.id}
              onClick={() => router.push(item.path)}
              className={`flex-1 flex flex-col items-center gap-0.5 py-2.5 transition-colors relative ${
                isActive ? "text-[#4366f4]" : "text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
              }`}
            >
              {isActive ? item.activeIcon : item.icon}
              <span className="text-[10px] font-medium">{item.label}</span>
              {item.id === "friends" && friendBadge > 0 && (
                <span className="absolute top-2 right-[calc(50%-14px)] w-4 h-4 bg-red-500 text-white text-[9px] font-bold rounded-full flex items-center justify-center">
                  {friendBadge > 9 ? "9+" : friendBadge}
                </span>
              )}
            </button>
          );
        })}
      </div>
    </nav>
  );
}
