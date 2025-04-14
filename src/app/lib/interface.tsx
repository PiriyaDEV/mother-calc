export interface StoredMatchedUser {
  "No.": string;
  "Register Name": string;
  "Register eMail": string;
  "Roommate Name": string;
  "Single Stay room": string;
  Remark: string;
  "Room No.": number;
  "Host Flag": string;
  "Check-in Date/Time": string;
}

export interface CleanedData {
  id: string;
  subItems: string;
  status: {
    changed_at: string;
    index: number;
  };
  [key: string]: any;
}

export interface Data {
  boards: Board[];
}

export interface Board {
  items_page: ItemsPage;
}

export interface ItemsPage {
  cursor: string | null;
  items: any[];
}

export interface ColumnValue {
  column: { title: string };
  value: any;
  type: string;
}
