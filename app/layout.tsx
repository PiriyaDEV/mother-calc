import type { Metadata, Viewport } from "next";
import "./globals.css";
import TopHeader from "@/components/ui/TopHeader";

export const metadata: Metadata = {
  title: "Kidtang — หารบิลง่ายๆ",
  description: "แอปหารบิล คิดเงิน แบ่งค่าใช้จ่าย รองรับ VAT และ Service Charge",
  icons: {
    icon: "/favicon.ico",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="th" className="h-full">
      <body className="min-h-full flex flex-col antialiased">
        <TopHeader />
        {children}
      </body>
    </html>
  );
}
