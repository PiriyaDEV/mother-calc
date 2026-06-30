# App UI Design System Update Prompt (Flutter)

> **Role for the AI:** You are acting as a senior **UX/UI Designer + Flutter Developer**.
> Your task: review the **entire existing Flutter app** (all screens, widgets, theme files) and **refactor/update the UI** to match the design system below — for **both Light and Dark mode**.
> This is a **general-purpose design system** — apply only the parts that are relevant to this app's actual screens (e.g. trip planning, bill splitting, member lists, expense tracking). Do not invent UI patterns that don't fit the app's real features (e.g. no chat bubbles, no voice/mic FAB unless the app actually has that).
> Re-evaluate spacing, contrast, and component consistency across **every screen, in both themes,** so the whole app feels cohesive after the change.

---

## 0. Visual Direction Summary

Style: **Minimal, modern, soft, rounded, airy** — light gradient backgrounds, borderless floating cards (shadow instead of stroke), pill-shaped buttons/inputs, generous spacing, rounded sans-serif typography. Primary color family: **blue / navy / sky** (no pink/orange/coral anywhere).

The app must support **Light mode** and **Dark mode**, switching via `ThemeMode` (system/manual toggle). Both themes use the same blue/navy brand identity — dark mode is not just "invert colors," it should feel like the natural night-time version of the same product (deep navy surfaces instead of black, glow instead of flat shadow).

---

## 1. Color Palette

### 1.1 Light Theme

#### Brand & Gradient
| Token | Hex | Usage |
|---|---|---|
| `primaryDeepNavy` | `#0B1E3D` | Headlines, primary text on light surfaces, high-emphasis dark elements |
| `primaryBlue` | `#2D5BFF` | Primary buttons, active states, links, selected tab/icon |
| `accentSky` | `#6EC6FF` | Secondary accents, active icons, progress indicators |
| `accentIce` | `#BFE3FF` | Light tonal backgrounds (icon badges, chips, tags) |
| `accentAqua` | `#7FE0D6` | Tertiary accent — use sparingly (category tags, charts) |
| `gradientStart` | `#E8F2FF` | Background gradient — top/left |
| `gradientMid` | `#CFE3FF` | Background gradient — mid tone |
| `gradientEnd` | `#A9C8FF` | Background gradient — bottom/right |

#### Neutral / Surface
| Token | Hex | Usage |
|---|---|---|
| `surfaceWhite` | `#FFFFFF` | Cards, sheets, input fields |
| `surfaceWhite90` | `#FFFFFFE6` | Glass/frosted cards over gradient background |
| `neutral50` | `#F5F8FC` | App background (solid, non-gradient screens) |
| `neutral100` | `#E9EEF6` | Dividers, subtle borders, disabled backgrounds |
| `neutral400` | `#9AA7BD` | Placeholder text, disabled icons, helper text |
| `neutral600` | `#5C6B85` | Secondary/body text |
| `neutral900` | `#10162B` | Primary text, headings |

### 1.2 Dark Theme

#### Brand & Gradient
| Token | Hex | Usage |
|---|---|---|
| `primaryDeepNavyDark` | `#E8EEFB` | Headlines, primary text on dark surfaces (inverted role — now light text) |
| `primaryBlueDark` | `#5B82FF` | Primary buttons, active states, links — lightened from light-mode blue so it has enough contrast on dark backgrounds |
| `accentSkyDark` | `#7FD0FF` | Secondary accents, active icons |
| `accentIceDark` | `#1C2C49` | Tonal backgrounds (icon badges, chips, tags) — dark desaturated navy instead of pale ice |
| `accentAquaDark` | `#5FC9BD` | Tertiary accent, slightly muted for dark backgrounds |
| `gradientStartDark` | `#0B132B` | Background gradient — top/left (deep navy, not black) |
| `gradientMidDark` | `#101E3D` | Background gradient — mid tone |
| `gradientEndDark` | `#16284F` | Background gradient — bottom/right |

