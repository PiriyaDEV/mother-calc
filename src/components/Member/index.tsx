"use client";

import CommonBtn from "@/components/CommonBtn";
import { ChangeEvent, useState } from "react";

interface Member {
  name: string;
  color: string;
}

interface Props {
  members: Member[];
  setMembers: React.Dispatch<React.SetStateAction<Member[]>>;
}

export default function Member({ members, setMembers }: Props) {
  const [name, setName] = useState<string>("");
  const [errorMsg, setErrorMsg] = useState<boolean>(false);

  const handleInputChange = (e: ChangeEvent<HTMLInputElement>) => {
    setName(e.target.value);
    setErrorMsg(false);
  };

  const getInitials = (name: string): string => {
    const trimmed = name.trim();
    const parts = trimmed.split(" ").filter(Boolean);

    if (parts.length === 1) {
      return parts[0].substring(0, 2).toUpperCase();
    }

    return parts
      .map((word) => word.charAt(0).toUpperCase())
      .join("")
      .slice(0, 2);
  };

  const getRandomColor = (): string => {
    const colors = [
      "#F87171",
      "#FBBF24",
      "#34D399",
      "#60A5FA",
      "#A78BFA",
      "#F472B6",
      "#FCD34D",
    ];
    return colors[Math.floor(Math.random() * colors.length)];
  };

  const onAddMember = () => {
    if (!name.trim()) {
      setErrorMsg(true);
      return;
    }

    const newMember: Member = {
      name: name.trim(),
      color: getRandomColor(),
    };

    setMembers((prev) => [...prev, newMember]);
    setName("");
  };

  return (
    <div className="flex items-center justify-center flex-col gap-10">
      <div>
        <div>Step 1: Add Member</div>
        <div>You can edit after this</div>
      </div>

      <div className="flex gap-2 flex-wrap">
        {members.length === 0 ? (
          <span className="text-xl">No Member added</span>
        ) : (
          members.map((member, index) => (
            <div
              key={index}
              className="w-16 h-16 rounded-full flex justify-center items-center"
              style={{ backgroundColor: member.color, color: "#fff" }}
              title={member.name}
            >
              <span className="text-xl font-semibold">
                {getInitials(member.name)}
              </span>
            </div>
          ))
        )}
      </div>

      <div className="flex items-center justify-center gap-2">
        <input
          type="text"
          placeholder="Please enter member name"
          className={`input input-bordered w-full max-w-xs ${
            errorMsg ? "border-red-500" : ""
          }`}
          value={name}
          onChange={handleInputChange}
        />
        <CommonBtn text="Add" onClick={onAddMember} className="!w-fit" />
      </div>

      <span>
        Member list: {members.map((member) => member.name).join(", ")}
      </span>
    </div>
  );
}
