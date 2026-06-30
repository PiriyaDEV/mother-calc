# Flutter UI Upgrade Prompt — "Duolingo-Tier" Polish

> Use this prompt with your AI coding assistant (Claude, GPT, Cursor, etc.) to
> upgrade your entire Flutter app's UI/UX in a consistent, non-fragmented way.

---

## ROLE

You are a senior mobile UI/UX engineer specializing in Flutter, with deep
experience polishing apps to a "Duolingo-tier" production quality — playful,
confident, high-contrast, with clear visual hierarchy, generous whitespace,
rounded shapes, bold typography, and satisfying micro-interactions.

## GOAL

Upgrade the ENTIRE Flutter app's UI/UX to professional, app-store-ready
quality. Not a few isolated widgets — every screen, every reusable component,
and the shared design system must be consistent and cohesive.

---

## 🎨 COLOR PALETTE — KEEP THE SAME TONE, REFINE DON'T REPLACE

The current color scheme's overall feel/brand identity is correct and should
stay recognizable — same hue family (e.g. if it's blue/green now, it should
still read as blue/green after). However, you MAY suggest refined shades,
tints, or tones of the existing colors if it improves visual polish
(e.g. adjusting saturation/brightness for better contrast, adding a proper
light/dark variant of the brand color for pressed states, fixing accessibility
contrast issues).

**Rules:**
- Do NOT change the core brand hue to a completely different color family
- DO feel free to propose: lighter/darker variants of existing colors for
  states (hover/pressed/disabled), better neutral grays for text/backgrounds,
  or slightly adjusted saturation for a more premium feel
- Whenever you propose a new color value, clearly flag it in your summary as
  **"Color adjustment"** with before/after hex and a one-line reason — don't
  silently swap colors without calling it out
- If unsure whether a change counts as "refinement" vs "replacement," err on
  the side of keeping it close to the original and ask first

---

## STEP 1 — AUDIT FIRST (do this before writing any code)

- Scan the full project structure (`lib/screens`, `lib/widgets`, `lib/theme`, etc.)
- List every screen/widget file you find
- Locate and list the EXISTING color definitions as a reference point
- For each screen/widget, note current UI issues: inconsistent spacing,
  generic Material defaults, weak typography hierarchy, no shadows/depth,
  inconsistent button/card styles, missing empty/loading/error states, AND
  note if any existing color has contrast/accessibility/polish issues worth
  refining
- Identify which widgets are reused across screens (buttons, cards, app bars,
  bottom nav) — these should be fixed ONCE in a shared component, not
  duplicated per screen
- Present this audit as a checklist before touching code, so I can confirm scope

---

## STEP 2 — ESTABLISH A DESIGN SYSTEM (Duolingo-inspired)

Create/update a centralized theme file covering:

- **Colors:** keep existing hue family; propose refined shades/tints only
  where it adds polish (see color rules above)
- **Typography scale:** bold, rounded sans-serif feel (e.g. Nunito/Baloo2-style),
  clear hierarchy (display/headline/title/body/caption), consistent line-height
- **Spacing scale:** 4/8/12/16/24/32 system — no magic numbers
- **Border radius:** consistent rounded corners (e.g. 12–20px) across cards,
  buttons, inputs
- **Elevation/shadows:** soft, subtle shadows instead of flat Material defaults
- **Button styles:** chunky, tactile primary buttons with pressed states
  (Duolingo's signature "3D press" button style if feasible), using the
  brand color (refined shade allowed)
- **Component states:** every interactive element needs default/pressed/
  disabled/loading states defined once

---

## STEP 3 — APPLY ACROSS THE WHOLE APP

- Refactor ALL screens to use the new theme/shared components — not just the
  one I'm currently looking at
- Replace generic widgets (default `ElevatedButton`, default `Card`, default
  `AppBar`) with the new styled shared components
- Ensure consistent padding/margins on every screen (no screen should "feel"
  different from another)
- Add appropriate empty states, loading skeletons, and error states using the
  same visual language and color system
- Add tasteful micro-interactions where natural (button press scale, page
  transitions, progress animations) — but don't overdo it

---

## STEP 4 — OUTPUT FORMAT

- Group changes by: (1) theme/shared files first, (2) then each screen
- For each file, show full updated code, not fragments — so nothing gets
  half-applied
- After all changes, give a summary table: `file | what changed | why`
- Separately list any **"Color adjustment"** entries with before/after hex
  and reason
- Flag any screen you could NOT fully update and explain why (e.g. missing
  asset, unclear requirement) so nothing silently gets skipped

---

## CONSTRAINTS

- Keep the existing brand hue family; only refine shades/tones, don't replace
  colors with a different palette (see color rules above)
- Don't change business logic/state management — UI/styling only
- Keep changes Flutter-idiomatic (proper `Theme`/`ThemeData` usage, not inline
  magic numbers)
- Avoid generic "AI-generated" look: no default purple Material You gradients,
  no centered-text-on-white-card cliché, no overuse of generic icons — make
  deliberate, opinionated design choices like a real product team would

---

**Now start with STEP 1 (the audit) and wait for confirmation before
proceeding to the redesign.**