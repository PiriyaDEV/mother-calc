"use client";

import { useState } from "react";
import { TiDelete } from "react-icons/ti";

import CommonBtn from "@/shared/components/CommonBtn";
import { MEMBER_COLORS } from "@/app/lib/constants";
import { MemberObj } from "@/app/lib/interface";
import ConfirmPopup from "@/shared/components/ConfirmPopup";

interface MemberProps {
  members: MemberObj[];
  setMembers: React.Dispatch<React.SetStateAction<MemberObj[]>>;
  setIsMemberSet: React.Dispatch<React.SetStateAction<boolean>>;
  onDeleteMember: (memberToDelete: MemberObj) => void;
}

export default function Member({
  members,
  setMembers,
  setIsMemberSet,
  onDeleteMember,
}: MemberProps) {
  const [name, setName] = useState("");
  const [error, setError] = useState(false);
  const [confirmDeleteIndex, setConfirmDeleteIndex] = useState<number | null>(
    null
  );

  const getColorByIndex = (index: number): string => {
    return MEMBER_COLORS[index % MEMBER_COLORS.length];
  };

  const addMember = () => {
    const trimmed = name.trim();
    if (!trimmed) return setError(true);

    const isDuplicate = members.some((member) => member.name === trimmed);
    if (isDuplicate) {
      alert("ชื่อสมาชิกนี้มีอยู่แล้ว");
      return;
    }

    setMembers([
      ...members,
      { name: trimmed, color: getColorByIndex(members.length) },
    ]);
    setName("");
    setError(false);
  };

  return (
    <div className="flex flex-col gap-10 pb-20 mt-[140px]">
      {" "}
      {/* Added padding-bottom for the fixed footer */}
      <div className="fixed z-[50] top-[80px] left-1/2 -translate-x-1/2 bg-white w-full sm:w-[450px] px-4">
        <h1 className="font-bold mt-3 pb-2">
          สมาชิกมีใครบ้าง ?{" "}
          <span className="!text-gray-400">({members.length} คน)</span>
        </h1>
      </div>
      <div
        className={`flex gap-4 flex-wrap w-full ${
          members.length > 4 ? "justify-center" : ""
        }`}
        style={{
          padding: "5px",
          paddingBottom: "120px",
        }}
      >
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
                onClick={() => setConfirmDeleteIndex(i)}
              >
                <TiDelete className="text-red text-xl" />
              </div>

              {confirmDeleteIndex === i && (
                <ConfirmPopup
                  isOpen={true}
                  title={`ยืนยันการลบ "${m.name}" ?`}
                  onConfirm={() => {
                    onDeleteMember(m);
                    setConfirmDeleteIndex(null);
                  }}
                  onCancel={() => {
                    setConfirmDeleteIndex(null);
                  }}
                />
              )}
            </div>
          ))
        ) : (
          <div className="text-center w-full">
            <p className="!font-bold text-sm">ยังไม่มีสมาชิก</p>
            <p className="mt-1 !text-gray-400 text-sm">
              กรุณาเพิ่มสมาชิกด้านล่าง
            </p>
          </div>
        )}
      </div>
      {/* Fixed Button Section */}
      <div className="fixed bottom-0 left-1/2 -translate-x-1/2 bg-white py-5 w-full sm:w-[450px] z-10">
        <div className="container mx-auto px-4 flex flex-col gap-7">
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
            />
            <CommonBtn text="เพิ่ม" onClick={addMember} className="!w-fit" />
          </div>
          <CommonBtn
            text="กลับ >"
            type="secondary"
            onClick={() => {
              setIsMemberSet(false);
            }}
            className="!max-w-none"
          />
        </div>
      </div>
    </div>
  );
}
