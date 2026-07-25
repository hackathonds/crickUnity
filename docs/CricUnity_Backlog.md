# CricUnity — Implementation Backlog v1.0
## PRD v1.3 + Design Spec v1.1 broken into agent-ready stories

**How to use this document:** each story is written to be handed to an AI coding agent *as-is*, one at a time, together with the two source documents. Stories are self-contained: they name their screens, cite the exact PRD/Design-Spec sections that govern them, enumerate states, and end in testable acceptance criteria. Build strictly in epic order E0 → E17 unless the dependency line says otherwise.

---

## 0. Agent Conventions (prepend to every story handed to an agent)

**Sources of truth:** `CricUnity_PRD.md` (behavior, rules — cited as PRD §x) and `CricUnity_Design_Spec.md` (visuals, motion, pixels — cited as DS §x). Where this backlog summarizes, the cited sections win. Never invent behavior; if a detail is genuinely absent from both documents, surface the question in the PR description rather than guessing.

**Pixel-perfect definition:** implement exactly the DS tokens — 8pt spacing scale (DS §2.1), radius r-xs 6 / r-sm 10 / r-md 14 / r-lg 20, elevation e1–e3, type ramp (DS §2.4: Clash Display + Inter, tabular numerals on every mutable number), icon grid 24/1.75px stroke, touch targets ≥44, reserved colors `live`/`coin`/`verified` never used decoratively (DS §2.3). All colors via semantic tokens only — a raw hex in a component is a defect. Reference frame 375×812; verify 320w and 135% dynamic type.

**Every UI story must ship all seven states** (DS §6): Default, Empty, Loading (skeleton mirroring layout — no spinners for full screens), Error (cause + retry + preserved input), Offline (cached + freshness stamp; money actions disabled with reason), Permission-denied (explains why + who can), Success. Motion uses DS §2.6/§5 tokens; reduced-motion parity mandatory. Accessibility per DS §8 is in-scope of every story, not a separate ticket.

**Definition of Done (all stories):** all AC pass · all 7 states demonstrable · light + dark (Theme 1 & 4) verified · 320w + 135% type verified · focus order + screen-reader labels present · click budget met where DS §1.5 defines one · zero raw hex/px-off-scale values · no console errors · story-named analytics events emitted (naming: `module.object.action`).

**Story format key:** `ID · Title (Size S/M/L/XL) [deps]` → *As a/I want/So that* → Scope In/Out → Build notes (cited) → AC (Given/When/Then). Sizes: S ≤ half-day equivalent, M ≈ 1 day, L ≈ 2–3 days, XL = must be split by the agent into the sub-tasks listed.

---

# EPIC E0 — Design System & App Shell (everything depends on this)

**E0-01 · Design tokens package (M) [—]**
As the design system, I want every semantic token defined once so no screen hardcodes styles.
In: color tokens for Themes 1–5 (DS §4), spacing/radius/elevation/type/motion tokens (DS §2), reserved-color enforcement note. Out: components.
AC: Given any theme is active, When any token is inspected, Then it resolves per DS §4 tables; Given Theme 4, Then borders are replaced by +lum elevation except money surfaces which keep a 1px border (DS §2.2); Given reduced-motion is on, Then motion tokens collapse to 120ms fades (DS §2.6).

**E0-02 · Typography system (S) [E0-01]** Clash Display + Inter ramp per DS §2.4 table incl. tnum on Stat/Money/Scoreboard roles; Money symbol at 70% top-aligned; dynamic type to 135% reflows without truncating amounts. AC includes a type-specimen screen rendering every role for QA.

**E0-03 · Icon set (M) [E0-01]** All families per DS §2.5, outline+filled pairs, 24-grid; coin is the only multicolor icon. AC: icon-gallery debug screen; active states use filled variant globally.

**E0-04 · App shell & navigation (L) [E0-01..03]** Bottom nav 5 tabs + raised FAB-in-bar (DS/PRD §3.1), collapsing app bar 96→56, side drawer with role-gated console sections (PRD §3.3; consoles hidden until role activates — PRD §2 activity-inferred rule), push/pop transitions (DS §5.1), 3-push depth cap enforced structurally.
AC: re-tap active tab scrolls to top, second re-tap refreshes (PRD §3.1); long-press Matches jumps to pinned live match; tab badges per PRD §3.1 logic; drawer console appears within same session a role activates (simulate via debug toggle).

**E0-05 · Sheet, dialog, snackbar primitives (M) [E0-04]** Bottom sheet detents 30/60/92 + grabber + drag physics (DS §3.5); dialog rules incl. typed-confirm for irreversibles (DS §3.21); snackbar single-action 5s queue-of-1 (DS §3.20). AC: sheet with unsaved input bounces and shows Save/Discard instead of dismissing.

**E0-06 · State scaffolds (M) [E0-04]** Reusable Empty/Loading/Error/Offline scaffolds per DS §3.22 incl. Arc-line illustration slot, skeleton shimmer 1.2s, offline freshness stamp, queued-action "pending pill" pattern (PRD §4 offline rules: availability/expense-entry queue; money never queues). AC: a demo screen can render each scaffold; a queued action shows pending pill then resolves or errors on reconnect.

