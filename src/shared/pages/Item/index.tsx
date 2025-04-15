import { ItemObj, MemberObj } from "@/app/lib/interface";
import CommonBtn from "@/shared/components/CommonBtn";
import { useState } from "react";

interface ItemProps {
  members: MemberObj[];
  setItemArr: React.Dispatch<React.SetStateAction<ItemObj[]>>;
  setItemModalOpen: React.Dispatch<React.SetStateAction<boolean>>;
}

export default function Item({
  members,
  setItemArr,
  setItemModalOpen,
}: ItemProps) {
  const [itemName, setItemName] = useState("");
  const [paidBy, setPaidBy] = useState<MemberObj | null>(null);
  const [price, setPrice] = useState("");

  const handleAddItem = () => {
    if (!itemName.trim() || !paidBy)
      return alert("กรุณากรอกข้อมูลให้ครบ");

    const newItem: ItemObj = {
      itemName: itemName.trim(),
      paidBy,
      price: price ? parseFloat(price) : undefined,
      selectedMembers: [],
    };

    setItemArr((prev) => [...prev, newItem]);
    setItemName("");
    setPaidBy(null);
    setPrice("");
    setItemModalOpen(false);
  };

  return (
    <div className="flex flex-col gap-2">
      <span className="!text-[#4366f4] font-bold text-sm">รายการ</span>
      <input
        type="text"
        placeholder="ใส่ชื่อรายการ"
        value={itemName}
        onChange={(e) => setItemName(e.target.value)}
        className="input input-bordered w-full"
      />

      <span className="!text-[#4366f4] font-bold text-sm">คนจ่าย</span>
      <select
        value={paidBy ? paidBy.name : ""}
        onChange={(e) => {
          const selected = members.find((m) => m.name === e.target.value);
          setPaidBy(selected ?? null);
        }}
        className="select select-bordered w-full text-black"
      >
        <option value="">เลือกคนจ่าย</option>
        {members.map((member, index) => (
          <option key={index} value={member.name}>
            {member.name}
          </option>
        ))}
      </select>

      <span className="!text-[#4366f4] font-bold text-sm">ราคา</span>
      <input
        type="number"
        placeholder="ราคา (ไม่จำเป็น)"
        value={price}
        onChange={(e) => setPrice(e.target.value)}
        className="input input-bordered w-full"
      />

      <div className="flex justify-end">
        <CommonBtn
          text="เพิ่ม"
          onClick={handleAddItem}
          disabled={members.length === 0}
          className="!w-fit"
        />
      </div>
    </div>
  );
}
