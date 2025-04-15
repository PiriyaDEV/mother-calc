"use client";

import { useEffect, useState } from "react";
import CommonBtn from "@/shared/components/CommonBtn";
import CommonLoading from "@/shared/components/CommonLoading";
import Calculate from "@/shared/pages/Calculate";
import Item from "@/shared/pages/Item";
import Member from "@/shared/pages/Member";
import Summary from "@/shared/pages/Summary";
import { ItemObj, MemberObj } from "./lib/interface";

export default function App() {
  const [isLoaded, setIsLoaded] = useState(false); // For hydration guard
  const [isMemberSet, setMemberSet] = useState(false);
  const [isItemModalOpen, setItemModalOpen] = useState(false);
  const [screen, setScreen] = useState<"list" | "summary">("list");
  const [members, setMembers] = useState<MemberObj[]>([]);
  const [itemArr, setItemArr] = useState<ItemObj[]>([]);

  // Load from localStorage on mount
  useEffect(() => {
    const storedMembers = localStorage.getItem("members");
    const storedItems = localStorage.getItem("itemArr");

    if (storedMembers) setMembers(JSON.parse(storedMembers));
    if (storedItems) setItemArr(JSON.parse(storedItems));

    setIsLoaded(true);
  }, []);

  // Update localStorage and filter invalid items when members change
  useEffect(() => {
    if (!isLoaded) return;

    localStorage.setItem("members", JSON.stringify(members));

    const activeNames = members.map((m) => m.name);
    const filteredItems = itemArr
      .map((item) => {
        if (!activeNames.includes(item.paidBy.name)) return null;

        const updatedSelectedMembers = item.selectedMembers.filter((m) =>
          activeNames.includes(m.name)
        );

        return { ...item, selectedMembers: updatedSelectedMembers };
      })
      .filter((item): item is ItemObj => item !== null);

    setItemArr(filteredItems);
  }, [members, isLoaded]);

  // Sync item array with localStorage
  useEffect(() => {
    if (isLoaded) {
      localStorage.setItem("itemArr", JSON.stringify(itemArr));
    }
  }, [itemArr, isLoaded]);

  const renderHeader = () => (
    <div className="flex items-center gap-6 justify-center">
      {["list", "summary"].map((view) => (
        <h1
          key={view}
          onClick={() => setScreen(view as "list" | "summary")}
          className={`font-bold cursor-pointer ${
            screen === view ? "text-black" : "!text-gray-400"
          }`}
        >
          {view === "list" ? "รายการ" : "ดูสรุป"}
        </h1>
      ))}
    </div>
  );

  const renderBody = () => {
    if (screen === "list") {
      return (
        <Calculate
          members={members}
          itemArr={itemArr}
          setItemArr={setItemArr}
        />
      );
    } else {
      return <Summary members={members} itemArr={itemArr} />;
    }

    // Future: render summary
    return null;
  };

  const renderModal = () =>
    isItemModalOpen && (
      <div
        className="modal modal-open !text-black"
        onClick={(e) => e.target === e.currentTarget && setItemModalOpen(false)}
      >
        <div className="modal-box">
          <Item
            members={members}
            setItemArr={setItemArr}
            setItemModalOpen={setItemModalOpen}
          />
        </div>
      </div>
    );

  const renderFooter = () => (
    <div className="absolute bottom-0 left-0 bg-white py-5 w-full">
      <div className="container mx-auto px-4 flex justify-between gap-7">
        <CommonBtn
          text="< ย้อนกลับ"
          type="secondary"
          onClick={() => setMemberSet(false)}
          disabled={members.length === 0}
          className="!w-fit"
        />
        <CommonBtn
          text="เพิ่มรายการ"
          onClick={() => setItemModalOpen(true)}
          disabled={members.length === 0}
          className="!w-fit"
        />
      </div>
    </div>
  );

  if (!isLoaded) return <CommonLoading />;

  return (
    <div className="flex flex-col gap-5">
      {!isMemberSet ? (
        <Member
          members={members}
          setMembers={setMembers}
          setIsMemberSet={setMemberSet}
        />
      ) : (
        <>
          {renderHeader()}
          {renderBody()}
          {renderModal()}
          {renderFooter()}
        </>
      )}
    </div>
  );
}
