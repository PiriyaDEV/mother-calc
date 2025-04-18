"use client";

import { useEffect, useState } from "react";
import { FaShareAlt } from "react-icons/fa";
import CommonBtn from "@/shared/components/CommonBtn";
import CommonLoading from "@/shared/components/CommonLoading";
import Calculate from "@/shared/pages/Calculate";
import Item from "@/shared/pages/Item";
import Member from "@/shared/pages/Member";
import Summary from "@/shared/pages/Summary";
import { ItemObj, MemberObj } from "./lib/interface";
import { PuffLoader } from "react-spinners";
import { FaList, FaTable } from "react-icons/fa";
import { encodeBase64, getShortUrl, getURLParams } from "./lib/utils";
import ItemModal from "@/shared/components/ItemModal";
import { MODE } from "./lib/constants";

export default function App() {
  const [isLoaded, setIsLoaded] = useState(false);
  const [isMember, setMember] = useState(false);
  const [isItemModalOpen, setItemModalOpen] = useState(false);
  const [screen, setScreen] = useState<"list" | "summary">("list");
  const [members, setMembers] = useState<MemberObj[]>([]);
  const [itemArr, setItemArr] = useState<ItemObj[]>([]);
  const [copySuccess, setCopySuccess] = useState(false); // State to track copy success
  const [billName, setBillName] = useState("ชื่อสมาชิก");
  const [mode, setMode] = useState(MODE.EDIT);

  // Load from URL parameters
  useEffect(() => {
    const {
      members: loadedMembers,
      itemArr: loadedItems,
      billName: loadedBillName,
      mode: loadedMode,
    } = getURLParams();
    setBillName(loadedBillName);
    setMembers(loadedMembers);
    setItemArr(loadedItems);
    setMode(loadedMode);
    setIsLoaded(true);
  }, []);

  // Update URL parameters when members or itemArr change
  useEffect(() => {
    if (!isLoaded) return;

    const params = new URLSearchParams();
    params.set("billName", encodeBase64(billName));
    params.set("members", encodeBase64(members));
    params.set("itemArr", encodeBase64(itemArr));
    params.set("mode", encodeBase64(mode));
    window.history.replaceState({}, "", "?" + params.toString());
  }, [members, itemArr, billName, mode, isLoaded]);

  // Handle the deletion of a member
  const handleDeleteMember = (deletedMember: MemberObj) => {
    // Remove the member from the members list
    const updatedMembers = members.filter(
      (member) => member.name !== deletedMember.name
    );
    setMembers(updatedMembers);

    // Remove items that are paid by the deleted member
    const updatedItems = itemArr.filter(
      (item) => item.paidBy !== deletedMember.name
    );

    // For items where the deleted member is selected, remove them from the selectedMembers list
    updatedItems.forEach((item) => {
      item.selectedMembers = item.selectedMembers.filter(
        (selectedMember) => selectedMember.name !== deletedMember.name
      );
    });

    setItemArr(updatedItems);
  };

  const handleShare = async () => {
    const longUrl = window.location.href;

    if (navigator.share) {
      try {
        const shortUrl = await getShortUrl(longUrl);

        await navigator.share({
          title: "📤 มาจ่ายเงินด้วยจ้า!",
          url: shortUrl,
        });

        console.log("Shared successfully");
      } catch (error) {
        if (error instanceof DOMException && error.name === "AbortError") {
          console.log("User canceled the share.");
        } else {
          console.error("Share failed:", error);
        }
      }
    } else {
      console.warn("Web Share API not supported.");
    }
  };

  const renderHeader = () => (
    <div className="flex items-center gap-10 justify-center">
      {["list", "summary"].map((view) => (
        <h1
          key={view}
          onClick={() => setScreen(view as "list" | "summary")}
          className={`font-bold cursor-pointer flex items-center gap-2 ${
            screen === view ? "text-black" : "!text-gray-400"
          }`}
        >
          {view === "list" ? <FaList /> : <FaTable />}
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
  };

  const renderModal = () =>
    isItemModalOpen && (
      <ItemModal
        members={members}
        itemArr={itemArr}
        setItemArr={setItemArr}
        setItemModalOpen={setItemModalOpen}
      />
    );

  const renderFooter = () => (
    <div className="absolute bottom-0 left-0 bg-white py-5 w-full">
      <div className="container mx-auto px-4 flex justify-between gap-7">
        <CommonBtn
          text="+ เพิ่มสมาชิก"
          type="secondary"
          onClick={() => setMember(true)}
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
      {isMember ? (
        <Member
          members={members}
          setMembers={setMembers}
          setIsMemberSet={setMember}
          onDeleteMember={handleDeleteMember}
        />
      ) : (
        <>
          <div className="flex items-center gap-3 whitespace-nowrap">
            <h1 className="font-bold">ชื่อบิล</h1>
            <input
              type="text"
              placeholder="ใส่ชื่อบิลที่นี่"
              className="font-bold text-[18px] input input-bordered w-full"
              value={billName}
              onChange={(e) => setBillName(e.target.value)}
            />
          </div>

          {renderHeader()}
          {renderBody()}
          {renderModal()}
          {renderFooter()}
        </>
      )}

      {/* Share Link Button */}
      <div className="absolute top-4 right-4">
        <button
          onClick={handleShare}
          className="p-2 bg-[#c5c6c7] text-white rounded-full flex items-center gap-2"
          title="Share link"
        >
          {!copySuccess ? (
            <FaShareAlt className="text-xs" />
          ) : (
            <PuffLoader
              color="white"
              loading={true}
              size={13}
              aria-label="Loading Spinner"
              data-testid="loader"
            />
          )}
        </button>
      </div>
    </div>
  );
}
