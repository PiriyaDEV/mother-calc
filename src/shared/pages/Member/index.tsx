"use client";

import { useState } from "react";
import { TiDelete } from "react-icons/ti";

import CommonBtn from "@/shared/components/CommonBtn";
import type { Member } from "@/interface";
import { MEMBER_COLORS } from "./constants";

interface MemberProps {
  members: Member[];
  setMembers: React.Dispatch<React.SetStateAction<Member[]>>;
}

export default function Member({ members, setMembers }: MemberProps) {
  const [name, setName] = useState("");
  const [error, setError] = useState(false);

  const getRandomColor = () =>
    MEMBER_COLORS[Math.floor(Math.random() * MEMBER_COLORS.length)];

  const addMember = () => {
    const trimmed = name.trim();
    if (!trimmed) return setError(true);
    setMembers([...members, { name: trimmed, color: getRandomColor() }]);
    setName("");
    setError(false);
  };

  const removeMember = (index: number) =>
    setMembers(members.filter((_, i) => i !== index));

  return (
    <div className="flex flex-col gap-10">
      <div className="flex gap-4 flex-wrap w-full">
        {members.length ? (
          members.map((m, i) => (
            <div
              key={i}
              className="relative w-16 h-16 rounded-full flex justify-center items-center"
              style={{ backgroundColor: m.color }}
            >
              <span className="text-xs font-semibold truncate text-white">
                {m.name}
              </span>
              <div
                className="bg-white rounded-full absolute -top-1 -right-1 h-5 w-5 flex justify-center items-center cursor-pointer"
                onClick={() => removeMember(i)}
              >
                <TiDelete className="text-red text-xl" />
              </div>
            </div>
          ))
        ) : (
          <span className="text-sm text-center w-full">ยังไม่มีสมาชิก</span>
        )}
      </div>

      <div className="absolute bottom-0 left-0 bg-white py-5 w-full">
        <div className="container mx-auto px-6 flex flex-col gap-7">
          <div className="flex items-center justify-center gap-2">
            <input
              type="text"
              placeholder="ใส่ชื่อสมาชิก"
              className={`input input-bordered w-full ${
                error ? "border-red-500" : ""
              }`}
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                setError(false);
              }}
              onKeyDown={(e) => e.key === "Enter" && addMember()}
            />
            <CommonBtn text="เพิ่ม" onClick={addMember} className="!w-fit" />
          </div>
          <CommonBtn
            text="ไปต่อ >"
            onClick={addMember}
            className="!max-w-none"
          />
        </div>
      </div>
    </div>
  );
}
