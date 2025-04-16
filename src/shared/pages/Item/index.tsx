import { ItemObj, MemberObj } from "@/app/lib/interface";
import CommonBtn from "@/shared/components/CommonBtn";
import { useState, useEffect } from "react";

interface ItemProps {
  members: MemberObj[];
  setItemArr: React.Dispatch<React.SetStateAction<ItemObj[]>>;
  setItemModalOpen: React.Dispatch<React.SetStateAction<boolean>>;
  editingItem?: ItemObj;
}

export default function Item({
  members,
  setItemArr,
  setItemModalOpen,
  editingItem,
}: ItemProps) {
  const [itemName, setItemName] = useState("");
  const [paidBy, setPaidBy] = useState<string>(""); // Store only the name as string
  const [price, setPrice] = useState("");
  const [isEqualSplit, setIsEqualSplit] = useState(true);

  // Effect to populate form fields if editing an item
  useEffect(() => {
    if (editingItem) {
      setItemName(editingItem.itemName);
      setPaidBy(editingItem.paidBy);
      setPrice(editingItem.price ? editingItem.price.toString() : "");
      setIsEqualSplit(editingItem.price !== undefined);
    }
  }, [editingItem]);

  const handleAddItem = () => {
    if (!itemName.trim() || !paidBy || (isEqualSplit && !price)) {
      return alert("กรุณากรอกข้อมูลให้ครบ");
    }

    // Retrieve the member object using the paidBy name
    const selectedMember = members.find((member) => member.name === paidBy);

    if (!selectedMember) return alert("สมาชิกที่เลือกไม่ถูกต้อง");

    const newItem: ItemObj = {
      itemName: itemName.trim(),
      paidBy: selectedMember.name,
      price: price ? parseFloat(price) : undefined,
      selectedMembers: editingItem ? editingItem.selectedMembers : [],
    };

    if (editingItem) {
      // If in edit mode, update the existing item, keeping the selectedMembers intact
      setItemArr((prev) =>
        prev.map((item) =>
          item === editingItem ? { ...item, ...newItem } : item
        )
      );
    } else {
      // Otherwise, add a new item
      setItemArr((prev) => [...prev, newItem]);
    }

    // Reset form state
    setItemName("");
    setPaidBy(""); // Reset to empty string, not null
    setPrice("");
    setIsEqualSplit(true);
    setItemModalOpen(false);
  };

  const handleSplitChange = (isEqual: boolean) => {
    setIsEqualSplit(isEqual);
    if (!isEqual) {
      setPrice(""); // Clear price if not equal split
    }
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
        value={paidBy}
        onChange={(e) => setPaidBy(e.target.value)}
        className="select select-bordered w-full text-black"
      >
        <option value="">เลือกคนจ่าย</option>
        {members.map((member, index) => (
          <option key={index} value={member.name}>
            {member.name}
          </option>
        ))}
      </select>

      <div>
        <span className="!text-[#4366f4] font-bold text-sm">ราคา</span>

        <div className="flex gap-4 my-2">
          <label className="flex items-center gap-2 text-xs">
            <input
              type="radio"
              name="split"
              value="equal"
              checked={isEqualSplit}
              onChange={() => handleSplitChange(true)}
            />
            หารเท่า
          </label>
          <label className="flex items-center gap-2 text-xs">
            <input
              type="radio"
              name="split"
              value="unequal"
              checked={!isEqualSplit}
              onChange={() => handleSplitChange(false)}
            />
            หารไม่เท่า
          </label>
        </div>

        {isEqualSplit ? (
          <div>
            <input
              type="number"
              placeholder="กรอกราคา"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              className="input input-bordered w-full"
            />
          </div>
        ) : (
          <span className="text-xs !text-[#c4c5c6]">
            * กรอกราคารายบุคคลหลังจากสร้างรายการ
          </span>
        )}
      </div>

      <div className="flex justify-end">
        <CommonBtn
          text={editingItem ? "แก้ไข" : "เพิ่ม"}
          onClick={handleAddItem}
          disabled={members.length === 0}
          className="!w-fit"
        />
      </div>
    </div>
  );
}
