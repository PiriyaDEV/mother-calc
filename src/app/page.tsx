"use client";

import CommonBtn from "@/shared/components/CommonBtn";
import Calculate from "@/shared/pages/Calculate";
import Item from "@/shared/pages/Item";
import Member from "@/shared/pages/Member";
import Summary from "@/shared/pages/Summary";
import { useEffect, useState } from "react";

interface Member {
  name: string;
  color: string;
}

interface Item {
  itemName: string;
  paidBy: Member;
  price?: number;
  selectedMembers: Member[];
}

export default function App() {
  const [isMemberSet, setMemberSet] = useState(false);
  const [members, setMembers] = useState<Member[]>([]);
  const [itemArr, setItemArr] = useState<Item[]>([]);
  const [isItemModalOpen, setItemModalOpen] = useState(false);

  useEffect(() => {
    // Get the names of the currently active members
    const activeMemberNames = members.map((member) => member.name);

    setItemArr(
      (prevItemArr) =>
        prevItemArr
          .map((item) => {
            // Remove item if 'paidBy' is in removed members
            if (!activeMemberNames.includes(item.paidBy.name)) {
              return null; // This item should be removed
            }

            // Filter out removed members from selectedMembers
            const updatedSelectedMembers = item.selectedMembers.filter(
              (member) => activeMemberNames.includes(member.name)
            );

            return {
              ...item,
              selectedMembers: updatedSelectedMembers,
            };
          })
          .filter((item) => item !== null) // Remove null values (items that are deleted)
    );
  }, [members]);

  return (
    <div className="flex flex-col gap-10">
      {/* Member Screen */}
      {!isMemberSet && (
        <Member
          members={members}
          setMembers={setMembers}
          setIsMemberSet={setMemberSet}
        />
      )}

      {/* Calculate Screen */}
      {isMemberSet && (
        <>
          <Calculate
            members={members}
            itemArr={itemArr}
            setItemArr={setItemArr}
          />

          {/* <Summary members={members} itemArr={itemArr} /> */}

          {isItemModalOpen && (
            <div
              className="modal modal-open !text-black"
              onClick={(e) => {
                if (e.target === e.currentTarget) {
                  setItemModalOpen(false);
                }
              }}
            >
              <div className="modal-box">
                <Item
                  members={members}
                  setItemArr={setItemArr}
                  setItemModalOpen={setItemModalOpen}
                />
              </div>
            </div>
          )}

          <div className="absolute bottom-0 left-0 bg-white py-5 w-full">
            <div className="container mx-auto px-4 flex justify-between gap-7">
              <CommonBtn
                text="< ย้อนกลับ"
                type="secondary"
                onClick={() => {
                  setMemberSet(false);
                }}
                disabled={members.length === 0}
                className="!w-fit"
              />

              <CommonBtn
                text="เพิ่มรายการ"
                onClick={() => {
                  setItemModalOpen(true);
                }}
                disabled={members.length === 0}
                className="!w-fit"
              />
            </div>
          </div>
        </>
      )}
    </div>
  );
}
