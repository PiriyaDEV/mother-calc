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
  setItemArr: React.Dispatch<React.SetStateAction<Item[]>>;
}

export default function Item({ members, setItemArr }: Props) {
  const [itemName, setItemName] = useState("");
  const [paidBy, setPaidBy] = useState("");
  const [price, setPrice] = useState("");

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

  return (
    <div className=" items-center justify-center">
      <div>
        <div>Step 2: Add Item</div>
        <div>You can edit after this</div>
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
    </div>
  );
}
