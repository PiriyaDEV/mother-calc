'use client'

import { useEffect, useState } from 'react'
import Image from 'next/image'
import { generatePromptPayQrDataUrl } from '@/lib/utils/promptpay'
import { formatCurrency } from '@/lib/utils/format'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

interface PromptPayQRProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  promptpay: string | null | undefined
  amount: number
  name: string
}

export function PromptPayQR({ open, onOpenChange, promptpay, amount, name }: PromptPayQRProps) {
  const [dataUrl, setDataUrl] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    if (open && promptpay) {
      generatePromptPayQrDataUrl(promptpay, amount)
        .then((url) => !cancelled && setDataUrl(url))
        .catch(() => !cancelled && setDataUrl(null))
    }
    return () => {
      cancelled = true
    }
  }, [open, promptpay, amount])

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-xs">
        <DialogHeader>
          <DialogTitle className="text-center">{name}</DialogTitle>
        </DialogHeader>
        <div className="flex flex-col items-center gap-3">
          {promptpay && dataUrl ? (
            <>
              <Image
                src={dataUrl}
                alt="PromptPay QR"
                width={240}
                height={240}
                className="rounded-2xl"
                unoptimized
              />
              <p className="amount text-2xl font-bold text-primary">
                {formatCurrency(amount)}
              </p>
              <p className="text-sm text-muted-foreground">พร้อมเพย์ {promptpay}</p>
            </>
          ) : (
            <p className="py-8 text-center text-sm text-muted-foreground">
              ไม่มีเลขพร้อมเพย์
            </p>
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}
