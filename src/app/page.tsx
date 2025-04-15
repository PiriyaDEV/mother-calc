"use client";

import { useEffect, useState } from "react";
import { FaShareAlt } from "react-icons/fa"; // Import the share icon from react-icons
import CommonBtn from "@/shared/components/CommonBtn";
import CommonLoading from "@/shared/components/CommonLoading";
import Calculate from "@/shared/pages/Calculate";
import Item from "@/shared/pages/Item";
import Member from "@/shared/pages/Member";
import Summary from "@/shared/pages/Summary";
import { ItemObj, MemberObj } from "./lib/interface";
import { PuffLoader } from "react-spinners";
import { FaList, FaTable } from "react-icons/fa";

// Helper functions (encode and decode as before)
const encodeBase64 = (data: any) => {
  const jsonString = JSON.stringify(data);
  const utf8Array = new TextEncoder().encode(jsonString);
  let binary = "";
  utf8Array.forEach((byte) => {
    binary += String.fromCharCode(byte);
  });
  return btoa(binary);
};

const decodeBase64 = (data: string) => {
  try {
    const decodedString = atob(data);
    const utf8Array = Array.from(decodedString).map((char) =>
      char.charCodeAt(0)
    );
    const jsonString = new TextDecoder().decode(new Uint8Array(utf8Array));
    return JSON.parse(jsonString);
  } catch (e) {
    return [];
  }
};

// Function to get URL parameters (Base64 encoded)
const getURLParams = () => {
  const params = new URLSearchParams(window.location.search);
  const membersParam = params.get("members");
  const itemArrParam = params.get("itemArr");

  return {
    members: membersParam ? decodeBase64(membersParam) : [],
    itemArr: itemArrParam ? decodeBase64(itemArrParam) : [],
  };
};

export default function App() {
  const [isLoaded, setIsLoaded] = useState(false);
  const [isMember, setMember] = useState(false);
  const [isItemModalOpen, setItemModalOpen] = useState(false);
  const [screen, setScreen] = useState<"list" | "summary">("list");
  const [members, setMembers] = useState<MemberObj[]>([]);
  const [itemArr, setItemArr] = useState<ItemObj[]>([]);
  const [copySuccess, setCopySuccess] = useState(false); // State to track copy success

  // Load from URL parameters
  useEffect(() => {
    const { members: loadedMembers, itemArr: loadedItems } = getURLParams();
    setMembers(loadedMembers);
    setItemArr(loadedItems);
    setIsLoaded(true);
  }, []);

  // Update URL parameters when members or itemArr change
  useEffect(() => {
    if (!isLoaded) return;

    const params = new URLSearchParams();
    params.set("members", encodeBase64(members));
    params.set("itemArr", encodeBase64(itemArr));
    window.history.replaceState({}, "", "?" + params.toString());
  }, [members, itemArr, isLoaded]);

  const handleShare = () => {
    const currentUrl = window.location.href;
    if (navigator.share) {
      navigator
        .share({
          title: "Check out this link!",
          url: currentUrl,
        })
        .then(() => {
          console.log("Thanks for sharing!");
        })
        .catch((error) => {
          console.error("Error sharing:", error);
        });
    } else {
      alert("Sharing not supported on this device.");
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
        />
      ) : (
        <>
          {renderHeader()}
          {renderBody()}
          {renderModal()}
          {renderFooter()}
        </>
      )}

      {/* Share Link Button */}
      <div className="absolute top-4 right-4">
        <button
          onClick={handleShare} // Change to trigger native share
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
