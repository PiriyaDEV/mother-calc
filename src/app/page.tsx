"use client";

import Calculate from "@/shared/pages/Calculate";
import Item from "@/shared/pages/Item";
import Member from "@/shared/pages/Member";
import Summary from "@/shared/pages/Summary";
import { useState } from "react";

interface Member {
  name: string;
  color: string;
}

interface Item {
  itemName: string;
  paidBy: string;
  price?: number;
  selectedMembers: Member[];
}

export default function App() {
  const [page, setPage] = useState(1);
  const [members, setMembers] = useState<Member[]>([]);
  const [itemArr, setItemArr] = useState<Item[]>([]);

  return (
    <div className="flex items-center justify-center min-h-screen flex-col gap-10">
      {/* {page === 1 && <Member members={members} setMembers={setMembers} />}

      {page === 2 && <Item members={members} />} */}

      {/* <CommonBtn
        text="Next"
        onClick={() => {
          if (page < 3) {
            setPage(page + 1);
          }
        }}
      /> */}

      <Member members={members} setMembers={setMembers} />
      <Item members={members} setItemArr={setItemArr} />
      <Calculate members={members} itemArr={itemArr} setItemArr={setItemArr} />

      <Summary members={members} itemArr={itemArr}/>

      {/* <div>{JSON.stringify(itemArr, null, 2)}</div> */}
    </div>
  );
}