#### Neutral / Surface
| Token | Hex | Usage |
|---|---|---|
| `surfaceDark` | `#121A2E` | Cards, sheets, input fields (base dark surface) |
| `surfaceDark90` | `#121A2EE6` | Glass/frosted cards over gradient background |
| `bgDark` | `#0A0F1E` | App background (solid, non-gradient screens) |
| `borderDark` | `#26314F` | Dividers, subtle borders, disabled backgrounds |
| `neutral400Dark` | `#7C89A8` | Placeholder text, disabled icons, helper text |
| `neutral600Dark` | `#A8B4CC` | Secondary/body text |
| `neutral900Dark` | `#F2F5FA` | Primary text, headings |

> **Elevation in dark mode:** since shadows are barely visible on dark backgrounds, raise elevated surfaces (cards, sheets) by using a **slightly lighter surface color** than the background (`surfaceDark` vs `bgDark`) instead of relying on shadow alone — this is the standard Material 3 dark-elevation approach. Keep a subtle shadow too, but treat the surface-color step-up as the primary depth cue.

### 1.3 Semantic Colors (same role, tuned per theme)
| Token | Light | Dark | Usage |
|---|---|---|---|
| `success` | `#34C77B` | `#3DDB8C` | Paid / settled / positive balance |
| `warning` | `#FFB23E` | `#FFC25F` | Pending / due soon |
| `error` | `#FF5C5C` | `#FF7A7A` | Overdue / you owe / negative balance |
| `info` | `#2D5BFF` | `#5B82FF` | Neutral informational state (same as primaryBlue) |

> Dark-mode semantic colors are slightly brighter/lighter than light-mode versions to maintain the same perceived contrast against dark backgrounds (WCAG-friendly).

### 1.4 Gradient Definitions
```dart
// Light theme background gradient
const backgroundGradientLight = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFE8F2FF),
    Color(0xFFCFE3FF),
    Color(0xFFA9C8FF),
  ],
);

// Dark theme background gradient
const backgroundGradientDark = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF0B132B),
    Color(0xFF101E3D),
    Color(0xFF16284F),
  ],
);

// Primary button gradient — light
const primaryButtonGradientLight = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF2D5BFF), Color(0xFF1A3FCC)],
);

// Primary button gradient — dark
const primaryButtonGradientDark = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF5B82FF), Color(0xFF3D5FE0)],
);
```

> Gradient background is **optional per screen** in both themes — use it on hero/dashboard-style screens (home, trip overview, summary). For list-heavy or data-heavy screens (transaction lists, member lists, settings), prefer the solid background token (`neutral50` light / `bgDark` dark) for readability.

---

## 2. Typography (Thai + Latin support)

Need a font with **full Thai glyph coverage**, paired with a matching Latin look, so mixed Thai/English (e.g. "ทริปเชียงใหม่ 2026", "฿1,250") reads cleanly at all sizes, in both themes.

### Recommended pairing
1. **Headlines/Titles → `Anuphan`** (Google Font) — rounded, modern, designed to harmonize Thai + Latin in one typeface. Bold weights feel premium and match the soft-rounded visual direction.
2. **Body/UI text → `Noto Sans Thai`** (Google Font) — most complete & stable Thai rendering at small sizes, good for line-dense screens like transaction lists and forms.
3. **Alternative single-family option:** `IBM Plex Sans Thai` for everything, if you want one font family across the whole app instead of two.

> Typography sizes/weights stay **identical** between light and dark mode — only the `color` applied to each `TextStyle` changes (via `Theme.of(context).colorScheme` / `textTheme`, never hardcoded).