**E0-07 · Core components batch 1 (XL — split per component) [E0-01..06]** Buttons (all variants incl. states, DS §3.1), Card base + context-menu/long-press (DS §3.2), Search bar w/ mic+QR affordances (DS §3.6), Segmented control, Chips, Avatar+level ring+presence (DS §3.23), Forms kit (floating labels, validation shake, currency field, Arc step-progress — DS §3.19), Stepper, Dropdown-as-sheet, Calendar (month/heat/range — DS §3.10).
AC per component: all six interaction states + skeleton; pressed = 0.98 scale 8% tint 80ms; focus ring 2px offset 2.

**E0-08 · Core components batch 2 (XL — split) [E0-07]** Match/Live/Tournament/Player/Expense/Stat/Progress/Reward cards to DS §3.2.1–3.2.9 exact anatomies; Leaderboard row w/ sticky self-clone (DS §3.18); Timeline + ball-scrub strip (DS §3.4); Comment widget (DS §3.13); Reaction arc-picker (DS §3.14); Coin chip + XP ring widgets w/ odometer & float animations (DS §3.15–16); Badge tile + detail sheet (DS §3.17); Scoreboard component + TV mode scale (DS §3.11); Chart kit shell (container, scrub-tooltip, table-view toggle — DS §3.3).
AC highlights: expense amounts share a right-aligned tabular axis; debt text is never red pre-overdue (DS §3.2.5); wagon wheel zone-tap filters a bound list; every chart exposes table toggle.

**E0-09 · Theme switcher & appearance settings (S) [E0-01]** Live-preview theme cards, text-size slider with sample, reduced-motion toggle (DS §7 screen 67). AC: `live`/`coin` hues identical across all five themes.

---

# EPIC E1 — Onboarding, Identity & Guest

**E1-01 · Welcome + registration + OTP (M) [E0]** Screens per DS §11.3: 3-slide pager, phone→OTP 6-cell auto-advance→name; 3 OTP attempts → cooldown with support link; existing-account → login suggestion (PRD §20-A2). AC: cells auto-advance/backspace correctly; resend disabled 30s with countdown.

**E1-02 · Minor detection & guardian gate (M) [E1-01]** DOB step; minor → blocking guardian-consent flow with waiting/resend states (DS §11.3, PRD §17 guardian layer). AC: Given consent pending, Then no other screen is reachable; Given consent granted, Then minor defaults lock to Private+ (PRD §5.20).

**E1-03 · Profile wizard + permissions primer + warm-up (M) [E1-01]** Completeness meter; every step skippable; permission cards with benefit copy and defined denial fallbacks (DS §6/§11.3); follow-suggestions warm-up — **no role question anywhere** (PRD §2 rule). AC: skipping photo/city still lands on Home; denial of location makes Nearby widget show its enable-prompt state (PRD §4.11).

**E1-04 · Guest mode (M) [E0]** Public rendering + contextual Register sheet + once-per-session auto-prompt + guest chip + private-link lock w/ request-access (DS §11.2, PRD §2.1). AC: Given a guest taps any interactive control, Then the sheet names the blocked action specifically; Given dismissal, Then no auto-prompt recurs this session.

**E1-05 · Onboarding checklist widget (S) [E1-03]** Replaces Home stack until 2 items complete; each item grants coins (PRD §4 edge cases). AC: completing "Join a team" marks item + coin float animation (DS §5.7).

---

# EPIC E2 — Player Profile

**E2-01 · Profile screen, viewer-relative (L) [E0]** Self/Teammate/Follower/Public/Blocked renders per PRD §5.20 + DS §7 screen 4-5: cover Arc-mask, avatar −48 overlap, action rows per relation, pinned-badge strip, sticky stat strip, tabs. AC: private profile shows minimal card + Request Follow; blocked shows "Profile unavailable"; verified stats carry engraved ✔ and unverified section renders lighter + dashed (Pillar 2).
**E2-02 · Edit profile (M) [E2-01]** Grouped form; name-change 2/yr helper + log (PRD §5.1); dirty-state Save/Discard guard.
**E2-03 · Stats tab + charts (L) [E0-08, E13-01]** Format tabs, stat cards tappable→match lists, form curve/wagon aggregate/SR-Avg scatter with ⓘ definitions (PRD §5.3/5.7). AC: every stat number opens its source list; self-reported pre-app stats labeled and excluded from rankings.
**E2-04 · Endorsements, style tags, private weaknesses (M) [E2-01]** Max-5 style tags; endorsement chips w/ endorser sheet; weaknesses self+shared-coach only, never public (PRD §5.8 hard rule). AC: a follower viewing profile can never fetch/see weaknesses surface.
**E2-05 · Achievements wall + badge detail (M) [E0-08]** Locked silhouettes with criteria; rarity %; friends-who-hold (PRD Appx D behavior rules).
**E2-06 · Activity calendar + heat privacy tiers (S) [E0-07]** Density-public/detail-friends/full-self (PRD §5.12).
**E2-07 · Trust & Sportsmanship bands (M) [E2-01]** Neutral-slate band chip + self breakdown screen + appeal link (DS §11.5, PRD §5.15). AC: raw scores never rendered; bands appear on join-request and gig cards only for role-holders evaluating.
**E2-08 · Titles equip + availability quick-toggle (S) [E2-01]** DS §11.18; Injured state links injury log (E16-05) and pauses streak penalties (PRD §13.2).

---

# EPIC E3 — Teams

