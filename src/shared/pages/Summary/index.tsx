import { ItemObj, MemberObj } from "@/app/lib/interface";

interface SummaryProps {
  itemArr: ItemObj[];
  members: MemberObj[];
}

interface Totals {
  [name: string]: {
    paid: number;
    shouldPay: number;
  };
}

interface DebtMatrix {
  [paidBy: string]: {
    [to: string]: number;
  };
}

export default function Summary({ itemArr, members }: SummaryProps) {
  const totals: Totals = {};
  const debtMatrix: DebtMatrix = {};

  // Initialize totals for all members with zero
  members.forEach((member) => {
    totals[member.name] = { paid: 0, shouldPay: 0 };
    debtMatrix[member.name] = {};
  });

  // Process items
  itemArr.forEach((item) => {
    const { price, paidBy, selectedMembers } = item;

    // Ensure payer is initialized, using the name instead of full object
    totals[paidBy] = totals[paidBy] || { paid: 0, shouldPay: 0 };

    // Add to paid total
    if (price !== undefined) {
      totals[paidBy].paid += price;
    } else {
      const customTotal = selectedMembers.reduce(
        (sum, m) => sum + (m.customPaid || 0),
        0
      );
      totals[paidBy].paid += customTotal;
    }

    // Calculate shouldPay
    const customMembers = selectedMembers.filter(
      (m) => m.customPaid !== undefined
    );
    const customTotal = customMembers.reduce(
      (sum, m) => sum + (m.customPaid || 0),
      0
    );
    const others = selectedMembers.filter((m) => m.customPaid === undefined);
    const splitAmount =
      price && others.length > 0 ? (price - customTotal) / others.length : 0;

    selectedMembers.forEach((member) => {
      totals[member.name] = totals[member.name] || { paid: 0, shouldPay: 0 };
      totals[member.name].shouldPay += member.customPaid ?? splitAmount;

      // Update debt matrix
      if (paidBy !== member.name) {
        const amount = price ? splitAmount : member.customPaid || 0;
        debtMatrix[paidBy][member.name] = debtMatrix[paidBy][member.name] || 0;
        debtMatrix[paidBy][member.name] += amount;
      }
    });
  });

  return (
    <div
      className="overflow-y-auto pb-5"
      style={{ height: "calc(100vh - 200px)", overflowY: "auto" }}
    >
      {/* Summary Table */}
      <h1 className="font-bold my-3">ตารางสรุป</h1>
      <div className="overflow-x-auto pb-5">
        <table className="min-w-full border border-gray-300 border-collapse text-sm">
          <thead>
            <tr className="bg-[#4366f4] text-white">
              <th className="px-2 py-1 text-left border border-gray-300">
                ชื่อ
              </th>
              <th className="px-2 py-1 text-left border border-gray-300">
                ต้องจ่าย
              </th>
              <th className="px-2 py-1 text-left border border-gray-300">
                จ่ายไป
              </th>
              <th className="px-2 py-1 text-left border border-gray-300">
                ทั้งหมด
              </th>
            </tr>
          </thead>
          <tbody>
            {members.map((member, index) => {
              const { name } = member;
              const { paid, shouldPay } = totals[name] || {
                paid: 0,
                shouldPay: 0,
              };
              return (
                <tr
                  key={name + index}
                  className={index % 2 === 0 ? "bg-white" : "bg-gray-50"}
                >
                  <td
                    className="px-2 py-1 border border-gray-300 font-semibold"
                    style={{ background: member.color }}
                  >
                    {name}
                  </td>
                  <td className="px-2 py-1 border border-gray-300">
                    {shouldPay.toFixed(2)}
                  </td>
                  <td className="px-2 py-1 border border-gray-300">
                    {paid.toFixed(2)}
                  </td>
                  <td
                    className={`px-2 py-1 border border-gray-300 ${
                      paid - shouldPay >= 0
                        ? "bg-green-100 text-green-800"
                        : "bg-red-100 text-red-800"
                    }`}
                  >
                    {(paid - shouldPay).toFixed(2)}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Debt Matrix Table */}
      <h1 className="font-bold my-3">ตารางที่ต้องได้</h1>
      <div className="overflow-x-auto pb-5">
        <table className="min-w-full border border-gray-300 border-collapse text-sm">
          <thead>
            <tr className="bg-[#4366f4] text-white">
              <th className="px-2 py-1 text-left border border-gray-300"></th>
              {members.map((member) => (
                <th
                  key={member.name}
                  className="px-2 py-1 text-left border border-gray-300"
                >
                  {member.name}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {members.map((rowMember) => (
              <tr key={rowMember.name}>
                <td
                  className="px-2 py-1 border border-gray-300 font-semibold"
                  style={{ background: rowMember.color }}
                >
                  {rowMember.name}
                </td>
                {members.map((colMember) => {
                  const debt = debtMatrix[rowMember.name][colMember.name] ?? 0;
                  return (
                    <td
                      key={colMember.name}
                      className={`px-2 py-1 border border-gray-300 ${
                        debt > 0 ? "bg-green-100 text-green-800" : ""
                      }`}
                    >
                      {debt > 0 ? `+${debt.toFixed(2)}` : debt.toFixed(2)}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
