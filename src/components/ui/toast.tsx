'use client'

import { create } from 'zustand'
import { AnimatePresence, motion } from 'motion/react'

interface ToastItem {
  id: number
  message: string
  variant: 'default' | 'error'
}

interface ToastStore {
  toasts: ToastItem[]
  push: (message: string, variant?: 'default' | 'error') => void
  remove: (id: number) => void
}

let counter = 0

const useToastStore = create<ToastStore>((set) => ({
  toasts: [],
  push: (message, variant = 'default') => {
    const id = ++counter
    set((s) => ({ toasts: [...s.toasts, { id, message, variant }] }))
    setTimeout(() => {
      set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) }))
    }, 2800)
  },
  remove: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),
}))

/** Fire a toast from anywhere (client-side). */
export function toast(message: string, variant?: 'default' | 'error') {
  useToastStore.getState().push(message, variant)
}

export function Toaster() {
  const toasts = useToastStore((s) => s.toasts)
  return (
    <div className="pointer-events-none fixed inset-x-0 top-4 z-[100] flex flex-col items-center gap-2">
      <AnimatePresence>
        {toasts.map((t) => (
          <motion.div
            key={t.id}
            initial={{ opacity: 0, y: -16, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            className={
              'pointer-events-auto rounded-full px-5 py-2.5 text-sm font-semibold shadow-lg ' +
              (t.variant === 'error'
                ? 'bg-destructive text-destructive-foreground'
                : 'bg-foreground text-background')
            }
          >
            {t.message}
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  )
}
