"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import CommonBtn from "@/components/CommonBtn";
import { isValidInput } from "@/utils";

export default function App() {
  const [search, setSearch] = useState<string>("");
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const router = useRouter();

  const onSearch = async () => {
    if (isValidInput(search)) {
      router.push(`/report?search=${search}`);
      setErrorMsg(null);
    } else {
      setErrorMsg("Please enter a valid email or name and surname.");
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearch(e.target.value);
  };

  return (
    <div className="flex items-center justify-center min-h-screen flex-col gap-10">
      <h1 className="text-[32px] font-bold stroked-text text-center sm:text-[28px] leading-[1.2]">
        <span className="block sm:inline">Welcome to </span>
        <span className="block sm:inline">IBMDT Outing </span>
        <span className="block sm:inline">2025</span>
      </h1>

      <div className="w-full flex items-center justify-center flex-col bg-[rgba(34,17,103,0.4)] gap-6 p-6 rounded-[10px] mb-[100px]">
        <label className="form-control w-full max-w-xs">
          <div className="label">
            <span className="label-text text-base font-medium">
              IBMDT Email / Full name
            </span>
          </div>
          <input
            type="text"
            placeholder="Enter IBMDT Email / Full Name"
            className={`input input-bordered w-full max-w-xs mt-3 ${
              errorMsg ? "border-red-500" : ""
            }`}
            value={search}
            onChange={handleInputChange}
          />
          {errorMsg && <p className="!text-red-500 mt-2">{errorMsg}</p>}
        </label>
        <CommonBtn text="OK" onClick={onSearch} />
      </div>
    </div>
  );
}