**E3-01 · Create/edit team (M) [E0]** Wizard per PRD §6.1 (name-unique-in-city suggestions, join policy, colors); creator = Owner+Captain; edit change-log + "formerly known as" 90-day chip (PRD §6.2).
**E3-02 · Team home, viewer-relative tabs (L) [E3-01]** Role-gated tabs hidden-not-disabled (DS §7 screen 11); archived read-only banner (PRD §6 edge).
**E3-03 · Invites & join requests (M) [E3-01]** QR/link(expiring 7d, revocable)/search invites; request cards show stats+Trust band+mutuals; 14d auto-expire; deny canned reasons (PRD §6.3–6.4). AC: 10-team cap enforced with clear error; rival-in-same-tournament join raises organizer-flag notice.
**E3-04 · Roles & permission matrix (M) [E3-02]** Appoint/demote per PRD §2.3–2.5 constraints; read-only matrix screen; 6 owner-configurable cells (PRD §6.5-6.7). AC: VC cannot remove Captain; removal requires reason and writes team log.
**E3-05 · Announcements (S) [E3-02]** Push-priority, seen-by list for author, 1-per-6h rate limit, per-announcement comment toggle (PRD §6.8).
**E3-06 · Availability matrix + nudges (M) [E3-02]** Tri-state grid, sticky name column, per-event nudge (1/12h limit disabled-with-tooltip), footer summary (PRD §6.11, DS §7-13).
**E3-07 · Practice sessions + attendance (L) [E3-02]** Template picker from Drill Library (PRD Appx E), RSVP, session-QR check-in + roll-call mode, no-show Trust ding w/ captain excuse, auto recap card (PRD §6.9-6.10). AC: check-in only within venue window ±1h; attendance writes to profile §5.17 and grants coins per PRD §13.1.
**E3-08 · Selection board & lineup (L) [E3-06]** Drag pool→XI slots, role-balance warnings, publish notifications (selected vs benched distinct), lock-at-toss, replacement flow w/ opponent ack (PRD §7.3-7.5, DS §7-14).
**E3-09 · Jersey board (M) [E3-02]** Size sheet, number-conflict resolver, order tracker, linked split (PRD §6.12).
**E3-10 · Carpool + duty roster + kit inventory + documents (L — split 4) [E3-02]** Per PRD G.13 / DS §7-17..21: seat pips + fuel-split suggestion; duty claim→Volunteer coins; custody hand-over dual confirm; role-based doc uploads.
**E3-11 · Recruitment board + pipeline (M) [E3-02]** Listing composer + kanban-lite stages with notify-on-move (DS §11.6).
**E3-12 · Peer ratings + chemistry (M) [E4-10]** 48h window sheet, anonymity threshold ≥3 raters, captain aggregate view; chemistry ring+factors+trend, team-private (PRD §6.27-6.28, DS §11.6).
**E3-13 · Milestones + season summary + ceremony mode (M) [E3-02]** Auto-milestone cards + commemorative badges to then-roster; wrap cards; Present mode; money slide excluded from public share (PRD §6.19/6.29).

---

# EPIC E4 — Matches (core loop; exemplar-depth stories)

**E4-01 · Create-match wizard (L) [E0, E3-01]**
As a captain, I want to set up a match in 4 steps with smart defaults so a repeat friendly takes under a minute.
In: steps Basics/Opponent/Ground&Time/Review per DS §7-24; format sub-rules editor (wide/no-ball rebowl+runs); ball-type selection (tennis/leather pools never merge — PRD §7.1); expense-preset toggle; visibility; guest-team inline creation; draft state; opponent Accept/Propose-changes(diff)/Decline. Out: tournament fixtures (organizer-generated only).
AC: Given I created a match last week, When I start the wizard, Then format/ground/time pre-fill from it; Given opponent proposes a change, Then I see a field-level diff and one-tap accept; Given both accept, Then availability poll auto-sends with default deadline 24h pre-start (PRD §7.3); wizard ≤12 fields touched on the happy path (DS §1.5).

**E4-02 · Match detail pre-live (M) [E4-01]** Info rows, map snippet, my-availability prominent + captain squad grid, expense preview, sticky Directions+RSVP; cancelled/rescheduled states w/ re-RSVP (DS §7-25).

**E4-03 · Toss (S) [E4-02]** 3D coin flip 1.2s either-captain, manual entry fallback, broadcast toast + timeline write (PRD §7.6).

**E4-04 · Scoring console — pad & over engine (XL: split pad / extras / bowler-select / strike-swap) [E0-08]**
In: pinned scoreboard, over beads, batter/bowler strips, bottom-45% pad with 64px run targets, extras steppers, auto strike-swap on odd runs & over-end, next-bowler sheet filtered by legal overs-left, 1-tap common outcomes (DS §7-27, PRD §7.7).
AC: Given a single is tapped, Then score/striker/beads/strips all update in one 240ms odometer cycle; Given over ends, Then bowler sheet lists only legal bowlers with overs-left captions; Given format says no-ball = 1 run + rebowl, Then extras honor the match's sub-rules from E4-01.

**E4-05 · Wicket flow (M) [E4-04]** W→type grid→fielder(where applicable)→new-batter list; run-out sub-fields; scoreboard underline-sweep + key-moment chip (DS §5.13). AC: 3 taps for a bowled dismissal (DS §1.5).

**E4-06 · Undo & corrections (M) [E4-04]** Unlimited undo within current over; prior-over correction flow requiring both-captain ack, logged (PRD §2.6). AC: corrected balls carry an audit marker in ball timeline.

