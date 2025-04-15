import type { Metadata } from "next";
import BackgroundLayout from "@/shared/components/BackgroundLayout";

import "./globals.css";

export const metadata: Metadata = {
  title: "Mother Calc",
  description: "แม่ๆคิดเงินให้หน่อย 👩🏻🙏🏻",
  openGraph: {
    images: "/public/images/metaImg.png",
  },
};

export default function AppLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return <BackgroundLayout>{children}</BackgroundLayout>;
}
