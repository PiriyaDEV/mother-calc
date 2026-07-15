# FEATURES.md — Kidtang (กิดตัง) · Next.js Rebuild Guide

> เอกสารนี้สรุป **ทุก feature ที่ต้องสร้างใหม่ใน Next.js** พร้อม tech stack, โครงสร้างโปรเจกต์, และ implementation notes ครบถ้วน

---

## Tech Stack

| Layer | Technology | Role |
|---|---|---|
| Framework | **Next.js 15** (App Router) | SSR, routing, API routes |
| Language | **TypeScript** | Type safety |
| Styling | **Tailwind CSS v4** | Utility-first styling ทุก component |
| UI Components (Base) | **shadcn/ui** (Radix UI) | Button, Dialog, Form, Input, Table, Tabs, Select, Sheet, Dropdown |
| UI Components (Effects) | **Magic UI** | Animation components: NumberTicker, AvatarCircles, AnimatedList, BorderBeam, ShimmerButton, Meteors, Confetti, MagicCard, Marquee |
| Animation | **Motion (Framer Motion)** | Page transitions, micro-interactions, gesture animations, layout animations |
| Backend / DB | **Supabase** (Postgres + RLS + Realtime) | Database, auth, realtime |
| Auth | **Supabase Auth** (Google, LINE) | Session management |
| State Management | **Zustand** (client stores) + React Server Components | Client-side state |
| i18n | **next-intl** (TH default + EN) | Bilingual support |
| Charts | **Recharts** | Analytics charts |
| Forms | **React Hook Form** + **Zod** | Form validation |
| Push Notifications | **Web Push (VAPID)** | Browser push only |
| QR Code | **qrcode** npm package | PromptPay QR generation |
| PDF Export | **@react-pdf/renderer** | Bill PDF export |
| Image Export | **html-to-image** | Bill PNG export |
| Deployment | **Vercel** | Hosting |

---

## Project Structure

```
src/
  app/
    [locale]/                    # i18n locale segment
      (auth)/
        login/page.tsx
        onboarding/page.tsx
      (app)/
        layout.tsx               # Bottom nav shell
        home/page.tsx
        bills/
          page.tsx               # Bills list
          create/page.tsx
          [id]/page.tsx          # Bill detail (tabs)
          [id]/share/page.tsx    # Public share view (no auth)
        groups/
          page.tsx
          create/page.tsx
          [id]/page.tsx
        friends/page.tsx
        me/
          page.tsx
          profile/page.tsx
      line-web-return/page.tsx
    api/
      auth/callback/route.ts     # Supabase auth callback
      line-auth/route.ts         # LINE PKCE exchange
      push/route.ts              # Web Push send
  components/
    home/
    bill/
    group/
    friends/
    me/
    shared/
    ui/                          # shadcn/ui components
  stores/                        # Zustand stores
    bills-store.ts
    groups-store.ts
    friends-store.ts
  repositories/                  # Supabase queries (server-side)
    bills-repository.ts
    groups-repository.ts
    friends-repository.ts
  lib/
    supabase/
      client.ts                  # Browser client
      server.ts                  # Server client (cookies)
      middleware.ts
    utils/
      bill-utils.ts              # calculateBill(), simplifyDebts()
      format.ts                  # formatCurrency(), formatDate()
  i18n/
    routing.ts
    navigation.ts
  messages/
    th.json                      # Thai strings (default)
    en.json                      # English strings
  types/
    bill.ts
    group.ts
    friend.ts
    profile.ts
middleware.ts                    # Auth + i18n middleware
```

---

## i18n Setup (next-intl)

### Configuration

```ts
// i18n/routing.ts
import { defineRouting } from 'next-intl/routing'

export const routing = defineRouting({
  locales: ['th', 'en'],
  defaultLocale: 'th',
})
```

```ts
// middleware.ts
import createMiddleware from 'next-intl/middleware'
import { routing } from './i18n/routing'

export default createMiddleware(routing)
```

### Message Files

```
messages/
  th.json    # ภาษาไทย (default)
  en.json    # English
```

### Usage in Components

```tsx
import { useTranslations } from 'next-intl'

export function MyComponent() {
  const t = useTranslations('bills')
  return <h1>{t('create_title')}</h1>
}
```

### Server Components

```tsx
import { getTranslations } from 'next-intl/server'

export default async function Page() {
  const t = await getTranslations('home')
  return <h1>{t('welcome')}</h1>
}
```

---

## Supabase Setup

### Clients

```ts
// lib/supabase/client.ts — Browser (Client Components)
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

```ts
// lib/supabase/server.ts — Server (Server Components, Route Handlers)
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { cookies: { getAll: () => cookieStore.getAll(), setAll: ... } }
  )
}
```

### Middleware (Auth + i18n)

```ts
// middleware.ts
import { updateSession } from '@/lib/supabase/middleware'
import createIntlMiddleware from 'next-intl/middleware'

export async function middleware(request: NextRequest) {
  // 1. Update Supabase session
  const response = await updateSession(request)
  // 2. Apply i18n routing
  return createIntlMiddleware(routing)(request)
}
```

### Environment Variables

```env
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=       # Server only
NEXT_PUBLIC_LINE_CHANNEL_ID=
LINE_CHANNEL_SECRET=             # Server only
VAPID_PUBLIC_KEY=
VAPID_PRIVATE_KEY=               # Server only
```

---

## Tailwind CSS v4

### Setup

```ts
// tailwind.config.ts
import type { Config } from 'tailwindcss'

const config: Config = {
  content: ['./src/**/*.{ts,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Primary — Blue (brand color)
        primary: {
          50:  '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',   // ← main brand color
          600: '#2563eb',
          700: '#1d4ed8',
          DEFAULT: '#3b82f6',
          foreground: '#ffffff',
        },
        // Surface (Clubhouse-like)
        surface: {
          light: '#fafafa',
          dark:  '#0f0f0f',
        },
        card: {
          light: '#ffffff',
          dark:  '#1a1a1a',
        },
      },
      fontFamily: {
        sans:    ['Noto Sans Thai', 'Inter', 'sans-serif'],
        display: ['Anuphan', 'Cal Sans', 'sans-serif'],
      },
      borderRadius: {
        '2xl': '20px',
        '3xl': '28px',
        '4xl': '36px',
      },
    },
  },
}
```

### Dark Mode

```tsx
// ใช้ next-themes
import { ThemeProvider } from 'next-themes'

