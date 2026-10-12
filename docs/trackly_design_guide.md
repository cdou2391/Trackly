# Trackly Design Guide

## 1. Purpose

This document defines the visual and interaction design system for **Trackly**, a subscription and recurring bills tracker.

The visual direction is:

> **Dark black-blue surfaces + teal accents + clean matte cards + restrained curves + highly legible status colors**

Trackly should feel simple, modern, calm, trustworthy, private, and practical.

Avoid:
- Glassmorphism
- Purple as a primary or accent color
- Excessive gradients
- Glossy surfaces
- Overly wide layouts
- Decorative shadows
- Dense finance-dashboard clutter
- Too many charts
- Overuse of curves

---

## 2. Core Design Principles

### 2.1 Content first
Prioritize:
1. Monthly recurring cost
2. Upcoming charges
3. Quick Add
4. Recent payments
5. Secondary insights

Decorative elements must never compete with these.

### 2.2 Curves define major sections
Use curves only for:
- Hero section boundaries
- Quick Add section boundaries
- Large page headers
- Major section transitions

Do not use curves for list rows, buttons, or status pills.

**Rule:**
- Large curves = major sections
- Rounded cards = interactive content
- Pills = status
- Matte surfaces = structure

### 2.3 Matte, not glass
Use opaque dark surfaces, subtle borders, and very light tonal elevation.

Avoid:
- Transparency blur
- Frosted backgrounds
- Glass panels
- Heavy background blur
- Translucent cards

### 2.4 Minimal color noise
Teal is the primary brand/accent color.

Functional colors:
- Green = active / paid / success
- Amber = trial / warning / due soon
- Red = cancelled / urgent
- Blue-gray = neutral dates / secondary information

---

## 3. Screen Proportions

Design for realistic modern smartphones.

Reference viewport:
- Width: 390–430 dp
- Height: 800–930 dp

Good implementation references:
- 390 × 844 logical pixels
- 412 × 915 logical pixels

Horizontal padding:
- 16 dp minimum
- 20 dp preferred
- 24 dp only for large hero content

Do not design around unusually wide phone proportions.

---

## 4. Spacing System

Use an 8-point system:

- 4 dp — micro spacing
- 8 dp — icon/text spacing
- 12 dp — compact internal spacing
- 16 dp — default spacing
- 20 dp — large card padding
- 24 dp — section spacing
- 32 dp — major section gap
- 40–48 dp — hero/page spacing

Avoid arbitrary values unless alignment requires them.

---

## 5. Dark Theme Color Palette

### Background
- App background: `#000000` (pure black, decided; was `#07111C`)
- Deep background option: `#050C14`

### Surfaces
- Surface 1: `#0D1B28`
- Surface 2: `#122433`
- Surface 3: `#183040`

### Brand teal
- Primary teal: `#16C7BE`
- Dark teal: `#0E8F89`
- Light teal: `#4EDDD5`

Use teal for:
- Primary actions
- Active navigation
- Focus borders
- Key highlights
- Hero illustration accents

Do not use teal everywhere.

---

## 6. Status Colors

### Success / Active
- Foreground: `#24C97A`
- Background: `#123D2E`

### Warning / Trial / Soon
- Foreground: `#FFB629`
- Background: `#3A2B12`

### Danger / Cancelled / Urgent
- Foreground: `#FF5D62`
- Background: `#3A181D`

### Neutral date
- Foreground: `#A9C0D2`
- Background: `#12293A`

---

## 7. Text Colors

- Primary text: `#F7FAFC`
- Secondary text: `#AAB8C5`
- Muted text: `#728394`

---

## 8. Light Theme Palette

Dark mode is the main reference, but light mode should preserve the same hierarchy.

- Background: `#F5F8FA`
- Surface: `#FFFFFF`
- Secondary surface: `#EDF5F5`
- Primary text: `#0D1B28`
- Secondary text: `#607184`
- Primary teal: `#0FA9A3`

Use the same status semantics as dark mode.

---

## 9. Typography

Recommended font:
- Inter

Acceptable alternative:
- Roboto

### Type scale

**Hero amount**
- 48–56 sp
- Weight 700
- Line height 1.0–1.05