**E4-07 · Interruptions & revised overs (M) [E4-04]** Rain/delay pause, follower notify, revised-overs calculator + simple par table per organizer preset (PRD §7.7). AC: resuming recomputes RRR strip.

**E4-08 · Offline scoring (M) [E4-04, E0-06]** Local-save banner, seamless continue, viewer "score paused" stamp; sync reconciliation states (PRD §7.7 offline UX). AC: airplane-mode scoring of 2 full overs syncs losslessly on reconnect.

**E4-09 · Wagon input + field map + scorer handover (M) [E4-04]** 1.5s ghost sector overlay never blocking next ball; captain field-map drag tool team-private; handover w/ dual-captain approval + audit (DS §11.7). AC: ignoring the ghost 10 times in a row auto-reduces its prompt frequency (respect the scorer).

**E4-10 · Scorecard + confirmation + dispute (L) [E4-04]**
In: innings accordions w/ dismissal text, FoW ladder, 3-avatar confirmation panel, 48h auto-confirm, dispute sheet freezing downstream releases (PRD §7.14, §13 anti-fraud gate).
AC: Given all three confirm, Then ✔ engraves once and coins/XP release (E6) and expense bundle finalizes (E5) and stats/rankings/attendance write — the full Match Ripple fires exactly once (PRD §7 ripple list); Given a dispute, Then rewards/settlement hold and both captains get the dispute queue notice.

**E4-11 · Live spectator view (L) [E4-04]** Scoreboard header, Commentary/Scorecard/Charts/Gallery tabs, auto-scroll + jump-to-live pill, fan prediction chip, delayed-data stamp (DS §7-28). Charts: Manhattan/Worm/partnerships/wagon live per DS §3.3.
**E4-12 · Post-match summary (M) [E4-10]** Order: result hero → MVP → my performance [Share] → XP/coin strip → expense Pay card → ratings entry → insights teaser (DS §7-30 order rule). AC: ceremony and obligation share first viewport.
**E4-13 · MVP & awards (S) [E4-10]** Auto-suggest, opposing-captain pick preferred, minting to profiles (PRD §7.16/7.21).
**E4-14 · Gallery, pin-to-ball, highlights builder (L) [E4-10]** Upload, captain curate, clip-to-ball attach → ball-timeline chips, reel builder + auto-cut chips when markers/footage exist (PRD §7.15, G.4).
**E4-15 · AI insights surfaces (M) [E4-10]** Team + per-player note cards, tone rules, minor-visibility restriction (PRD §7.19).
**E4-16 · Match sharing & privacy (S) [E4-02]** Canonical links, private-match approval gate, performance-card image share (PRD §7.24).

---
# EPIC E5 — Expenses & Wallets

**E5-01 · Expense object + Add/Edit (L) [E0-07]** Category-first grid driving smart forms; amount pad-first; multi-payer; proof attach (+5 coin chip); context link; live remainder line; approval routing >threshold incl. no-self-approval rule (PRD §11.1-11.3/11.7, DS §7-49). AC: split≠total blocks save showing exact delta; captain's own >₹1,000 entry routes to VC/Owner.
**E5-02 · Category behaviors (L — split per category) [E5-01]** Ground-fee auto-draft from booking; ball qty w/ losing-team-pays toggle (pre-agreed); officials' fees cross-team half-half object; travel per-vehicle sub-groups; food attendees-from-check-ins; equipment amortize + jersey link; fines require published fine chart + contest flow; prize income distribution methods with visible math (PRD §11.2). AC per category = its PRD bullet verbatim.
**E5-03 · Auto-split bundle (M) [E5-01, E4-10]** Draft at match create; finalize vs final squad (unavailable excluded, replacements included, MVP-exempt rule); one-sheet captain review; per-payer P1 notifications (PRD §11.4 + Appx A criteria — implement those four Given/Whens as tests).
**E5-04 · Settle up + who-owes-whom (L) [E5-01]** Net graph simplification *suggested not forced*; full/partial/custom; counterpart confirm w/ 72h auto + 48h reminder; declined→mini-dispute; handshake success motion; on-time streak credit (PRD §11.6, DS §5.10). AC: both ledgers update atomically in UI.
**E5-05 · Reminders & pending views (M) [E5-01]** Cadence T+3/7/weekly, payer-visible schedule, snooze 1/48h, payee manual 1/day; I-owe/Owed tabs with age chips (PRD §11.10/11.6).
**E5-06 · Disputes & proof lifecycle (M) [E5-01]** Per-person freeze, resolution paths, escalation after 7d, edit-lock after any settlement w/ consent-recompute (PRD §11.7).
**E5-07 · Collections & team wallet (M) [E3-02, E5-01]** Progress paid-grid, deadline reminders, wallet dual-approval payouts, leaving-member policy display (PRD §11.5/11.8).
**E5-08 · Reports & insights + export (M) [E5-01]** Donut/trend/insight cards; CSV statement export; monthly auto-statement toggle (PRD §11.9, G.12).
**E5-09 · Recurring + scan-itemize + recently-deleted (L — split 3) [E5-01]** Cadence series w/ this-one/all-future edits; detected-lines sheet all-user-confirmed; 30-day restore re-notifying participants (DS §11.13, PRD G.12).

# EPIC E6 — Rewards, Coins, XP, Gamification

