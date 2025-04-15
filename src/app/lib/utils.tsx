import { MemberObj } from "@/app/lib/interface";

export const getMemberObjByName = (
  name: string,
  members: MemberObj[]
): MemberObj | undefined => {
  return members.find((m) => m.name === name);
};
