import type { Metadata } from "next";
import BackgroundLayout from "@/shared/components/BackgroundLayout";

import "./globals.css";

export const metadata: Metadata = {
  title: "Mother Calc",
  description: "แม่ๆคิดเงินให้หน่อย 👩🏻🙏🏻",
  openGraph: {
    images: `https://mother-calc.netlify.app/images/metaImg.png`,
  },
  viewport: {
    width: "device-width",
    initialScale: 1,
    maximumScale: 1,
    userScalable: false,
  },
};

export default function AppLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return <BackgroundLayout>{children}</BackgroundLayout>;
}
