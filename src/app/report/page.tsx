"use client";

import PersonalView from "@/components/PersonalView";
import UserCard from "@/components/UserCard";
import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { cleanData } from "../lib/utils";
import CommonLoading from "@/components/CommonLoading";
import { isValidInput } from "@/utils";

const ReportContent = () => {
  const [matchedUser, setMatchedUser] = useState<any>(null);
  const [isAdmin, setIsAdmin] = useState<boolean>(false);
  const [userLoading, setUserLoading] = useState<boolean>(true);
  const [allUserLoading, setAllUserLoading] = useState<boolean>(true);
  const [allUsers, setAllUsers] = useState<any>(null);

  const [activeTab, setActiveTab] = useState("personal");
  const router = useRouter();

  const searchParams = useSearchParams();
  const search = searchParams.get("search");

  const getAllUserGraph = async () => {
    const response = await fetch(`/api/user`);
    const result = await response.json();

    if (response) {
      const cleanedData = cleanData(result?.data?.boards[0].items_page.items);
      setAllUsers(cleanedData);
      setAllUserLoading(false);
    }
  };

  const getUserByColumnValueGraph = async (search: string) => {
    if (!isValidInput(search)) {
      router.push("/blank");
      return;
    }

    const response = await fetch(`/api/user/${search}`);
    const result = await response.json();

    if (response) {
      const cleanedData =
        cleanData(
          result?.data?.items_page_by_column_values?.items ?? []
        )?.[0] ?? {};

      if (!cleanedData.id) {
        router.push("/blank");
        return;
      }

      const isAdmin = cleanedData["Admin"] === "Y";
      setIsAdmin(isAdmin);
      setMatchedUser(cleanedData);

      if (isAdmin) {
        setAllUserLoading(true);
        setActiveTab("admin");
        getAllUserGraph();
      } else {
        setAllUserLoading(false);
      }

      setUserLoading(false);
    }
  };

  const postUserCheckedInGraph = async (id: string) => {
    const response = await fetch("/api/user", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id }),
    });

    if (response.ok) {
      router.push(`/agenda?search=${search}`);
    } else {
      console.error("Failed to update data:", response.statusText);
    }
  };

  useEffect(() => {
    if (search) {
      getUserByColumnValueGraph(search);
    } else {
      router.push("/blank");
    }
  }, [search]);

  return (
    <>
      {userLoading || allUserLoading ? (
        <CommonLoading />
      ) : (
        <div className="flex items-center flex-col gap-5 pt-[64px]">
          <div className="w-full">
            {isAdmin && (
              <div className="flex border-b border-white">
                {/* Admin View Tab */}
                <div
                  className={`w-full px-6 py-2 cursor-pointer text-white hover:text-white hover:font-bold transition-colors 
            border-b-2 border-transparent hover:border-white text-lg ${
              activeTab === "admin" ? "border-white font-bold" : ""
            }`}
                  onClick={() => setActiveTab("admin")}
                >
                  Admin View
                </div>

                {/* Personal View Tab */}
                <div
                  className={`w-full px-6 py-2 cursor-pointer text-white hover:text-white hover:font-bold transition-colors 
            border-b-2 border-transparent hover:border-white text-lg ${
              activeTab === "personal" ? "border-white font-bold" : ""
            }`}
                  onClick={() => setActiveTab("personal")}
                >
                  Personal View
                </div>
              </div>
            )}

            {/* Tab content */}
            <div className="mt-[40px] h-[calc(100vh-150px)] overflow-y-auto">
              {activeTab === "admin" && (
                <div className="flex flex-col gap-6 pb-5">
                  {allUsers?.map((matchedUser: any) => (
                    <UserCard
                      key={matchedUser["userNo"]}
                      registrationNo={matchedUser["userNo"]}
                      name={matchedUser["Name"]}
                      roommateName={matchedUser["Roommate"]}
                      roomNo={matchedUser["Room"]}
                      isRoomSingle={matchedUser["Single"]}
                      isCheckedIn={matchedUser["status"]?.index}
                    />
                  ))}
                </div>
              )}
              {activeTab === "personal" && (
                <div>
                  {matchedUser && (
                    <PersonalView
                      onClick={() => {
                        if (matchedUser["status"]?.index === 1) {
                          router.push(`/agenda?search=${search}`);
                        } else {
                          postUserCheckedInGraph(matchedUser["id"]);
                        }
                      }}
                      checkedIn={matchedUser["status"]?.index === 1}
                      registrationNo={matchedUser["userNo"]}
                      name={matchedUser["Name"]}
                      roommateName={matchedUser["Roommate"]}
                      roomNo={matchedUser["Room"]}
                      isRoomSingle={matchedUser["Single"]}
                    />
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default function Report() {
  return (
    <Suspense fallback={<CommonLoading />}>
      <ReportContent />
    </Suspense>
  );
}