<ThemeProvider attribute="class" defaultTheme="light" enableSystem>
  {children}
</ThemeProvider>
```

---

## 🎨 Design System

> **Visual Direction:** Clubhouse-inspired (warm, social, avatar-centric, rounded) + สีฟ้า + Magic UI animations

### Color Palette

| Token | Light | Dark | ใช้ที่ไหน |
|---|---|---|---|
| `primary` | `#3b82f6` | `#3b82f6` | ปุ่ม, accent, highlight |
| `primary-50` | `#eff6ff` | — | background subtle |
| `background` | `#fafafa` | `#0f0f0f` | page background |
| `card` | `#ffffff` | `#1a1a1a` | card background |
| `border` | `#f0f0f0` | `#2a2a2a` | card border |
| `text-primary` | `#0f0f0f` | `#f5f5f5` | heading, body |
| `text-secondary` | `#6b7280` | `#888888` | subtitle, label |
| `success` | `#22c55e` | `#22c55e` | จ่ายแล้ว badge |
| `warning` | `#f59e0b` | `#f59e0b` | open status |
| `destructive` | `#ef4444` | `#ef4444` | ลบ, error |

### Typography

```css
/* Heading — Anuphan Bold (Clubhouse-like rounded feel) */
h1, h2, h3 { font-family: 'Anuphan', sans-serif; font-weight: 700; }

/* Body — Noto Sans Thai */
body { font-family: 'Noto Sans Thai', 'Inter', sans-serif; }

/* Numbers/amounts — tabular */
.amount { font-variant-numeric: tabular-nums; font-feature-settings: 'tnum'; }
```

### Component Style Guide

#### Cards (Clubhouse-style)
```css
.card {
  background: white;                          /* dark: #1a1a1a */
  border-radius: 20px;                        /* rounded-2xl */
  border: 1px solid #f0f0f0;                  /* dark: #2a2a2a */
  box-shadow: 0 2px 20px rgba(0,0,0,0.06);
  padding: 20px;
}
```

#### Avatars (Clubhouse signature)
```css
/* ใหญ่, circular, border สีฟ้า */
.avatar {
  border-radius: 50%;
  border: 3px solid #3b82f6;
  width: 48px; height: 48px;
}
/* Stack avatars (AvatarCircles) */
.avatar + .avatar { margin-left: -12px; }
```

#### Buttons
```css
/* Primary — shimmer gradient */
.btn-primary {
  background: linear-gradient(135deg, #3b82f6, #2563eb);
  border-radius: 14px;
  font-weight: 700;
  color: white;
}

/* Secondary — ghost blue */
.btn-secondary {
  background: #eff6ff;
  color: #2563eb;
  border-radius: 14px;
}

/* Destructive */
.btn-destructive {
  background: #fef2f2;
  color: #ef4444;
  border-radius: 14px;
}
```

#### Bottom Navigation (Floating Pill — Clubhouse-like)
```css
/* ไม่ใช่ full-width bar — เป็น floating pill */
.bottom-nav {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  background: white;                          /* dark: #1a1a1a */
  border-radius: 28px;                        /* rounded-3xl */
  box-shadow: 0 8px 32px rgba(0,0,0,0.12);
  padding: 8px 16px;
  backdrop-filter: blur(20px);               /* glassmorphism */
  border: 1px solid rgba(255,255,255,0.2);
}
```

#### Status Badges
```css
.badge-draft   { background: #f3f4f6; color: #6b7280; border-radius: 999px; }
.badge-open    { background: #fef3c7; color: #d97706; border-radius: 999px; }
.badge-settled { background: #dcfce7; color: #16a34a; border-radius: 999px; }
```

---

### Magic UI Components

| Component | ใช้ที่ไหน | Effect |
|---|---|---|
| `NumberTicker` | ยอดเงินใน HeroBalanceCard | animate count up เมื่อ load |
| `AnimatedGradientText` | ชื่อแอป / hero text บน login | gradient shimmer text |
| `BorderBeam` | card ที่ active / selected bill | rotating border glow |
| `ShimmerButton` | ปุ่ม primary action (สร้างบิล, ส่งบิล) | shimmer sweep effect |
| `Meteors` | background decoration บน login/hero | falling particles |
| `AvatarCircles` | member avatars ซ้อนกัน (bill card, group card) | stacked avatars |
| `Marquee` | tags scroll บน bill/group card | horizontal scroll loop |
| `AnimatedList` | debt transaction list | animate in ทีละ row |
| `Confetti` | เมื่อบิล settled 🎉 | burst confetti |
| `Skeleton` | loading state ทุก card | shimmer placeholder |
| `MagicCard` | bill card hover effect | spotlight gradient on hover |
| `Ripple` | background บน empty states | subtle ripple animation |

### Motion (Framer Motion) — Animation Layer

> ใช้ `motion` จาก `framer-motion` สำหรับ animation ที่ต้องการ control มากกว่า Magic UI

| Use Case | Component | Animation |
|---|---|---|
| Page transitions | `<AnimatePresence>` + `<motion.div>` | fade + slide up เมื่อเปลี่ยน route |
| Tab switching | `<motion.div layoutId>` | layout animation ระหว่าง tabs |
| Bottom nav active indicator | `<motion.div layoutId="nav-indicator">` | sliding pill indicator |
| Card enter | `<motion.div initial/animate>` | stagger fade-in ทีละ card |
| Sheet/Modal | `<motion.div>` | slide up from bottom |
| Debt row enter | `<motion.li>` | stagger animate in ทีละ row |
| Number count up | ใช้ Magic UI `NumberTicker` แทน | — |
| Confetti | ใช้ Magic UI `Confetti` แทน | — |
| Hover effects | ใช้ Magic UI `MagicCard` แทน | — |

**ตัวอย่าง Page Transition:**
```tsx
// app/[locale]/(app)/layout.tsx
import { AnimatePresence, motion } from 'motion/react'

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -8 }}
        transition={{ duration: 0.2, ease: 'easeOut' }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  )
}
```

**ตัวอย่าง Stagger Cards:**
```tsx
const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.08 }
  }
}
const item = {
  hidden: { opacity: 0, y: 16 },
  show:   { opacity: 1, y: 0 }
}

<motion.ul variants={container} initial="hidden" animate="show">
  {bills.map(bill => (
    <motion.li key={bill.id} variants={item}>
      <BillCard bill={bill} />
    </motion.li>
  ))}
</motion.ul>
```

