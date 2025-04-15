import { FC } from "react";

interface CommonBtnProps {
  onClick: () => void;
  className?: string;
  text: string;
}

const CommonBtn: FC<CommonBtnProps> = ({
  onClick,
  className = "",
  text = "Click",
}) => {
  return (
    <button
      className={`btn btn-primary w-full px-5 max-w-xs font-bold text-md bg-[#4366f4] border-none ${className}`}
      onClick={onClick}
    >
      {text}
    </button>
  );
};

export default CommonBtn;
