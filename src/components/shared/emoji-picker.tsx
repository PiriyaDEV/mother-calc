'use client'

import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'

const EMOJIS = [
  '🧾', '🍜', '🍕', '🍔', '🍣', '🍛', '🍺', '🍷', '☕', '🎉',
  '🛒', '🏨', '✈️', '🚕', '⛽', '🎬', '🎮', '🏖️', '🎂', '🍰',
  '🥘', '🍲', '🍱', '🥗', '🍦', '🧋', '🍩', '🏠', '💊', '🎁',
]

interface EmojiPickerProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSelect: (emoji: string) => void
}

export function EmojiPicker({ open, onOpenChange, onSelect }: EmojiPickerProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>เลือกอีโมจิ</DialogTitle>
        </DialogHeader>
        <div className="grid grid-cols-6 gap-2">
          {EMOJIS.map((e) => (
            <button
              key={e}
              type="button"
              onClick={() => {
                onSelect(e)
                onOpenChange(false)
              }}
              className="flex aspect-square items-center justify-center rounded-xl text-2xl transition-colors hover:bg-muted"
            >
              {e}
            </button>
          ))}
        </div>
      </DialogContent>
    </Dialog>
  )
}