**ตัวอย่าง Bottom Nav Indicator:**
```tsx
// Floating pill nav — active tab indicator
{activeTab === tab.id && (
  <motion.div
    layoutId="nav-indicator"
    className="absolute inset-0 bg-primary/10 rounded-2xl"
    transition={{ type: 'spring', stiffness: 400, damping: 30 }}
  />
)}
```

**ตัวอย่าง Bottom Sheet:**
```tsx
<motion.div
  initial={{ y: '100%' }}
  animate={{ y: 0 }}
  exit={{ y: '100%' }}
  transition={{ type: 'spring', stiffness: 300, damping: 30 }}
  className="fixed bottom-0 left-0 right-0 bg-card rounded-t-3xl"
>
  {children}
</motion.div>
```

---

### UI Library Decision Guide

> เมื่อต้องสร้าง component ใหม่ ให้เลือก library ตาม priority นี้:

```
1. shadcn/ui   → ถ้าเป็น interactive primitive (Button, Dialog, Form, Input, Select, Tabs, Sheet)
2. Magic UI    → ถ้าต้องการ visual effect สำเร็จรูป (NumberTicker, AvatarCircles, Shimmer, etc.)
3. Motion      → ถ้าต้องการ animation ที่ custom (transitions, gestures, layout animations)
4. Tailwind    → styling ทุกอย่าง ไม่ว่าจะใช้ library ไหน
```

**ห้ามใช้ซ้ำซ้อน:**
- ❌ ใช้ทั้ง Magic UI `AnimatedList` และ Motion stagger บน list เดียวกัน
- ❌ ใช้ shadcn Dialog และ Motion sheet บน modal เดียวกัน
- ✅ shadcn `Dialog` + Motion `AnimatePresence` สำหรับ enter/exit animation ของ dialog

---

### Screen-by-Screen Design Notes

#### Login Screen
- Full-screen blue gradient background + `Meteors` animation
- Logo ใหญ่ตรงกลาง + `AnimatedGradientText` ชื่อแอป
- Google/LINE buttons: pill shape (`rounded-full`), ขนาดใหญ่

#### Home Screen
- `HeroBalanceCard`: gradient blue card, `NumberTicker` animate ยอด, avatar ใหญ่ 64px
- `QuickActionTiles`: 3 icon buttons แบบ circle + label ด้านล่าง
- `MyDebtsCard`: `AnimatedList` — debt rows animate in ทีละรายการ
- `RecentBillsList`: `AvatarCircles` แสดง member ซ้อนกัน บน bill card

#### Bill Card
- Emoji ใหญ่ 48px ด้านซ้าย
- `AvatarCircles` ของ members ด้านขวา
- Status badge: pill shape
- `MagicCard` hover effect (spotlight)

#### Bill Detail — Summary Tab
- Debt rows: `AnimatedList`, แต่ละ row มี avatar → arrow → avatar + ยอด
- "ของฉัน" highlight: `bg-primary-50` border-l-4 สีฟ้า
- QR button: `ShimmerButton`

#### Group Settlement Tab
- Hero number: `NumberTicker` — ยอดรวมทั้งกลุ่ม
- Transaction list: `AnimatedList`
- `Confetti` เมื่อทุกคนจ่ายครบ

---

## Features

---

### 1. 🔐 Authentication & Onboarding

#### Sign-In Methods
- **Google Sign-In** — Supabase Auth `signInWithOAuth({ provider: 'google' })`
- **LINE Sign-In** — PKCE OAuth2 flow ผ่าน `/api/line-auth` Route Handler

#### Auth Flow

```
/login → signIn → Supabase callback → check profile.onboarding_completed
  → false → /onboarding
  → true  → /home
```

#### Onboarding Page (`/[locale]/onboarding`)
- กรอก **username** (validate: `^[a-zA-Z0-9_]{3,30}$`)
- กรอก **display name**
- กรอก **เลขพร้อมเพย์** (optional)
- บันทึกผ่าน `profiles` table + set `onboarding_completed = true`
- Auto-create profile ผ่าน Supabase DB trigger `handle_new_user`

#### Middleware Auth Guard

```ts
// middleware.ts — redirect ถ้าไม่ได้ login
if (!session && !isPublicRoute) {
  return NextResponse.redirect('/login')
}
if (session && !profile.onboarding_completed && !isOnboarding) {
  return NextResponse.redirect('/onboarding')
}
```

#### Implementation Notes
- ใช้ `@supabase/ssr` สำหรับ cookie-based session
- LINE callback URL: `/line-web-return`
- Store session ใน cookie (ไม่ใช่ localStorage)

---

### 2. 🏠 หน้าหลัก (Home)

**Route:** `/[locale]/home`  
**Rendering:** Server Component (fetch data) + Client Components (interactive)

#### Components

| Component | รายละเอียด |
|---|---|
| `HeroBalanceCard` | ทักทาย + emoji ตามยอด + ยอดค้างจ่าย/รอรับ |
| `QuickActionTiles` | 3 ปุ่ม: สร้างบิล, สร้างกลุ่ม, เพิ่มเพื่อน |
| `MyDebtsCard` | สรุปยอดหนี้ net ทุกบิล — ต้องจ่ายใคร + รอรับจากใคร |
| `StatsGrid` | จำนวนบิล, ยอดรวม, กลุ่ม, เพื่อน |
| `RecentBillsList` | บิลล่าสุด 3 รายการ |
| `HomeEmptyState` | empty state + CTA |

> **หมายเหตุ:** Currency Card ถูกตัดออกจาก Home — ไม่ใช่ core feature ของ bill splitting

#### MyDebtsCard — สรุปยอดหนี้ net ทุกบิล

แสดงยอดหนี้ที่ net แล้วข้ามทุกบิล แยกเป็น 2 กลุ่ม:

```
💰 ยอดค้างจ่าย

  ต้องจ่าย:
    [avatar] นิดา    ฿230   (จาก 2 บิล)   [QR]
    [avatar] สมชาย   ฿150   (จาก 1 บิล)   [QR]

  รอรับ:
    [avatar] วิชัย   ฿400   (จาก 3 บิล)
```