**Page title**
- 34–40 sp
- Weight 700

**Section heading**
- 22–26 sp
- Weight 700

**Card title**
- 16–18 sp
- Weight 600

**Body**
- 14–16 sp
- Weight 400

**Supporting metadata**
- 13–14 sp
- Weight 400

**Status pill**
- 12–13 sp
- Weight 500

---

## 10. Header

Home header:

- Trackly
- Subscriptions & Bills
- Search icon
- Settings icon

Guidelines:
- Left-align title and subtitle
- Right-align actions
- Keep it compact
- Do not add profile avatars or greetings
- Do not overload the header with extra actions

---

## 11. Hero Section

The hero is Trackly’s most distinctive visual element.

### Content
Example:

```text
YOUR RECURRING COST

$84.37 / month

$1,012.44 per year
```

### Visual
- Solid deep teal `#0B3138` (the brand teal, darkened), set against the black page
- Flat teal two-tone illustration on the right
- Main amount aligned left
- Illustration remains secondary to the amount, but large enough to read

### Bottom boundary (decided)
No separate corners and no wave. The filled hero's bottom edge is one wide arc
that runs edge to edge:
- The sides sit 36 dp higher than the middle, which is the lowest point
- The fill itself defines the edge; there is no separate border line

Waves remain for the Quick Add panel's top edge (section 15).

### Illustration size (decided)
The artwork is drawn about 200 dp wide. It reserves less room in the row (about
120 dp) and spills left over its own transparent margin, so the amount keeps
its space.

### Padding
- Horizontal: 24 dp
- Vertical: 20–28 dp

---

## 12. Hero Illustration Style

Use:
- Flat vector
- Two-tone teal/navy
- Minimal detail
- No people
- No 3D
- No photo assets

Good subjects:
- Calendar
- Renewal card
- Reminder bell
- Subscription card
- Recurring arrows

---

## 13. Status Summary Cards

Three cards:
- Active
- Trial
- Cancelled

Each card contains:
- Icon
- Count
- Label
- Chevron

Semantic color:
- Active = green
- Trial = amber
- Cancelled = red

Use three equal-width matte cards.

Avoid blur or glass treatment.

Paused items:
- There is no Paused card.
- Paused items are counted in the Active card.
- Their rows show a neutral "Paused" pill.
- They are excluded from hero totals and from Upcoming.

Trials:
- A trial item is counted only in the Trial card, not in the Active card.
- Active + Trial counts therefore never overlap.

---

## 14. Quick Add Section

Quick Add is a core Trackly interaction.

### Heading
`Add a new subscription`

### Helper
`Quick add — you can edit details later`

### Fields
- Service name
- Amount
- Frequency
- Start date
- Save

Recommended layout:

First row:
`Search a service`

Second row:
`Amount | Frequency | Start date | Save`

---

## 15. Quick Add Surface

Use a slightly teal-tinted matte surface.

Recommended:
`#0D2730`

Allow a subtle shallow curve at the top or bottom boundary.

Do not use blur or transparency.

---

## 16. Quick Add Save Button

Use a real button rather than a plus icon.

Label:
`Save`

Optional icon:
checkmark

Recommended:
- Background: `#16C7BE`
- Text: `#041112`
- Height: 48–52 dp
- Radius: 16 dp

Pressed:
`#0E8F89`

Disabled:
- Background: `#274149`
- Text: `#70848B`

Disable until minimum required fields are valid.

---

## 17. Input Fields

Dark mode:
- Background: `#122433`
- Border: `#244052`

Focused:
- Border: `#16C7BE`

Error:
- Border: `#FF5D62`

Radius:
- 14–16 dp

Height:
- 48–56 dp

Avoid underline-only inputs and heavy shadows.

---

## 18. Upcoming Charges

Each row contains:
- Service icon/logo
- Service name
- Frequency • Currency
- Due status/date
- Amount
- Chevron

Example:

```text
Netflix
Monthly • USD
Due tomorrow
$15.49
```

---

## 19. Charge Card

Recommended:
- Background: `#0D1B28`
- Radius: 16 dp
- Padding: 14–16 dp
- Border: 1 dp `#173142`

