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
      className={`btn btn-primary w-full max-w-xs font-bold text-xl bg-gradient-to-b from-[#3a2b77] to-[#261669] border-none ${className}`}
      onClick={onClick}
    >
      {text}
    </button>
  );
};

export default CommonBtn;