- คำนวณโดย aggregate `simplifyDebts()` ของทุกบิลที่ status = `open`
- Net ยอดต่อ userId — ถ้าค้างกันหลายบิล รวมเป็น 1 row
- ปุ่ม QR → เปิด QR PromptPay ของคนรับ
- ใช้ `AnimatedList` — rows animate in
- ถ้าไม่มีหนี้ → แสดง "✅ ไม่มียอดค้างจ่าย" + `Ripple` background

```ts
// คำนวณ MyDebts จากทุกบิล
function calculateMyDebts(bills: Bill[], myUserId: string): {
  iOwe: { userId: string; name: string; avatarUrl?: string; amount: number; billCount: number }[]
  owedToMe: { userId: string; name: string; avatarUrl?: string; amount: number; billCount: number }[]
} {
  const netByUser: Record<string, { amount: number; billCount: number; name: string; avatarUrl?: string }> = {}

  for (const bill of bills) {
    if (bill.status !== 'open') continue
    const calc = calculateBill(bill)
    const debts = simplifyDebts(calc.memberSummaries, bill.members)

    for (const debt of debts) {
      if (debt.from.userId === myUserId) {
        // ฉันต้องจ่าย debt.to
        const key = debt.to.userId!
        netByUser[key] = {
          amount: (netByUser[key]?.amount ?? 0) + debt.amount,
          billCount: (netByUser[key]?.billCount ?? 0) + 1,
          name: debt.to.name,
          avatarUrl: debt.to.profile?.avatarUrl ?? undefined,
        }
      } else if (debt.to.userId === myUserId) {
        // debt.from ต้องจ่ายฉัน
        const key = `recv_${debt.from.userId}`
        netByUser[key] = {
          amount: (netByUser[key]?.amount ?? 0) + debt.amount,
          billCount: (netByUser[key]?.billCount ?? 0) + 1,
          name: debt.from.name,
          avatarUrl: debt.from.profile?.avatarUrl ?? undefined,
        }
      }
    }
  }
  // ... split into iOwe / owedToMe
}
```

#### Emoji Logic

```ts
function getTotalEmoji(total: number): string {
  if (total < 100) return '🤏'
  if (total < 500) return '💸'
  if (total < 1000) return '💰'
  if (total < 3000) return '🤑'
  return '🏦'
}
```

---

### 3. 🧾 บิล (Bills)

#### 3.1 สร้าง / แก้ไขบิล

**Route:** `/[locale]/bills/create`  
**Form:** React Hook Form + Zod validation

```ts
const billSchema = z.object({
  title: z.string().min(1),
  emoji: z.string().default('🧾'),
  tags: z.array(z.string()).default([]),
  settings: z.object({
    serviceCharge: z.number().min(0).max(100).default(0),
    vat: z.number().min(0).max(100).default(0),
    isService: z.boolean().default(false),
    isVat: z.boolean().default(false),
    tip: z.number().min(0).default(0),
    discount: z.number().min(0).default(0),
    currency: z.enum(['THB','USD','EUR','JPY','GBP','SGD','CNY','KRW','AUD','HKD','MYR']).default('THB'),
  }),
})
```

**Fields:**
- ชื่อบิล (text input)
- Emoji Picker (grid modal)
- Tags (preset chips + custom input)
- VAT toggle + % input
- Service Charge toggle + % input
- Tip (flat amount)
- Discount (flat amount)
- Currency dropdown

#### 3.2 สถานะบิล

```ts
type BillStatus = 'draft' | 'open' | 'settled'
```

| Status | ความหมาย | แก้ไขได้? |
|---|---|---|
| `draft` | กำลังสร้าง | ✅ ทุกอย่าง |
| `open` | เปิดบิลแล้ว รอจ่าย | ✅ บางส่วน |
| `settled` | ปิดบิล จ่ายครบแล้ว | ❌ read-only |

- ปุ่ม "ส่งบิล" → `draft → open`
- ปุ่ม "ปิดบิล" → `open → settled`
- ลบบิล (confirm dialog)
- ย้ายบิลเข้า/ออกกลุ่ม (modal sheet)

#### 3.3 Bill Detail Page

**Route:** `/[locale]/bills/[id]`  
**Layout:** Tab navigation (4 tabs)

```tsx
const tabs = ['members', 'items', 'summary', 'analytics']
// ใช้ URL search params: ?tab=members
```

---

#### 3.4 แท็บ Members

**การแสดงผล:**
- เรียงลำดับ: ตัวเองก่อน → เพื่อน → คนอื่น/external
- แสดงยอดที่แต่ละคนต้องจ่าย (คำนวณ real-time)
- Badge "จ่ายแล้ว" ต่อสมาชิก

**Add Member Modal:**
- กรอกชื่อ + เลือกสี (color picker)
- กรอกเลขพร้อมเพย์ (optional)
- เพิ่มจากรายชื่อ **เพื่อน** (search)
- เพิ่มจากสมาชิก **กลุ่ม**
- สมาชิก **External** (ไม่มี account)

**Types:**

```ts
interface BillMember {
  id: string
  billId: string
  userId: string | null      // null = external
  name: string
  color: string              // hex
  promptpay: string | null
  isExternal: boolean
  profile?: {
    avatarUrl: string | null
  }
}
```

---

#### 3.5 แท็บ Items

**Item Form Modal:**

```ts
interface BillItem {
  id: string
  billId: string
  name: string
  price: number
  quantity: number
  memberIds: string[]
  customShares: Record<string, number>  // memberId → weight
  paidBy: string | null                 // memberId ที่จ่ายเงินต้นสำหรับรายการนี้
}
```

**Split Mode Toggle:**

| Mode | วิธีทำงาน |
|---|---|
| **Equal Split (หารเท่า)** | checkbox เลือกใครร่วมจ่าย → หารเท่ากัน |
| **Unequal Split (กำหนดสัดส่วน)** | กรอก weight ต่อคน → คำนวณตามสัดส่วน (เช่น 2:1:1) |

```ts
// Equal: customShares = {}
// Unequal: customShares = { 'memberId1': 2, 'memberId2': 1 }

function splitWeights(item: BillItem): Record<string, number> {
  if (Object.keys(item.customShares).length > 0) return item.customShares
  return Object.fromEntries(item.memberIds.map(id => [id, 1]))
}
```

