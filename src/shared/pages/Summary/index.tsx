import { ItemObj, MemberObj } from "@/app/lib/interface";
import { getPrice } from "@/app/lib/utils";

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

  members.forEach((member) => {
    totals[member.name] = { paid: 0, shouldPay: 0 };
    debtMatrix[member.name] = {};
  });

  itemArr.forEach((item) => {
    const {
      price,
      vatRate: vat,
      serviceChargeRate: serviceCharge,
      paidBy,
      selectedMembers,
    } = item;

    totals[paidBy] = totals[paidBy] || { paid: 0, shouldPay: 0 };

    let itemTotal = 0;

    if (price !== undefined) {
      itemTotal = getPrice(price, vat, serviceCharge);
      totals[paidBy].paid += itemTotal;
    } else {
      const customTotal = selectedMembers.reduce((sum, m) => {
        const value = m.customPaid ?? 0;
        return sum + getPrice(value, vat, serviceCharge);
      }, 0);
      totals[paidBy].paid += customTotal;
      itemTotal = customTotal;
    }

    const customMembers = selectedMembers.filter(
      (m) => m.customPaid !== undefined
    );

    const customTotal = customMembers.reduce((sum, m) => {
      const value = m.customPaid ?? 0;
      return sum + getPrice(value, vat, serviceCharge);
    }, 0);

    const others = selectedMembers.filter((m) => m.customPaid === undefined);
    const splitAmount =
      price && others.length > 0
        ? (itemTotal - customTotal) / others.length
        : 0;

    selectedMembers.forEach((member) => {
      totals[member.name] = totals[member.name] || { paid: 0, shouldPay: 0 };
      const shouldPayAmount =
        member.customPaid !== undefined
          ? getPrice(member.customPaid, vat, serviceCharge)
          : splitAmount;

      totals[member.name].shouldPay += shouldPayAmount;

      if (paidBy !== member.name) {
        debtMatrix[paidBy][member.name] = debtMatrix[paidBy][member.name] || 0;
        debtMatrix[paidBy][member.name] += shouldPayAmount;
      }
    });
  });

  return (
    <div
      className="pb-5"
      style={{
        paddingBottom: "120px",
      }}
    >
      {itemArr.length !== 0 ? (
        <>
          <h1 className="font-bold my-3">ตารางสรุป</h1>
          <div className="overflow-x-auto pb-5">
            <table className="min-w-full border border-gray-300 border-collapse text-sm">
              <thead>
                <tr className="bg-[#4366f4] text-white">
                  <th className="px-2 py-1 text-left border border-gray-300">
                    ชื่อ
                  </th>
                  <th className="px-2 py-1 text-left border border-gray-300">
                    ค่าใช้จ่ายทั้งหมด
                  </th>
                  <th className="px-2 py-1 text-left border border-gray-300">
                    จำนวนเงินที่ออก
                  </th>
                  <th className="px-2 py-1 text-left border border-gray-300">
                    เงินที่ต้องจ่าย
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
                      <td className={`px-2 py-1 border border-gray-300`}>
                        {(paid + shouldPay).toLocaleString("en-US", {
                          minimumFractionDigits: 2,
                          maximumFractionDigits: 2,
                        })}
                      </td>

                      <td className="px-2 py-1 border border-gray-300">
                        {paid.toLocaleString("en-US", {
                          minimumFractionDigits: 2,
                          maximumFractionDigits: 2,
                        })}
                      </td>
                      <td
                        className={`px-2 py-1 border border-gray-300 ${
                          paid - shouldPay > 0
                            ? "bg-green-100 text-green-800"
                            : paid - shouldPay < 0
                            ? "bg-red-100 text-red-800"
                            : ""
                        }`}
                      >
                        {paid - shouldPay > 0 && "+"}
                        {paid - shouldPay < 0 && "-"}
                        {shouldPay.toLocaleString("en-US", {
                          minimumFractionDigits: 2,
                          maximumFractionDigits: 2,
                        })}

                        {paid - shouldPay > 0 && " (ได้คืน)"}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          <h1 className="font-bold my-3">ตารางต่อรายบุคคล</h1>
          <div className="overflow-x-auto pb-5">
            <table className="min-w-full border border-gray-300 border-collapse text-sm">
              <thead>
                <tr className="bg-[#4366f4] text-white">
                  <th className="border border-gray-300 bg-white"></th>
                  <th
                    colSpan={members.length}
                    className="px-2 py-2 text-center border border-gray-300"
                  >
                    เงินที่ต้องจ่าย (-)
                  </th>
                </tr>
                <tr className="bg-[#4366f4] text-white">
                  <th className="px-2 py-1 text-left border border-gray-300 max-w-[80px]">
                    เงินที่ต้องได้คืน (+)
                  </th>
                  {members.map((member) => (
                    <th
                      key={member.name}
                      className="px-2 py-1 text-left border border-gray-300 text-black"
                      style={{ background: member.color }}
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
                      const debt =
                        debtMatrix[rowMember.name][colMember.name] ?? 0;
                      const formattedDebt = debt.toLocaleString("en-US", {
                        minimumFractionDigits: 2,
                        maximumFractionDigits: 2,
                      });
                      return (
                        <td
                          key={colMember.name}
                          className={`px-2 py-1 border border-gray-300 ${
                            debt === 0 ? "bg-gray-100" : ""
                          }`}
                        >
                          {debt > 0 ? formattedDebt : "-"}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      ) : (
        <div className="flex justify-center">
          <div className="text-center">
            <p className="!font-bold">ยังไม่มีข้อมูล</p>
            <p className="mt-1 !text-gray-400">
              กรุณาเพิ่มรายการที่ปุ่ม "เพิ่มรายการ"
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
