import type { Metadata, Viewport } from "next";
import "./globals.css";
import TopHeader from "@/components/ui/TopHeader";

export const metadata: Metadata = {
  title: "Kidtang! - มาจ่ายเงินกัน",
  description: "แอปหารบิล คิดเงิน แบ่งค่าใช้จ่าย รองรับ VAT และ Service Charge",
  applicationName: "Kidtang!",
  keywords: ["หารบิล", "คิดเงิน", "แบ่งค่าใช้จ่าย", "bill splitter", "VAT", "service charge"],
  authors: [{ name: "Kidtang" }],
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "any" },
      { url: "/icon.png", type: "image/png" },
      { url: "/icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [
      { url: "/apple-icon.png", type: "image/png" },
    ],
  },
  appleWebApp: {
    capable: true,
    title: "Kidtang!",
    statusBarStyle: "default",
  },
  formatDetection: {
    telephone: false,
  },
  openGraph: {
    type: "website",
    title: "Kidtang! - มาจ่ายเงินกัน",
    description: "แอปหารบิล คิดเงิน แบ่งค่าใช้จ่าย รองรับ VAT และ Service Charge",
    siteName: "Kidtang!",
    images: [{ url: "/icon-512.png" }],
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  themeColor: "#4366f4",
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
