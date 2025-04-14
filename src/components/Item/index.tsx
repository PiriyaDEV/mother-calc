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
}

export default function Item({ members }: Props) {
  const [itemArr, setItemArr] = useState<Item[]>([]);
  const [itemName, setItemName] = useState("");
  const [paidBy, setPaidBy] = useState("");
  const [price, setPrice] = useState("");
  const [selectedItemIndex, setSelectedItemIndex] = useState<number | null>(
    null
  );
  const [selectedMembers, setSelectedMembers] = useState<Member[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectAll, setSelectAll] = useState(false);

  const handleAddItem = () => {
    if (!itemName.trim() || !paidBy)
      return alert("Please fill out all fields.");

    const newItem: Item = {
      itemName: itemName.trim(),
      paidBy,
      price: price ? parseFloat(price) : undefined,
      selectedMembers: [],
    };

    setItemArr((prev) => [...prev, newItem]);
    setItemName("");
    setPaidBy("");
    setPrice("");
  };

  const handleMemberSelection = (member: Member) => {
    if (selectedItemIndex === null) return;

    const updatedItems = [...itemArr];
    const currentItem = updatedItems[selectedItemIndex];
    const isSelected = currentItem.selectedMembers.some(
      (m) => m.name === member.name
    );

    currentItem.selectedMembers = isSelected
      ? currentItem.selectedMembers.filter((m) => m.name !== member.name)
      : [...currentItem.selectedMembers, member];

    setItemArr(updatedItems);
    setSelectedMembers(currentItem.selectedMembers);
  };

  const handleItemClick = (index: number) => {
    setSelectedItemIndex(index);
    setSelectedMembers(itemArr[index].selectedMembers);
    setIsModalOpen(true);
  };

  const toggleSelectAll = () => {
    if (selectedItemIndex === null) return;

    const updatedItems = [...itemArr];
    const currentItem = updatedItems[selectedItemIndex];
    const shouldSelectAll =
      currentItem.selectedMembers.length !== members.length;

    currentItem.selectedMembers = shouldSelectAll ? [...members] : [];
    setItemArr(updatedItems);
    setSelectedMembers(currentItem.selectedMembers);
    setSelectAll(shouldSelectAll);
  };

  const handleCustomPaidChange = (member: Member, customPaid: string) => {
    if (selectedItemIndex === null) return;

    const updatedItems = [...itemArr];
    const currentItem = updatedItems[selectedItemIndex];
    const updatedMembers = currentItem.selectedMembers.map((m) =>
      m.name === member.name
        ? { ...m, customPaid: customPaid ? parseFloat(customPaid) : undefined }
        : m
    );

    currentItem.selectedMembers = updatedMembers;
    setItemArr(updatedItems);
  };

  return (
    <div className="flex flex-col gap-4 max-w-md w-full">
      <div className="text-xl font-semibold">Add Item</div>
      <div className="flex flex-col gap-2 mt-4">
        <div className="font-semibold">Items:</div>
        {itemArr.length === 0 ? (
          <span>No items added</span>
        ) : (
          itemArr.map((item, index) => (
            <span
              key={index}
              className="p-2 rounded bg-gray-100 text-sm !text-black"
              onClick={() => handleItemClick(index)}
            >
              <strong>{item.itemName}</strong> — Paid by:{" "}
              <span className="font-medium !text-black">{item.paidBy}</span> —
              Price:{" "}
              {item.price !== undefined ? `$${item.price.toFixed(2)}` : "N/A"} —
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

      <div className="mt-6">
        <input
          type="text"
          placeholder="Item name"
          value={itemName}
          onChange={(e) => setItemName(e.target.value)}
          className="input input-bordered w-full"
        />
        <select
          value={paidBy}
          onChange={(e) => setPaidBy(e.target.value)}
          className="select select-bordered w-full text-black"
        >
          <option value="">Select member who paid</option>
          {members.map((member, index) => (
            <option key={index} value={member.name}>
              {member.name}
            </option>
          ))}
        </select>
        <input
          type="number"
          placeholder="Price (optional)"
          value={price}
          onChange={(e) => setPrice(e.target.value)}
          className="input input-bordered w-full"
        />
        <button onClick={handleAddItem} className="btn btn-primary w-fit">
          Add
        </button>
      </div>

      {/* Modal for member selection */}
      {isModalOpen && (
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
              {members.map((member, index) => (
                <li key={index} className="flex items-center gap-2">
                  <button
                    onClick={() => handleMemberSelection(member)}
                    className={`btn btn-ghost w-full text-left ${
                      selectedMembers.some((m) => m.name === member.name)
                        ? "bg-blue-200 text-blue-800"
                        : ""
                    }`}
                  >
                    {member.name}
                  </button>
                  {itemArr[selectedItemIndex!].price === undefined &&
                    selectedMembers.some((m) => m.name === member.name) && (
                      <input
                        type="number"
                        placeholder="Custom Paid"
                        onChange={(e) =>
                          handleCustomPaidChange(member, e.target.value)
                        }
                        className="input input-bordered w-24"
                      />
                    )}
                </li>
              ))}
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