Use little or no shadow.

---

## 20. Service Icon

Recommended size:
- 44–48 dp

Radius:
- 12–14 dp

If a service logo is unavailable:
- Use a generic category icon

Do not require logos for custom services.

---

## 21. Status Pills

Examples:
- Due tomorrow
- In 3 days
- Paid 2 Oct
- 18 Oct 2026

Recommended:
- Radius: 999 dp
- Horizontal padding: 8–12 dp
- Vertical padding: 6–8 dp

Status pills are informational, not primary actions.

---

## 22. Recent Payments

Use the same structure as Upcoming Charges.

Example:
`Paid 2 Oct`

Use green status styling.

Consistency is more important than inventing a separate card style.

---

## 23. Bottom Navigation

Items:
- Home
- Insights
- Add
- Calendar
- More

Navigation surface:
`#000000` (pure black, matching the app background)

Top border:
`#000000` (black, so no visible line above the bar)

Active item:
Teal

Inactive:
`#8394A5`

No glass blur.

---

## 24. Bottom Add Button

Use a centered circular teal button.

- Size: 56–64 dp
- Background: `#16C7BE`
- Icon: plus

Meaning:
- Bottom + = open the full add form as a panel that slides up from the navigation bar (not a separate screen). The + turns into a cross while the panel is open. Tapping the dim area, the cross, a tab, or the system back gesture closes it.
- Quick Add Save = save the inline form

---

## 25. Card Radii

Global radius guidance:
- Small: 12 dp
- Medium: 16 dp
- Large: 20 dp
- Section container: 24 dp
- Pill: 999 dp

Do not over-round every component.

---

## 26. Shadows

Dark mode should rely on tonal hierarchy rather than visible shadows.

Recommended:
- Black at 20–30% opacity
- Blur 8–16
- Y offset 2–4

Use sparingly.

---

## 27. Borders

Use borders to separate dark matte surfaces.

Default:
- 1 dp
- `#173142`

Focused/accent:
- Teal at reduced opacity

---

## 28. Buttons

### Primary
- Teal background
- Dark text

### Secondary
- Dark surface
- Teal text
- Thin teal border

### Destructive
- Dark red background
- Red text/icon

Avoid gradients on primary buttons.

---

## 29. Iconography

Recommended:
- Material Symbols Rounded

Use:
- Simple line icons
- Medium weight
- Consistent stroke

Do not mix unrelated icon families or emoji within core UI.

---

## 30. Motion

Keep motion restrained.

Timing:
- 120–180 ms: button/state feedback
- 180–240 ms: card transitions
- 220–300 ms: screen-level transitions

Curves:
- easeOutCubic
- easeInOutCubic

Avoid bouncing and continuous decorative motion.

---

## 31. Home Entrance Motion

Allowed:
- Hero fade-in
- Quick Add short fade/slide
- Very slight row stagger

Avoid:
- Full-screen transforms
- Large bounce
- Continuous animation

---

## 32. Quick Add Interaction

Flow:

```text
Tap service name
→ Choose/type service
→ Enter amount
→ Select frequency
→ Select start date
→ Save activates
→ Tap Save
→ Show inline success
→ New item appears in Upcoming
```

Suggested success feedback:

`Saved — next charge 8 Nov`

Use a subtle check animation.

---

## 33. Component States

Every interactive component must define:
- Default
- Focused
- Pressed
- Disabled
- Error
- Success
- Loading

---

## 34. Empty States

Example:

```text
No upcoming charges

Add your first subscription to start tracking renewals.
```

Use:
- Small illustration
- Clear CTA
- No giant empty card

Curves may appear behind the illustration.

---

## 35. Error States

Prefer clear errors:

`Couldn't save subscription. Try again.`

Avoid vague messages like:
`Something went wrong`

unless no better context is available.

---

## 36. Accessibility

Minimum touch target:
- 48 × 48 dp

Requirements:
- High contrast
- Semantic labels
- Screen reader support
- Dynamic text
- Status text in addition to color

Do not rely solely on red/green color coding.

---

## 37. Dynamic Text