### Flutter setup
```yaml
dependencies:
  google_fonts: ^6.2.1
```
```dart
TextTheme buildTextTheme(Color textPrimary, Color textSecondary) {
  return TextTheme(
    displayLarge: GoogleFonts.anuphan(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2, color: textPrimary),
    headlineMedium: GoogleFonts.anuphan(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25, color: textPrimary),
    titleLarge: GoogleFonts.anuphan(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, color: textPrimary),
    titleMedium: GoogleFonts.notoSansThai(fontSize: 17, fontWeight: FontWeight.w600, height: 1.35, color: textPrimary),
    bodyLarge: GoogleFonts.notoSansThai(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: textPrimary),
    bodyMedium: GoogleFonts.notoSansThai(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: textSecondary),
    labelLarge: GoogleFonts.notoSansThai(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3, color: textPrimary), // buttons
    labelSmall: GoogleFonts.notoSansThai(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: textSecondary), // captions, timestamps
  );
}

// Build per theme:
final lightTextTheme = buildTextTheme(Color(0xFF10162B), Color(0xFF5C6B85)); // neutral900 / neutral600
final darkTextTheme  = buildTextTheme(Color(0xFFF2F5FA), Color(0xFFA8B4CC)); // neutral900Dark / neutral600Dark
```

### Type scale reference
| Style | Token | Size | Weight | Usage |
|---|---|---|---|---|
| Display | `displayLarge` | 32px | 700 Bold | Big hero headline (e.g. "ทริปของคุณ") |
| Headline | `headlineMedium` | 24px | 700 Bold | Screen titles, section headers |
| Title | `titleLarge` | 20px | 600 SemiBold | App bar title |
| Title Small | `titleMedium` | 17px | 600 SemiBold | Card titles (trip name, bill name) |
| Body | `bodyLarge` | 16px | 400 Regular | Main paragraph text, list item primary text |
| Body Small | `bodyMedium` | 14px | 400 Regular | Card descriptions, secondary list text |
| Button | `labelLarge` | 14px | 600 SemiBold | Button labels, chips, tabs |
| Caption | `labelSmall` | 12px | 400 Regular | Timestamps, helper/meta text |
| Numeric/Amount | `headlineMedium` (or custom 22–28px, tabular figures) | — | 700 Bold | Currency amounts — use `FontFeature.tabularFigures()` so numbers align in lists |

---

## 3. Spacing & Radius System

(Identical in both themes — spacing/radius never change with theme, only color does)

| Token | Value | Usage |
|---|---|---|
| `space-xs` | 4px | Icon-to-text gap |
| `space-sm` | 8px | Tight internal padding |
| `space-md` | 16px | Default card padding, screen margins |
| `space-lg` | 24px | Section spacing |
| `space-xl` | 32px | Major section breaks |
| `radius-sm` | 12px | Chips, small buttons, tags |
| `radius-md` | 20px | Cards |
| `radius-lg` | 28px | Large cards, bottom sheets, modals |
| `radius-full` | 999px | Pill buttons, input fields, avatar containers |

---

## 4. Borders & Elevation

### Light mode
- **No hard borders by default.** Cards float via soft shadow, not stroke:
  ```dart
  BoxShadow(
    color: Color(0xFF2D5BFF).withOpacity(0.08),
    blurRadius: 24,
    offset: Offset(0, 8),
  )
  ```
- Border when needed (outlined button, idle input field): `1px solid neutral100 (#E9EEF6)`.
- Active/focused/selected state: `1.5px solid primaryBlue` + glow shadow `Color(0xFF2D5BFF).withOpacity(0.15), blurRadius: 12`.
- Glass/frosted cards over gradient background: `surfaceWhite90` fill + `1px solid Color(0xFFFFFFFF).withOpacity(0.6)` border.

### Dark mode
- Shadows are mostly invisible on dark backgrounds — use **surface elevation (lighter fill color)** as the primary depth cue, per §1.2 note. Keep a faint shadow for subtle depth on truly floating elements (FAB, modals):
  ```dart
  BoxShadow(
    color: Colors.black.withOpacity(0.4),
    blurRadius: 24,
    offset: Offset(0, 8),
  )
  ```
- Border when needed: `1px solid borderDark (#26314F)` — slightly more visible than light mode's border since dark surfaces have less inherent contrast between layers.
- Active/focused/selected state: `1.5px solid primaryBlueDark (#5B82FF)` + glow shadow `Color(0xFF5B82FF).withOpacity(0.25), blurRadius: 14`.
- Glass/frosted cards over gradient background: `surfaceDark90` fill + `1px solid Color(0xFFFFFFFF).withOpacity(0.08)` border (a faint light edge, not white-90% like light mode).

