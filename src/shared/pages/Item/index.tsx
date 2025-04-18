import { ItemObj, MemberObj } from "@/app/lib/interface";
import CommonBtn from "@/shared/components/CommonBtn";
import { Settings } from "@/shared/components/SettingPopup";
import { useState, useEffect } from "react";
import { FaChevronDown } from "react-icons/fa";

interface ItemProps {
  members: MemberObj[];
  setItemArr: React.Dispatch<React.SetStateAction<ItemObj[]>>;
  setItemModalOpen: React.Dispatch<React.SetStateAction<boolean>>;
  editingItem?: ItemObj;
  settings: Settings;
}

export default function Item({
  members,
  setItemArr,
  setItemModalOpen,
  editingItem,
  settings,
}: ItemProps) {
  const [itemName, setItemName] = useState("");
  const [paidBy, setPaidBy] = useState<string>("");
  const [price, setPrice] = useState("");
  const [isEqualSplit, setIsEqualSplit] = useState(true);
  const [selectedMembers, setSelectedMembers] = useState<MemberObj[]>([]);

  const isEditing = !!editingItem;

  const [isVatChecked, setIsVatChecked] = useState(() => {
    if (isEditing) {
      return editingItem.vatRate != null;
    }
    return settings.isVat || false;
  });

  const [isServiceChargeChecked, setIsServiceChargeChecked] = useState(() => {
    if (isEditing) {
      return editingItem.serviceChargeRate != null;
    }
    return settings.isService || false;
  });

  const [vatRate, setVatRate] = useState(() => {
    if (isEditing) {
      return editingItem.vatRate != null ? editingItem.vatRate.toString() : "0";
    }
    return settings.vat != null ? settings.vat.toString() : "0";
  });

  const [serviceChargeRate, setServiceChargeRate] = useState(() => {
    if (isEditing) {
      return editingItem.serviceChargeRate != null
        ? editingItem.serviceChargeRate.toString()
        : "0";
    }
    return settings.serviceCharge != null
      ? settings.serviceCharge.toString()
      : "0";
  });

  const [isAdditionalSettingsVisible, setIsAdditionalSettingsVisible] =
    useState(false);

  useEffect(() => {
    if (editingItem) {
      setItemName(editingItem.itemName);
      setPaidBy(editingItem.paidBy);
      setPrice(editingItem.price ? editingItem.price.toString() : "");
      setIsEqualSplit(editingItem.price !== undefined);
      setSelectedMembers(editingItem.selectedMembers);
    } else {
      setSelectedMembers([]);
    }
  }, [editingItem]);

  const toggleSelectAll = () => {
    const shouldSelectAll = selectedMembers.length !== members.length;
    setSelectedMembers(shouldSelectAll ? members.map((m) => ({ ...m })) : []);
  };

  const handleMemberSelection = (member: MemberObj) => {
    const isSelected = selectedMembers.some((m) => m.name === member.name);
    const updated = isSelected
      ? selectedMembers.filter((m) => m.name !== member.name)
      : [...selectedMembers, { ...member }];
    setSelectedMembers(updated);
  };

  const handleCustomPaidChange = (member: MemberObj, customPaid: string) => {
    setSelectedMembers((prev) =>
      prev.map((m) =>
        m.name === member.name
          ? {
              ...m,
              customPaid: customPaid ? parseFloat(customPaid) : undefined,
            }
          : m
      )
    );
  };

  const handleSplitChange = (isEqual: boolean) => {
    setIsEqualSplit(isEqual);
    if (!isEqual) setPrice("");
  };

  const handleVatChange = (isChecked: boolean) => {
    setIsVatChecked(isChecked);
  };

  const handleServiceChargeChange = (isChecked: boolean) => {
    setIsServiceChargeChecked(isChecked);
  };

  const handleAddItem = () => {
    if (
      !itemName.trim() ||
      !paidBy ||
      (isEqualSplit && !price) ||
      selectedMembers.length === 0
    ) {
      return alert("กรุณากรอกข้อมูลให้ครบ");
    }

    const selectedMember = members.find((m) => m.name === paidBy);
    if (!selectedMember) return alert("สมาชิกที่เลือกไม่ถูกต้อง");

    // Add validation for unequal split
    if (!isEqualSplit) {
      for (const member of selectedMembers) {
        if (
          member.customPaid === undefined ||
          member.customPaid === null ||
          isNaN(member.customPaid)
        ) {
          return alert(`กรุณาใส่ค่าใช้จ่ายของสมาชิก ${member.name}`);
        }
      }
    }

    if (isVatChecked && !vatRate) {
      return alert(`กรุณาใส่ค่า VAT`);
    }

    if (isServiceChargeChecked && !serviceChargeRate) {
      return alert(`กรุณาใส่ค่า Service Charge`);
    }

    const newItem: ItemObj = {
      itemName: itemName.trim(),
      paidBy: selectedMember.name,
      price: isEqualSplit && price ? parseFloat(price) : undefined,
      selectedMembers,
      vatRate: isVatChecked ? parseInt(vatRate) : undefined,
      serviceChargeRate: isServiceChargeChecked
        ? parseInt(serviceChargeRate)
        : undefined,
    };

    if (editingItem) {
      setItemArr((prev) =>
        prev.map((item) =>
          item === editingItem ? { ...item, ...newItem } : item
        )
      );
    } else {
      setItemArr((prev) => [...prev, newItem]);
    }

    // Reset
    setItemName("");
    setPaidBy("");
    setPrice("");
    setIsEqualSplit(true);
    setSelectedMembers([]);
    setIsVatChecked(false);
    setVatRate(settings.vat.toString());
    setIsServiceChargeChecked(false);
    setServiceChargeRate(settings.serviceCharge.toString());
    setItemModalOpen(false);
    setIsAdditionalSettingsVisible(false);
  };

  return (
    <div className="flex flex-col gap-2">
      <span className="!text-[#4366f4] font-bold text-sm">
        รายการ <span className="!text-red-500">*</span>
      </span>
      <input
        type="text"
        placeholder="ใส่ชื่อรายการ"
        value={itemName}
        onChange={(e) => setItemName(e.target.value)}
        className="input input-bordered w-full"
      />

      <div>
        <span className="!text-[#4366f4] font-bold text-sm">
          ราคา <span className="!text-red-500">*</span>
        </span>

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
          <input
            type="number"
            placeholder="กรอกราคา"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "-" || e.key === "e") {
                e.preventDefault();
              }
            }}
            className="input input-bordered w-full"
          />
        ) : (
          <span className="text-xs !text-[#c4c5c6]">
            * กรอกราคารายบุคคลด้านล่าง
          </span>
        )}
      </div>

      <div>
        {/* Toggle for additional settings */}
        <div
          className="my-4 flex items-center justify-between cursor-pointer"
          onClick={() => {
            setIsAdditionalSettingsVisible(!isAdditionalSettingsVisible);
          }}
        >
          <span className="!text-gray-500 font-bold text-xs">
            ตั้งค่าเพิ่มเติม
          </span>
          <FaChevronDown
            className={`!text-gray-500 ${
              isAdditionalSettingsVisible ? "rotate-180" : ""
            }`}
          />
        </div>

        {/* Conditionally render additional settings */}
        {isAdditionalSettingsVisible && (
          <div className="flex gap-4 my-2 flex-col">
            <label className="flex items-center gap-2 text-xs">
              <input
                type="checkbox"
                name="vat"
                checked={isVatChecked}
                onChange={() => handleVatChange(!isVatChecked)}
              />
              ค่า VAT
              {isVatChecked && (
                <input
                  type="number"
                  placeholder="กรอก VAT"
                  value={vatRate ?? 0}
                  onChange={(e) => setVatRate(e.target.value)}
                  className="input input-bordered w-full max-w-[150px]"
                />
              )}
            </label>

            <label className="flex items-center gap-2 text-xs">
              <input
                type="checkbox"
                name="serviceCharge"
                checked={isServiceChargeChecked}
                onChange={() =>
                  handleServiceChargeChange(!isServiceChargeChecked)
                }
              />
              ค่า Service Charge
              {isServiceChargeChecked && (
                <input
                  type="number"
                  placeholder="กรอก Service Charge"
                  value={serviceChargeRate ?? 0}
                  onChange={(e) => setServiceChargeRate(e.target.value)}
                  className="input input-bordered w-full max-w-[150px]"
                />
              )}
            </label>
          </div>
        )}
      </div>

      <span className="!text-[#4366f4] font-bold text-sm mt-2">
        เลือกคนจ่าย <span className="!text-red-500">*</span>
      </span>
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
        <div className="flex justify-between items-center mb-5 mt-2">
          <p className="!text-[#4366f4] font-bold text-sm">
            เลือกสมาชิก <span className="!text-red-500">*</span>
          </p>

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
                onClick={() => !isSelected && handleMemberSelection(member)}
              >
                <div className="flex items-center gap-2">
                  <div
                    onClick={() => handleMemberSelection(member)}
                    className="relative w-10 h-10 rounded-full flex justify-center items-center cursor-pointer"
                    style={{
                      backgroundColor: isSelected ? member.color : "#d3d3d3",
                    }}
                  >
                    <span className="text-xs font-semibold truncate text-white">
                      {member.name}
                    </span>
                  </div>

                  {!isEqualSplit && (
                    <input
                      type="number"
                      placeholder="ใส่จำนวน"
                      value={
                        selectedMembers.find((m) => m.name === member.name)
                          ?.customPaid ?? ""
                      }
                      onChange={(e) =>
                        handleCustomPaidChange(member, e.target.value)
                      }
                      className={`mt-1 px-2 py-1 border border-gray-300 rounded text-sm w-24 ${
                        !isSelected ? "bg-gray-100" : ""
                      }`}
                    />
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      <div className="flex justify-end mt-5">
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
