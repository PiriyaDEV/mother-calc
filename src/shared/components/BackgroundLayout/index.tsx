import { FC } from "react";
import { IBM_Plex_Sans } from "next/font/google";
import type { Metadata } from "next";

interface BackgroundLayoutProps {
  children: React.ReactNode;
}

const ibmPlexSans = IBM_Plex_Sans({
  weight: ["300", "400", "500", "700"],
  style: ["normal", "italic"],
  variable: "--font-ibm-plex-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "IBMDT Outing 2025",
  description: "Welcome to IBMDT Outing 2025",
};

const BackgroundLayout: FC<BackgroundLayoutProps> = ({ children }) => {
  return (
    <html lang="en">
      <body className={`${ibmPlexSans.variable} antialiased`}>
        <div className="min-h-screen bg-cover bg-center bg-[url('../../public/images/mobileBg.png')] sm:bg-[url('../../public/images/desktopBg.png')]">
          <div className="container mx-auto px-6">{children}</div>
        </div>
      </body>
    </html>
  );
};

export default BackgroundLayout;