---

## 5. Card Styles

> All card specs below apply to **both themes** — only swap `surfaceWhite → surfaceDark`, `neutral900 → neutral900Dark`, `neutral600 → neutral600Dark`, etc. per the token tables in §1.

### Standard Content Card (e.g. trip card, bill summary card)
- Background: `surfaceWhite` / `surfaceDark` (or the `90` glass variant over gradient)
- Radius: `radius-md` (20px)
- Padding: `space-md` (16px)
- Shadow/elevation per §4
- Optional icon/image badge top-left, or cover image with rounded top corners
- Title: `titleMedium`, color `neutral900` / `neutral900Dark`
- Subtitle/meta (date, location, member count): `bodyMedium`, color `neutral600` / `neutral600Dark`
- Optional trailing amount (e.g. "฿1,250") in bold, right-aligned

### List Item Card (e.g. transaction row, member row)
- Background: `surfaceWhite` / `surfaceDark`, radius `radius-md`, padding `12px 16px`
- Leading: avatar or icon badge (see §7)
- Middle: title (`bodyLarge`) + subtitle (`bodyMedium`)
- Trailing: amount/status, right-aligned, color-coded by semantic token (theme-correct variant)
- Light shadow, or a `1px` divider (`neutral100` / `borderDark`) if used in a dense list instead of separated cards

### Tag / Chip / Pill (e.g. category tag, filter, status badge)
- Background: tonal color (`accentIce` / `accentIceDark`, or a semantic tone at low opacity e.g. `success.withOpacity(0.12)` — use `0.18–0.20` opacity in dark mode so it stays visible against the dark base)
- Radius: `radius-full`
- Padding: `12px horizontal, 6px vertical`
- Text: `labelLarge`, color matches the tone's full-strength color for that theme

---

## 6. Button Styles

> Same structure in both themes — swap gradient/solid tokens per §1.4.

### Primary Button (filled)
- Background: `primaryButtonGradientLight` / `primaryButtonGradientDark` (or solid `primaryBlue` / `primaryBlueDark`)
- Text: always white-on-blue in both themes (white retains contrast against both gradient variants), `labelLarge`
- Radius: `radius-full` for standalone CTAs (e.g. "Create Trip", "Add Expense"), `radius-sm` (12px) for inline/card buttons
- Height: 48px standalone, 40px inline
- Pressed state: darken further (light: `#1A3FCC`, dark: `#3D5FE0`), scale 0.98

### Secondary Button (tonal / outlined)
- Tonal: background `accentIce` / `accentIceDark`, text `primaryBlue` / `primaryBlueDark`
- Outlined: background `transparent`, border `1px solid neutral100` / `borderDark`, text `neutral900` / `neutral900Dark`
- Same radius/height rules as primary
- Used for: secondary actions ("Cancel", "Skip", "Later")

### Icon Button (circular)
- Size: 40–44px circle
- Background: `surfaceWhite` / `surfaceDark`, with shadow/elevation per §4
- Icon: `neutral900` / `neutral900Dark` default, `primaryBlue` / `primaryBlueDark` when active/selected
- Used for: back button, overflow menu (⋮), filter icon, add (+) button

### Floating Action Button (only if app already uses one, e.g. "Add Expense" / "Add Trip")
- Size: 56px circle (or pill with label + icon for higher emphasis)
- Background: `primaryButtonGradientLight` / `primaryButtonGradientDark`
- Icon: white, centered
- Shadow: light `Color(0xFF2D5BFF).withOpacity(0.25)`; dark `Color(0xFF5B82FF).withOpacity(0.35)` (slightly stronger to read against a dark base), `blurRadius: 16, offset: (0,6)`

