import type { Currency } from '@/types/bill'

export function formatNumber(value: number): string {
  const rounded = Math.round((value + Number.EPSILON) * 100) / 100
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: Number.isInteger(rounded) ? 0 : 2,
    maximumFractionDigits: 2,
  }).format(rounded)
}

export function formatCurrency(value: number, currency: Currency = 'THB'): string {
  if (currency === 'THB') return `${formatNumber(value)} บาท`
  return `${formatNumber(value)} ${currency}`
}

/** Relative Thai date, falling back to an absolute Thai date for older items. */
export function formatDate(input: Date | string): string {
  const date = typeof input === 'string' ? new Date(input) : input
  const diff = Date.now() - date.getTime()
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)

  if (days === 0 && hours === 0 && minutes <= 0) return 'เมื่อกี้'
  if (days === 0 && hours === 0) return `${minutes} นาทีที่แล้ว`
  if (days === 0) return `${hours} ชั่วโมงที่แล้ว`
  if (days === 1) return 'เมื่อวาน'
  if (days < 7) return `${days} วันที่แล้ว`
  return new Intl.DateTimeFormat('th-TH', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  }).format(date)
}
