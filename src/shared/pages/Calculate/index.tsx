import { ItemObj, MemberObj } from "@/app/lib/interface";
import { useState } from "react";

import { TiTrash } from "react-icons/ti";
import { FaPen } from "react-icons/fa";
import ConfirmPopup from "@/shared/components/ConfirmPopup";
import { getMemberObjByName, getPrice } from "@/app/lib/utils";
import ItemModal from "@/shared/components/ItemModal";
import { Settings } from "@/shared/components/SettingPopup";
import { MODE } from "@/app/lib/constants";

interface CalculateProps {
  members: MemberObj[];
  itemArr: ItemObj[];
  setItemArr: React.Dispatch<React.SetStateAction<ItemObj[]>>;
  settings: Settings;
  mode: "VIEW" | "EDIT";
}

export default function Calculate({
  members,
  itemArr,
  setItemArr,
  settings,
  mode,
}: CalculateProps) {
  const [selectedItemIndex, setSelectedItemIndex] = useState<number | null>(
    null
  );
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [confirmDeleteIndex, setConfirmDeleteIndex] = useState<number | null>(
    null
  );
  const [editingItem, setEditingItem] = useState<ItemObj | null>(null);

  const handleEditItemClick = (index: number) => {
    setSelectedItemIndex(index);

    const updatedItems = [...itemArr];
    const currentItem = updatedItems[index]; // Get the current item

    setEditingItem(currentItem); // Set the current item as the editing item
    setIsEditModalOpen(true); // Open the edit modal
  };

  const handleDeleteItem = (index: number) => {
    const updatedItems = [...itemArr];
    updatedItems.splice(index, 1);
    setItemArr(updatedItems);

    if (selectedItemIndex === index) {
      setSelectedItemIndex(null);
    }
  };

  return (
    <div className="flex flex-col gap-4 w-full mt-[94px]">
      {itemArr.length !== 0 && (
        <h1 className="font-bold mt-3">มีรายการอะไรไปบ้าง ?</h1>
      )}

      <div
        style={{
          paddingBottom: "150px",
        }}
      >
        <div className="flex flex-col gap-2 mt-2">
          {itemArr.length === 0 || members.length === 0 ? (
            <>
              {members.length === 0 ? (
                <div className="text-center">
                  <p className="!font-bold">ยังไม่มีสมาชิก</p>
                  <p className="mt-1 !text-gray-400">
                    กรุณาเพิ่มสมาชิกที่ปุ่ม "+ เพิ่มสมาชิก" ซ้ายล่าง
                  </p>
                </div>
              ) : itemArr.length === 0 ? (
                <div className="text-center">
                  <div className="flex justify-center mb-7 gap-3">
                    {members.map((m, i) => (
                      <div
                        key={i}
                        className="relative w-10 h-10 rounded-full flex justify-center items-center"
                        style={{ backgroundColor: m.color }}
                      >
                        <span className="text-[8px] font-semibold truncate text-white">
                          {m.name}
                        </span>
                      </div>
                    ))}
                  </div>

                  <p className="!font-bold">
                    คุณมีสมาชิกแล้ว! แต่ยังไม่มีรายการ
                  </p>
                  <p className="mt-1 !text-gray-400">
                    กรุณาเพิ่มสมาชิกที่ปุ่ม "เพิ่มรายการ" ขวาล่าง
                  </p>
                </div>
              ) : null}
            </>
          ) : (
            itemArr.map((item, index) => {
              const paidByMember = getMemberObjByName(item.paidBy, members);

              return (
                <div key={index} className="flex justify-between my-2 gap-2">
                  <div className="w-full">
                    <div
                      className={`p-2 rounded-[8px] bg-gray-100 text-sm !text-black grid ${
                        mode === MODE.EDIT ? "grid-cols-3" : "grid-cols-2"
                      } items-center`}
                    >
                      <strong>
                        {item.itemName}
                        <div
                          className="text-xs font-semibold"
                          style={{ color: paidByMember?.color || "black" }}
                        >
                          ({paidByMember?.name || item.paidBy})
                        </div>
                      </strong>

                      <div className="flex flex-col gap-1">
                        <div className="font-bold">
                          {item.price !== undefined
                            ? `${getPrice(
                                item.price,
                                item.vatRate,
                                item.serviceChargeRate
                              ).toLocaleString("en-US", {
                                minimumFractionDigits: 2,
                                maximumFractionDigits: 2,
                              })} บาท`
                            : item.selectedMembers.length > 0
                            ? `${getPrice(
                                item.selectedMembers.reduce(
                                  (sum, m) => sum + (m.customPaid || 0),
                                  0
                                ),
                                item.vatRate,
                                item.serviceChargeRate
                              ).toLocaleString("en-US", {
                                minimumFractionDigits: 2,
                                maximumFractionDigits: 2,
                              })} บาท`
                            : "N/A"}
                        </div>
                        {(item.vatRate || item.serviceChargeRate) && (
                          <div className="text-gray-500">
                            <span className="text-[10px]">รวม</span>
                            {item.vatRate && item.vatRate !== null && (
                              <span className="ml-1 text-[10px]">
                                VAT({item.vatRate}%)
                              </span>
                            )}
                            {item.serviceChargeRate &&
                              item.serviceChargeRate !== null && (
                                <span className="ml-1 text-[10px]">
                                  Service Charge({item.serviceChargeRate}%)
                                </span>
                              )}
                          </div>
                        )}
                      </div>

                      {mode === MODE.EDIT && (
                        <div className="flex items-center justify-end gap-4 !text-[#333333]">
                          <FaPen
                            onClick={() => handleEditItemClick(index)}
                            className="text-[18px] mr-1 cursor-pointer"
                          />

                          <TiTrash
                            onClick={() => setConfirmDeleteIndex(index)}
                            className="text-[25px] cursor-pointer"
                          />
                        </div>
                      )}
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
                                    getPrice(
                                      item.price,
                                      item.vatRate,
                                      item.serviceChargeRate
                                    ) / item.selectedMembers.length
                                  ).toLocaleString("en-US", {
                                    minimumFractionDigits: 2,
                                    maximumFractionDigits: 2,
                                  })} บาท`
                                : `${getPrice(
                                    memberItem.customPaid ?? 0,
                                    item.vatRate,
                                    item.serviceChargeRate
                                  ).toLocaleString("en-US", {
                                    minimumFractionDigits: 2,
                                    maximumFractionDigits: 2,
                                  })} บาท`}
                            </span>
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>

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
      </div>

      {isEditModalOpen && editingItem && (
        <ItemModal
          settings={settings}
          members={members}
          setItemArr={setItemArr}
          setItemModalOpen={setIsEditModalOpen}
          editingItem={editingItem}
        />
      )}
    </div>
  );
}
