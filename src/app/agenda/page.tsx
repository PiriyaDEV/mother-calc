"use client";

import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { cleanData } from "../lib/utils";
import CommonLoading from "@/components/CommonLoading";
import CommonBtn from "@/components/CommonBtn";
// import Image from "next/image";
// import activitiesImg from "../../../public/images/activities.png";
import { isValidInput } from "@/utils";

interface AgendaItem {
  time: string;
  detail: string;
  additional?: string;
}

interface Agenda {
  date: string;
  data: AgendaItem[];
}

const agendaData: Agenda[] = [
  {
    date: "28 March 2025",
    data: [
      {
        time: "08:00 - 09:00",
        detail:
          "Company bus participants gather at IBMDT Spring Tower office round-about. Bus departure is at 9:00 AM",
      },
      { time: "09:00 - 11:45", detail: "Travel to Pattaya" },
      {
        time: "11:45 - 12:00",
        detail:
          "Registration and check-in Veranda Resort Pattaya at welcome area. Pick up your IBMDT Team Building T-Shirt upon registration.",
      },

      {
        time: "12:00 - 13:00",
        detail: "Lunch at the hotel",
      },
      {
        time: "13:00 - 16:00",
        detail:
          "Team-building activities at Veranda Resort Pattaya. Dress code: Wear your IBMDT T-shirt with comfortable attire",
      },
      {
        time: "16:00 - 16:30",
        detail: "Room keys distributed coffee break.",
      },
      {
        time: "16:30 - 18:00",
        detail: "Relaxation and free time",
      },
      {
        time: "18:00 - 22:00",
        detail:
          "Dinner and social activities at the hotel. Evening dress code: “I Wanna Be..” !",
      },
    ],
  },
  {
    date: "29 March 2025",
    data: [
      {
        time: "08:00 - 10:00",
        detail: "Breakfast",
      },
      { time: "10:00 - 11:00", detail: "Checkout" },
      { time: "11:00", detail: "Bus departs from Pattaya to Bangkok" },
    ],
  },
];

const AgendaContent = () => {
  const [matchedUser, setMatchedUser] = useState<any>(null);
  const [userLoading, setUserLoading] = useState<boolean>(true);

  const searchParams = useSearchParams();
  const search = searchParams.get("search");
  const router = useRouter();

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

      if (cleanedData["status"]["index"] === 0) {
        router.push(`/report?search=${search}`);
        return;
      }

      if (cleanedData) {
        setMatchedUser(cleanedData);
      }

      setUserLoading(false);
    }
  };

  useEffect(() => {
    if (search) {
      getUserByColumnValueGraph(search);
    }
  }, [search]);

  function formatTime(dateStr: string) {
    const date = new Date(dateStr);
    return date.toLocaleTimeString("en-US", {
      timeZone: "Asia/Bangkok",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hour12: true,
    });
  }

  return (
    <>
      {userLoading ? (
        <CommonLoading />
      ) : (
        <div className="flex flex-col min-h-screen gap-6 pt-[64px] pb-7">
          <div className="flex flex-col gap-8">
            <div>
              {matchedUser && (
                <>
                  <p className="text-2xl font-bold">
                    Hi, {matchedUser["Name"]}
                  </p>
                  <p className="text-lg font-medium">
                    Successfully checked in at{" "}
                    {formatTime(matchedUser["status"].changed_at)}
                  </p>
                </>
              )}
            </div>

            <div className="flex flex-col gap-8">
              <hr className="h-px my-2 bg-gray-200 border-0" />
              <p className="text-xl font-bold">Itinerary</p>

              {agendaData.map((agenda, index) => (
                <div key={index}>
                  <div className="bg-[#231269] px-4 py-2 rounded-t-[10px] text-xl font-bold w-fit border-x border-t border-white border-opacity-20">
                    {agenda.date}
                  </div>
                  <div className="w-full flex justify-center flex-col bg-[rgba(34,17,103,0.4)] gap-6 p-6 rounded-b-[10px] rounded-tr-[10px] border border-white border-opacity-20">
                    {agenda.data.map((item, itemIndex) => (
                      <div
                        key={itemIndex}
                        className="grid grid-cols-[2fr,3fr] gap-4"
                      >
                        <p className="text-base font-bold">{item.time}</p>
                        <div>
                          <p className="text-base font-medium">{item.detail}</p>
                          {item.additional && (
                            <span className="text-xs font-normal">
                              {item.additional}
                            </span>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>

          <CommonBtn
            text="Go to Mainpage"
            onClick={() => {
              router.push("/");
            }}
            className="min-w-full"
          />

          {/* <Image
            src={activitiesImg}
            alt="IBM Logo"
            // width={"100%"}
            style={{
              display: "block",
              marginLeft: "auto",
              marginRight: "auto",
            }}
          /> */}
        </div>
      )}
    </>
  );
};

export default function Agenda() {
  return (
    <Suspense fallback={<CommonLoading />}>
      <AgendaContent />
    </Suspense>
  );
}
