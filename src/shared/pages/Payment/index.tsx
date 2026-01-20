import { ItemObj, MemberObj } from "@/app/lib/interface";
import { getPrice } from "@/app/lib/utils";

interface PaymentProps {
  itemArr: ItemObj[];
  members: MemberObj[];
  payer: string;
  setPayer: (payer: string) => void;
}

interface DebtMatrix {
  [paidBy: string]: {
    [to: string]: number;
  };
}

interface PaymentDetail {
  receiver: string;
  amount: number;
  color: string;
}

export default function Payment({
  itemArr,
  members,
  payer,
  setPayer,
}: PaymentProps) {
  // Calculate debt matrix
  const debtMatrix: DebtMatrix = {};

  members.forEach((member) => {
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

    let itemTotal = 0;

    if (price !== undefined) {
      itemTotal = getPrice(price, vat, serviceCharge);
    } else {
      const customTotal = selectedMembers.reduce((sum, m) => {
        const value = m.customPaid ?? 0;
        return sum + getPrice(value, vat, serviceCharge);
      }, 0);
      itemTotal = customTotal;
    }

    const customMembers = selectedMembers.filter(
      (m) => m.customPaid !== undefined,
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
      const shouldPayAmount =
        member.customPaid !== undefined
          ? getPrice(member.customPaid, vat, serviceCharge)
          : splitAmount;

      if (paidBy !== member.name) {
        debtMatrix[paidBy][member.name] = debtMatrix[paidBy][member.name] || 0;
        debtMatrix[paidBy][member.name] += shouldPayAmount;
      }
    });
  });

  // Get payment details for selected payer
  const paymentDetails: PaymentDetail[] = [];
  let totalToPay = 0;

  if (payer) {
    members.forEach((member) => {
      const amount = debtMatrix[member.name]?.[payer] ?? 0;
      if (amount > 0) {
        paymentDetails.push({
          receiver: member.name,
          amount: amount,
          color: member.color,
        });
        totalToPay += amount;
      }
    });
  }

  return (
    <div className="pb-5 mt-[190px]" style={{ paddingBottom: "120px" }}>
      <div>
        {/* Payer Selection */}
        <div className="mb-6">
          <h1 className="font-bold my-3">คนจ่ายเงิน</h1>
          <select
            value={payer}
            onChange={(e) => setPayer(e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">เลือกคนจ่ายเงิน</option>
            {members.map((member) => (
              <option key={member.name} value={member.name}>
                {member.name}
              </option>
            ))}
          </select>
        </div>

        {/* Payment Details */}
        {payer && (
          <div className="space-y-4">
            {paymentDetails.length > 0 ? (
              <>
                {/* Total Summary */}
                <div className="p-4 bg-gradient-to-r from-red-50 to-pink-50 rounded-lg border-2 border-red-200">
                  <p className="text-gray-700 text-center mb-2">
                    <span className="font-semibold text-lg">{payer}</span>{" "}
                    ต้องจ่ายเงินทั้งหมด
                  </p>
                  <p className="text-4xl font-bold text-red-600 text-center">
                    {totalToPay.toLocaleString("en-US", {
                      minimumFractionDigits: 2,
                      maximumFractionDigits: 2,
                    })}{" "}
                    <span className="text-2xl">บาท</span>
                  </p>
                </div>

                {/* Individual Payments */}
                <div className="mt-6">
                  <h2 className="font-semibold text-gray-700 mb-3">
                    รายละเอียดการจ่ายเงิน
                  </h2>
                  <div className="space-y-3">
                    {paymentDetails.map((detail) => (
                      <div
                        key={detail.receiver}
                        className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-200 hover:shadow-md transition-shadow"
                        onClick={() => {
                          window.open(
                            "https://promptpay.io/0896832465/123",
                            "_blank",
                            "noopener,noreferrer",
                          );
                        }}
                      >
                        <div className="flex items-center gap-3">
                          <div
                            className="w-10 h-10 rounded-full flex items-center justify-center font-semibold text-sm"
                            style={{ background: detail.color }}
                          >
                            {detail.receiver.charAt(0)}
                          </div>
                          <div>
                            <p className="font-semibold text-gray-800">
                              {detail.receiver}
                            </p>
                            <p className="text-sm text-gray-500">คนรับเงิน</p>
                          </div>
                        </div>
                        <div className="text-right">
                          <p className="text-2xl font-bold text-blue-600">
                            {detail.amount.toLocaleString("en-US", {
                              minimumFractionDigits: 2,
                              maximumFractionDigits: 2,
                            })}
                          </p>
                          <p className="text-sm text-gray-500">บาท</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </>
            ) : (
              <div className="text-center py-8 bg-green-50 rounded-lg border-2 border-green-200">
                <p className="text-xl font-semibold text-green-600">
                  🎉 {payer} ไม่มีหนี้ที่ต้องจ่าย
                </p>
                <p className="text-gray-600 mt-2">ยอดเยี่ยม!</p>
              </div>
            )}
          </div>
        )}

        {/* Instruction */}
        {!payer && (
          <div className="text-center py-8 text-gray-500">
            <p>กรุณาเลือกคนจ่ายเงิน</p>
          </div>
        )}
      </div>
    </div>
  );
}
