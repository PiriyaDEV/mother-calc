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
  title: "Mother Calc",
  description: "แม่ๆคิดเงินให้หน่อย 👩🏻🙏🏻",
  openGraph: {
    images: `https://mother-calc.netlify.app/images/metaImg.png`,
  },
};

const BackgroundLayout: FC<BackgroundLayoutProps> = ({ children }) => {
  return (
    <html lang="en" className={`${sarabun.variable} h-full`}>
      <body className="antialiased h-full">
        <div className="bg-cover bg-center overflow-hidden flex flex-col">
          <div className="text-center font-bold py-4 mb-2 text-[22px] text-[#4366f4]">
            แม่ๆ คิดเงินให้หน่อย
            <div className="text-xs text-center text-[#c5c6c7]">
              Made by @pd.piriya 🤪✨
            </div>
          </div>
          <div className="container mx-auto px-4 flex-grow">{children}</div>
        </div>
      </body>
    </html>
  );
};


export default BackgroundLayout;
