import { ItemObj, MemberObj } from "@/app/lib/interface";
import { getPrice } from "@/app/lib/utils";
import { useEffect } from "react";

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

  useEffect(() => {
    if (!payer && members.length > 0) {
      setPayer(members[0].name);
    }
  }, [members, payer, setPayer]);

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

  // Simplify debts by netting out mutual obligations
  const simplifiedDebtMatrix: DebtMatrix = {};
  members.forEach((member) => {
    simplifiedDebtMatrix[member.name] = {};
  });

  members.forEach((personA) => {
    members.forEach((personB) => {
      if (personA.name !== personB.name) {
        const aOwesB = debtMatrix[personB.name]?.[personA.name] ?? 0;
        const bOwesA = debtMatrix[personA.name]?.[personB.name] ?? 0;

        if (aOwesB > bOwesA) {
          // A owes B the net amount
          simplifiedDebtMatrix[personB.name][personA.name] = aOwesB - bOwesA;
        } else if (bOwesA > aOwesB) {
          // B owes A the net amount
          simplifiedDebtMatrix[personA.name][personB.name] = bOwesA - aOwesB;
        }
        // If equal, both debts cancel out (no entry needed)
      }
    });
  });

  // Get payment details for selected payer
  const paymentDetails: PaymentDetail[] = [];
  let totalToPay = 0;

  if (payer) {
    members.forEach((member) => {
      const amount = simplifiedDebtMatrix[member.name]?.[payer] ?? 0;
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

  function maskThaiContact(value?: string) {
    if (!value) return "";

    const digits = value.replace(/\D/g, "");

    // Phone number (10 digits) → 081-xxx-x678
    if (digits.length === 10) {
      return digits.replace(/^(\d{3})\d{3}(\d{4})$/, "$1-xxx-$2");
    }

    // Thai ID card (13 digits) → 1-234x-xxxxx-xx-7
    if (digits.length === 13) {
      return "";
    }

    return value;
  }

  return (
    <div
      className="fixed inset-0 flex flex-col bg-white
             w-full sm:max-w-[450px]
             left-1/2 -translate-x-1/2"
      style={{ top: "190px" }}
    >
      {/* Fixed Header Section */}
      <div className="flex-shrink-0 bg-white border-b border-gray-200">
        {/* Payer Selection */}
        <div className="p-4 pt-2">
          <h1 className="font-bold mb-3">คนจ่ายเงิน</h1>
          <select
            value={payer}
            onChange={(e) => setPayer(e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            {/* <option value="">เลือกคนจ่ายเงิน</option> */}
            {members.map((member) => (
              <option key={member.name} value={member.name}>
                {member.name}
              </option>
            ))}
          </select>
        </div>

        {/* Total Summary - Fixed */}
        {payer && paymentDetails.length > 0 && (
          <div className="px-4 pb-4">
            <div className="p-1 bg-gradient-to-r from-red-50 to-pink-50 rounded-lg border border-red-200 flex items-center justify-center gap-2 text-red-600">
              <span className="font-semibold text-gray-700">{payer}</span>
              <span className="text-gray-700">ต้องจ่าย</span>
              <span className="font-bold text-lg">
                {totalToPay.toLocaleString("en-US", {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2,
                })}
              </span>
              <span className="text-sm">บาท</span>
            </div>
          </div>
        )}
      </div>

      {/* Scrollable Payment Details Section */}
      <div className="flex-1 overflow-y-auto">
        {payer && (
          <div className="p-4">
            {paymentDetails.length > 0 ? (
              <div>
                <div className="space-y-3">
                  {paymentDetails.map((detail, index) => {
                    const receiverMember = members.find(
                      (m) => m.name === detail.receiver,
                    );

                    const hasPhoneNumber =
                      receiverMember?.phoneNumber &&
                      receiverMember.phoneNumber.trim() !== "";

                    return (
                      <div
                        key={`${detail.receiver}-${index}`}
                        className={`p-4 bg-white rounded-lg border border-gray-200
        ${hasPhoneNumber ? "hover:shadow-md cursor-pointer" : ""}
        transition-shadow`}
                      >
                        {/* Top Section: Avatar, Name, Amount */}
                        <div className="flex items-center justify-between mb-4">
                          <div className="flex items-center gap-3">
                            <div
                              className="w-10 h-10 rounded-full flex items-center justify-center font-bold text-lg text-white"
                              style={{ background: detail.color }}
                            >
                              {detail.receiver.charAt(0)}
                            </div>

                            <div>
                              <p className="font-bold text-xl text-gray-800">
                                {detail.receiver}
                              </p>
                              <p className="text-sm text-gray-500">
                                {hasPhoneNumber
                                  ? "คนรับเงิน"
                                  : "กรุณาใส่เบอร์พร้อมเพย์เพื่อชำระเงิน"}
                              </p>
                            </div>
                          </div>

                          <div className="text-right">
                            <p className="text-2xl font-bold text-gray-800">
                              {detail.amount.toLocaleString("en-US", {
                                minimumFractionDigits: 2,
                                maximumFractionDigits: 2,
                              })}
                            </p>
                            <p className="text-sm text-gray-500">บาท</p>
                          </div>
                        </div>

                        {/* QR Code Section - Medium Thai QR Payment */}
                        {hasPhoneNumber && (
                          <div className="mt-4 bg-gradient-to-b from-blue-700 to-blue-800 rounded-lg overflow-hidden">
                            {/* Header */}
                            <div
                              className="h-[64px]"
                              style={{
                                backgroundImage: "url('/images/payment.png')",
                                backgroundPosition: "center",
                                backgroundRepeat: "no-repeat",
                                backgroundSize: "cover",
                              }}
                            />

                            {/* QR Code Container */}
                            <div className="bg-white p-4">
                              {/* PromptPay Logo */}
                              <div className="flex justify-center mb-3">
                                <img
                                  src="/images/prompt-pay-logo.png"
                                  alt="PromptPay"
                                  className="w-[85px]"
                                />
                              </div>

                              {/* QR Code */}
                              <div className="flex justify-center mb-3">
                                <img
                                  src={`https://promptpay.io/${receiverMember!.phoneNumber}/${detail.amount.toFixed(2)}.png`}
                                  alt="PromptPay QR Code"
                                  className="w-40 h-40"
                                />
                              </div>

                              {/* Text Information */}
                              <div className="text-center space-y-1">
                                <p className="text-teal-500 font-semibold text-sm">
                                  สแกน QR เพื่อโอนเข้าบัญชีพร้อมเพย์
                                </p>
                                <p className="text-gray-800 font-semibold text-sm">
                                  ชื่อ : {detail.receiver} (
                                  {maskThaiContact(receiverMember?.phoneNumber)}
                                  )
                                </p>
                              </div>
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            ) : (
              <div className="p-1 bg-green-50 rounded-lg border border-green-200 flex items-center justify-center gap-2 text-green-600">
                <span className="font-semibold">🎉 {payer}</span>
                <span>ไม่มีหนี้ที่ต้องจ่าย</span>
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