**E6-01 · Coin & XP engine surfaces (M) [E0-08]** Earning table wiring per PRD §13.1; release gated on scorecard confirmation (with E4-10); coin float + XP ring + level-up ceremony queueing rules incl. suppression during money/live (DS §5.7-5.9).
**E6-02 · Streak system (M) [E6-01]** Login + playing streaks, monthly shield auto-apply, injury pause (PRD §13.2). AC: missed day with shield available shows shield-used note, streak intact.
**E6-03 · Missions board + season planner (M) [E6-01]** 3-daily/weekly/monthly/epic tabs, claim states, refresh token, role-fair pool rotation, published year calendar (PRD Appx C, DS §7-54/55).
**E6-04 · Badge engine + celebrations (M) [E6-01]** Full Appx D catalog data-driven; tiered upgrades keep history; unlock ceremony + timeline entry + share card.
**E6-05 · Wallet, marketplace, redemption (L) [E6-01]** Expiring FIFO strip w/ 30/7d warnings; catalog w/ level locks, stock, terms; voucher codes + failed-fulfillment auto-refund +10 (PRD §13.5).
**E6-06 · Luck layer (M) [E6-05]** Scratch mask, spin physics w/ public odds page, chest burst, pity rule, monthly lucky draw card w/ entry-count disclosure (PRD §13.4, DS §7-56/11.14).
**E6-07 · Referral + Pro & Family (M) [E6-05]** Code card, referee-state rows, dual rewards on first verified match; paywall with integrity note prominent; 4-slot family manager (PRD §13.1/13.6/G.11, DS §11.14).

# EPIC E7 — Social

**E7-01 · Feed + ranking toggle (L) [E0-08]** Relationship-ranked + Latest toggle, why-am-I-seeing-this, attached-object rich cards w/ verified chips, caught-up interstitial (PRD §12.1, DS §7-57).
**E7-02 · Composer (M) [E7-01]** Text/media/object-attach/poll/audience persistent-visible; edit history label; soft-delete 30d restore (PRD §12.2).
**E7-03 · Comments, reactions, shares, mentions, tags (L — split) [E7-01]** Threaded 2-level, pin-1, arc reaction picker + props default, reshare paths, tag-approval before profile display, hashtag pages (PRD §12.6, DS §3.13-14).
**E7-04 · Stories + reels (L) [E7-02]** 24h stories w/ live score sticker, highlights save; reels ≤90s + remix toggle + auto-suggest from clips (PRD §12.3).
**E7-05 · Messenger (XL — split list/thread/requests/voice/object-cards) [E0-08]** Team-chat roster sync, voice notes hold-record slide-cancel 2×, live expense-card state in chat, receipts/last-seen reciprocity toggles, disappearing 1:1, minor request routing (PRD §12.9).
**E7-06 · Groups + events (M) [E7-01]** Privacy tiers, join questions, post-approval, event RSVP/ticketing (PRD §12.5).
**E7-07 · Moderation, report, block (M) [E0-05]** Reason tree, tracker, offender ladder states, block semantics incl. shared-team roster exception (PRD §12.10, DS §11.16).

# EPIC E8 — Recognition

**E8-01 · Leaderboards hub (M) [E0-08]** Scope×metric×window, qualification minimums, sticky self-row, age/experience-band filters (PRD §14/G.11, DS §7-63).
**E8-02 · Records hub + ground/tournament records + near-record alerts (L) [E4-10]** Appx F categories data-driven, vacant "be first", provenance links, live approach alerts, record-transfer flow with respectful prior-holder notice (PRD Appx F.9).
**E8-03 · Challenges (M) [E6-01]** Global/club/friend H2H live bars + stakes cap 50, overtaken notifications (PRD §13.3/§14).
**E8-04 · Compare + heatmap + PB shelf (M) [E2-03]** Consent-gated side-by-side + radar; visited-grounds map; PB detection announcements (DS §11.15, PRD §14).
**E8-05 · Goals (S) [E6-01]** Metric/target/period cards w/ pace ring; coach-proposed accept/decline (G.11).
**E8-06 · Year in review (M) [E2-06]** December story cards, per-card exclusion, share (PRD §14).

# EPIC E9 — Grounds

**E9-01 · Discovery map+list+filters (M)**, **E9-02 · Ground profile** (facilities/pitch/boundary/records shelf/par-score stats — PRD §10.1, §19.8), **E9-03 · Booking flow** (hold 15:00, policy ack, QR ticket, reschedule/cancel per policy, no-show grace 30m — PRD §10.2), **E9-04 · Reviews** (verified-booker gate, facets, single owner reply — PRD §10.3, DS §11.17), **E9-05 · Owner console** (occupancy/revenue/price-nudges/maintenance blocks/staff — PRD §10.6), **E9-06 · Caretaker mode** (single-purpose check-in/no-show — DS §11.17). Sizes M/L/M/M/L/S; deps E0.

# EPIC E10 — Tournaments

**E10-01 · Creation wizard (L)** all rule declarations incl. tie-breakers order + rain-final rule mandatory at creation (PRD §8.1 + edge cases). **E10-02 · Registration + escrow + eligibility flags (L)** duplicate-player block, waitlist auto-promote, forms checklist (PRD §8.2/G.13). **E10-03 · Fixtures generator + editor (L)** constraints honored, drag-adjust conflicts, versioned changes re-notify (PRD §8.3). **E10-04 · Points table + NRR + what-if calculator (M)** tap-formula, adjusted-badges, slider scenarios savable (PRD §8.4/G.3). **E10-05 · Brackets + seeding (M)**. **E10-06 · Auction room (XL — split lot/bidding/purse/spectator/reconnect)** purse-reserve math enforced (PRD §8.7, DS §7-40). **E10-07 · Organizer console + wallet + payouts (L)** transparency summary to captains, payout confirm, Organizer-Score inputs (PRD §8.13-14). **E10-08 · Stats hub + awards + records (M)** orange/purple lists w/ qualifications, awards minting, hall of champions (PRD §8.10-8.12/8.16). **E10-09 · Sanctioning + association pages (M)** request tracker + revocation public reason (G.9, DS §11.10).

