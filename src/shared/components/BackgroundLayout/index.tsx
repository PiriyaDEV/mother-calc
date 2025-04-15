import { FC } from "react";
import { Sarabun } from "next/font/google";
import type { Metadata } from "next";

interface BackgroundLayoutProps {
  children: React.ReactNode;
}

const sarabun = Sarabun({
  weight: ["100", "200", "300", "400", "500", "600", "700", "800"],
  style: ["normal", "italic"],
  subsets: ["thai", "latin"],
  variable: "--font-sarabun",
});

export const metadata: Metadata = {
  title: "IBMDT Outing 2025",
  description: "Welcome to IBMDT Outing 2025",
};

const BackgroundLayout: FC<BackgroundLayoutProps> = ({ children }) => {
  return (
    <html lang="en" className={sarabun.variable}>
      <body className="antialiased">
        <div className="bg-cover bg-center">
          <div className="text-center font-bold py-4 mb-2 text-[22px] text-[#4366f4]">
            แม่ๆ คิดเงินให้หน่อย
          </div>
          <div className="container mx-auto px-6">{children}</div>
        </div>
      </body>
    </html>
  );
};

export default BackgroundLayout;
