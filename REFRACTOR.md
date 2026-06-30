# Flutter Code Refactor Prompt — Structure & Redundancy Cleanup

> Use this prompt with your AI coding assistant to audit the project structure
> and refactor redundant/duplicated code into clean, reusable components —
> WITHOUT changing how the app looks or behaves.

---

## ROLE

You are a senior Flutter engineer doing a code-quality refactor pass. Your
job is to find redundancy, inconsistent structure, and duplicated logic/UI
code across the project, then consolidate it into clean, reusable, well-
organized pieces — without changing any visual design or app behavior.

## GOAL

1. Assess whether the current project structure (folders, file organization,
   naming conventions) is good practice or needs reorganizing.
2. Find duplicated/near-duplicated code — especially UI widgets that repeat
   with slightly different data (e.g. bill cards, group cards, emoji
   pickers/displays, list items, badges, etc.) — and extract them into
   single reusable, parameterized widgets.
3. Reduce redundancy in logic too (repeated formatting functions, repeated
   validation, repeated API-call patterns, etc.), not just UI.

This is a **refactor**, not a redesign — the app must look and behave
exactly the same after, just built on cleaner, more maintainable code.

---

## STEP 1 — STRUCTURE AUDIT (do this before writing any code)

- Scan the full project (`lib/` and subfolders) and map out the current
  folder structure
- Evaluate it against standard Flutter project conventions, e.g.:
  - Is there a clear separation between `screens`/`pages`, `widgets`
    (reusable components), `models`, `services`/`repositories`, `theme`,
    and `utils`?
  - Are widgets grouped by feature or dumped in one flat folder?
  - Are there naming inconsistencies (e.g. `BillCard` vs `bill_card_widget`
    vs `CardBill`)?
- Give a verdict: is current structure OK, needs minor cleanup, or needs a
  bigger reorganization? Explain why.
- Propose a target folder structure (only if current one has real problems —
  don't reorganize just for the sake of it)

---

## STEP 2 — FIND DUPLICATION / REDUNDANCY

Go file by file and identify:

- **Repeated UI patterns:** widgets that are copy-pasted with small tweaks
  across screens. Specifically check for (but not limited to):
  - Bill/transaction card-style widgets
  - Group/category card-style widgets
  - Emoji picker, emoji display, or emoji-in-circle/avatar widgets
  - List item rows, section headers, badges/chips, dialogs, bottom sheets
- **Repeated logic:** duplicated formatting (currency, date, number),
  duplicated validation, duplicated API/service call patterns, duplicated
  state-management boilerplate
- **Repeated styling inline:** the same `BoxDecoration`, `TextStyle`, or
  padding values typed out repeatedly instead of reused from theme/constants

For each duplication found, list:
- Where it appears (file + line/widget name)
- How many times it's duplicated
- Whether the duplicates are 100% identical or have small variations
  (if variations, note what differs — so it can become a parameter)

Present this as a checklist/report BEFORE refactoring, so I can confirm scope.

---

## STEP 3 — REFACTOR PLAN

For each duplication group identified in Step 2, propose:

- A single new reusable widget/function name and location
  (e.g. `lib/widgets/cards/bill_card.dart`)
- Its parameters (what varies between the old duplicates becomes a
  constructor parameter / function argument)
- Which files will now import and use it instead of their inline version

Group related items together, for example:
- **Card widgets** → `lib/widgets/cards/` (bill_card.dart, group_card.dart, etc.)
- **Emoji widgets** → `lib/widgets/emoji/` (emoji_avatar.dart, emoji_picker.dart, etc.)
- **Shared formatting/helpers** → `lib/utils/` (currency_formatter.dart, date_formatter.dart, etc.)

Wait for my confirmation on this plan before applying changes, unless the
duplication is small/obvious and low-risk.

---

## STEP 4 — APPLY THE REFACTOR

- Create the new reusable widgets/functions first
- Replace each duplicated instance across the app with a call to the new
  shared version
- Make sure every replaced instance passes the correct parameters so the
  rendered output is pixel-identical to before
- Do NOT change colors, spacing, fonts, copy text, or behavior — this is
  structural cleanup only, not a visual change
- Remove now-unused old code/files (don't leave dead duplicate widgets behind)

---

## STEP 5 — OUTPUT FORMAT

- Show full code for every new shared widget/function created
- Show a diff-style summary for every file that was updated to use the new
  shared component (what was removed, what was added)
- Provide a summary table: `duplication found | consolidated into | files affected`
- Flag anything that LOOKED like a duplicate but you decided NOT to merge,
  and explain why (e.g. behavior differs too much, premature abstraction risk)
- Confirm at the end: "no visual or behavioral changes were made, only
  structural refactoring"

---

## CONSTRAINTS

- No visual changes — same colors, spacing, fonts, text, icons, layout
- No behavior changes — same business logic, same state management approach
- Don't over-abstract: only merge things that are genuinely repeated 2+ times
  with a clear shared shape. Don't force unrelated widgets into one
  "god component" just because they look similar at a glance
- Keep new shared widgets simple and well-named — prefer a few clear,
  purpose-built reusable widgets over one giant configurable mega-widget
- Preserve existing imports/package structure conventions already used in
  the project unless Step 1 audit says otherwise

---

**Now start with STEP 1 (structure audit), then STEP 2 (duplication report).
Wait for my confirmation before proceeding to STEP 3 and STEP 4.**