# EPIC E11 — Clubs, Academies, Coaching

**E11-01 · Club home + console (L)** members/dues grid, tiers/subscriptions/grace, inter-team scheduler, wall of fame (PRD §9). **E11-02 · Academy console (L)** batches, guardian-consent enrollment, fee ledgers, trials, talent showcase opt-in (PRD §2.10). **E11-03 · Coach console + drill library + homework (L)** template sessions, per-student rings, drill PB graphs, monthly progress card approve→send, age autoscaling + workload caps (PRD Appx E, DS §7-45/46). **E11-04 · Compliance vault + forms (M)** cert/first-aid expiries, signed-status matrix blocking registration (G.13).

# EPIC E12 — Search & Notifications

**E12-01 · Global search + grouped results + zero-state (M)**, **E12-02 · Advanced per-type filters + saved filter sets (M)**, **E12-03 · Voice + QR search/scanner (M)** (PRD §16, DS §3.6). **E12-04 · Notification center (M)** tabs, entity rollups, inline actions, swipe done/snooze (PRD §3.7/§15). **E12-05 · Channels, priorities, quiet hours, mute ladder, follow-ups (M)** full catalog wiring per PRD §15 table — implement each row's who/when/priority/actions as data-driven config. AC: quiet-hours holds P1, P0 same-day-match breaks through.

# EPIC E13 — Analytics

**E13-01 · Chart library completion (L) [E0-08]** all 23 visualizations DS §19.2/§3.3 incl. Manhattan wicket-dots, win-prob worm, dot-pressure gauge, race chart, tag-coverage captions. **E13-02 · Player analytics (L)** full metric dictionary incl. dot%, phase splits, pressure/entry analyses + insights/recommendation strips (PRD §19.3). **E13-03 · Captain/team/match analysis rooms (L)** momentum timeline + turning-point card (PRD §19.4-19.6). **E13-04 · Custom Stats Explorer (L)** query builder, qualifications, save/pin-as-widget, small-sample caption (PRD §19.9). **E13-05 · Entity analytics** (ground/expense/social/rewards/attendance — M, composition of existing cards).

# EPIC E14 — Officials & Knowledge

**E14-01 · Gig board (M)**, **E14-02 · Officials console + earnings + ratings + tiers (L)**, **E14-03 · Conduct report + appeal (M)**, **E14-04 · Commentator room + moment markers (M)** (PRD §2.6-2.7/G.2, DS §11.4). **E14-05 · Knowledge hub: trivia + quiz packs + certification exams (L)** distraction-reduced exam mode, attempts limits, certificate mint gating Silver tier (G.5, DS §11.11).

# EPIC E15 — Streaming, Sponsors, Marketplace, Discover

**E15-01 · Go-Live + viewer + VOD chapters (L)**, **E15-02 · Production kit + overlays + lower-thirds (M)** (G.8, DS §11.8). **E15-03 · Sponsor console + offers + campaign dashboard + fixed sponsored zones (L)** (PRD §2.15, DS §11.9). **E15-04 · Discover content lane (M)** tip→drill deep-links (G.6). **E15-05 · Gear exchange + shops directory (L)** two-party sold confirm, trusted-seller ladder, minor guardian-routing (G.7, DS §11.12).

# EPIC E16 — Privacy, Safety, Settings, Platform

**E16-01 · Privacy center (L)** per-surface audience dials, preview-as, reciprocity rules, ranked-stats fairness rule (PRD §17 table). **E16-02 · Blocking + restricted (M)**. **E16-03 · Verification flows (M)** three distinct marks (PRD §17). **E16-04 · Guardian view (M)** (DS §11.16). **E16-05 · Medical card + injury log + return-to-play (M)** event-window reveal watermark (G.13). **E16-06 · Data export + deactivate/delete semantics (M)** anonymized-line persistence disclosure (PRD §17). **E16-07 · Help, sandbox tutorial, coach-marks, feature-request board (M)** sandbox zero-writes banner (G.14, DS §11.18). **E16-08 · Deep links + launcher shortcuts + calendar sync (M)** actionable-state landing rule (DS §1.3). **E16-09 · Wearable glances + TV scoreboard mode (M)** (G.10, DS §3.11). **E16-10 · Localization + accessibility audit pass (L)** run DS §9 checklists across shipped screens as executable test list. **E16-11 · Admin/moderation console + audit logs (L)** Theme-5 forced, SLA chips (DS §7-69).

# EPIC E17 — Cross-cutting Integration Stories (build last in each phase)

