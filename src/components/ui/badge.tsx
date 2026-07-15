import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils/cn'

const badgeVariants = cva(
  'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold',
  {
    variants: {
      variant: {
        draft: 'bg-gray-100 text-gray-500 dark:bg-gray-800 dark:text-gray-300',
        open: 'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300',
        settled: 'bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-300',
        primary: 'bg-primary-50 text-primary-600',
        muted: 'bg-muted text-muted-foreground',
      },
    },
    defaultVariants: { variant: 'muted' },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof badgeVariants> {}

export function Badge({ className, variant, ...props }: BadgeProps) {
  return <span className={cn(badgeVariants({ variant }), className)} {...props} />
}

export { badgeVariants }