**Paid By Picker (ต่อรายการ):**
- Chip picker เลือกสมาชิกที่จ่ายเงินต้นสำหรับรายการนี้
- รองรับ use case ที่หลายคนจ่ายคนละรายการในบิลเดียวกัน
- Default = สมาชิกคนแรก (ตัวเอง)

**Preview real-time:**
- "คนละ X บาท (N คน)" — debounce 300ms
- Validation banner: total weight เมื่อ unequal

**Sticky Summary Bar (bottom):**
- subtotal, service, VAT, tip, discount, **total**

---

#### 3.6 แท็บ Summary

**Components:**

```
SummaryTab/
  BillBreakdownCard      # subtotal → total breakdown
  MemberSelector         # เลือกดูสรุปต่อคน
  SelectedMemberCard     # รายการ + ยอดของคนที่เลือก
  AllMembersSection      # ยอดทุกคน
  DebtSection            # สรุปหนี้ (ใครโอนให้ใคร) — ดูด้านล่าง
  PromptPayQR            # QR code ต่อสมาชิก
  ShareBillButton        # ปุ่ม copy share link
  DownloadSummary        # export PNG / PDF
```

**DebtSection — "ใครต้องจ่ายให้ใคร" (ปรับปรุงใหม่):**

แสดงเป็น transaction list ที่ชัดเจน แทนที่จะแสดงแค่ยอดต่อคน:

```
💸 สรุปการโอนเงิน

  [avatar] สมชาย  →  นิดา [avatar]     ฿150   [QR] [คัดลอก]
  [avatar] สมหญิง →  นิดา [avatar]      ฿80   [QR] [คัดลอก]
  [avatar] วิชัย  →  สมชาย [avatar]    ฿200   [QR] [คัดลอก]
```

- แต่ละ row = 1 transaction (จาก → ถึง + ยอด)
- Row ที่ตัวเองเกี่ยวข้อง: highlight `bg-primary-50` + `border-l-4 border-primary`
- ปุ่ม **QR** → เปิด modal แสดง QR PromptPay ของคนรับ พร้อมยอดที่ต้องโอน
- ปุ่ม **คัดลอก** → copy ข้อความ "โอน ฿150 ให้นิดา พร้อมเพย์ 0812345678"
- ใช้ `AnimatedList` — rows animate in ทีละรายการ

**"ของฉัน" Toggle:**

```tsx
// Toggle filter เฉพาะ transaction ที่ตัวเองเกี่ยวข้อง
const [myViewOnly, setMyViewOnly] = useState(false)

const filteredDebts = myViewOnly
  ? debts.filter(d => d.from.userId === myUserId || d.to.userId === myUserId)
  : debts
```

แสดงแยก 2 กลุ่ม:
```
👤 ของฉัน (นิดา)

  รอรับจาก:
    สมชาย   ฿150  ✅ จ่ายแล้ว
    สมหญิง   ฿80  ⏳ รอจ่าย

  ต้องจ่าย:
    (ไม่มี)
```

**Bill Calculation:**

```ts
// lib/utils/bill-utils.ts
export function calculateBill(bill: Bill): BillCalculation {
  const subtotal = bill.items.reduce((sum, item) => sum + item.price, 0)
  const serviceAmount = subtotal * (bill.settings.serviceCharge / 100)
  const vatBase = subtotal + serviceAmount
  const vatAmount = vatBase * (bill.settings.vat / 100)
  const tipAmount = bill.settings.tip
  const discountAmount = bill.settings.discount
  const total = subtotal + serviceAmount + vatAmount + tipAmount - discountAmount
  const multiplier = subtotal > 0 ? total / subtotal : 1

  // per-member calculation...
  return { subtotal, serviceAmount, vatAmount, tipAmount, discountAmount, total, memberSummaries }
}
```

**Debt Simplification:**

```ts
export function simplifyDebts(
  summaries: MemberSummary[],
  members: BillMember[],
  excludeMemberId?: string,
  ownerUserId?: string
): DebtTransaction[] {
  // minimum-transactions algorithm
  // Mode 1: มี paidBy ต่อรายการ → คำนวณตาม paidBy จริง
  // Mode 2: ไม่มี paidBy → owner จ่ายทั้งหมด
}
```

**QR PromptPay:**

```ts
import QRCode from 'qrcode'

// Generate PromptPay QR payload (EMV format)
function generatePromptPayPayload(phoneOrId: string, amount: number): string { ... }

const qrDataUrl = await QRCode.toDataURL(payload)
```

**Mark Paid:**
- Toggle `paidMemberIds[]` ใน bill
- Optimistic update ใน Zustand store

**Export:**

```ts
// PNG
import { toPng } from 'html-to-image'
const dataUrl = await toPng(elementRef.current)

// PDF
import { pdf } from '@react-pdf/renderer'
const blob = await pdf(<BillPDF bill={bill} />).toBlob()
```

---

#### 3.7 แท็บ Analytics (Fun Stats)

> **หมายเหตุ:** เปลี่ยนจาก "Fairness Score" เป็น fun stats ที่สนุกและเข้าใจง่ายกว่า

| Component | รายละเอียด |
|---|---|
| `BiggestSpenderCard` | 🏆 ใครกินเยอะสุดในบิลนี้ |
| `MostFrugalCard` | 🥗 ใครประหยัดสุด (จ่ายน้อยสุด) |
| `TopPayerCard` | 💸 ใครจ่ายเงินต้นเยอะสุด (paidBy) |
| `TopItemsCard` | 🍽️ รายการที่แพงสุด 3–5 อันดับ |
| `MemberSpendingList` | ยอดต่อสมาชิก + bar chart (Recharts) |
| `ItemsPerMemberGrid` | grid ว่าแต่ละคนกินอะไรบ้าง |
| `StatsRow` | avg / max / min per person |

---

#### 3.8 Bills List Page

**Route:** `/[locale]/bills`

- Tab filter: ทั้งหมด / draft / open / settled
- Infinite scroll (Intersection Observer)
- Pull-to-refresh (mobile)
- Bill card: emoji, ชื่อ, วันที่, ยอดรวม, จำนวนสมาชิก, status badge, group badge
- **Realtime sync** ผ่าน Supabase Realtime channel

```ts
// Realtime subscription
const channel = supabase
  .channel('bills')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'bills' },
    (payload) => billsStore.handleRealtimeChange(payload))
  .subscribe()
```