### Input Field (text input, search, amount input)
- Background: `surfaceWhite` / `surfaceDark`
- Radius: `radius-full` for search/simple inputs, `radius-sm` (12px) for form fields
- Height: 48–52px
- Idle border: `1px solid neutral100` / `borderDark`
- Focused border: `1.5px solid primaryBlue` / `primaryBlueDark` + glow shadow
- Placeholder: `bodyMedium`, `neutral400` / `neutral400Dark`
- Leading/trailing icon slots: 40px circular icon buttons inside the field padding

---

## 7. Avatars, Member Icons & Group Elements

(Relevant for trip planner / bill splitting — member list, who-owes-who, group selection)

- **Avatar shape:** circle, radius `radius-full`
- **Sizes:** `28px` (inline in lists/chips), `40px` (default list row), `56px` (profile header / trip member summary)
- **Fallback (no photo):** solid tonal background from a rotating palette derived from the brand tones (light: `primaryBlue`, `accentSky`, `accentAqua`, `primaryDeepNavy` / dark: their `Dark` counterparts) + initials in white (light bg) or `neutral900Dark` (if the tonal bg is light enough) — always re-check contrast per swatch
- **Stacked avatars** (e.g. "5 members" preview): overlapping circles with a border matching the surface behind them (`2px surfaceWhite` light / `2px surfaceDark` dark) between each; last one shows `+N` overflow badge in `neutral100`/`borderDark` background with `neutral600`/`neutral600Dark` text
- **Selected member chip:** avatar + name in a pill (`radius-full`, `accentIce`/`accentIceDark` background), with a small checkmark badge (`primaryBlue`/`primaryBlueDark` circle, white check icon) in bottom-right corner of avatar when selected
- **Owner/role indicator (optional):** small `8px` dot, `success` color (theme variant), bottom-right of avatar with a border ring matching the surface behind it

---

## 8. Iconography

- Style: rounded/outline icon set (e.g. `lucide_icons` or `phosphor_flutter`, "regular" weight) — soft, consistent stroke width, matches the rounded visual direction. Same icon set in both themes; only the icon `color` changes per theme tokens.
- Icon badges (circular containers behind icons, e.g. category icons for "Food", "Transport", "Accommodation"): 40–44px circle, tonal background (`accentIce`/`accentIceDark` or a semantic/category color at low opacity — increase opacity slightly in dark mode for visibility), icon at full theme-correct accent color in center.
- Avoid sharp/filled icon styles — keep consistent rounded-outline language app-wide, in both themes.

---

## 9. Screen-Level Background Usage

| Screen type | Light | Dark |
|---|---|---|
| Home / Dashboard / Trip overview | `backgroundGradientLight` full screen + white/glass cards on top | `backgroundGradientDark` full screen + `surfaceDark`/glass cards on top |
| Detail screens (trip detail, bill detail) | Gradient behind hero header, `neutral50` solid below the fold | Gradient behind hero header, `bgDark` solid below the fold |
| Lists (transactions, members, expenses) | Solid `neutral50` | Solid `bgDark` |
| Forms (add expense, create trip, settings) | Solid `neutral50` or `surfaceWhite` | Solid `bgDark` or `surfaceDark` |
| Modals / Bottom sheets | `surfaceWhite`, top corners `radius-lg` (28px) | `surfaceDark`, top corners `radius-lg` (28px) |

---

## 10. Flutter Theming Architecture

- Define **two `ThemeData` objects** — `lightTheme` and `darkTheme` — built from the same token *structure* but different color values, so adding a new component automatically supports both themes if it correctly reads from `Theme.of(context)`.
- Wrap all custom tokens (gradients, semantic colors, elevation rules) in a custom `ThemeExtension` (e.g. `AppColors extends ThemeExtension<AppColors>`) rather than separate global constants, so `Theme.of(context).extension<AppColors>()` gives the correct light/dark values automatically — avoid `if (isDark) ... else ...` checks scattered through widget code.
- Respect system theme by default (`ThemeMode.system`) but support a manual override (light/dark/system) stored in app settings if the app has a settings screen.
- **No widget should hardcode a `Color(0x...)` value.** Every color must come from `Theme.of(context).colorScheme` or the custom `AppColors` extension, so the app switches cleanly when the user toggles theme.

