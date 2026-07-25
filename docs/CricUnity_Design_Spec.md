# CricUnity — Production Design Specification (UX/UI)
## Companion to PRD v1.3 · Design Spec v1.0

**Audience:** Product Designers (Figma build), Frontend implementers, QA, Accessibility reviewers.
**Scope:** Mobile-first (375×812 reference frame), scaling rules to small (320) and large (430+) phones and tablets. Behavior and business rules live in the PRD; this document defines *how everything looks, moves, and feels*. No code, no technology.

---

# 0. Design Vision

**One line:** the calm confidence of Apple, the ceremonial reward moments of CRED, the trustworthy warmth of Airbnb, the typographic discipline of Linear, and the athletic pride of Strava — applied to grassroots cricket.

**Design pillars (every decision must serve one):**
1. **Glance-first.** A player standing at a boundary with one thumb and 4G must get the answer in <3 seconds. Information hierarchy is ruthless: answer → context → actions.
2. **Verified feels different.** Verified data (✔ scorecards, earned badges) gets a distinct visual voice — solid, engraved, permanent. Unverified/social content is lighter, softer. Users should *feel* the difference before reading it.
3. **Ceremony where it's earned.** Motion is quiet everywhere except achievement moments (badge unlock, record broken, settlement complete), which get full ceremonial animation. Contrast is what makes ceremony premium.
4. **Money is calm.** Expense surfaces use a subdued, banking-grade tone: no gamification color, generous whitespace, unambiguous numerals. Trust through restraint.
5. **One-thumb law.** Every primary action sits in the bottom 40% of the screen. Nothing critical lives in the top corners.

**Signature element — "The Arc."** A quarter-circle arc derived from the cricket wagon wheel is the brand's geometric signature. It appears as: progress rings (¾-arc, gap at 45° bottom-right), the loading spinner (arc sweep), section header underlines (28×3px arc-ended bar), the celebration burst (arcs radiating like shot directions), and the app icon. The Arc is the *only* decorative device permitted; everything else is content.

---

# 1. Information Architecture

## 1.1 Sitemap (top level → depth 3; ▸ = pushed screen, ⌂ = tab root, ● = modal/sheet)

```
⌂ HOME (Dashboard)
   ▸ Notification Center ─ ▸ Notification Settings
   ▸ Global Search ─ ▸ Results ▸ Advanced Filters ● QR Scanner
   ▸ Wallet & Coins ─ ▸ Coin History ▸ Marketplace ▸ Listing ▸ My Rewards
   ▸ Missions Board ─ ▸ Season Planner
   ● Quick-action chips (Respond / Pay / Confirm)
⌂ MATCHES
   ▸ Match Detail (pre-live) ─ ● Availability sheet ● Directions
   ▸ Live Match View ─ tabs: Commentary · Scorecard · Charts · Gallery
   ▸ Live Scoring Console (scorer only) ─ ● Wicket sheet ● Interrupt sheet
   ▸ Scorecard (final) ─ ● Dispute sheet
   ▸ Post-Match Summary ─ ▸ Insights ▸ Ratings ● MVP pick
   ▸ Match Expense Sheet ─ ▸ Expense Detail
   ▸ Create Match (wizard, 4 steps) ─ ● Ground picker ● Toss
● CREATE (+) — role-aware sheet
   → Post / Story / Reel / Poll / Match / Expense / Team / Session /
     Tournament / Announcement / Challenge
⌂ COMMUNITY
   ▸ Feed ─ ▸ Post Detail ▸ Profile(any) ▸ Hashtag
   ▸ Stories viewer (overlay) · Reels player (overlay)
   ▸ Groups ─ ▸ Group Home ▸ Group Settings
   ▸ Events ─ ▸ Event Detail
   ▸ Messenger ─ ▸ Thread ▸ New message ▸ Requests
⌂ PROFILE (Me)
   ▸ Edit Profile · ▸ Achievements Wall ▸ Badge Detail
   ▸ Activity Calendar · ▸ Year in Review (overlay story)
   ▸ My Teams ─ ▸ Team Home ─ ▸ Members ▸ Treasury ▸ Availability Matrix
        ▸ Selection Board ▸ Jersey ▸ Carpool ▸ Duty Roster ▸ Documents
   ▸ My Tournaments ▸ My Bookings ▸ Leaderboards ▸ Records
   ▸ Expenses Home ─ ▸ Add Expense ▸ Expense Detail ▸ Settle Up ▸ Reports
   ▸ Settings ─ ▸ Privacy ▸ Notifications ▸ Appearance ▸ Blocked ▸ Help
SIDE DRAWER (roles): Captain / Scorer / Umpire / Coach / Ground / Academy /
   Organizer / Club / Sponsor consoles (each a self-contained stack)
HIDDEN (reachable only contextually): Toss, Auction Room, Awards Ceremony
   mode, Scoreboard TV mode, Guardian view, Sandbox tutorial match,
   Report flow, Moderation console, Recently Deleted, Restore flows
```

