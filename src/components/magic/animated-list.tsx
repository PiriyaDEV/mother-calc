'use client'

import { motion } from 'motion/react'
import { cn } from '@/lib/utils/cn'

const container = {
  hidden: { opacity: 0 },
  show: { opacity: 1, transition: { staggerChildren: 0.06 } },
}
const item = {
  hidden: { opacity: 0, y: 12 },
  show: { opacity: 1, y: 0 },
}

export function AnimatedList({
  children,
  className,
}: {
  children: React.ReactNode
  className?: string
}) {
  return (
    <motion.ul
      variants={container}
      initial="hidden"
      animate="show"
      className={cn('flex flex-col gap-2', className)}
    >
      {Array.isArray(children)
        ? children.map((child, i) => (
            <motion.li key={i} variants={item}>
              {child}
            </motion.li>
          ))
        : <motion.li variants={item}>{children}</motion.li>}
    </motion.ul>
  )
}
