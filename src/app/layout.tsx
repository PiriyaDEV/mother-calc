import type { Metadata } from "next";
import BackgroundLayout from "@/components/BackgroundLayout";

import "./globals.css";

export const metadata: Metadata = {
  title: "Mother Calc",
  description: "mother calc",
};

export default function AppLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return <BackgroundLayout>{children}</BackgroundLayout>;
}
