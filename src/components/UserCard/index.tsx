import { FC } from "react";
import { FaCheckCircle } from "react-icons/fa";

interface UserCardProps {
  registrationNo: string;
  name: string;
  roommateName: string;
  roomNo: string;
  isRoomSingle: string;
  isCheckedIn: number;
}

const UserCard: FC<UserCardProps> = ({
  registrationNo,
  name,
  roommateName,
  roomNo,
  isRoomSingle = "Y",
  isCheckedIn,
}) => {
  return (
    <div className="w-full flex justify-center flex-col bg-[rgba(34,17,103,0.4)] gap-3 p-6 rounded-[10px]">
      <div className="flex items-start justify-between">
        <div className="flex flex-col gap-2">
          <p className="text-xs font-medium">Name</p>
          <span className="text-base font-bold">{name}</span>
        </div>

        {isCheckedIn === 1 && (
          <div className="bg-[#AFFFAF] px-2 py-1 rounded-[100px] text-[#221166] font-medium w-fit flex items-center justify-center gap-2 whitespace-nowrap">
            Checked in
            <FaCheckCircle className="text-[#00BA00]" />
          </div>
        )}
      </div>

      {roommateName && (
        <div className="flex flex-col gap-2">
          <p className="text-xs font-medium">Roommate&apos;s Name</p>
          <span className="text-base font-bold">{roommateName}</span>
        </div>
      )}

      <div className="grid grid-cols-3 gap-x-4">
        <div className="flex flex-col gap-2">
          <p className="text-xs font-medium">Regis No.</p>
          <span className="text-base font-bold">{registrationNo}</span>
        </div>
        <div className="flex flex-col gap-2">
          <p className="text-xs font-medium">Room No.</p>
          <span className="text-base font-bold">{roomNo}</span>
        </div>
        <div className="flex flex-col gap-2">
          <p className="text-xs font-medium">Room Type</p>
          <span className="text-base font-bold">
            {isRoomSingle === "Y" ? "Single" : "Double"}
          </span>
        </div>
      </div>
    </div>
  );
};

export default UserCard;
