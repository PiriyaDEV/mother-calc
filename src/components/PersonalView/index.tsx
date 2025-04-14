import { FC, useEffect, useState } from "react";
import CommonBtn from "../CommonBtn";
import moment from "moment-timezone";

interface PersonalViewProps {
  onClick: () => void;
  registrationNo: string;
  name: string;
  roommateName: string;
  roomNo: string;
  isRoomSingle: string;
  checkedIn: boolean;
}

const PersonalView: FC<PersonalViewProps> = ({
  onClick,
  registrationNo,
  name,
  roommateName,
  roomNo,
  checkedIn = false,
  isRoomSingle = "Y",
}) => {
  const [isEnabled, setIsEnabled] = useState(false);

  useEffect(() => {
    const checkTime = () => {
      const currentTime = moment.tz("Asia/Bangkok");
      const targetTime = moment.tz("2025-02-27 15:54:00", "Asia/Bangkok");

      if (currentTime.isAfter(targetTime, "minute")) {
        setIsEnabled(true);
      }
    };
    checkTime();

    const interval = setInterval(checkTime, 60000);

    if (isEnabled) {
      clearInterval(interval);
    }
    return () => clearInterval(interval);
  }, [isEnabled]);

  return (
    <div>
      <div className="flex items-center flex-col">
        <p className="text-base font-medium">Your registration no. is </p>
        <div className="text-8xl leading-none font-bold mt-2">
          {registrationNo}
        </div>
      </div>

      <div className="w-full flex justify-center flex-col bg-[rgba(34,17,103,0.4)] gap-6 p-6 rounded-[10px] mt-6">
        <div className="flex flex-col gap-2">
          <p className="text-base font-medium">Name</p>
          <span className="text-2xl font-bold">{name}</span>
        </div>

        {roommateName && (
          <div className="flex flex-col gap-2">
            <p className="text-base font-medium">Roommate&apos;s Name</p>
            <span className="text-2xl font-bold">{roommateName}</span>
          </div>
        )}

        <div className="flex flex-col gap-2">
          <p className="text-base font-medium">Room No.</p>
          <span className="text-2xl font-bold">{roomNo}</span>
        </div>

        <div className="flex flex-col gap-2">
          <p className="text-base font-medium">Room Type</p>
          <span className="text-2xl font-bold">
            {isRoomSingle === "Y" ? "Single" : "Double"}
          </span>
        </div>

        {isEnabled && (
          <CommonBtn
            text={checkedIn ? "View Agenda" : "Check in"}
            onClick={onClick}
            className="min-w-full"
          />
        )}
      </div>
    </div>
  );
};

export default PersonalView;
