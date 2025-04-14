"use client";

import Item from "@/shared/pages/Item";
import Member from "@/shared/pages/Member";
import { useState } from "react";

interface Member {
  name: string;
  color: string;
}

export default function App() {
  const [page, setPage] = useState(1);
  const [members, setMembers] = useState<Member[]>([]);

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
      <Item members={members} />
    </div>
  );
}