**E17-01 · Match Ripple integration test (M) [E4-10,E5-03,E6-01,E8-02]** One confirmed match must demonstrably trigger all nine downstream updates exactly once, in order, with the ceremony-suppression rules honored (PRD §7 ripple, Appx B). AC = a scripted E2E walkthrough per PRD Appx A pattern.
**E17-02 · Notification catalog conformance (M) [E12-05]** Every PRD §15 table row fires with correct audience/priority/inline actions.
**E17-03 · Click-budget audit (S) [phase-end]** Automated/manual verification of every DS §1.5 budget row.
**E17-04 · State-contract sweep (M) [phase-end]** Every shipped screen demonstrates all 7 states; screenshots archived per theme.

---

## Phasing (recommended build order)

**Phase 1 — Core loop (E0, E1, E2-01/02, E3-01..08, E4 all, E5-01..05, E6-01, E12-04/05 subset, E17-01/03/04):** one Sunday match end-to-end — create, respond, score, confirm, split, settle, celebrate.
**Phase 2 — Retention (E5 rest, E6 rest, E7, E8, E2 rest, E9, E13-01/02, E16-01/02/07/08).**
**Phase 3 — Ecosystem (E10, E11, E14, E15, E13 rest, E16 rest).**

## Story count summary
E0:9 · E1:5 · E2:8 · E3:13 · E4:16 · E5:9 · E6:7 · E7:7 · E8:6 · E9:6 · E10:9 · E11:4 · E12:5 · E13:5 · E14:5 · E15:5 · E16:11 · E17:4 → **134 stories** (XLs split further by agents per their listed sub-tasks → ~170 implementable units).

---

# AUDIT v1.1 — Second-pass PRD reconciliation

A slow, section-by-section re-walk of PRD v1.3 against the 134 stories above found the gaps below: **1 missing epic (the Home Dashboard itself), 17 missing stories, and 12 AC amendments to existing stories.** Nothing else in the PRD is uncovered after this addendum.

## EPIC E18 — Home Dashboard (was entirely absent — the largest gap)

**E18-01 · Home shell + widget framework (L) [E0]** Vertical widget stack with ordering engine (pinned → urgency → recency), per-widget header/⋮/2-action contract, pull-refresh, role-based first-launch presets (PRD §4 layout model, DS §7-1). AC: urgency reordering demonstrable (a payment-due widget outranks informational ones); hidden widgets reachable under "More for you".
**E18-02 · Edit Home mode (S) [E18-01]** Long-press lift + drag reorder, hide, pin max-3, reset (PRD §4, DS §7-3).
**E18-03 · Widget batch A — cricket (L — split) [E18-01, E4]** Upcoming Matches (inline availability chips, squad-lock countdown, status rail), Today's Activity (check-in window ±1h), Live Matches (self-hides when none; my-team>followed ordering), Nearby Matches (location-permission fallback state, radius-widen suggestion) — per PRD §4.1/4.3/4.11/4.12 states verbatim.
**E18-04 · Widget batch B — money & rewards (M — split) [E18-01, E5, E6]** Expense Summary (privacy-blur option, all-settled state), Pending Payments (snooze 1/48h, overdue escalation ambers/reds + Trust tooltip), Coin Balance (expiring countdown chip), Rewards (self-hides when none), Challenges (≥80% pulse) — PRD §4.4-4.7/4.19.
**E18-05 · Widget batch C — social & progress (M — split) [E18-01, E7, E8]** Recent Performance (24h confetti-once, stale→season swap, disputed grey), Suggested Friends/Teams/Grounds (dense-graph auto-collapse to weekly digest, dismiss-learning), Recent Posts (6h anti-duplication rule), Recent Achievements, Followers delta, Messages preview w/ inline reply, Invitations decision cards w/ expiry, Unread digest (≥5 & >12h rule), Player Ranking (progress-to-ranked <5 matches), Fitness Progress, Attendance ("Iron Player" chip; <60% tip self-only) — PRD §4.2/4.8-4.10/4.15-4.18/4.20-4.24.
**E18-06 · Weather widget + captain alert (S) [E18-01]** Ground-and-time-specific forecast (not city-generic), severe-alert reschedule nudge, one-tap "Notify captain" share-to-team-chat (PRD §4.13).
**E18-07 · Quick-action chips + app-icon shortcuts + account/role switcher (M) [E0-04]** Max-3 dynamic urgent chips; launcher shortcuts; long-press Profile tab = role-view switcher ("Deepak — Scorer view"); Ground-owner Business-mode tab swap + Fan Live-tab swap (PRD §3.1/3.5/3.6 — previously uncovered).

## Added stories in existing epics