Layouts should remain usable around:
- 100%
- 120%
- 150%

Avoid fixed-height containers for content-heavy cards.

---

## 38. One-Handed Use

Primary actions should remain reachable.

Good placements:
- Quick Add
- Bottom Add button
- Bottom navigation

Do not place all primary actions in the upper-right corner.

---

## 39. Responsive Behavior

For screens below 360 dp wide:
- Let Quick Add wrap into two rows
- Do not shrink text aggressively

Example:

```text
Amount | Frequency
Start date | Save
```

For widths above 430 dp:
- Increase outer padding modestly
- Keep max content width around 480–520 dp
- Do not stretch list cards excessively

---

## 40. Insights Screen

Use the same design language.

Possible layout:
- Curved summary header
- Monthly spend
- Annual spend
- Category breakdown
- Upcoming 30 days

Avoid chart overload.

---

## 41. Calendar Screen

Use:
- Matte dark header
- Teal selected date
- Simple monthly/agenda view

A curved top section may contain:
- Month
- Total due this month

Keep it functional, not decorative.

---

## 42. Add/Edit Screen

Use a normal page layout.

Structure:
- Basic details
- Billing
- Reminder
- Optional details
- Save

Do not repeat the full Home hero treatment.

---

## 43. Detail Screen

Example:

```text
Netflix

$15.49 / month
Next: 18 Oct
Reminder: 3 days before
Status: Active

Payment history
Notes
Edit
Cancel subscription
```

Keep the recurring lifecycle visible.

---

## 44. Flutter Color Tokens

```dart
class TracklyColors {
  static const background = Color(0xFF000000);
  static const surface1 = Color(0xFF0D1B28);
  static const surface2 = Color(0xFF122433);
  static const surface3 = Color(0xFF183040);

  static const teal = Color(0xFF16C7BE);
  static const tealDark = Color(0xFF0E8F89);
  static const tealLight = Color(0xFF4EDDD5);

  static const success = Color(0xFF24C97A);
  static const warning = Color(0xFFFFB629);
  static const danger = Color(0xFFFF5D62);

  static const textPrimary = Color(0xFFF7FAFC);
  static const textSecondary = Color(0xFFAAB8C5);
  static const textMuted = Color(0xFF728394);
}
```

---

## 45. Flutter Radius Tokens

```dart
class TracklyRadius {
  static const small = 12.0;
  static const medium = 16.0;
  static const large = 20.0;
  static const section = 24.0;
  static const pill = 999.0;
}
```

---

## 46. Flutter Spacing Tokens

```dart
class TracklySpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const base = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}
```

---

## 47. Material 3 Integration

Use Material 3:

```dart
ThemeData(
  useMaterial3: true,
)
```

Customize:
- `ColorScheme`
- `CardTheme`
- `InputDecorationTheme`
- `NavigationBarTheme`
- `FilledButtonTheme`
- `TextTheme`

Do not rely on default Material colors.

---

## 48. Surface Hierarchy

Use this tonal hierarchy:

```text
Background
#000000

Cards, rows, summary cards (Surface 1)
#0D1B28

Inputs (Surface 2)
#122433

Elevated / selected (Surface 3)
#183040

Quick Add panel
#0D2730

Accent
#16C7BE
```

This provides separation without glassmorphism.

Decision: this is the single source of truth for surfaces. It matches §19 and §55.

---

## 49. Do / Don't

### DO
- Use matte black-blue surfaces
- Use teal sparingly
- Use clear financial hierarchy
- Use curved section boundaries
- Use compact rows
- Use readable typography
- Use status pills
- Use thin borders
- Use contextual actions

### DON'T
- Use purple
- Use glass blur
- Use translucent cards
- Use excessive neon
- Use gradients everywhere
- Use many decorative accent colors
- Use too many waves
- Use giant cards
- Use dense charts
- Use tiny text

---

## 50. Home Screen Hierarchy

Recommended order:

```text
Status bar
→ Header
→ Curved Hero
→ Status Summary
→ Quick Add
→ Upcoming Charges
→ Recent Payments
→ Bottom Navigation
```

