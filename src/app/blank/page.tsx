"use client";

import CommonBtn from "@/shared/components/CommonBtn";
import { useRouter } from "next/navigation";
import { PiSmileySadLight } from "react-icons/pi";

export default function Blank() {
  const router = useRouter();

  return (
    <div className="flex flex-col items-center justify-center min-h-screen gap-6">
      <PiSmileySadLight className="text-8xl" />

      <p className="text-base font-medium text-center">
        Sorry your registration was not <br className="sm:hidden" /> found
        please contact
      </p>

      <span className="text-2xl font-bold text-center">
        <span className="underline">touchano@th.ibm.com</span> <br />
        via slack
      </span>

      <CommonBtn
        text="Go to Mainpage"
        onClick={() => {
          router.push("/");
        }}
        className="min-w-full"
      />
    </div>
  );
}
