---
description: CricUnity design tokens and UI rules — load when building or reviewing any UI
paths:
  - "lib/**"
  - "src/**"
  - "app/**"
---

# Design system quick reference (authoritative detail: docs/CricUnity_Design_Spec.md)

## Spacing (8pt base, 4pt half-step)
4 icon↔label, chip internals · 8 intra-card gap · 12 list-row vertical, gutters
16 screen side margins, card padding · 20 featured-card padding · 24 section gap
32 major sections · 40/48 hero headers, empty states. Nothing off this scale.

## Radius / elevation / borders (DS §2.2)
r-xs 6 chips · r-sm 10 buttons+inputs · r-md 14 cards · r-lg 20 sheets · r-full pills
e1 y2/b8/6% · e2 y4/b16/10% (FAB, sticky bars) · e3 y8/b32/16% (sheets, dialogs)
Dark themes: elevation via +4/+8/+12% surface luminance, no shadows; money
surfaces ALWAYS keep a 1px border in every theme.

## Type ramp (DS §2.4) — Clash Display + Inter, tnum on mutable numbers
Display Clash600 34/40 · H1 Clash600 28/34 · H2 Inter600 20/26 · Title Inter600 17/24
Subtitle Inter500 15/22 · Body Inter400 15/22 · Caption 13/18 · Label 12/16
Button Inter600 15/20 · Stat Inter600 tnum 22/28 · Money Inter600 tnum (₹ at 70%,
top-aligned) · Scoreboard Clash700 tnum 40/44. Min body 13. 135% dynamic type
must reflow; money wraps before it truncates.

## Color rules (DS §2.3, §4)
Semantic tokens only. Reserved: live red / coin amber / verified teal — constant
across themes, never decorative. Debt text is neutral ink; red = overdue only.
Charts: theme categorical ramp, shapes+labels never color-only.

## Interaction states (every component, DS §3 intro)
Pressed scale0.98 + 8% tint 80ms · Disabled 38% fg on disabledBg · Focus 2px ring
offset 2 · Loading = shape-preserving skeleton (width locked) · Selected per spec.

## Motion tokens (DS §2.6, §5)
80 instant · 160 fast · 240 standard (push/sheet) · 360 gentle (expand) ·
900–1400 ceremony. Standard easing cubic(0.2,0,0,1); spring damping 0.8 only for
coin/XP physics. Reduced-motion: 120ms fades, static ceremony cards.
Ceremonies queue; never over Live Scoring or money confirmations.

## Layout constants (DS §2.1)
Frame 375×812 · bottom nav 56+inset · app bar 56 (large-title 96→56) ·
FAB 56 raised 12 · sticky action bar 72 · touch ≥44 (48 primary), gaps ≥8 ·
carousel card 280 w/ 24 peek · content max 600 on tablets.