---

#### 3.9 Share Bill (Public View) 🆕

**Route:** `/[locale]/bills/[id]/share` — **ไม่ต้อง login**

- แสดงข้อมูลบิลแบบ read-only
- Bill breakdown (subtotal, VAT, service, tip, discount, total)
- รายการทุกอย่างในบิล
- ยอดที่แต่ละคนต้องจ่าย
- QR PromptPay ต่อสมาชิก (ถ้ามีเลขพร้อมเพย์)
- ปุ่ม Copy Link / Share

**Implementation:**
- ใช้ Supabase RLS policy แยกสำหรับ public read (ไม่ต้อง auth)
- หรือใช้ Supabase service role ใน Server Component
- URL: `kidtang.app/bills/[id]/share`

```ts
// ปุ่ม Share ใน Summary Tab
async function copyShareLink(billId: string) {
  const url = `${window.location.origin}/bills/${billId}/share`
  await navigator.clipboard.writeText(url)
  toast('คัดลอก link แล้ว!')
}
```

---

### 4. 👥 กลุ่ม (Groups)

#### 4.1 สร้าง / แก้ไขกลุ่ม

**Route:** `/[locale]/groups/create`

```ts
interface Group {
  id: string
  name: string
  description: string | null
  emoji: string
  tags: string[]
  ownerId: string
  members: GroupMember[]
}

interface GroupMember {
  id: string
  groupId: string
  userId: string
  role: 'owner' | 'member'
  status: 'pending' | 'accepted' | 'declined'
  invitedBy: string
}
```

#### 4.2 Group Detail Page

**Route:** `/[locale]/groups/[id]`  
**Tabs:** Bills / Members / Analytics

**Bills Tab:**
- รายการบิลในกลุ่ม
- ปุ่มสร้างบิลใหม่ในกลุ่ม

**Members Tab:**
- รายชื่อสมาชิก + role badge
- เชิญสมาชิกด้วย username (search + invite)
- ลบสมาชิก (owner เท่านั้น)

**Analytics / Settlement Tab (ปรับปรุงใหม่):**

> เปลี่ยนจาก "Analytics" เป็น **"สรุปยอด"** (Settlement) — feature หลักที่ user ต้องการจริงๆ

```
👥 กลุ่มทริปเชียงใหม่ — สรุปยอดทั้งหมด

  📊 5 บิล  |  ยอดรวม ฿4,500

  💸 ต้องโอนเงิน (net ข้ามบิลแล้ว)

  [avatar] สมชาย  →  นิดา [avatar]    ฿350   [QR]
  [avatar] วิชัย  →  นิดา [avatar]    ฿120   [QR]
  [avatar] สมหญิง →  สมชาย [avatar]   ฿200   [QR]

  ✅ จ่ายครบแล้ว: สมศักดิ์
```

**วิธีคำนวณ Group Settlement:**

```ts
// lib/utils/bill-utils.ts
export function calculateGroupSettlement(
  bills: Bill[],
  groupMembers: { userId: string; name: string; avatarUrl?: string }[]
): DebtTransaction[] {
  // 1. รวม net balance ของทุกบิลในกลุ่ม (เฉพาะบิลที่ยังไม่ settled)
  const netBalance: Record<string, number> = {}

  for (const bill of bills) {
    if (bill.status === 'settled') continue
    const calc = calculateBill(bill)
    const debts = simplifyDebts(calc.memberSummaries, bill.members)

    for (const debt of debts) {
      const fromUserId = debt.from.userId
      const toUserId = debt.to.userId
      if (!fromUserId || !toUserId) continue

      netBalance[fromUserId] = (netBalance[fromUserId] ?? 0) - debt.amount
      netBalance[toUserId]   = (netBalance[toUserId]   ?? 0) + debt.amount
    }
  }

  // 2. simplify ข้ามบิล (minimum-transactions บน net balance)
  return simplifyNetBalance(netBalance, groupMembers)
}
```

**Key behaviors:**
- Net ยอดระหว่างคนเดิมข้ามบิล — ถ้า A ค้าง B ฿100 จากบิล 1 แต่ B ค้าง A ฿60 จากบิล 2 → A จ่าย B แค่ ฿40
- เฉพาะบิลที่ status = `open` (ยังไม่ settled)
- แสดง `NumberTicker` ยอดรวมทั้งกลุ่ม
- `AnimatedList` สำหรับ transaction rows
- `Confetti` เมื่อทุกคนจ่ายครบ (netBalance ทุก entry = 0)
- ปุ่ม QR ต่อ transaction → เปิด QR PromptPay ของคนรับ

#### 4.3 จัดการกลุ่ม
- แก้ไขข้อมูลกลุ่ม (owner เท่านั้น)
- ลบกลุ่ม (owner เท่านั้น + confirm dialog)
- Manage Members Sheet

---

### 5. 🤝 เพื่อน (Friends)

**Route:** `/[locale]/friends`

```ts
interface Friend {
  id: string
  requesterId: string
  addresseeId: string
  status: 'pending' | 'accepted' | 'declined'
  // joined profile:
  displayName: string
  username: string
  avatarUrl: string | null
}
```

#### Components

| Component | รายละเอียด |
|---|---|
| `AddFriendPanel` | ค้นหา username + ส่ง request |
| `PendingRequestsCard` | คำขอที่รอ + รับ/ปฏิเสธ |
| `FriendRow` | avatar + ชื่อ + username + ลบ |
| `EmptyFriendsState` | empty state |

#### Actions
- ส่ง friend request ด้วย username
- รับ / ปฏิเสธ คำขอ
- ลบเพื่อน (confirm dialog)
- เพิ่มเพื่อนเป็นสมาชิกบิลโดยตรง

---

### 6. 👤 โปรไฟล์ & ตั้งค่า (Me)

**Route:** `/[locale]/me`

#### Components

| Component | รายละเอียด |
|---|---|
| `ProfileHeader` | avatar + display name + @username |
| `AccountSection` | แก้ไข display name, username, promptpay, รูปโปรไฟล์ |
| `SecuritySection` | เปลี่ยนรหัสผ่าน (show/hide toggle) |
| `SettingsSection` | ภาษา (dialog picker) + dark/light mode |
| `ToastBanner` | แจ้งผล success/error |

