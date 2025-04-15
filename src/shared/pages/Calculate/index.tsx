import CommonBtn from "@/shared/components/CommonBtn";
import { useState, useEffect } from "react";

import { TiDelete } from "react-icons/ti";

interface Member {
  name: string;
  color: string;
  customPaid?: number;
}

interface Item {
  itemName: string;
  paidBy: Member;
  price?: number;
  selectedMembers: Member[];
}

interface Props {
  members: Member[];
  itemArr: Item[];
  setItemArr: React.Dispatch<React.SetStateAction<Item[]>>;
}

export default function Calculate({ members, itemArr, setItemArr }: Props) {
  const [selectedItemIndex, setSelectedItemIndex] = useState<number | null>(
    null
  );
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectAll, setSelectAll] = useState(false);

  const handleMemberSelection = (member: Member) => {
    if (selectedItemIndex === null) return;

    const updatedItems = [...itemArr];
    const currentItem = updatedItems[selectedItemIndex];
    const isSelected = currentItem.selectedMembers.some(
      (m) => m.name === member.name
    );

    currentItem.selectedMembers = isSelected
      ? currentItem.selectedMembers.filter((m) => m.name !== member.name)
      : [...currentItem.selectedMembers, { ...member }];

    setItemArr(updatedItems);
  };

  const handleItemClick = (index: number) => {
    setSelectedItemIndex(index);
    setIsModalOpen(true);
  };

  const handleDeleteItem = (index: number) => {
    const updatedItems = [...itemArr];
    updatedItems.splice(index, 1);
    setItemArr(updatedItems);
    if (selectedItemIndex === index) {
      setSelectedItemIndex(null);
      setIsModalOpen(false);
    }
  };

  const toggleSelectAll = () => {
    if (selectedItemIndex === null) return;

    const updatedItems = [...itemArr];
    const currentItem = updatedItems[selectedItemIndex];
    const shouldSelectAll =
      currentItem.selectedMembers.length !== members.length;

    currentItem.selectedMembers = shouldSelectAll
      ? members.map((m) => ({ ...m }))
      : [];

    setItemArr(updatedItems);
    setSelectAll(shouldSelectAll);
  };

  const handleCustomPaidChange = (member: Member, customPaid: string) => {
    if (selectedItemIndex === null) return;

    const updatedItems = [...itemArr];
    const currentItem = updatedItems[selectedItemIndex];
    currentItem.selectedMembers = currentItem.selectedMembers.map((m) =>
      m.name === member.name
        ? { ...m, customPaid: customPaid ? parseFloat(customPaid) : undefined }
        : m
    );

    setItemArr(updatedItems);
  };

  const selectedMembers =
    selectedItemIndex !== null
      ? itemArr[selectedItemIndex]?.selectedMembers || []
      : [];

  return (
    <div className="flex flex-col gap-4 max-w-md w-full">
      <h1 className="font-bold mt-3">กินอะไรไปบ้าง ?</h1>

      <div>
        {itemArr.length !== 0 && (
          <div className="grid grid-cols-3 font-bold text-sm !text-[#c5c6c7]">
            <span>ชื่อ</span>
            <span>จ่ายโดย</span>
            <span>ราคา</span>
          </div>
        )}

        <div className="flex flex-col gap-2 mt-2">
          {itemArr.length === 0 ? (
            <span>ยังไม่มีรายการ</span>
          ) : (
            itemArr.map((item, index) => (
              <div key={index} className="flex justify-between my-2 gap-2">
                <div className="w-full">
                  <div
                    onClick={() => handleItemClick(index)}
                    className="p-2 rounded-[8px] bg-gray-100 text-sm !text-black grid grid-cols-3 items-center"
                  >
                    <strong>{item.itemName}</strong>

                    <div
                      className="relative p-2 h-7 w-14 rounded-full flex justify-center items-center"
                      style={{ backgroundColor: item.paidBy.color }}
                    >
                      <span className="text-xs font-semibold truncate text-white">
                        {item.paidBy.name}
                      </span>
                    </div>

                    <div>
                      {item.price !== undefined
                        ? `${item.price.toFixed(2)} บาท`
                        : item.selectedMembers.length > 0
                        ? `${item.selectedMembers
                            .reduce((sum, m) => sum + (m.customPaid || 0), 0)
                            .toFixed(2)} บาท`
                        : "N/A"}{" "}
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-2 mt-2">
                    {item.selectedMembers.map((memberItem, index) => (
                      <div
                        key={`${memberItem} ${index}`}
                        className="relative p-2 h-5 w-fit rounded-full flex justify-center items-center"
                        style={{ backgroundColor: memberItem.color }}
                      >
                        <span className="text-[10px] font-semibold truncate text-white">
                          {memberItem.name}{" "}
                          <span>
                            :{" "}
                            {item.price !== undefined
                              ? `${(
                                  item.price / item.selectedMembers.length
                                ).toFixed(2)} บาท`
                              : `${memberItem.customPaid} บาท`}
                          </span>
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                <TiDelete
                  onClick={() => handleDeleteItem(index)}
                  className="text-[28px] mt-2"
                />
              </div>
            ))
          )}
        </div>
      </div>

      {isModalOpen && selectedItemIndex !== null && (
        <div
          className="modal modal-open !text-black"
          onClick={(e) => {
            if (e.target === e.currentTarget) {
              setIsModalOpen(false);
            }
          }}
        >
          <div className="modal-box">
            <div className="flex justify-between items-center mb-3">
              <h2 className="text-md font-semibold">เลือกคนกิน</h2>

              <CommonBtn
                text="ทั้งหมด"
                type="secondary"
                onClick={toggleSelectAll}
                disabled={members.length === 0}
                className="!w-fit"
              />
            </div>

            <div className="flex flex-wrap gap-2">
              {members.map((member, index) => {
                const isSelected = selectedMembers.some(
                  (m) => m.name === member.name
                );

                return (
                  <div
                    key={index}
                    onClick={() => handleMemberSelection(member)}
                    className={`relative w-16 h-16 rounded-full flex justify-center items-center cursor-pointer ${
                      isSelected ? "border-2 border-[#80ef80]" : ""
                    }`}
                    style={{ backgroundColor: member.color }}
                  >
                    <span className="text-xs font-semibold truncate text-white">
                      {member.name}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