---

## 11. Implementation Checklist for the AI Agent

1. [ ] Create/update a centralized theme source (e.g. `theme/colors.dart`, `theme/text_styles.dart`, `theme/theme.dart`, `theme/app_colors_extension.dart`) with all light + dark tokens above — remove magic hex values scattered across widgets.
2. [ ] Build both `lightTheme` and `darkTheme` `ThemeData` objects, plus the `AppColors` `ThemeExtension`, and wire up `ThemeMode` switching (system + manual toggle if applicable).
3. [ ] Register `Anuphan` (headlines) and `Noto Sans Thai` (body/UI) via `google_fonts`; verify Thai strings (long compound words, tone marks, vowels above/below consonants) render without clipping at the defined sizes, in both font weights and **both themes** (check contrast in dark mode specifically).
4. [ ] Replace any existing pink/orange/coral/warm-toned color references across the codebase with the new blue/navy tokens, for both light and dark variants. Map old semantic uses to the closest new token rather than guessing.
5. [ ] First, inventory the app's actual recurring UI patterns (e.g. trip card, expense list item, member avatar row, balance summary, add-expense form) — then build/refactor shared widgets only for patterns that actually exist in this app. Do not add chat bubbles, voice/mic buttons, or other components not present in the app.
6. [ ] Extract shared widgets, e.g.: `AppCard`, `ListItemCard`, `PrimaryButton`, `SecondaryButton`, `AppTextField`, `IconBadge`, `Avatar` / `StackedAvatars`, `StatusChip` (paid/pending/overdue) — each must read colors from theme, never hardcoded.
7. [ ] Apply gradient backgrounds only to hero/dashboard-style screens per §9, using the theme-correct gradient; keep list/form-heavy screens on the solid background token for that theme.
8. [ ] Audit every screen for contrast in **both themes** — text over gradient/dark areas must use the correct high-contrast token; never place a low-contrast/placeholder color directly on a gradient or dark background without checking it visually.
9. [ ] Verify elevation in dark mode uses surface color step-up (not just shadow) per §1.2/§4, since shadows barely read on dark backgrounds.
10. [ ] Ensure consistent spacing using the `space-*` tokens (replace ad-hoc one-off `EdgeInsets` values) — spacing/radius do not change between themes.
11. [ ] Apply semantic colors consistently for money/status states (paid = `success`, pending = `warning`, owed/overdue = `error`) in both theme variants.
12. [ ] Test both English and Thai content, plus currency formatting (e.g. "฿1,250.00"), in every updated component, **in both light and dark mode**, to confirm visual balance and that numbers use tabular figures where shown in lists.
13. [ ] Manually toggle the app between light/dark at runtime and check every screen for any leftover hardcoded color that didn't switch.
14. [ ] Summarize, at the end, every file changed and a short rationale per screen.

---

## 12. Quick Reference: Old → New Color Mapping

| If the app currently uses... | Light mode replacement | Dark mode replacement |
|---|---|---|
| Any pink/coral/peach primary or accent color | `primaryBlue (#2D5BFF)` / `accentSky (#6EC6FF)` | `primaryBlueDark (#5B82FF)` / `accentSkyDark (#7FD0FF)` |
| Any orange/warm gradient background | `backgroundGradientLight` | `backgroundGradientDark` |
| Warm-toned icon badge backgrounds | `accentIce (#BFE3FF)` | `accentIceDark (#1C2C49)` |
| Solid black primary buttons/FAB | `primaryDeepNavy (#0B1E3D)` or `primaryButtonGradientLight` | `primaryButtonGradientDark` (avoid pure black; use deep navy family) |
| Generic gray text/borders | `neutral600` (text) / `neutral100` (borders) | `neutral600Dark` (text) / `borderDark` (borders) |
| Existing app background (white/light gray) | `neutral50 (#F5F8FC)` | `bgDark (#0A0F1E)` |
| Existing card/surface background | `surfaceWhite (#FFFFFF)` | `surfaceDark (#121A2E)` |