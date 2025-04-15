import { useState } from "react";

interface Member {
  name: string;
  color: string;
  customPaid?: number;
}

interface Item {
  itemName: string;
  paidBy: string;
  price?: number;
  selectedMembers: Member[];
}

interface Props {
  itemArr: Item[];
  members: Member[];
}

interface Totals {
  [name: string]: {
    paid: number;
    shouldPay: number;
  };
}

export default function Summary({ itemArr, members }: Props) {
  const totals: Totals = {};

  // Initialize totals for all members with zero
  members.forEach((member) => {
    totals[member.name] = { paid: 0, shouldPay: 0 };
  });

  // Process items
  itemArr.forEach((item) => {
    const { price, paidBy, selectedMembers } = item;

    // Ensure payer is initialized
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
    });
  });

  return (
    <div style={{ padding: "1rem", fontFamily: "sans-serif" }}>
      <div>
        <div>Step 4: Summary</div>
        <div>You can edit after this</div>
      </div>
      <table
        border={1}
        cellPadding={8}
        style={{ borderCollapse: "collapse", width: "100%" }}
      >
        <thead>
          <tr>
            <th>Name</th>
            <th>Must Pay</th>
            <th>Paid</th>
            <th>Balance</th>
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
              <tr key={name + index}>
                <td>{name}</td>
                <td>{shouldPay.toFixed(2)}</td>
                <td>{paid.toFixed(2)}</td>
                <td>{(paid - shouldPay).toFixed(2)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