Primary information priority:
1. Recurring cost
2. Upcoming charges
3. Quick Add
4. Recent activity

---

## 51. Approximate Vertical Sizing

For ~844 dp height:

- Header: 80–100 dp
- Hero: 220–260 dp
- Status cards: 84–96 dp
- Quick Add: 200–230 dp
- Upcoming rows: variable
- Bottom nav: 76–88 dp

Allow natural scrolling.

Do not force the whole experience into one viewport.

---

## 52. Visual Density

Trackly should feel comfortable, not wasteful.

List rows:
- approximately 72–84 dp high

This keeps the app practical on normal smartphones.

---

## 53. Brand Mark Direction

Potential icon concepts:
- Recurring arrow
- Calendar + repeat
- Stacked recurring card
- Circular renewal mark

Use teal on dark blue.

Avoid generic dollar-sign-only branding.

---

## 54. Light/Dark Parity

Light mode must preserve:
- Same hierarchy
- Same spacing
- Same component dimensions
- Same curve logic
- Same status semantics

Only surface values and contrast should change.

---

## 55. Recommended Dark Theme Composition

```text
Background       #000000
Hero             #0B3138 (deep teal) + teal illustration
Summary cards    #0D1B28
Quick Add        #0D2730
List cards       #0D1B28
Inputs           #122433
Bottom nav       #000000
Primary action   #16C7BE
```

---

## 56. Recommended Light Theme Composition

```text
Background       #F5F8FA
Hero             dark teal
Summary cards    #FFFFFF
Quick Add        #E9F4F4
List cards       #FFFFFF
Inputs           #F3F6F8
Bottom nav       #FFFFFF
Primary action   #0FA9A3
```

---

## 57. Implementation Priority

### Phase 1
- Color tokens
- Typography
- Spacing
- Radius
- Theme

### Phase 2
- Hero
- Status cards
- Quick Add
- Subscription row
- Status pill
- Bottom navigation

### Phase 3
- Insights
- Calendar
- Details
- Forms
- Settings

---

## 58. Acceptance Criteria

The Trackly design is successful when:

- Monthly recurring cost is obvious within one second
- Upcoming charges are readable without another screen
- Adding a subscription feels fast
- Dark mode is black-blue rather than gray or purple
- The interface remains matte
- Curves feel intentional rather than decorative
- Teal is recognizable but restrained
- The app works on a standard narrow smartphone
- Status colors remain semantic and readable
- The app feels modern without becoming visually noisy

---

## 59. Core Design Rule

If a visual element does not improve one of:

- Clarity
- Hierarchy
- Actionability
- Trust
- Readability

do not add it.

Trackly should be visually recognizable through:

> **dark black-blue surfaces + teal accents + curved major sections + clean typography + compact recurring-payment cards**

—not through excessive effects.

---

## 60. Light theme (current default, as built)

Warm, premium, restrained. Gold is an accent, never the main color.

**Colors**
- Page `#FAF8F4`, cards `#FFFFFF`, hairline border `#E7E4DE`
- Text `#0B1322`, secondary text `#657286`
- Gold accent `#C99A3D` (decoration, center button); deeper gold `#8F6A22` for small text such as "See all"
- Save button and primary actions: ink navy `#1A2130`
- Status chips use deeper shades of green, amber and red than the brand colors, so small labels pass 4.5:1

**Type**
- Wordmark and page titles: Playfair Display, 40 sp, semi-bold
- Everything else: Inter. Subtitle 18, section headings 24 (semi-bold), list titles 17 (semi-bold), body 13-14
- Hero amount 50 sp bold with a small "/month"

**Home**
- Header on the page background; hero is a rounded cream card (28 dp radius) with a warm illustration
- Summary cards: tinted icon circle, count, label, chevron. Side by side from about 118 dp per card, stacked on narrower ones
- Quick Add: flat white card. Search full width; amount, frequency, start date and Save on one row (two rows below about 350 dp)
- Rows: white, hairline border, 44 dp tile, chip beside the name when everything fits, otherwise under it
- Bottom navigation: white, gold dot under the active tab, 62 dp gold center button

The dark theme keeps its black page, deep-teal hero with an arc, and teal accent.

