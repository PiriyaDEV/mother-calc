import QRCode from 'qrcode'

/** CRC-16/CCITT-FALSE for the EMVCo PromptPay payload. */
function crc16(payload: string): string {
  let crc = 0xffff
  for (let i = 0; i < payload.length; i++) {
    crc ^= payload.charCodeAt(i) << 8
    for (let j = 0; j < 8; j++) {
      crc = crc & 0x8000 ? (crc << 1) ^ 0x1021 : crc << 1
      crc &= 0xffff
    }
  }
  return crc.toString(16).toUpperCase().padStart(4, '0')
}

function field(id: string, value: string): string {
  return id + value.length.toString().padStart(2, '0') + value
}

/** Normalise a Thai phone / national id / e-wallet id into the AID target field. */
function formatTarget(raw: string): string {
  const digits = raw.replace(/\D/g, '')
  if (digits.length === 13) {
    // National ID
    return field('02', digits)
  }
  // Phone number → 0066 + last 9 digits
  const local = digits.replace(/^0/, '')
  return field('01', `0066${local}`)
}

/**
 * Build an EMVCo-compliant PromptPay QR payload.
 * @param phoneOrId phone number (e.g. 0812345678) or 13-digit national id
 * @param amount optional amount in THB
 */
export function generatePromptPayPayload(phoneOrId: string, amount?: number): string {
  const merchantAccount = field(
    '29',
    field('00', 'A000000677010111') + formatTarget(phoneOrId)
  )

  let payload =
    field('00', '01') + // payload format indicator
    field('01', amount && amount > 0 ? '12' : '11') + // dynamic if amount present
    merchantAccount +
    field('53', '764') + // THB
    field('58', 'TH')

  if (amount && amount > 0) {
    payload += field('54', amount.toFixed(2))
  }

  payload += '6304' // CRC placeholder id+len
  return payload + crc16(payload)
}

export async function generatePromptPayQrDataUrl(
  phoneOrId: string,
  amount?: number
): Promise<string> {
  const payload = generatePromptPayPayload(phoneOrId, amount)
  return QRCode.toDataURL(payload, { margin: 1, width: 320 })
}