**E2-09 · Profile Timeline tab (M) [E2-01]** Auto-generated life-in-cricket entries (debut, first fifty, captaincy, championships), per-entry hide, per-entry share (PRD §5.19).
**E3-14 · Transfers (M) [E3-03]** Player-move flow: personal stats travel / team aggregates freeze, tournament transfer-window enforcement (organizer-set, default locked post-fixtures), courtesy notification to former captain, rival-transfer organizer visibility (PRD §6.26).
**E3-15 · VC auto-elevation + captaincy succession (M) [E3-04]** Captain marks unavailable → VC gains match-day powers for that match only, logged + team-notified; ownership transfer 7-day cooling notice; inactive-owner (180d) petition flow with 30-day response window; captain-exit-without-transfer blocking wizard (PRD §2.4/2.9/§6 edge cases).
**E3-16 · Free-agent mode, player side (M) [E3-11]** "Find a Game" flow: free-agent profile toggle w/ availability days + roles, browse team needs, apply→pipeline mirror, individual registration into tournament auction pools (PRD §2.2/§8.7).
**E4-17 · Officials assignment in match setup + self-scoring rules (M) [E4-01, E14-01]** Assign scorer (self/member/hire via Gig Board inline) and optional umpires during creation; playing-scorer block with dual-captain override that flags the scorecard "self-scored — reduced verification weight"; umpire own-team conflict flag with dual-captain waiver (PRD §2.6/2.7/§7.1).
**E4-18 · Commentary stream + scorer quick-edit (S) [E4-04]** Auto-text per ball, scorer edit/custom notes, key-moment auto-flags feeding spectator tab (PRD §7.8).
**E5-10 · Multi-currency expenses (M) [E5-01]** Currency per expense, home-currency converted display with stored conversion note, one-agreed-currency-per-pair settlements (PRD G.12 — was omitted from E5-09's split).
**E5-11 · Expense comments (S) [E5-01]** Participant-only threads w/ @mentions, dispute-link from comment (PRD G.12; make explicit rather than implied by E5-06).
**E6-08 · Ranks — percentile bands (M) [E6-01, E8-01]** Bronze→Elite bands per city+format+discipline, 60-day soft decay preserving historical peaks, rank≠level in-product explainer (PRD §18 — distinct from leaderboards, was uncovered).
**E6-09 · Season rewards & tier frames (S) [E6-04]** Bronze→Legend season-XP tiers, exclusive frames, season rollover ceremony (PRD §13.2).
**E7-08 · Bookmarks & saved collections (S) [E7-01]** Save-to-folders, private saved tab, saved-from context (PRD §12.7).
**E7-09 · Fan engagement system (M) [E4-11, E8-01]** Predictions (result + MVP), prediction-accuracy fan leaderboards, superfan streaks, fan-tier coin earning wired to §13 marketplace fan items (PRD §2.14 — fan role had no dedicated story).
**E8-07 · Periodic awards engine (M) [E8-01]** Monthly Consistency/Fair-Play/Fitness/Attendance/Volunteer/Community awards: auto-nominee computation, city/club winner announcement posts, certificate cards (PRD §14 awards list — surfaces existed, the engine didn't).
**E8-08 · Progress rings (S) [E8-05]** Weekly Play/Train/Contribute rings with user targets, ring-close streaks + burst, distinct from goals (PRD §14, §4.23).
**E11-05 · Personal training log (M) [E11-03]** Drill Library access for *all* users (not only academy students): self-log drills with units, optional proof (+bonus), partner-confirm, per-drill PBs & progress graphs, feeds daily missions D5/D7/D8 and Net-Grinder/Circle-Runner badges, age workload caps (PRD Appx C.1/E — the library was coach-console-only in E11-03).
**E16-12 · Super-Admin economy console (M) [E16-11]** Coin/XP rate + fee-policy configuration with dual-Super-Admin co-sign, feature flags per region, public changelog surface for user-affecting changes, platform status banner (PRD §2.17, G.14 — governance tooling was uncovered).

## AC amendments to existing stories (append to each story's AC)

1. **E3-02:** team Followers get match alerts + follow CTA on public team page (PRD §6.20).
2. **E3-02:** club-linked teams render club branding only after team-owner acceptance (PRD §9).
3. **E4-01:** "Challenge a friend/team" entry creates a challenge card the receiver accepts into the wizard (PRD §7.1 types).
4. **E5-03:** attendance-based and role-based split methods selectable in review sheet (PRD §11.3 — methods list must be complete, not just equal/custom).
5. **E9-03:** owner cancellation <48h auto-applies refund + visible reliability-score drop on listing (PRD §2.11).
6. **E9-02:** followed grounds emit new-slot and price-drop notifications (PRD §10.4) — add rows to E12-05 catalog config.
7. **E10-03:** mid-league team withdrawal applies the pre-declared results rule; organizer inactivity 14d mid-event exposes the Admin-intervention path to captains (PRD §8 edge cases).
8. **E10-07:** completed-result changes require both-captains+scorer ack or a publicly-logged committee ruling (PRD §2.12).
9. **E11-01:** inter-wallet transfers between club and team treasuries require both treasurers' confirmation (PRD §2.13).
10. **E11-03:** analytics-consent toggle default ON for academy students / OFF for adult attachments; minor progress notes surface to guardian (PRD §2.8).
11. **E14-02:** Verified-Scorer badge auto-grants at 10 dispute-free matches ≥4.0 avg; tournament official filters honor tier + certification (PRD §2.6, G.5).
12. **E16-11:** Admin actions fully logged and visible to Super Admin; reported-thread access limited to reported excerpt (PRD §2.16).

## Revised totals & phasing

Story count: 134 + 24 added = **158 stories** (~200 implementable units after XL splits). Phasing updates: **E18-01..07 and E3-15, E4-17, E5-10/11 join Phase 1** (the Home Dashboard is the daily entry point of the core loop and cannot wait); E2-09, E3-14/16, E6-08/09, E7-08/09, E8-07/08, E11-05 join Phase 2; E16-12 joins Phase 3. E17-01's ripple test now also asserts dashboard widgets refresh (Recent Performance, Pending Payments, Coin Balance) after match confirmation.

**Audit method note:** this pass walked PRD §§1–20 and Appendices A–G line-by-line, mapping every normative sentence to a story ID; the mapping found no further uncovered requirements. Residual risk sits in the XL splits — agents must enumerate their sub-tasks in the PR before starting, per Section 0.

— End of Backlog v1.1 —
