import { ItemObj, MemberObj } from "@/app/lib/interface";
import CommonBtn from "@/shared/components/CommonBtn";
import { useState } from "react";

import { TiTrash } from "react-icons/ti";
import { FaUserCheck } from "react-icons/fa";
import ConfirmPopup from "@/shared/components/ConfirmPopup";
import { getMemberObjByName } from "@/app/lib/utils";

interface CalculateProps {
  members: MemberObj[];
  itemArr: ItemObj[];
  setItemArr: React.Dispatch<React.SetStateAction<ItemObj[]>>;
}

export default function Calculate({
  members,
  itemArr,
  setItemArr,
}: CalculateProps) {
  const [selectedItemIndex, setSelectedItemIndex] = useState<number | null>(
    null
  );
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [confirmDeleteIndex, setConfirmDeleteIndex] = useState<number | null>(
    null
  );
  const [selectAll, setSelectAll] = useState(false);

  const handleMemberSelection = (member: MemberObj) => {
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

  const handleCustomPaidChange = (member: MemberObj, customPaid: string) => {
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
    <div className="flex flex-col gap-4 w-full">
      {itemArr.length !== 0 && (
        <h1 className="font-bold mt-3">กินอะไรไปบ้าง ?</h1>
      )}

      <div
        className="flex flex-col gap-2 mt-2"
        style={{ height: "calc(100vh - 280px)", overflowY: "auto" }}
      >
        {itemArr.length === 0 ? (
          <span className="text-center">ยังไม่มีรายการ</span>
        ) : (
          itemArr.map((item, index) => {
            const paidByMember = getMemberObjByName(item.paidBy, members);

            return (
              <div key={index} className="flex justify-between my-2 gap-2">
                <div className="w-full">
                  <div className="p-2 rounded-[8px] bg-gray-100 text-sm !text-black grid grid-cols-2 items-center">
                    <strong>
                      {item.itemName}
                      <div
                        className="text-xs font-semibold"
                        style={{ color: paidByMember?.color || "black" }}
                      >
                        ({paidByMember?.name || item.paidBy})
                      </div>
                    </strong>

                    <div>
                      {item.price !== undefined
                        ? `${item.price.toFixed(2)} บาท`
                        : item.selectedMembers.length > 0
                        ? `${item.selectedMembers
                            .reduce((sum, m) => sum + (m.customPaid || 0), 0)
                            .toFixed(2)} บาท`
                        : "N/A"}
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-2 mt-2">
                    {item.selectedMembers.length === 0 && (
                      <span className="text-xs !text-gray-400">
                        * ยังไม่ได้เลือกสมาชิก
                      </span>
                    )}
                    {item.selectedMembers.map((memberItem, index) => (
                      <div
                        key={`${memberItem.name}-${index}`}
                        className="relative p-2 h-5 w-fit rounded-full flex justify-center items-center"
                        style={{ backgroundColor: memberItem.color }}
                      >
                        <span className="text-[10px] font-semibold truncate text-white">
                          {memberItem.name}
                          <span>
                            :{" "}
                            {item.price !== undefined
                              ? `${(
                                  item.price / item.selectedMembers.length
                                ).toFixed(2)} บาท`
                              : `${memberItem.customPaid ?? "0"} บาท`}
                          </span>
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                <FaUserCheck
                  onClick={() => handleItemClick(index)}
                  className="text-[28px] mt-2 cursor-pointer"
                />

                <TiTrash
                  onClick={() => setConfirmDeleteIndex(index)}
                  className="text-[28px] mt-2 cursor-pointer"
                />

                {confirmDeleteIndex === index && (
                  <ConfirmPopup
                    title={`ยืนยันการลบ "${item.itemName}" ?`}
                    isOpen={true}
                    onConfirm={() => {
                      handleDeleteItem(index);
                      setConfirmDeleteIndex(null);
                    }}
                    onCancel={() => {
                      setConfirmDeleteIndex(null);
                    }}
                  />
                )}
              </div>
            );
          })
        )}
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
              <div>
                <h2 className="text-md font-semibold">เลือกคนกิน</h2>

                {itemArr[selectedItemIndex]?.price === undefined && (
                  <span className="text-xs !text-[#c4c5c6]">
                    เลือกคนกินก่อนใส่จำนวน
                  </span>
                )}
              </div>

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
                  <div key={index} className="flex items-center gap-2">
                    <div
                      onClick={() => handleMemberSelection(member)}
                      className={`relative w-10 h-10 rounded-full flex justify-center items-center cursor-pointer`}
                      style={{
                        backgroundColor: isSelected ? member.color : "#d3d3d3",
                      }}
                    >
                      <span className="text-xs font-semibold truncate text-white">
                        {member.name}
                      </span>
                    </div>

                    {itemArr[selectedItemIndex]?.price === undefined &&
                      isSelected && (
                        <input
                          type="number"
                          placeholder="ใส่จำนวน"
                          disabled={!isSelected}
                          value={
                            selectedMembers.find((m) => m.name === member.name)
                              ?.customPaid ?? ""
                          }
                          onChange={(e) =>
                            handleCustomPaidChange(member, e.target.value)
                          }
                          className="mt-1 px-2 py-1 border border-gray-300 rounded text-sm w-24"
                        />
                      )}
                  </div>
                );
              })}
            </div>

            <div className="flex w-full mt-6">
              <CommonBtn
                text="ตกลง"
                onClick={() => {
                  setIsModalOpen(false);
                }}
                disabled={members.length === 0}
                className="!w-full !max-w-none"
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