## 1.2 Feature & navigation hierarchy rules
- **Depth cap = 3 pushes** from any tab root; anything deeper becomes a sheet or a tab-within-screen. (Rationale: back-stack legibility, Hick's Law.)
- **Parent owns state:** a child screen never introduces a filter its parent list can't reflect on return.
- **Modules by frequency:** daily-frequency modules (Home, Matches, Feed, Messages, Profile) get tab roots; weekly-frequency (Expenses, Teams, Wallet) get one-tap access from Home widgets + Profile; monthly/rare (Consoles, Settings) live in the drawer.
- **Module dependencies (design contract):** Match screens may embed Expense, Reward, and Social components; Expense screens never embed gamified components (Pillar 4); Reward ceremonies may interrupt any screen except Live Scoring and any money confirmation (never obscure a financial decision).

## 1.3 Deep links & quick actions
- Every object screen has a canonical link (match, team, profile, tournament, ground, expense, post) that restores exact scroll-target (e.g., link to ball 14.3 opens Scorecard scrolled + highlighted).
- Launcher shortcuts (long-press app icon): Start Scoring · My Next Match · Scan QR · Add Expense.
- Notification taps always deep-link to the *actionable* state, not the parent list (payment reminder → Settle sheet pre-filled, one tap from done).

## 1.4 User journey map (primary persona: club player "Priya", weekly rhythm)
```
Thu 20:00  Push: availability poll → 1 tap "Yes" from notification (0 screens)
Fri 18:00  Home: Upcoming Match widget → checks weather chip, taps Directions
Sun 06:40  Geo-window: Check-in chip appears on Home → 1 tap check-in
Sun 07:05  Watches toss result toast; benched friend follows Live view
Sun 10:30  Match ends → Post-Match Summary sheet auto-offered to squad
           → sees 38(22), +70 XP ring fills, expense share ₹283 card
Sun 10:31  Taps Pay on the same card → Settle sheet → marks UPI paid → done
Sun 10:33  Auto-drafted performance card → edits caption → posts
Mon 09:00  Weekly digest: rank ↑4, streak week 9, 2 props received
```
Design targets from this journey: **0-screen actions from notifications wherever a decision is binary; ≤2 taps from match end to payment done; ceremony (XP ring) before obligation (payment) but obligation visible in the same viewport.**

## 1.5 Task flows — click budgets (hard UX budgets; QA-audited)
| Task | Entry | Budget (taps) | Path |
|---|---|---|---|
| Respond availability | Push notification | **1** | Inline action |
| Respond availability | In-app | 2 | Home widget chip → confirm haptic (undo snackbar) |
| Start live scoring next assigned match | Launcher shortcut | 2 | Shortcut → Console |
| Record a dot ball / single | Console | **1** | Pad tap |
| Record a wicket | Console | 3 | W → type → new batter |
| Pay my match share | Push | 2 | Pay → confirm method note |
| Create friendly match | + | ≤12 fields, 4 steps | Wizard w/ smart defaults (last format, home ground, auto-poll on) |
| Post match performance card | Summary | 2 | Share → Post |
| Check who owes me | Home | 1 | Expense widget (net line visible with 0 taps) |
| Book a ground slot | Ground profile | 4 | Slot → details → policy ack → confirm |
| Find & follow a player | Search | 3 | Search icon → type/QR → Follow |
| Redeem a voucher | Wallet | 3 | Marketplace → listing → Redeem |
| Open my next match | Anywhere | 2 | Matches tab long-press → pinned next |

**Decision flow pattern:** binary decisions = inline chips; 3–5 options = bottom sheet; >5 or destructive = full sheet with search + typed confirmation for destructive. Alternative paths always converge on the same terminal screen (e.g., all payment entries end on Expense Detail with updated state) so users build one mental model. Back navigation: system back = up one push; in wizards, back = previous step with state preserved; abandoning a wizard with entered data triggers a "Save draft / Discard" dialog (never silent loss). Error recovery: every failed submit keeps user input intact, shows inline cause, and focuses the offending field.

---

# 2. Design System Foundations

## 2.1 Grid, spacing, layout metrics
- **Base unit 8pt; half-step 4pt.** Spacing scale: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48. Usage: 4 = icon↔label, chip internals; 8 = intra-card element gap; 12 = list row internal vertical; 16 = screen side margins, card padding; 20 = card padding (featured cards); 24 = section gaps; 32 = between major sections; 40/48 = hero headers, empty-state breathing room.
- **Grid:** 4-column, 16px margins, 12px gutters (phones). Card widths: full-bleed lists span all 4 cols; carousel cards = 280px (peek 24px of next card — affordance that content continues); half cards = (width−16·2−12)/2.
- **Content max-width** on large screens/tablets: 600px centered for reading surfaces; dashboards go 2-column at ≥720px.
- **Safe areas:** respect device insets; bottom nav height 56px + inset; top app bar 56px (large-title variant 96px collapsing to 56); FAB-in-bar center button 56px diameter, raised 12px above bar.
- **Touch targets:** minimum 44×44px (48×48 for primary); interactive elements ≥8px apart.
- **Thumb map:** primary CTAs anchored bottom (sticky action bar 72px incl. 16px padding); destructive options placed *top* of sheets (out of accidental-thumb zone) with confirmation.
- **Image ratios:** avatar 1:1; cover 3:1; media in feed 4:5 max height; ground gallery 16:9; story 9:16.

## 2.2 Radius, borders, elevation
- Radius tokens: r-xs 6 (chips, tags) · r-sm 10 (buttons, inputs) · r-md 14 (cards) · r-lg 20 (sheets, featured cards) · r-full (avatars, pills, FAB).
- Borders: 1px hairline `border` token for card outlines in light themes; dark themes use surface elevation instead of borders (except money surfaces, which always keep a 1px border — Pillar 4 "banking" cue).
- Elevation (shadow) scale — light themes:
  - e1 card: y2 blur8 @ 6% black
  - e2 raised (FAB, sticky bar): y4 blur16 @ 10%
  - e3 sheet/dialog: y8 blur32 @ 16%
  - Dark themes: shadows replaced by surface lightening (+4%, +8%, +12% luminance) + e2 keeps a soft glow only for FAB.
- Overlay/scrim: black 40% (light), black 60% (dark), always blurred 8px behind sheets on capable devices.

## 2.3 Color system (semantic tokens; theme palettes in §4)
Semantic roles every theme must map: `primary`, `onPrimary`, `secondary`, `accent`, `bg`, `surface`, `surfaceAlt`(container), `textPrimary`, `textSecondary`, `textTertiary`, `border`, `divider`, `success`, `warning`, `error`, `info`, `disabledFg/Bg`, `overlay`, `verified`(engraved teal-slate reserved solely for verified marks), `coin`(metallic amber reserved for currency), `live`(signal red reserved for live indicators). **Reservation rule:** `verified`, `coin`, `live` may not be used decoratively anywhere else — their meaning must stay unambiguous. Charts get an ordered 6-color categorical ramp per theme + a sequential ramp for heatmaps; all ramps pass 3:1 against `bg` and remain distinguishable under deuteranopia (verified via simulation; shapes/labels never rely on color alone).

## 2.4 Typography
**Faces (production-licensed, variable):**
- **Display — Clash Display** (semi-bold/bold): hero numbers, screen large-titles, ceremony text. Characterful geometric; used with restraint (≤2 instances per screen).
- **UI & Body — Inter** (variable): everything else. Tabular lining figures (`tnum`) mandatory for any number that can change or align in columns (scores, money, stats).
- **Scoreboard numerals — Clash Display Bold with tabular spacing**, letter-spaced +1%, used only in Scoreboard/Live components.

| Role | Face/weight | Size/Line | Tracking | Usage |
|---|---|---|---|---|
| Display | Clash 600 | 34/40 | −0.5% | Screen hero ("₹450", "Level 12") |
| H1 large-title | Clash 600 | 28/34 | −0.25% | Collapsing app-bar titles |
| H2 section | Inter 600 | 20/26 | 0 | Card group headers |
| Title | Inter 600 | 17/24 | 0 | Card titles, dialog titles |
| Subtitle | Inter 500 | 15/22 | 0 | Secondary card lines |
| Body | Inter 400 | 15/22 | 0 | Paragraphs, comments |
| Caption | Inter 400 | 13/18 | +0.5% | Timestamps, helper text |
| Label | Inter 500 | 12/16 | +2% UPPERCASE optional | Eyebrows, chips |
| Button | Inter 600 | 15/20 | +0.25% | All buttons, sentence case |
| Stat number | Inter 600 tnum | 22/28 | 0 | Stat cards |
| Money | Inter 600 tnum | 17–28 | 0 | Always with currency symbol at 70% size, top-aligned |
| Scoreboard | Clash 700 tnum | 40/44 | +1% | Live score only |
Minimum body size 13; dynamic type scales all roles up to 135% with layouts reflowing (no truncation of amounts, ever — money wraps before it truncates).

## 2.5 Iconography
- **System:** rounded-outline icon set, 1.75px stroke, 24×24 grid (20 for dense rows, 28 for tab bar), squared terminals softened 2px. Filled variants used *only* for active/selected states (tab bar, toggled reactions) — outline=available, filled=active is a global rule users learn once.
- **Families:** Navigation (home, matches bat-and-ball glyph, plus, people, avatar) · Sports (bat, ball, stumps, gloves, helmet, whistle, scorebook, trophy, pitch) · Status (live dot, verified engraved-check, pending clock, locked, synced/offline cloud) · Rewards (coin — always the metallic amber disc with "C" cutout, XP bolt, chest, spin, scratch) · Expense (receipt, split, settle-handshake, wallet, remind-bell) · Social (heart, clap "props" hands, comment, share arc, bookmark).
- Rules: never mix stroke weights; icons never carry meaning alone (label or accessible name always present); the coin icon is the *only* multicolor icon.

## 2.6 Motion system (tokens; per-pattern specs in §5)
Durations: instant 80ms (state tints) · fast 160ms (chips, toggles) · standard 240ms (push/pop, sheet) · gentle 360ms (card expand) · ceremony 900–1400ms (unlocks). Easing: standard `cubic(0.2,0,0,1)`; decelerate for entrances; accelerate for exits; spring (damping 0.8) reserved for the coin/XP physics. **Reduced-motion setting:** all movement collapses to 120ms opacity fades; ceremonies become static cards with a subtle Arc shimmer; nothing is information-only-in-motion.

---
# 3. Component Library (pixel-level specs)

Global anatomy conventions: sizes in px at 1× (375-wide frame); every component defines the six states **Default / Pressed / Disabled / Loading / Focused / Selected** plus validation where inputs exist. Pressed = scale 0.98 + 8% primary tint overlay, 80ms. Disabled = 38% opacity fg on `disabledBg`, no elevation, no press feedback. Focused (keyboard/switch access) = 2px `primary` ring offset 2px. Loading = content swaps to component-shaped skeleton, width preserved (no layout shift).

## 3.1 Buttons
| Variant | Height | Pad H | Radius | Style | Use |
|---|---|---|---|---|---|
| Primary | 52 | 24 | r-sm | `primary` fill, `onPrimary` text | One per viewport max |
| Secondary | 52 | 24 | r-sm | transparent, 1.5px `primary` border | Paired alternative |
| Tertiary | 44 | 16 | r-sm | text-only `primary` | Inline, low emphasis |
| Destructive | 52 | 24 | r-sm | `error` fill | Always behind confirm |
| Chip-action | 36 | 14 | r-full | `surfaceAlt` fill | Inline decisions (Yes/No) |
| Icon button | 44×44 | — | r-full | outline icon 24 | Toolbars |
| FAB (+) | 56 | — | r-full | `primary`, e2 | Tab-bar center only |
Loading: label fades, 20px Arc spinner centers, width locked. Icon+label buttons: icon 20, gap 8, icon leads. Full-width buttons inset 16 each side inside sticky bars.

## 3.2 Cards (base)
Padding 16 (20 featured), radius r-md, e1, `surface` fill. Header row: leading avatar/icon 40, title Title-style, trailing ⋮ 44-target. Internal vertical rhythm 8; card gap in lists 12. Tap = whole card (unless it contains ≥2 actions, then only header navigates). Long-press = peek + context menu.

### 3.2.1 Player Card (list, 72h)
`[Avatar 48 + level ring 2px] 12 [Name 17/600 + role chips 12] [right: rating 22 tnum + trend arrow 12]`. Second line: team · city, textSecondary 13. Selected state (selection board): 1.5px primary border + check overlay on avatar. Skeleton: circle + two bars (60%/40%).

### 3.2.2 Match Card (upcoming, 132h)
Row1: `[Team A crest 32] vs [Team B crest 32]` centered, format tag chip right. Row2 Display-ish 17/600: "Sun 7:00 AM · Green Park (2.4 km)". Row3: weather glyph + rain% · squad-lock countdown caption. Row4: availability chips [Yes][Maybe][No] 36h — the *only* card with embedded actions (frequency justifies it). Left edge 3px status rail: amber=response needed, green=locked-in, grey=done, red=cancelled. Swipe right = share, left = pin.

### 3.2.3 Live Match Card (104h)
Score line in Scoreboard type 28: "142/3 (14.2)". Chasing strip: "Need 47 off 34" 13/500. Live dot (`live` red, 8px, 1.2s pulse — pulse pauses in reduced motion, dot remains). Key-moment chip animates in from right on wicket ("WICKET · Sharma 34"). Tapping anywhere → Live view; long-press → mute this match.

### 3.2.4 Tournament Card (116h)
Banner strip 3:1 top (radius top only), overlay gradient bottom 40% for legibility. Body: name 17/600 + sanctioned chip (verified color) if applicable; meta row: teams count · dates · entry fee; footer: my-team position pill or "Register by {date}" CTA-tertiary. Registration-closing <48h = warning-tinted footer.

### 3.2.5 Expense Card (Home summary, 96h)
Banking voice: `surface` with mandatory 1px border, no icons except category glyph 20 muted. Line1 Money 22 tnum: "You are owed ₹450" (success-tinted text) or "You owe ₹300" (textPrimary — debt is *not* colored red; red is reserved for overdue). Line2: top counterparty + pending count caption. Actions row: [Settle up · primary-tertiary] [Remind]. Overdue chip: `warning` >3d, `error` >7d, right-aligned, 24h with day count.

### 3.2.6 Expense Row (ledger, 64h)
`[Category glyph 20] [Title 15 + context caption "vs Titans · Sun"] [right: ₹ amount 17 tnum + state dot]`. State dots: hollow=pending, half=partial, solid=settled, slash=disputed. Swipe right = Pay/Settle, left = Remind/Dispute. Amount column right-aligned on a shared axis across all rows (tabular).

### 3.2.7 Reward Card (scratch/spin/chest, 140×140 grid tiles)
r-lg, subtle metallic gradient (theme coin ramp), Arc glint sweep every 6s (off in reduced motion). Unclaimed badge dot top-right. Tap → claim overlay (§5). Stacked count "×3" pill bottom-right.

### 3.2.8 Progress Card (challenge, 112h)
Title + reward chip; Arc progress ring 44 left OR linear bar 6h full-width (ring when single metric, bar when target text matters); "64/100 runs · 9 days left". ≥80% = ring pulses gently once on screen-enter. Failed state: desaturated, copy "Ends {date} — try next month" (never shame).

### 3.2.9 Statistics Card (2-up grid, 96h)
Eyebrow label 12 uppercase, number 22 tnum, delta chip (▲ success / ▼ textTertiary — down is neutral, not red, except money surfaces). Tap → underlying list. Info ⓘ 16 opens definition popover (every derived stat is explainable — trust rule).

## 3.3 Charts (shared rules)
Container r-md, padding 16, title + period segmented control top; axis text 11 textTertiary; gridlines hairline divider at 40%; tooltips = tap-and-hold scrub with haptic tick per datapoint, value bubble follows finger, sticky legend. Every chart offers a "table view" toggle (accessibility + screenshots). Manhattan: bar width = (plot/overs)−2 gap, wicket dots 6 on top; Worm: 2px lines, chasing overlay dashed for required-rate; Wagon wheel: ground-shape aware, 4s in `secondary`, 6s in `accent`, zone-tap filters the ball list below; Radar: max 6 axes, fill 12% opacity.

## 3.4 Timeline (match/audit)
Left rail 2px divider with node dots 10 (event-typed glyphs 16 inside 28 circles for key events); content cards right, 12 gap; sticky date separators. Scrub-bar variant (ball timeline): horizontal strip 48h, balls as 8px ticks colored by outcome, drag = scrub with over/ball readout bubble.

## 3.5 Bottom Sheet
Detents: peek 30% / half 60% / full 92%. Grabber 36×4 r-full centered top 8. Radius top r-lg, e3, scrim+blur. Drag physics with velocity fling; below-peek drag = dismiss (unless containing unsaved input — then bounce + dialog). Title row optional 56h with trailing Close 44. Content scrolls internally only at full detent. Keyboard raises sheet above it.

## 3.6 Search Bar
44h, r-full, `surfaceAlt` fill, leading search icon 20, trailing mic 20 + QR 20 (20 gap). Focus expands to full-width app-bar replacement (240ms), recent list slides up. Voice: press-hold mic = waveform inline, transcript editable before submit.

## 3.7 Dropdown / Select
Field 52h styled as input; opens bottom sheet (never floating menus on mobile) with radio rows 52h, search row if >8 options. Selected row: filled radio + primary text.

## 3.8 Segmented Control
36h, r-full track `surfaceAlt`, animated thumb `surface` e1 slides 160ms; 2–4 segments max; ≥5 options become scrollable chip row instead.

## 3.9 Stepper
For counts (overs, players): 44h, [−][value tnum][+], long-press = auto-repeat accelerating; bounds disable respective button; invalid manual entry snaps back with shake 3px×2.

## 3.10 Calendar
Month grid, day cells 44, event dots ≤3 + "+n"; heat variant (activity) uses 4-step sequential ramp with density legend; range-select (booking) paints connective pill. Today = 1.5px primary ring. Long-press day = peek agenda.

## 3.11 Scoreboard (hero component, Live view header)
Height 128, `surface`, sticky under app bar. Layout: teams row (crest 24 + short name 13) / score line Scoreboard-40 "167/4" + overs "(16.3)" Inter 17 baseline-aligned / context strip 13 (CRR · RRR or lead text). Score digits animate odometer-roll 240ms on change; wicket flashes the score line with a 1-frame `live` underline sweep. TV Scoreboard mode: same component scaled ×3, dark high-contrast, auto-cycling bowler/batter strips every 8s.

## 3.12 Live Match Widget (mini, persists on Home)
Collapsible 72h pill, draggable to dismiss for session; shows score + last-ball chip; tap = Live view. Only one pinned at a time (user's own match outranks followed).

## 3.13 Comment Widget
Composer docked bottom 56h (grows to 3 lines), avatar 28, send icon activates on input. Thread rows: avatar 32, name+time row, body, action row (Props · Reply) 13; replies indent 40 with 2px rail; "View 4 replies" expands inline 240ms.

## 3.14 Reaction Bar
Long-press any post/message → radial-arc picker (6 reactions on the Arc, 48 targets) above thumb; quick-tap = default Props clap. Chosen reaction particles once (8 particles, 600ms). Counts pill under content; tap = breakdown sheet.

## 3.15 Coin Widget & 3.16 XP Widget
Coin chip (app bar): 32h pill, coin icon 18 + balance tnum; on earn, +N floats up 12px fading 600ms while balance odometer-rolls; tap = Wallet; long-press = last-5 popover. XP: Level ring on avatars (2px, Arc gap); gains render as ring-fill sweep + "+50 XP" toast-chip bottom-center 2s; level-up triggers ceremony (§5.8).

## 3.17 Badge Widget
Hex-soft tile 88 (grid) / 56 (strip); earned = full color + engraved inner stroke; locked = 12% silhouette + criteria on tap; tier ribbon bottom. Detail sheet: 160 art, name Clash 20, criteria, rarity %, "friends who hold this" avatars, earn-date + provenance link, Share.

## 3.18 Leaderboard Row (56h)
`[Rank 24 tnum] [Avatar 32] [Name + team caption] [right: metric tnum]`. My row: `surfaceAlt` fill + 2px primary left rail, sticky-clones to bottom when off-screen. Top-3: rank numerals in `coin` metallic with laurel micro-arc; movement chevrons ▲2/▼1 caption. Ties share rank number.

## 3.19 Forms (global)
Field 52h, r-sm, 1px border → primary 1.5px on focus; floating label 13→11 rise 160ms; helper/error text 13 below (error `error` + icon 14, field shakes 3px×2 once, error announced to screen reader). Inline validation on blur; submit disabled until required valid; multi-step forms show Arc-segmented progress (not dots) with step labels. Currency fields: right-aligned tnum, symbol fixed, auto-thousand separators.

## 3.20 Snackbar
Bottom, above nav 8, 48h, r-sm, dark surface, single action max ("UNDO"), 5s (persist while touched); queue max 1 (new replaces old); never used for errors requiring decisions (those get dialogs).

## 3.21 Dialogs
Max width 320, r-lg, e3, centered; title 17/600, body 15, actions right-aligned (Tertiary + Primary), destructive dialogs put the safe action as Primary and require typed confirmation for irreversibles. One dialog at a time, ever.

## 3.22 Empty / Loading / Error scaffolds (reused everywhere)
Empty: Arc-line illustration 120, one-sentence invitation, one Primary CTA (+ optional Tertiary), top-aligned at 25% viewport (thumb reach for CTA). Loading: skeletons mirror the real layout exactly (list = 6 rows, card = card shape); shimmer 1.2s L→R; never spinners for full screens (spinner only inside buttons/inline refresh). Error: cause in plain words + [Retry] + "Report a problem" tertiary; input preserved; offline variant swaps icon to cloud-off and adds freshness stamp "Showing data from 2h ago".

## 3.23 Avatars & status
Sizes 24/32/40/48/64/96; fallback = initials on deterministic theme-ramp color; level ring ≥40 only; presence dot 10 bottom-right (online success / away warning) per privacy; verified check overlays 16 at −45° only on 48+.

---

# 4. Color Themes (five; all map §2.3 tokens, all AA-verified)

**1 · Modern Cricket Green (default light).** Primary #0E7A4A · Secondary #123B2A · Accent #F2B824 · BG #F7F8F7 · Surface #FFFFFF · Cards white e1 · Buttons primary-fill white text · Icons #3C4A44 · Text #101613/#5A665F · Charts ramp green→amber→slate · Badges engraved forest · Gradient (ceremony only) #0E7A4A→#15A05F · Mood: fresh turf, honest, energetic. For: default brand, daytime outdoor use.
**2 · Royal Navy Gold.** Primary #14213D · Accent #D4A017 · BG #F4F5F8 · Surface #FFFFFF · Buttons navy/gold-outline pair · Numbers navy, gold reserved for ranks/awards · Mood: club blazer, prestige. For: clubs, tournaments, award ceremonies.
**3 · Electric Blue.** Primary #1257E0 · Accent #37D2C4 · BG #F5F8FF · Surface white · Charts blue→teal→violet · Mood: fast, broadcast, stat-forward. For: analytics lovers, live viewing.
**4 · Dark Graphite Neon (default dark).** BG #0E1113 · Surface #171B1E (+lum elevation) · Primary #3DDC84 (neon leaf) · Accent #F2B824 · Text #F2F4F3/#9AA5A0 · Borders replaced by elevation, money keeps #2A3237 border · Glow only on FAB/live · Mood: night matches, CRED-like ceremony. For: dark mode, streaming.
**5 · Premium White Emerald.** BG #FCFCFC · Surface #FFFFFF hairline-bordered (no shadows — Linear-flat) · Primary #0C8F5B · Accent #101613 (ink) · Typography-led, dividers do the structure · Mood: minimal, editorial, executive. For: organizers, sponsors, reports.
Rules: themes change tokens only, never layout; `live` red and `coin` amber stay constant across all themes (recognition constancy); user-selectable in Appearance with live preview card; system light/dark maps to Themes 1↔4 unless overridden.

---

# 5. Motion Design (pattern specs)

1. **Page push/pop:** 240ms parallax (incoming slides 100%→0 over outgoing −24px, scrim 8%); pop mirrors; tab switch = 160ms crossfade + 8px rise (no lateral motion between peers).
2. **Card expansion (match card → detail):** shared-element: card lifts e1→e3, corners r-md→0, crest/scores morph into header positions, 360ms gentle; back reverses.
3. **Bottom sheet:** spring-in from bottom 240ms, scrim fade parallel; detent snaps with soft haptic.
4. **Loading:** skeleton shimmer 1.2s; Arc spinner (sweep 270°, rotate 900ms) only inline.
5. **Pull-refresh:** Arc draws 0→270° with pull distance, releases into spin, resolves with a tick morph + light haptic.
6. **Props/like:** clap icon fills + 8 arc-particles 600ms + count odometer; double-tap on media = center clap bloom 400ms.
7. **Coin earn:** coins (2–5 sprites) arc-toss from source into app-bar chip with spring physics, chip bounces 1.05, balance rolls; total ≤900ms; sound optional (off default).
8. **Achievement/level ceremony:** full overlay — dim 60%, badge scales 0.6→1 spring, Arc rays sweep, name letters cascade 20ms/char, [Share] [Done]; 1.4s to interactive; skippable by tap; queues if multiple (never stacks); suppressed during Live Scoring & money confirmations, delivered after.
9. **XP gain:** ring fills clockwise from Arc-gap 400ms + toast-chip.
10. **Success (settlement):** handshake icon draws-on 500ms + both parties' rows resolve to solid dots simultaneously; calm, no confetti (Pillar 4).
11. **Error:** field shake 3px×2 120ms + border to `error`; global errors slide-down banner 240ms.
12. **Swipe rows:** action underlay reveals with icon scaling 0.8→1 at 40% threshold; haptic at commit point; snap-back 160ms.
13. **Live update:** score odometer 240ms; wicket = scoreboard underline sweep + key-moment chip springs in; boundary = brief 4/6 numeral pop 1.1×.
14. **Scroll:** app-bar large-title collapses 96→56 linked to offset; sticky elements dock with hairline shadow fade-in.
15. **Gesture feedback:** every commit action = light haptic; destructive = double-tick haptic; selection = single tick.

---
# 6. Canonical Screen Template & State Contract

Every screen in §7 inherits this contract (deviations are called out per screen):
- **Layout skeleton:** [Status/app bar 56–96] → [optional sticky context strip] → [scroll region, sections separated 24] → [optional sticky action bar 72] → [bottom nav 56 on tab roots].
- **Hierarchy order:** Answer (what user came for) → Status (state/urgency) → Actions → Context → Related. First screenful must complete the primary user goal or show the path to it.
- **States:** Default · Empty (§3.22) · Loading (mirrored skeleton) · Error (retry + preserved input) · Offline (cached + freshness stamp; queue-safe actions show pending pill; money actions disabled with reason) · Permission-denied (explains why + who can + request path) · Success (inline confirmation + next-step suggestion).
- **Accessibility:** logical focus order top→bottom; headings marked; live regions announce score/coin changes politely; all charts have table toggles; targets ≥44; contrast AA; content usable at 135% type.
- **Responsive:** ≤340w drops secondary columns; ≥720w dashboards 2-col, master-detail for list→detail pairs; landscape live-view = scoreboard left / commentary right.

# 7. Screen-by-Screen Specifications (all modules)

Format per screen — **N. Screen (User · Permission)** Objective | Layout & wireframe | Components & placement | Interactions & navigation | States/edge notes. Wireframe notation: rows top→bottom, `[ ]` components, `{ }` sticky.

## 7.1 Dashboard module
**1. Home (all · own data)** Objective: answer "what needs me + how am I doing" in one glance. Layout: {app bar: avatar 32 · greeting/context title · search · bell · coin chip} → quick-chips row (max 3 urgent) → widget stack per PRD §4 ordering (urgency > pinned > recency) → "More for you" footer. Wireframe: `[chips][Upcoming Match card][Pending Payments][Recent Performance][Coin/Missions 2-up][Suggestions carousel]…`. Interactions: long-press widget = Edit-Home reorder mode (cards lift e2, drag with haptics); pull-refresh Arc; widget ⋮ = hide/pin. Edge: new user shows Onboarding-Checklist widget replacing stack until 2 items done; >6 unread urgent chips collapse into "5 actions" pill → sheet.
**2. Notification Center (all)** Two tabs For You/Following; group headers by entity; rows 72 with inline decision chips; swipe right done, left snooze sheet (1h/tonight/tmrw); overflow ⋮ = mute ladder. Empty: "All caught up" Arc-tick. Priority-pinned cards carry colored left rail.
**3. Edit Home (all)** Full-screen reorder list, pin toggles (max 3), hidden section below divider; Save sticky. Reset-to-default tertiary.

## 7.2 Player module
**4. My Profile / 5. Public Profile (viewer-relative)** Objective: identity + verified career at a glance. Layout: cover 3:1 with Arc-mask bottom → avatar 96 overlapping −48 + level ring → name Clash 24 + verified/role chips → action row (self: Edit·Share·QR / other: Follow[primary]·Message·⋮) → badge strip (3 pinned) → stat header strip {sticky on scroll: M·Runs·Wkts·Rating tnum} → tabs [Overview·Stats·Media·Timeline]. Overview: Recent-form string, favorites shelves, endorsement chips. Stats tab: format segmented → stat cards grid → charts (form curve, wagon aggregate, SR/Avg scatter) each with ⓘ and table toggle; Verified/Unverified toggle (unverified section visibly lighter + dashed border — Pillar 2). Privacy-limited view: minimal card + lock explainer + Request Follow. Edge: minor profile forces private layout, no message button for non-teammates.
**6. Edit Profile** Grouped form sections; sticky Save appears only on dirty state; name-change shows "2/yr" helper; leaving dirty → Save/Discard dialog.
**7. Achievements Wall** Filter chips by category; grid 3-col badge tiles; locked silhouettes interleaved (motivation); tap → Badge sheet (§3.17). Empty: nearest-3 achievable badges with progress.
**8. Activity Calendar** Heat grid + month pager; day tap → agenda peek sheet; legend footer.
**9. Year in Review (overlay)** Story-format 9:16 cards, tap-advance, per-card exclude toggle before Share; music toggle; exits X top-right.

## 7.3 Team module
**10. My Teams** Cards 96 with role chip + next-event caption; long-press = default/mute/leave; [Create team] empty-CTA.
**11. Team Home (viewer-relative)** Cover+crest header → follower/member counts → tabs [Feed·Matches·Members·Stats·Media·Money*·Manage*] (*role-gated, gated tabs hidden not disabled for outsiders). Announcement pinned card top of Feed with "Seen 11/15" for author.
**12. Members & Roles (captain+)** Roster rows with role chips; ⋮ per row (change role/remove w/ reason dialog); header [Invite] → sheet (QR big, link, search); Permission-Matrix link opens read-only table screen.
**13. Availability Matrix (captain/VC)** Sticky first column names, columns=events, cells 44 tri-state glyphs; tap cell = detail popover; header per column [Nudge pending] (disabled if <12h since last, tooltip why); footer summary "9 ✔ · 3 ❓ · 2 ✖". Landscape optimized.
**14. Selection Board (captain/VC)** Two panes: Available pool (top, chips-grid of Player Cards mini) / XI list (bottom, drag-target slots 56 numbered 1–11 +12th); drag with lift+haptic; role-balance meter strip (WK/bowler counts) warns amber; {Publish lineup} sticky primary; post-lock entry switches to Replacement flow banner.
**15. Practice Session detail** Hero: template name + focus tags; drill list rows (name·prescription·XP chip); RSVP chips; on-site window shows [Check-in QR] primary; roll-call mode (coach): roster toggles.
**16. Treasury (all-see)** Net wallet Display header → Collections progress cards (paid-grid avatars) → ledger list (Expense Rows) → {Add expense} sticky for Manager/Captain. Dual-approval pending items carry "Awaiting {name}" chip.
**17. Jersey Board / 18. Carpool / 19. Duty Roster / 20. Documents / 21. Kit Inventory** — pattern screens: list + claim/submit sheets; Carpool cards show seats pips (● ● ○), Join → confirm; Duty slots show claimant avatar or [Claim]; Kit rows show custody avatar + [Hand over] flow (both confirm).
**22. Season Summary / Awards Ceremony mode** Wrap cards vertical; [Present] switches to full-screen sequential reveal (tap-advance, Clash display, Theme-2 styling), money slide auto-excluded from public share.

## 7.4 Match module
**23. My Matches** Segmented Upcoming/Live/Recent; cards per §3.2.2–3; empty per tab ("Find a game" links Discover).
**24. Create Match (wizard 4 steps)** Steps: Basics(format presets grid, smart defaults) → Opponent(search/QR/recent) → Ground&Time(picker w/ availability) → Review(expense-preset toggle, visibility, availability-deadline). Arc-progress header; per-step primary "Continue"; Review shows editable summary rows; Send → opponent-pending state screen with share nudge.
**25. Match Detail (pre-live)** Header mini-scoreboard placeholder (crests/date) → info rows (ground w/ map snippet, officials, ball) → availability panel (mine prominent; squad grid for captain) → expense preview card → {Directions}+{RSVP} sticky pair. Cancelled: struck header + reason banner + re-RSVP if rescheduled.
**26. Toss (captains)** Full-screen coin 160 with 3D flip 1.2s on [Flip] (either captain), result Clash 28, [Record manual] tertiary; result broadcast toast.
**27. Live Scoring Console (scorer)** {Scoreboard 128 pinned} → current-over beads strip 32 → batter/bowler stat strips → **pad zone bottom 45%**: run grid (0·1·2·3·4·6 big 64 targets), extras row, [WICKET] full-width `error`-outline 52, [Undo] left 44, [⋯ interrupt] right. Wicket → sheet (type grid → fielder → new batter list). End-over auto-sheet: next bowler (legal list only, overs-left captions). Offline: amber "Saving locally" chip under scoreboard. All targets bottom-weighted for thumbs; landscape = pad right, card left.
**28. Live Match View (spectator)** {Scoreboard} → tabs Commentary(default)/Scorecard/Charts/Gallery; commentary auto-scroll with "Jump to live" pill when scrolled up; fan prediction chip after over 2; reaction bar floats on key-moment cards. Delayed-data stamp when scorer offline.
**29. Scorecard (final)** Innings accordions (batting table: dismissal text 13 wraps, tnum columns aligned) → FoW ladder → confirmation panel (3 avatar-checks: captains+scorer; mine = [Confirm][Dispute]); ✔ engraved stamp animates once on full confirmation.
**30. Post-Match Summary** Result hero (winner crest + margin Clash 22) → MVP card → my performance card [Share] → XP/coins earned strip → expense card "₹283 · [Pay]" → rate-players entry (window countdown) → insights teaser → timeline link. Order enforces Pillar: ceremony visible, obligation adjacent.
**31. Match Expense Sheet / 32. Insights / 33. Gallery & Highlights** per patterns; Highlights builder: clip rail, drag-reorder, [Publish reel] primary; auto-cut chips labeled by moment.

## 7.5 Tournament module
**34. Discover Tournaments** Filter chips + cards; map toggle. **35. Tournament Home** Banner → sanctioned chip → follow → tabs Fixtures/Table/Stats/Media/Info; Fixtures list groups by date, my-team filter chip; **36. Points Table**: sticky team column, tnum grid, NRR tap → explainer sheet with [What-if calculator] → sliders screen (result cards savable); adjusted rows flagged ⓘ. **37. Bracket** horizontal-scroll rounds, connectors 2px, tap slot → match; my-team path highlighted. **38. Registration flow** squad multi-select (eligibility flags inline) → fee summary (escrow/refund policy expandable) → forms/waivers checklist → pay-context confirm → success with fixture-alert opt-in. **39. Organizer Console** dashboard tiles (registrations, disputes, payouts) → queues; fixture editor: drag matches between slots, conflict warnings inline; wallet ledger banking-style. **40. Auction Room** lot card center (player card XL + base price), purse rail top (all teams tnum), bid buttons increments bottom 64 targets, timer ring Arc 12s; spectator layout hides bid controls; reconnect banner preserves lot state.

## 7.6 Ground / Academy / Club
**41. Ground Discovery** map 55% + card carousel bottom; list toggle; filter sheet (price slider, facilities checklist, date-availability). **42. Ground Profile** gallery pager 16:9 → name+verified → rating facets bars → facilities chip grid → pricing table → availability calendar (range-pick) → records shelf → reviews; {Book} sticky primary. **43. Booking flow** slot → purpose/party → quote breakdown (deposit, policy ack checkbox) → confirm → ticket card (QR big, add-to-calendar). Held-slot 15:00 countdown chip. **44. Ground Console** occupancy chart, calendar admin (block-slot paint), price editor, staff list, review-reply inbox. **45. Academy Console / 46. Coach Console** batch cards → student roster (progress rings 44 per student) → session planner (template picker grid from Drill Library, drill cards showing prescription) → progress-card composer (approve → send). Guardian view mirrors student scope read-only. **47. Club Home/Console** per pattern: dashboard tiles, member dues grid (green/amber/red dots), Wall of Fame carousel.

## 7.7 Expense & Wallet module (banking voice throughout)
**48. Expenses Home** Net header Display ("You're owed ₹450") → tabs I-owe/Owed/All → rows §3.2.6 → {Add} FAB-less: sticky [Add expense]. All-square state: calm tick illustration. **49. Add/Edit Expense** category grid (glyphs) first (drives smart form) → amount pad-first field (auto-focus, tnum XL) → paid-by selector → split editor: method segmented (Equal/Custom/Shares/%/Items/Attendance) with per-person rows and live remainder line ("₹0.04 → payer") → proof attach (camera-first, +5 coin chip) → context link → [Save]/(Approval note if >threshold). Validation: totals must equal — mismatch shows exact delta in error. **50. Expense Detail** amount hero → per-person state list → proof gallery → comments thread → activity log accordion → actions [Pay/Remind/Dispute]. Frozen-in-dispute banner. **51. Settle Up** counterpart picker (pre-filled from entry) → simplify suggestion card ("3 payments instead of 7" [Use]) → amount (full/partial chips) → method note → confirm → success handshake (§5.10) → both ledgers update. **52. Reports** period segmented → donut by category → trendline → insight cards → [Export statement]. **53. Wallet & Coins** balance hero + expiring strip warning → earn/redeem 2-up → history list (source glyphs) → Marketplace grid → Listing (terms accordion, [Redeem] with level-lock state) → My Rewards (voucher cards, copy-code, redeem-by countdown).

## 7.8 Rewards & Gamification screens
**54. Missions Board** Daily 3 cards (claim states), weekly/monthly tabs, Season Planner link; refresh-token chip. **55. Season Planner** year scroller of monthly themes (locked future months show theme + criteria). **56. Claim overlays** scratch (finger-scratch mask reveal), spin (wheel physics, odds link visible), chest (tap-burst) — all skippable, results also listed in history (no FOMO loss).

## 7.9 Social module
**57. Feed** cards: author row → attached-object rich card (match/performance verified chip) → media → reaction bar → top comment; "Latest" toggle in header; caught-up interstitial with Arc. **58. Composer** full sheet: text area top, attach rail (media/object/poll/feeling), audience selector row (persistent visible — privacy always one glance away), [Post] disabled-until-content. **59. Post Detail/Comments** per §3.13. **60. Stories/Reels** standard viewers; score-sticker live-updating outlined `live`. **61. Groups/Events** pattern screens. **62. Messenger** thread list (swipe read/mute), thread: bubbles r-lg (own primary-tinted), object-cards interactive (expense card shows live paid state), voice-note hold-to-record with slide-cancel affordance, request inbox banner.

## 7.10 Leaderboards, Followers, Search, Settings, Analytics, Admin
**63. Leaderboards Hub** scope segmented + metric dropdown + window chips; my-row sticky bottom clone; unranked → qualification progress card. **64. Followers/Following** lists with mutual chips; restrict/remove via ⋮. **65. Global Search** §3.6 behavior; grouped results with "See all"; zero-state Recent/Trending; **66. Advanced Filters** per-type sheets. **67. Settings hub** grouped rows; **Appearance**: theme cards live-preview (mini Home render per theme), text-size slider with live sample, reduced-motion toggle; **Privacy** per PRD §17 with per-surface audience rows + [Preview as…]. **68. Analytics screens** stat-card grids + chart stacks per PRD §19; every screen ends with Insights/Recommendations cards; Custom Stats Explorer: query-builder rows (discipline → filter chips → qualification stepper) → results table (sortable, sticky header) → [Save query][Pin as widget]. **69. Admin/Moderation** queue rows with evidence preview, action sheet (reason codes mandatory), audit log; SLA countdown chips; intentionally utilitarian styling (Theme-5 forced).

---

# 8. Accessibility Guidelines (full)
Contrast AA minimum (AAA for body on money surfaces); color-blind-safe chart shapes/patterns; dynamic type to 135% with reflow; screen-reader: meaningful labels ("Pay ₹283 to Arjun for ground fee"), grouped stat announcements, live-score polite announcements with user rate-limit setting; focus visible everywhere; hit targets ≥44; haptics never sole feedback (paired visual); reduced-motion full parity; captions on app videos; voice-search vernacular; left/right-hand reachability equal (no edge-anchored critical gestures); cognitive: one primary action per viewport, plain-language errors, no timed decisions except live scoring (which has undo).

# 9. Checklists

**Production Design Checklist (per screen before handoff):** all 7 states designed · click budget met · thumb-zone primary CTA · skeleton mirrors layout · dark + light + Theme-5 verified · 320w and 135% type verified · haptic/motion spec noted · analytics events named · copy in product voice (verbs, sentence case) · deep-link target defined.
**UI Consistency Checklist:** tokens only (no raw hex) · spacing on 4/8 scale · radius tokens only · icon stroke uniform · tnum on all mutable numbers · reserved colors (live/coin/verified) unabused · one Primary button per viewport · sheet vs dialog per decision-pattern rule.
**Design QA Checklist (build review):** odometer numerals aligned · skeleton no layout-shift · sticky bars respect insets · undo present on destructive swipes · offline stamps render · ceremony suppression during money/live honored · focus order tested · screen-reader pass on 5 core flows.
**UX Audit Checklist (quarterly):** task-budget regression audit · Nielsen heuristics pass (visibility of status, match to real world, control/undo, consistency, error prevention, recognition>recall, flexibility, minimalism, error recovery, help) · Fitts (target sizes vs frequency) · Hick (choices per decision ≤5 visible) · drop-off review on wizards · empty-state conversion review.

# 10. Scalability & Reusable Component Rules
New features must compose from §3 components before proposing new ones; a new component requires: 3+ distinct usages, token-only styling, all six states, RTL mirror spec, and deprecation note for anything it replaces. Variant explosion guard: max 4 variants/component; beyond that = new component with new name. Theme additions must map every semantic token and pass the contrast matrix. Module growth: new modules enter via drawer consoles first; promotion to a Home widget requires usage data; promotion to tab bar requires replacing, never adding (5-tab cap is permanent). Iconography additions follow the 24-grid/1.75-stroke recipe with paired outline+filled. Motion additions must pick existing duration/easing tokens. Copy additions follow the voice rules (§ frontline: verbs, specificity, same action-name across flow).

# 11. PRD Traceability Audit & Addendum (Design Spec v1.1)

A line-by-line re-check of this spec against PRD v1.3 found the gaps below. This section closes them: first the traceability matrix, then full specs for every missing screen/component. The §1.1 sitemap is amended accordingly (additions marked ⊕ join the stacks noted per item).

## 11.1 Traceability matrix (PRD → design coverage)

| PRD area | Was covered by | Gaps → closed in |
|---|---|---|
| §2 Guest | — | 11.2 |
| §20-A Onboarding set | — | 11.3 |
| §2.6–2.7, G.2 Officials (Scorer/Umpire/Commentator), Gig Board, earnings, conduct reports | drawer mention only | 11.4 |
| §5.15 Trust & Sportsmanship display | — | 11.5 |
| §6.25–6.28 Recruitment, peer ratings, chemistry | — | 11.6 |
| §7.9/7.12 Wagon input, field map; scorer handover | partial | 11.7 |
| §8.9, G.8, §12.4 Streaming & Go-Live | — | 11.8 |
| §2.15, §6.13, §8.8 Sponsor console & sponsored surfaces | — | 11.9 |
| G.9 Associations | — | 11.10 |
| G.5 Knowledge Hub (quizzes/certifications) | — | 11.11 |
| G.6 Content Discover lane · G.7 Gear marketplace | — | 11.12 |
| G.12 Recurring expenses, scan-to-itemize, Recently Deleted | partial | 11.13 |
| §13.4/13.6/13.1 Lucky draw, Pro & Family, Referral | partial | 11.14 |
| §14 Compare tool, ground heatmap, Records Hub, G.11 Goals | partial | 11.15 |
| G.13 Medical card, injury log · §17 Verification, Guardian view, Report flow | listed only | 11.16 |
| §10.3/10.6 Review composer, caretaker check-in | — | 11.17 |
| §18 Titles equip · G.14 Sandbox tutorial | — | 11.18 |
| Everything else (Home, Teams, Match, Tournament, Ground core, Club, Expense core, Wallet, Rewards core, Social, Leaderboards, Search, Settings, Analytics, Admin, states, a11y) | §§1–10 | ✅ no gap |

## 11.2 Guest mode (⊕ overlays on public screens)
Objective: convert shared-link viewers without blocking value. All public screens render fully; every interactive control a Guest taps triggers the **Register sheet** (half detent): value line specific to the blocked action ("Create a free profile to follow Rohan"), [Continue with phone] primary, [Not now] tertiary; sheet remembers dismissals (max 1 auto-prompt per session; taps always allowed to re-trigger). Persistent Guest chip in app bar ("Viewing as guest · Sign up") 32h. Private-object link → lock scaffold with "Request access" (forces registration first). No coin chip, no bell for guests.

## 11.3 Onboarding set (⊕ pre-tab stack)
**Welcome:** 3-slide value pager (verified career · money made simple · rewards), Arc page dots, [Get started] sticky + [Explore first] tertiary → Guest. **Registration:** single-field-per-screen rhythm (phone → OTP 6-cell auto-advance boxes 48, resend countdown 30s, 3 attempts → cooldown state with support link → name). **Guardian gate (minors, blocking):** DOB step detects minor → explains guardian requirement plainly → guardian contact capture → "waiting" state screen with resend; app unusable past this point until consent (business rule §17). **Profile wizard:** photo (camera/library/skip) → city (auto-suggest) → playing info chips; completeness meter fills live; every skip allowed. **Permissions primer:** one card per permission (location/notifications) with concrete benefit copy and [Allow]/[Later]; denial writes the §6 fallback states. **Interest warm-up:** follow-suggestion cards (no role question — PRD rule); [Done] lands on Home with Onboarding-Checklist widget active.

## 11.4 Officials suite (⊕ drawer: Scorer/Umpire/Commentator consoles)
**Gig Board:** filter chips (distance slider, fee min, date); gig cards 116: match line, teams' Trust bands, fee tnum 17, distance, [Accept]/[Details]; accepting → assignment confirmation with calendar add. Empty: radius-widen suggestion. **Officials Console:** next-assignment hero card → calendar strip → tabs Assignments/Earnings/Ratings. Earnings: banking voice, monthly bars + ledger rows (fee · match · status paid/pending), [Request payment reminder] on pending >7d. Ratings: average hero + facet bars + recent review rows; dispute-appeal row state. Credential tier card: Arc progress to next tier ("34/50 matches to Silver") + certification requirement chip linking 11.11. **Conduct report (umpire, from match ⋮):** stepped sheet — incident type grid → involved player picker (match roster only) → description (min 30 chars) → severity → submit; confirmation states it goes to organizer review; relationship auto-disclosure chip if applicable. **Commentator room:** stream-audio status tile, [Mark moment] oversized 64 primary (feeds highlights), marker history list, mute-self toggle; assigned-only access, denied state explains assigner path.

## 11.5 Trust & Sportsmanship components (add to §3)
**Band chip:** 24h pill, band name + micro-glyph (shield=Trust, handshake=Sportsmanship); colors: neutral slate ramps only (never success/error — bands aren't judgments of the viewer's worth); "Under review" = warning-outline. Placement: join-request cards, gig cards, registration review (captain/organizer views). **Self breakdown screen** (from Profile → band tap): factor rows with personal trend sparklines + "how to improve" plain-language rows; 90-day decay-forgiveness explainer; appeal link where applicable. Never visible on public profile beyond band (PRD rule).

## 11.6 Team additions
**Recruitment Board (⊕ Team stack + Discover):** post composer (role-needed chips, day/time, area) → listing cards; applicant pipeline screen: kanban-lite horizontal stages (Applied→Trial→Offered→Joined), applicant cards drag between stages with status-notification confirm. **Peer-rating sheet (post-match, window countdown):** teammate rows with 5-star tap targets 44 + optional tag chips; anonymity note pinned top; submit-all sticky; aggregate-view (rated player) shows stars + tags only after ≥3 raters — pre-threshold state: "Ratings unlock after 3 teammates rate". **Chemistry card (captain, Team Stats):** composite ring + 4 factor bars + 12-week trendline; insight row ("4 unsettled expenses >2w — main drag"); team-private lock icon in header.

## 11.7 Scoring enrichments
**Wagon direction input:** after any scoring shot, optional ghost overlay of ground sectors fades in for 1.5s at pad top — tap sector to log, ignore to skip (never blocks next ball); completeness % lives in Charts tab. **Field map tool (captain, from Match ⋮):** drag 11 fielder tokens 32 on oval; phase presets save slots; team-private badge. **Scorer handover:** Console ⋮ → Handover → picker (present members) → both-captains approve sheet (their devices get approve push) → console transfers with toast; audit line in match timeline.

## 11.8 Streaming & Go-Live (⊕ Match/Tournament stacks)
**Go-Live flow (squad/organizer):** entry from Match Detail [Go live]; pre-flight checklist card (orientation, stability, score-sync ✓) → overlay theme picker (3 thumbnails) → sponsor-slot confirm (if contracted) → countdown 3-2-1 → live HUD: viewer count, health dot, [Mark moment], [End]. **Production kit screen (organizer):** overlay theme gallery, lower-third editor (text fields with live preview strip), destination checklist, commentator-assign row. **Viewer:** Live view gains Watch tab with player 16:9, live chat (slow-mode chip when set), pinned comment slot; VOD chaptered scrubber (innings/wicket chapter ticks).

## 11.9 Sponsor surfaces
**Sponsor Console (⊕ drawer):** marketplace list (teams/tournaments/grounds seeking, audience stat chips) → entity detail → [Make offer] form (asset segmented: Jersey/Banner/Trophy/Stream · amount · duration) → offer states (sent/countered/accepted). **Campaign dashboard:** impressions & engagement stat cards per asset, date filter; export card. **Sponsored rendering rules (global):** sponsor logo slots are fixed-size reserved zones (team header 88×28, match card footer 72×20, stream lower-third), always with "Sponsored" microlabel 10, never animated, never in feed posts (PRD rule).

## 11.10 Associations (⊕ Discover + drawer for admins)
**Association profile:** crest header + verified-body chip → member clubs grid → sanctioned tournaments list (sanction chip explains on tap) → official rankings tabs → circulars feed. **Sanction request (organizer side):** from Tournament Console — request card → status tracker (Requested/Review/Granted with public-reason on revoke). Rankings pages reuse Leaderboard components with association scope.

## 11.11 Knowledge Hub (⊕ Discover)
**Hub home:** Daily-trivia card (3-question inline flow, per-question 20s soft timer ring, streak chip) → quiz-pack shelf → certification tracks. **Certification exam:** syllabus screen (version chip, pass mark, attempts left) → exam mode: distraction-reduced layout (no nav bar), question counter Arc, flag-for-review, submit-confirm dialog → result screen: pass = certificate ceremony (restrained Theme-2 styling) + profile card mint; fail = section-wise feedback + next-attempt date. Certificates render on Officials Console and profile credentials row.

## 11.12 Discover lane & Gear marketplace (⊕ Community top segmented: Feed | Discover)
**Discover:** editorial cards (tip/rules/news templates), tip cards carry [Add drill] chip deep-linking Drill Library; strictly separate scroll from Feed (PRD rule), sponsored-education label style per 11.9. **Gear exchange:** listing grid 2-up (photo 1:1, price tnum, condition chip); listing detail: gallery, condition facets, seller card with Trusted-Seller badge + Trust band, [Chat with seller] (opens Messenger thread templated with listing card); mark-sold two-party confirm → mutual review prompt; safety-tips banner on first chat; minor accounts see guardian-routed state. **Shops directory:** verified shop profiles reusing Ground-profile pattern (catalog strip instead of calendar).

## 11.13 Expense engine additions
**Recurring expense:** in Add-Expense, cadence row (Off/Weekly/Monthly/Season) → series summary line ("Creates on the 1st, 3 days notice"); series objects show ⟳ glyph on rows; editing asks "This one / All future" sheet; end-date picker; upcoming-instances preview list. **Scan-to-itemize:** proof camera → detected line-items sheet as editable rows (name+amount) with per-row assignee avatars multi-select; confidence-low rows flagged for manual check; [Looks right] confirms — every line user-confirmed before save. **Recently Deleted (⊕ Expenses ⋮):** 30-day list, rows show deleted-by + countdown, [Restore] per row; restore re-notifies participants.

## 11.14 Rewards additions
**Lucky draw:** monthly card in Wallet — tickets earned tnum, prize gallery, entry-count disclosure line, past winners list; draw-day result state. **Pro & Family:** paywall screen (feature table honest: integrity note "Pro never affects rankings" prominent), plan cards, Family = manage-members screen (4 slots, invite by QR/link, guardian bundles); manage/cancel states plain. **Referral:** hero code card (copy/share big targets), progress list of referees with state chips (Joined → First verified match ✓ = both reward rows), terms accordion.

## 11.15 Recognition additions
**Compare tool (⊕ from any profile ⋮ "Compare with me"):** side-by-side columns (avatars top), radar center, stat rows with per-row winner-tint (subtle, never red), format/window filters; blocked states: other's comparison off / private → explainer. **Grounds heatmap:** map with visited-ground pins sized by matches, my-city aggregate toggle; pin tap → my record at that ground card. **Records Hub (⊕ Discover):** scope tabs (Global/City/Ground/Tournament), category list matching PRD Appendix F groups, record rows (holder card + value tnum + provenance link), vacant "Be the first" cards, "Closest to me" personalized shelf with delta chips. **Goals:** Goals screen (Profile): goal cards with pace ring + on/off-track chip; create-goal sheet (metric picker → target stepper → period); coach-proposed goals arrive as accept/decline cards.

## 11.16 Safety & identity flows
**Medical & emergency card:** Profile → private section; form (blood group select, allergies tags, conditions, emergency contact); consent screen states exactly who sees it and when (event-window reveal), toggle per team; captain's event-day view: roster ⋮ → Medical (only within window, view-only, watermarked "visible during event"). **Injury log:** add-injury sheet (type, date, notes private) → auto-Injured availability + streak-shield note; return-to-play checklist screen (self-check rows → confirm) reactivates availability. **Verification request (blue tick / listing green tick):** guided doc-upload steps, status tracker, decision states with reason + reapply date. **Guardian view (⊕ guardian's drawer):** child cards → per-child dashboard (followers/messages surface read-only, coach notes, session completion, consents pending queue with approve sheets). **Report flow (global modal):** reason tree (2 levels max), optional evidence attach, anonymity note, submit → tracker in Settings ("Reviewed — action taken" states); duplicate-report merge notice inline.

## 11.17 Ground module additions
**Review composer (verified bookers only, post-booking prompt):** overall stars XL 44 targets → facet star rows (pitch/facilities/staff/value) → photos → text; publish → owner-notified. Non-eligible visitors see "Reviews come from teams who've played here" note (trust cue). **Caretaker mode (staff sub-account):** single-purpose screen: today's bookings list with [Check in] scan button per row + [Mark no-show] (enabled after 30-min grace, reason sheet); intentionally no other navigation.

## 11.18 Micro-additions
**Titles equip:** Profile edit → Titles row → sheet of earned titles (radio), preview on name live; seasonal expired shown in archive section. **Sandbox tutorial:** first scoring-console open offers "Practice with a sample match" — console loads with SANDBOX watermark chip and coach-mark sequence per control; exit anytime; zero stat/XP writes (explicit banner). **Calendar sync:** Settings row with subscribe explainer + per-category toggles (matches/practice/bookings). **Availability quick toggle:** profile-menu Availability sheet (Available/Busy-until-date-picker/Injured→links 11.16).

## 11.19 Sitemap amendments summary
Discover (Community segmented) now hosts: Content lane, Knowledge Hub, Records Hub, Gear exchange, Shops, Associations, Tournaments discovery. Drawer consoles add: Officials (Scorer/Umpire/Commentator), Sponsor, Association-admin, Guardian view. Wallet adds Lucky Draw + Referral + Pro. Expenses ⋮ adds Recently Deleted. All additions respect the 3-push depth cap (deeper flows are sheets), the 5-tab cap (nothing new in tab bar), and the state contract of §6.

— End of Design Spec v1.1 —
