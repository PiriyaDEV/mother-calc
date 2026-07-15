'use client'

import { Document, Page, Text, View, StyleSheet } from '@react-pdf/renderer'
import { formatCurrency } from '@/lib/utils/format'
import type { Bill, BillCalculation, DebtTransaction } from '@/types/bill'

const s = StyleSheet.create({
  page: { padding: 32, fontSize: 11, color: '#0f0f0f' },
  title: { fontSize: 18, marginBottom: 12, fontWeight: 700 },
  section: { marginBottom: 16 },
  heading: { fontSize: 13, marginBottom: 6, fontWeight: 700 },
  row: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 3 },
  total: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 6, paddingTop: 6, borderTopWidth: 1, borderColor: '#ddd', fontWeight: 700 },
  muted: { color: '#666' },
})

export function BillPdf({
  bill,
  calc,
  debts,
}: {
  bill: Bill
  calc: BillCalculation
  debts: DebtTransaction[]
}) {
  const cur = bill.settings.currency
  return (
    <Document>
      <Page size="A4" style={s.page}>
        <Text style={s.title}>
          {bill.emoji} {bill.title}
        </Text>

        <View style={s.section}>
          <Text style={s.heading}>สรุปยอด</Text>
          <View style={s.row}>
            <Text style={s.muted}>ยอดรวมย่อย</Text>
            <Text>{formatCurrency(calc.subtotal, cur)}</Text>
          </View>
          {calc.serviceAmount > 0 && (
            <View style={s.row}>
              <Text style={s.muted}>ค่าบริการ</Text>
              <Text>{formatCurrency(calc.serviceAmount, cur)}</Text>
            </View>
          )}
          {calc.vatAmount > 0 && (
            <View style={s.row}>
              <Text style={s.muted}>VAT</Text>
              <Text>{formatCurrency(calc.vatAmount, cur)}</Text>
            </View>
          )}
          <View style={s.total}>
            <Text>รวมทั้งหมด</Text>
            <Text>{formatCurrency(calc.total, cur)}</Text>
          </View>
        </View>

        <View style={s.section}>
          <Text style={s.heading}>รายการ</Text>
          {bill.items.map((it) => (
            <View key={it.id} style={s.row}>
              <Text>{it.name}</Text>
              <Text>{formatCurrency(it.price, cur)}</Text>
            </View>
          ))}
        </View>

        <View style={s.section}>
          <Text style={s.heading}>การโอนเงิน</Text>
          {debts.map((d, i) => (
            <View key={i} style={s.row}>
              <Text>
                {d.from.name} → {d.to.name}
              </Text>
              <Text>{formatCurrency(d.amount, cur)}</Text>
            </View>
          ))}
        </View>
      </Page>
    </Document>
  )
}
