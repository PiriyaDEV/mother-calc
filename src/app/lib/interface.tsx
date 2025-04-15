export interface MemberObj {
  name: string;
  color: string;
  customPaid?: number;
}

export interface ItemObj {
  itemName: string;
  paidBy: MemberObj;
  price?: number;
  selectedMembers: MemberObj[];
}