#### Settings
- **ภาษา**: เปลี่ยน locale → redirect ไป `/{newLocale}/me`
- **Dark mode**: `next-themes` + persist ใน localStorage
- **ออกจากระบบ**: `supabase.auth.signOut()` + clear stores + redirect `/login`
- **ลบบัญชี**: confirm dialog → delete profile + auth user

---

### 7. 🔔 การแจ้งเตือน (Push Notifications)

> **Scope:** Web Push เด้งเท่านั้น — ไม่มี notification center ในแอป

#### Web Push (VAPID)

```ts
// lib/push.ts
export async function subscribePush(userId: string) {
  const registration = await navigator.serviceWorker.ready
  const subscription = await registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY,
  })
  // Save subscription to supabase vapid_subscriptions table
}
```

#### Send Push (API Route)

```ts
// app/api/push/route.ts
import webpush from 'web-push'

webpush.setVapidDetails(
  'mailto:admin@kidtang.app',
  process.env.VAPID_PUBLIC_KEY!,
  process.env.VAPID_PRIVATE_KEY!
)
```

#### Notification Types (push only)

| Type | Trigger |
|---|---|
| `group_invite` | ถูกเชิญเข้ากลุ่ม |
| `friend_request` | มีคนส่งคำขอเป็นเพื่อน |
| `friend_accepted` | เพื่อนรับคำขอ |
| `bill_paid` | สมาชิกในบิลจ่ายเงินแล้ว |
| `bill_settled` | บิลถูกปิด |

---

### 8. 💳 การชำระเงิน (Payment)

#### QR PromptPay
- Generate EMV QR payload ตามมาตรฐาน PromptPay
- ใช้ `qrcode` package render เป็น `<img>`
- ยอดใน QR = ยอดที่สมาชิกนั้นต้องจ่าย (จาก debt calculation)
- เลขพร้อมเพย์ = จากโปรไฟล์สมาชิก

#### ทำเครื่องหมายจ่ายแล้ว
- Toggle `paidMemberIds[]` ใน bill
- Optimistic update ใน Zustand

#### Export Summary
- Export เป็น **รูปภาพ (PNG)** — บันทึกลงเครื่อง / share
- Export เป็น **PDF** — บันทึกลงเครื่อง / share

---

### 9. 🌍 ภาษา & สกุลเงิน

#### i18n (next-intl)

```
messages/
  th.json    # ภาษาไทย (default)
  en.json    # English
```

**Key namespaces:**
- `common` — ปุ่ม, labels ทั่วไป
- `auth` — login, onboarding
- `home` — home screen
- `bills` — bill screens
- `groups` — group screens
- `friends` — friends screen
- `me` — profile/settings

#### สกุลเงิน

```ts
const CURRENCIES = ['THB','USD','EUR','JPY','GBP','SGD','CNY','KRW','AUD','HKD','MYR'] as const
type Currency = typeof CURRENCIES[number]

function formatCurrency(value: number, currency: Currency): string {
  if (currency === 'THB') return `${formatNumber(value)} บาท`
  return `${formatNumber(value)} ${currency}`
}
```

#### Date Formatting

```ts
function formatDate(date: Date): string {
  const diff = Date.now() - date.getTime()
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)

  if (days === 0 && hours === 0 && minutes === 0) return 'เมื่อกี้'
  if (days === 0 && hours === 0) return `${minutes} นาทีที่แล้ว`
  if (days === 0) return `${hours} ชั่วโมงที่แล้ว`
  if (days === 1) return 'เมื่อวาน'
  if (days < 7) return `${days} วันที่แล้ว`
  return new Intl.DateTimeFormat('th-TH', { day: 'numeric', month: 'short', year: 'numeric' }).format(date)
}
```

---

### 10. 🧮 Bill Calculation Engine

**File:** `src/lib/utils/bill-utils.ts`

#### สูตรคำนวณ

```ts
export function calculateBill(bill: Bill): BillCalculation {
  const subtotal = bill.items.reduce((sum, item) => sum + item.price, 0)
  const serviceAmount = subtotal * (bill.settings.serviceCharge / 100)
  const vatBase = subtotal + serviceAmount
  const vatAmount = vatBase * (bill.settings.vat / 100)
  const tipAmount = bill.settings.tip
  const discountAmount = bill.settings.discount
  const total = subtotal + serviceAmount + vatAmount + tipAmount - discountAmount
  const multiplier = subtotal > 0 ? total / subtotal : 1

  const memberSummaries = bill.members.map(member => {
    let rawTotal = 0
    const itemShares: MemberItemShare[] = []

    for (const item of bill.items) {
      const weights = splitWeights(item)
      if (!weights[member.id]) continue
      const totalWeight = Object.values(weights).reduce((s, w) => s + w, 0)
      const rawAmount = (weights[member.id] / totalWeight) * item.price
      rawTotal += rawAmount
      itemShares.push({ item, amount: rawAmount * multiplier })
    }

    return { member, total: rawTotal * multiplier, items: itemShares }
  })

  return { subtotal, serviceAmount, vatAmount, tipAmount, discountAmount, total, memberSummaries }
}
```

#### Debt Simplification (Minimum Transactions Algorithm)

```ts
export function simplifyDebts(
  summaries: MemberSummary[],
  members: BillMember[],
  excludeMemberId?: string,
  ownerUserId?: string
): DebtTransaction[] {
  const net: Record<string, number> = {}
  members.forEach(m => net[m.id] = 0)

  const hasPaidBy = summaries.some(s => s.items.some(i => i.item.paidBy))

  if (hasPaidBy) {
    // Mode 1: per-item paidBy — หลายคนจ่ายคนละรายการ
    for (const summary of summaries) {
      for (const itemShare of summary.items) {
        const payerId = itemShare.item.paidBy
        if (!payerId || payerId === summary.member.id) continue
        net[summary.member.id] -= itemShare.amount
        net[payerId] += itemShare.amount
      }
    }
  } else {
    // Mode 2: owner paid everything
    const payer = members.find(m => m.userId === ownerUserId) ?? members[0]
    for (const summary of summaries) {
      if (summary.member.id === payer.id || summary.total <= 0) continue
      net[summary.member.id] -= summary.total
      net[payer.id] += summary.total
    }
  }

  // Minimum-transactions algorithm
  const debtors = Object.entries(net)
    .filter(([id, amt]) => id !== excludeMemberId && amt < -0.005)
    .map(([id, amt]) => ({ member: members.find(m => m.id === id)!, amount: -amt }))
    .sort((a, b) => b.amount - a.amount)

  const creditors = Object.entries(net)
    .filter(([id, amt]) => id !== excludeMemberId && amt > 0.005)
    .map(([id, amt]) => ({ member: members.find(m => m.id === id)!, amount: amt }))
    .sort((a, b) => b.amount - a.amount)

  const debts: DebtTransaction[] = []
  let di = 0, ci = 0

  while (di < debtors.length && ci < creditors.length) {
    const transfer = Math.min(debtors[di].amount, creditors[ci].amount)
    if (transfer > 0.005) {
      debts.push({ from: debtors[di].member, to: creditors[ci].member, amount: transfer })
    }
    debtors[di].amount -= transfer
    creditors[ci].amount -= transfer
    if (debtors[di].amount < 0.005) di++
    if (creditors[ci].amount < 0.005) ci++
  }

  return debts
}
```

