import { useState } from "react";

interface Member {
  name: string;
  color: string;
  customPaid?: number;
}

interface Item {
  itemName: string;
  paidBy: string;
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
      ? itemArr[selectedItemIndex].selectedMembers
      : [];

  return (
    <div className="flex flex-col gap-4 max-w-md w-full">
      <div>
        <div>Step 3: Calculate</div>
        <div>You can edit after this</div>
      </div>

      <div className="flex flex-col gap-2 mt-4">
        <div className="font-semibold">Items:</div>
        {itemArr.length === 0 ? (
          <span>No items added</span>
        ) : (
          itemArr.map((item, index) => (
            <span
              key={index}
              className="p-2 rounded bg-gray-100 text-sm !text-black cursor-pointer"
              onClick={() => handleItemClick(index)}
            >
              <strong>{item.itemName}</strong> — Paid by:{" "}
              <span className="font-medium !text-black">{item.paidBy}</span> —
              Price:{" "}
              {item.price !== undefined
                ? `$${item.price.toFixed(2)}`
                : item.selectedMembers.length > 0
                ? `$${item.selectedMembers
                    .reduce((sum, m) => sum + (m.customPaid || 0), 0)
                    .toFixed(2)}`
                : "N/A"}{" "}
              —{" "}
              {item.selectedMembers.length > 0 ? (
                <span className="font-medium !text-black">
                  Members:{" "}
                  <span className="selected-members">
                    {item.selectedMembers.map((m) => m.name).join(", ")}
                  </span>
                </span>
              ) : (
                <span className="font-medium !text-black">
                  No members selected
                </span>
              )}
            </span>
          ))
        )}
      </div>

      {isModalOpen && selectedItemIndex !== null && (
        <div className="modal modal-open !text-black">
          <div className="modal-box">
            <h2 className="text-xl font-semibold mb-4">Select Members</h2>
            <button
              onClick={toggleSelectAll}
              className="btn btn-secondary mb-4 w-full"
            >
              {selectAll ? "Deselect All" : "Select All"}
            </button>
            <ul className="space-y-2">
              {members.map((member, index) => {
                const isSelected = selectedMembers.some(
                  (m) => m.name === member.name
                );
                const selectedMember = selectedMembers.find(
                  (m) => m.name === member.name
                );

                return (
                  <li key={index} className="flex items-center gap-2">
                    <button
                      onClick={() => handleMemberSelection(member)}
                      className={`btn btn-ghost w-full text-left ${
                        isSelected ? "bg-blue-200 text-blue-800" : ""
                      }`}
                    >
                      {member.name}
                    </button>
                    {itemArr[selectedItemIndex].price === undefined &&
                      isSelected && (
                        <input
                          type="number"
                          placeholder="Custom Paid"
                          value={selectedMember?.customPaid ?? ""}
                          onChange={(e) =>
                            handleCustomPaidChange(member, e.target.value)
                          }
                          className="input input-bordered w-24"
                        />
                      )}
                  </li>
                );
              })}
            </ul>
            <div className="modal-action">
              <button className="btn" onClick={() => setIsModalOpen(false)}>
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      <div>{JSON.stringify(itemArr, null, 2)}</div>
    </div>
  );
}
