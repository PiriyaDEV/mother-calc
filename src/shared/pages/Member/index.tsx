"use client";

import { useState } from "react";
import { FiEdit2, FiTrash } from "react-icons/fi";

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
  const [phoneNumber, setPhoneNumber] = useState("");
  const [error, setError] = useState(false);
  const [confirmDeleteIndex, setConfirmDeleteIndex] = useState<number | null>(
    null,
  );
  const [editingIndex, setEditingIndex] = useState<number | null>(null);

  const getColorByIndex = (index: number): string => {
    return MEMBER_COLORS[index % MEMBER_COLORS.length];
  };

  const isValidThaiPhoneOrID = (input: string): boolean => {
    if (!input.trim()) return true; // Empty is valid (optional field)
    const cleaned = input.replace(/\s|-/g, ""); // Remove spaces and dashes

    // Check if it's a valid Thai phone number (10 digits starting with 08, 09, 06, or 02)
    const isPhone = /^(08|09|06|02)\d{8}$/.test(cleaned);

    // Check if it's a valid Thai ID (13 digits)
    const isThaiID = /^\d{13}$/.test(cleaned);

    return isPhone || isThaiID;
  };

  const isFormValid = (): boolean => {
    return name.trim() !== "" && isValidThaiPhoneOrID(phoneNumber);
  };

  const addMember = () => {
    const trimmed = name.trim();
    if (!trimmed) return setError(true);

    const isDuplicate = members.some(
      (member, idx) => member.name === trimmed && idx !== editingIndex,
    );
    if (isDuplicate) {
      alert("ชื่อสมาชิกนี้มีอยู่แล้ว");
      return;
    }

    if (editingIndex !== null) {
      // Edit existing member
      const updatedMembers = [...members];
      updatedMembers[editingIndex] = {
        ...updatedMembers[editingIndex],
        name: trimmed,
        phoneNumber: phoneNumber.trim() || undefined,
      };
      setMembers(updatedMembers);
      setEditingIndex(null);
    } else {
      // Add new member
      const newMember: any = {
        name: trimmed,
        color: getColorByIndex(members.length),
      };

      if (phoneNumber.trim()) {
        newMember.phoneNumber = phoneNumber.trim();
      }

      setMembers([...members, newMember]);
    }

    setName("");
    setPhoneNumber("");
    setError(false);
  };

  const handleEdit = (index: number) => {
    if (editingIndex === index) {
      // Toggle off - cancel edit
      cancelEdit();
    } else {
      // Toggle on - start edit
      const member = members[index];
      setName(member.name);
      setPhoneNumber(member.phoneNumber || "");
      setEditingIndex(index);
      setError(false);
    }
  };

  const cancelEdit = () => {
    setEditingIndex(null);
    setName("");
    setPhoneNumber("");
    setError(false);
  };

  function formatThaiNumberOrId(value: any) {
    if (!value) return "";

    const digits = value.replace(/\D/g, "");

    // Thai mobile phone (10 digits)
    if (digits.length === 10) {
      return `${digits.slice(0, 3)}-${digits.slice(3, 6)}-${digits.slice(6)}`;
    }

    // Thai national ID (13 digits)
    if (digits.length === 13) {
      return `${digits[0]}-${digits.slice(1, 5)}-${digits.slice(5, 10)}-${digits.slice(10, 12)}-${digits[12]}`;
    }

    // fallback (unknown length)
    return value;
  }

  return (
    <div className="flex flex-col gap-10 pb-20 mt-[140px]">
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
          paddingBottom: "180px",
        }}
      >
        {members.length ? (
          members.map((m, i) => (
            <div
              key={i}
              className={`relative w-[80px] h-[80px] rounded-full flex justify-center items-center ${
                editingIndex === i ? "ring-4 ring-blue-400" : ""
              }`}
              style={{ backgroundColor: m.color }}
              onClick={() => handleEdit(i)}
            >
              <div className="flex flex-col items-center">
                <p className="text-sm font-bold truncate text-white px-1">
                  {m.name}
                </p>
                {m.phoneNumber && (
                  <p
                    className={`font-semibold truncate text-white px-1 ${
                      m.phoneNumber.length === 13 ? "text-[7px]" : "text-[8px]"
                    }`}
                  >
                    ({formatThaiNumberOrId(m.phoneNumber)})
                  </p>
                )}
              </div>
              <div
                className="bg-white rounded-full absolute -top-1 -right-1 h-6 w-6 flex justify-center items-center cursor-pointer shadow-md hover:shadow-lg transition-shadow"
                onClick={(e) => {
                  e.stopPropagation();
                  handleEdit(i);
                }}
              >
                <FiEdit2 className="text-blue-500 text-sm" />
              </div>
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

      {confirmDeleteIndex !== null && (
        <ConfirmPopup
          isOpen={true}
          title={`ยืนยันการลบ "${members[confirmDeleteIndex].name}" ?`}
          onConfirm={() => {
            onDeleteMember(members[confirmDeleteIndex]);
            if (editingIndex === confirmDeleteIndex) {
              cancelEdit();
            }
            setConfirmDeleteIndex(null);
          }}
          onCancel={() => {
            setConfirmDeleteIndex(null);
          }}
        />
      )}

      {/* Fixed Button Section */}
      <div className="fixed bottom-0 left-1/2 -translate-x-1/2 bg-white py-4 w-full sm:w-[450px] z-10 shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.1)]">
        <div className="container mx-auto px-4 flex flex-col gap-3">
          <div className="flex flex-col gap-2 w-full">
            <div className="flex items-center justify-between">
              <label className="text-sm font-medium">
                ชื่อสมาชิก <span className="!text-red-500">(*)</span>
              </label>

              {editingIndex !== null && (
                <label
                  onClick={() => setConfirmDeleteIndex(editingIndex)}
                  className=" py-2 text-sm font-medium text-red-500 flex items-center gap-2 border border-red-500 rounded-xl w-fit py-1 px-2"
                >
                  ลบสมาชิกนี้ <FiTrash />
                </label>
              )}
            </div>
            <input
              type="text"
              placeholder="ใส่ชื่อสมาชิก"
              className={`input input-bordered w-full ${
                error ? "!bg-red-50 !border-red-500" : ""
              }`}
              disabled={editingIndex !== null}
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                setError(false);
              }}
            />
            <label className="text-sm font-medium">
              เบอร์พร้อมเพย์ / รหัสบัตรประชาชน
            </label>
            <input
              type="tel"
              placeholder="เบอร์พร้อมเพย์ / รหัสบัตรประชาชน (ไม่บังคับ)"
              className={`input input-bordered w-full ${
                phoneNumber.trim() && !isValidThaiPhoneOrID(phoneNumber)
                  ? "!bg-red-50 !border-red-500"
                  : ""
              }`}
              maxLength={13}
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
            />
            {phoneNumber.trim() && !isValidThaiPhoneOrID(phoneNumber) && (
              <p className="text-red-500 text-xs mt-1">
                กรุณาใส่เบอร์โทรศัพท์ไทย (08, 09, 06, 02) หรือรหัสบัตรประชาชน 13
                หลัก
              </p>
            )}
          </div>

          {editingIndex !== null ? (
            <div className="flex gap-2">
              <CommonBtn
                text="ยกเลิก"
                type="secondary"
                onClick={cancelEdit}
                className="flex-1"
              />
              <CommonBtn
                text="แก้ไข"
                type="primary"
                onClick={addMember}
                className="flex-1"
                disabled={!isFormValid()}
              />
            </div>
          ) : (
            <CommonBtn
              text="เพิ่ม"
              onClick={addMember}
              className="!max-w-none"
              disabled={!isFormValid()}
            />
          )}

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