---

### 11. 🗃️ State Management (Zustand)

```ts
// stores/bills-store.ts
interface BillsStore {
  bills: Record<string, Bill>
  setBills: (bills: Bill[]) => void
  addBill: (bill: Bill) => void
  updateBill: (id: string, updates: Partial<Bill>) => void
  deleteBill: (id: string) => void
  optimisticUpdate: <T>(
    id: string,
    update: Partial<Bill>,
    persist: () => Promise<T>
  ) => Promise<T>
}

export const useBillsStore = create<BillsStore>((set, get) => ({
  bills: {},
  optimisticUpdate: async (id, update, persist) => {
    const prev = get().bills[id]
    set(state => ({ bills: { ...state.bills, [id]: { ...prev, ...update } } }))
    try {
      return await persist()
    } catch (e) {
      set(state => ({ bills: { ...state.bills, [id]: prev } }))
      throw e
    }
  },
}))
```

---

### 12. 🗄️ Database Schema (Supabase)

#### Tables

```sql
-- profiles
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  promptpay TEXT,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  fcm_token TEXT,
  locale TEXT DEFAULT 'th',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- bills
CREATE TABLE bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  emoji TEXT DEFAULT '🧾',
  tags TEXT[] DEFAULT '{}',
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft','open','settled')),
  owner_id UUID REFERENCES profiles(id),
  group_id UUID REFERENCES groups(id),
  settings JSONB DEFAULT '{}',
  paid_member_ids TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- bill_members
CREATE TABLE bill_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id UUID REFERENCES bills(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),  -- nullable (external)
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  promptpay TEXT,
  is_external BOOLEAN DEFAULT FALSE
);

-- bill_items
CREATE TABLE bill_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id UUID REFERENCES bills(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  price NUMERIC NOT NULL,
  quantity INTEGER DEFAULT 1,
  member_ids TEXT[] DEFAULT '{}',
  custom_shares JSONB DEFAULT '{}',
  paid_by TEXT  -- bill_member.id (nullable — ใครจ่ายเงินต้นสำหรับรายการนี้)
);

-- groups
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  emoji TEXT DEFAULT '👥',
  tags TEXT[] DEFAULT '{}',
  owner_id UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- group_members
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id),
  role TEXT DEFAULT 'member' CHECK (role IN ('owner','member')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','accepted','declined')),
  invited_by UUID REFERENCES profiles(id)
);

-- friends
CREATE TABLE friends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID REFERENCES profiles(id),
  addressee_id UUID REFERENCES profiles(id),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','accepted','declined')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- app_config (remote feature flags)
CREATE TABLE app_config (
  key TEXT PRIMARY KEY,
  value JSONB
);

-- vapid_subscriptions (Web Push)
CREATE TABLE vapid_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id),
  subscription JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### RLS Policies
- ทุก table มี RLS enabled
- Helper functions: `is_group_member()`, `is_group_owner()`, `can_access_bill()`
- **Share bill**: เพิ่ม policy `allow_public_read_bill` สำหรับ `/bills/[id]/share`

#### Realtime
- Subscribe: `bills`, `bill_members`, `bill_items`

---

### 13. 🗺️ Routes

| Route | Page | Auth |
|---|---|---|
| `/` | redirect → `/home` | ✅ |
| `/login` | Login | ❌ |
| `/onboarding` | Onboarding | ✅ |
| `/home` | Home | ✅ |
| `/bills` | Bills list | ✅ |
| `/bills/create` | Create bill | ✅ |
| `/bills/[id]` | Bill detail (4 tabs) | ✅ |
| `/bills/[id]/share` | Public bill view | ❌ (no auth) |
| `/groups` | Groups list | ✅ |
| `/groups/create` | Create group | ✅ |
| `/groups/[id]` | Group detail (3 tabs) | ✅ |
| `/friends` | Friends | ✅ |
| `/me` | Me / Settings | ✅ |
| `/me/profile` | Edit profile | ✅ |
| `/line-web-return` | LINE OAuth callback | ❌ |

> ทุก route อยู่ภายใต้ `/[locale]/` prefix (next-intl)

---

### 14. ✨ ฟีเจอร์ใหม่ที่แนะนำให้เพิ่มในอนาคต

| Feature | Priority | Notes |
|---|---|---|
| **ค้นหา/กรองบิล** | 🔴 High | filter ด้วย tag, วันที่, ยอดเงิน, สถานะ |
| **Drag-to-assign** รายการ | 🟡 Medium | dnd-kit บน web |
| **Bill templates** | 🟡 Medium | บันทึก preset บิลที่ใช้บ่อย |
| **แบ่งตามเปอร์เซ็นต์** | 🟡 Medium | นอกจาก weight ratio |
| **Export CSV/Excel** | 🟢 Low | สำหรับ accounting |
| **ประวัติการแก้ไขบิล** | 🟢 Low | audit log |
| **Recurring bills** | 🟢 Low | บิลประจำ (รายเดือน) |
| **Bill comments/notes** | 🟢 Low | note ต่อบิลหรือต่อรายการ |
| **Real-time collaborative** | 🟢 Low | หลายคนแก้พร้อมกัน |

---

*อัปเดตล่าสุด: กรกฎาคม 2026 — Next.js Rebuild Guide สำหรับ Kidtang v2*
