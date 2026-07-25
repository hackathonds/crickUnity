# CricUnity — The Complete Cricket Ecosystem
## Product Requirements Document (PRD) v1.0

**Prepared by:** Product Strategy Office
**Audience:** Product Managers, UX Designers, Business Analysts, QA, Stakeholders
**Scope:** Full product behavior specification. No technology or implementation detail is included by design.

---

# 1. Product Vision

## 1.1 Why This Application Exists

Grassroots and club cricket runs on fragmented tools: one app for scoring, WhatsApp for coordination, a spreadsheet or Splitwise for money, Instagram for highlights, and nothing at all for recognition, discipline, or long-term motivation. The result:

- **Coordination failure.** Captains chase 15 players across 3 chat groups to confirm availability for Sunday's match.
- **Money friction.** Ground fees, ball costs, and umpire fees are collected in cash, tracked in memory, and disputed for weeks. The captain silently absorbs losses.
- **Invisible careers.** A player with 4,000 club runs over 10 years has no verified record, no shareable profile, no recognition.
- **No motivation loop.** Players who show up to every practice get the same "reward" as players who show up to none: nothing.
- **Disconnected community.** Grounds don't know which teams need them; academies can't find talent; sponsors can't find local audiences; fans can't follow local heroes.

CricUnity exists to be the **single operating system for a cricketer's entire life in the sport** — playing, organizing, paying, celebrating, improving, and belonging.

## 1.2 Who It Is For

| Audience | Core Need |
|---|---|
| Players (13–60+) | Verified career record, matches to play, recognition, fair money |
| Captains / Vice-Captains | Team logistics, availability, selection, discipline |
| Team Managers | Money, jerseys, sponsors, admin work |
| Scorers & Umpires | Professional identity, bookings, fees, reputation |
| Coaches & Academies | Student progress, drills, talent pipeline |
| Ground Owners | Bookings, revenue, visibility, reviews |
| Tournament Organizers | Registrations, fixtures, fees, sponsors, streaming |
| Club Owners | Multi-team governance, membership, revenue |
| Fans | Follow local players/teams, live scores, content |
| Sponsors | Hyper-local, measurable cricket audiences |

## 1.3 Problems It Solves (Summary Table)

| Problem | CricUnity Answer |
|---|---|
| "Who's available Sunday?" | One-tap availability polls tied to matches; visible response matrix |
| "Who owes ₹250 for the ball?" | Auto-split match expenses; who-owes-whom ledger; settlement suggestions |
| "Prove I scored that century" | Verified scorecards signed by opponent + scorer; tamper-evident career stats |
| "Nobody notices my consistency" | Streaks, badges, XP, Fair Play score, Year-in-Review |
| "Where do we play Saturday?" | Ground discovery, live availability calendar, in-app booking |
| "How do I fill my tournament?" | Public registration, verified team records, escrowed entry fees |

## 1.4 How It Is Different From the Inspirations

**vs. CricHeroes.** CricHeroes is a scoring-first utility. CricUnity treats scoring as one input into a larger loop: a scored match automatically triggers expense settlement, XP and coin rewards, social posts, attendance records, ranking updates, and achievement checks. CricHeroes stops when the match ends; CricUnity's value *begins* when the match ends. CricUnity also adds money, gamified motivation, ground commerce, and a real social graph.

**vs. Facebook.** Facebook is a general-purpose graph where cricket content drowns. CricUnity's social layer is *structured around cricket objects*: every post can attach to a match, a performance, a ground, or a tournament, giving it context, stats, and permanence. Feeds are ranked by cricketing relevance (your teammates, your grounds, your tournaments), not engagement bait. There are no ads masquerading as posts; sponsorship is explicit and cricket-native.

**vs. Splitwise.** Splitwise is generic and knows nothing about *why* an expense exists. CricUnity's expense engine is cricket-aware: it knows a match has a ground fee, two umpires, a ball, and 11–15 payers; it pre-builds the split the moment the match is created, adjusts when a player marks unavailable, and can waive shares by rule (e.g., "Player of the Match pays nothing"). Settlement is tied to attendance and reputation (Trust Score), which Splitwise cannot do.

**vs. CRED.** CRED rewards a financial behavior (bill payment). CricUnity rewards *contribution to cricket*: playing, scoring for others, umpiring, organizing, attending practice, settling dues on time. Coins are earned by verified on-ground actions, not spend — making the reward economy meritocratic and fraud-resistant (rewards require multi-party match verification).

**vs. Strava.** Strava celebrates individual endurance metrics. Cricket is a *team* sport with discrete events. CricUnity's recognition system honors team outcomes, role diversity (a scorer's 50th scored match is celebrated like a batter's 50th fifty), sportsmanship, and reliability — dimensions Strava has no concept of. Segments become "Ground Records" (fastest fifty at Shivaji Ground); kudos become context-rich reactions on verified performances.

## 1.5 Unique Selling Points

1. **The Match Ripple.** One completed match updates 9 systems automatically (stats, rankings, expenses, coins, XP, attendance, achievements, feed, ground records). No other product closes this loop.
2. **Verified Careers.** Dual-confirmation scorecards create a trusted, portable cricket CV.
3. **Trust & Sportsmanship Scores.** Reliability and fair play become visible currency — changing behavior on the ground.
4. **Cricket-native money.** The only expense system that understands overs, no-shows, and match roles.
5. **Every role is a first-class citizen.** Scorers, umpires, and ground owners have profiles, ratings, earnings, and careers — not just players.

## 1.6 Long-Term Vision

**Year 1:** Own the Sunday match — availability, scoring, money, recognition.
**Year 2:** Own the ecosystem — grounds marketplace, tournament platform, academy tools, verified rankings by city.
**Year 3:** Own the pathway — talent discovery for academies/selectors, sponsor marketplace, live streaming network of local cricket, and the definitive database of amateur cricket careers.
**North Star Metric:** Verified matches completed per week.

---

# 2. User Types

Each role below is a *capability set*, not an exclusive identity. One account can hold multiple roles (a Player can also be a Scorer and a Ground Owner). Roles are either **self-declared + verified by activity** (Player, Fan), **appointed** (Captain, Vice-Captain, Manager — by team hierarchy), **credentialed** (Umpire, Scorer, Coach — via activity history and endorsements), or **asset-backed** (Ground Owner, Academy Owner — via listing verification).

**Global permission principles:**
- Permission = Role ∩ Context. A Captain has captain powers only inside *their* team.
- Visibility never exceeds the viewer's relationship (Public < Follower < Teammate/Friend < Role-holder < Owner).
- Money actions always require the payer's explicit confirmation; no role can move another user's money.
- Destructive actions (delete team, cancel tournament) require typed confirmation + cooling-off notice to affected users.

## 2.1 Guest

- **Purpose:** Frictionless evaluation; watch live scores shared via link; browse public content.
- **Responsibilities:** None.
- **Permissions:** View public profiles, public matches (live + completed), public tournaments, ground listings, public feed posts. Use global search (read-only).
- **Restrictions:** Cannot react, comment, follow, message, join, book, pay, or appear in search results. No coins/XP. Session data (viewed matches) is discarded unless they register.
- **Visible modules:** Discover, Live Matches, Public Profiles, Ground Directory, Tournament listings.
- **Hidden modules:** Home Dashboard, Expenses, Wallet, Messages, Notifications, Rewards, Team internals.
- **Upgrade path:** Register → becomes Fan by default; selecting "I play cricket" during onboarding → Player.
- **Example:** Rohan's father opens a shared live-score link, watches the last over, sees a "Create your free profile to follow Rohan" prompt.
- **Edge cases:** Guest opening a *private* match link sees "This match is private — ask the captain for access" with a request-access button that forces registration first.

## 2.2 Player

- **Purpose:** The atomic unit of the ecosystem. Plays matches, builds a verified career.
- **Responsibilities:** Respond to availability polls (in-time responses affect Trust Score), pay their expense shares, confirm scorecards involving them (silent approval after 48h).
- **Permissions:** Create/edit own profile; join/leave teams (leaving mid-tournament requires captain acknowledgment); post; follow; message mutuals and teammates; view own analytics; register for open tournaments as individual (auction pools); book grounds; challenge friends; redeem coins.
- **Restrictions:** Cannot edit team settings, cannot score matches they play in *for stat verification purposes* unless a second verifier confirms, cannot see teammates' private expense details outside shared items, cannot delete verified match records (may only dispute).
- **Visible modules:** All personal + social + rewards + own teams' shared modules.
- **Hidden modules:** Team treasury admin, tournament organizer console, ground owner console.
- **Upgrade paths:** Appointed Captain/VC/Manager by a team; Scorer/Umpire credential by completing role activities; Coach via academy attachment; asset roles via listing.
- **Example:** Priya (opening batter, 2 teams) checks Sunday availability poll, marks "Available," pays her ₹120 share from last week from the settlement card, and posts her 45* clip auto-attached to the verified scorecard.
- **Empty state:** New player with 0 matches sees "Your career starts with match #1" and CTAs: Find a team / Create a team / Join as a free agent.

## 2.3 Captain

- **Purpose:** On-field and organizational leader of one team.
- **Responsibilities:** Create/accept match invites, run availability polls, publish lineup, conduct toss entry, approve match result confirmation, resolve selection disputes, approve expense entries above the team's threshold.
- **Permissions (within their team):** Everything a Player has, plus: invite/remove players (removal requires reason, logged); appoint/demote VC and Manager; create matches; edit team profile; post announcements (push-priority); lock lineup; approve/deny join requests; initiate expense splits; view full team expense ledger; view every member's availability history and attendance %; endorse player skills.
- **Restrictions:** Cannot edit a member's personal profile; cannot mark a player "Paid" (only payer or Manager-with-proof can); cannot delete team if any unsettled balances or active tournament — must resolve first; removal of a player mid-tournament triggers organizer notification.
- **Visible modules:** Captain Console (availability matrix, selection board, discipline log), team treasury (read + approve), team analytics.
- **Hidden modules:** Other teams' consoles; organizer finance.
- **Upgrade path:** → Team Owner (if they created the team); → Club Owner by founding a club.
- **Example:** Arjun opens the Availability Matrix Friday 6 PM, sees 9 confirmed/3 pending/2 unavailable, sends one-tap "Nudge pending," locks a 12-man squad Saturday noon, which auto-notifies selected + benched players with distinct messages.
- **Business rule:** A team has exactly one Captain. Transferring captaincy requires the current Captain's action or Team Owner override; the outgoing captain gets the "Former Captain" badge with tenure dates.

## 2.4 Vice Captain

- **Purpose:** Continuity when Captain is absent; shared leadership load.
- **Responsibilities:** Same as Captain when acting; co-approve sensitive actions if team setting "dual approval" is on.
- **Permissions:** All Captain permissions *except*: cannot remove the Captain, cannot appoint another VC, cannot transfer team ownership, cannot delete team, cannot demote the Manager. VC actions are labeled "by VC {name}" in the team log.
- **Restrictions:** If Captain marks self "Unavailable" for a match, VC automatically gains full match-day powers for that match only (auto-elevation, logged, notified to team).
- **Visible/Hidden modules:** Same as Captain; treasury approvals visible but require Captain co-sign for amounts above threshold unless auto-elevated.
- **Upgrade path:** → Captain (appointment).
- **Example:** Captain is traveling; VC locks the lineup; the lineup card shows "Selected by VC Kunal."

## 2.5 Manager

- **Purpose:** The team's operations and finance officer — the non-playing backbone (may or may not be a playing member).
- **Responsibilities:** Record expenses with receipts, chase settlements, manage jersey orders, liaise with grounds and sponsors, maintain the team calendar.
- **Permissions:** Create/edit expenses and attach proof; send payment reminders (rate-limited to 1/day/person); mark cash payments received *with payer confirmation request*; manage team wallet inflows record; book grounds on team's behalf; edit logistics fields of matches (venue, time) with change-notification to squad; upload team media.
- **Restrictions:** No selection powers, no roster changes, cannot post as "Captain," cannot approve their own expense entries above threshold (Captain approves), cannot access members' personal wallets.
- **Visible modules:** Treasury console, sponsor console, logistics calendar.
- **Hidden modules:** Selection board, discipline log (read-only summary only).
- **Upgrade path:** → Team Owner/Club roles.
- **Edge case:** If a team has no Manager, Captain inherits Manager permissions and sees a persistent "Appoint a Manager to share workload" suggestion after 5 expense entries.

## 2.6 Scorer

- **Purpose:** Professional match documentarian. Scoring quality underpins the entire verified-stats economy.
- **Responsibilities:** Ball-by-ball scoring accuracy; submitting final scorecard; responding to disputes within 24h.
- **Permissions:** Access Live Scoring console for assigned matches; edit balls within the correction window (last 2 overs freely; older balls require both captains' acknowledgment); set fees on their public Scorer Profile; accept/decline scoring gigs; view their scoring history, ratings, and earnings ledger.
- **Restrictions:** Cannot score a match they are playing in (system blocks; override only if both captains approve — flagged "self-scored, reduced verification weight"); cannot edit a *submitted* scorecard (dispute flow only); cannot see team private chats.
- **Visible modules:** Scorer Console, Gig Board (matches needing scorers nearby), earnings, ratings.
- **Hidden modules:** Team internals of the teams they score for.
- **Credentialing:** "Verified Scorer" badge after 10 dispute-free scored matches with avg rating ≥ 4.0. Badge tiers: Bronze (10), Silver (50), Gold (150), Platinum (500).
- **Example:** Deepak accepts a Gig Board request (₹400 fee, 3 km away), scores the match, both captains confirm within 2h, his fee auto-enters the match expense split, and he earns 150 Scorer XP + coins.

## 2.7 Umpire

- **Purpose:** Match officiation with a professional identity and booking pipeline.
- **Responsibilities:** Confirm assignments, record key decisions when using the Umpire companion view (optional), file match conduct reports (fair play incidents), rate team behavior.
- **Permissions:** Umpire Gig Board; set fees & travel radius; conduct-report tools (report reaches organizer + affects Sportsmanship Scores after review); view earnings, ratings, decision-dispute history.
- **Restrictions:** Cannot alter scores; cannot umpire a match involving their own active team (conflict flag; both captains must waive); conduct reports about a team they follow socially get an auto-disclosed relationship tag.
- **Visible modules:** Umpire Console, assignments calendar, earnings.
- **Hidden modules:** Team/organizer finance beyond own fees.
- **Credentialing tiers:** mirror Scorer tiers; tournament organizers can filter "Silver+ umpires only."
- **Example:** During a tournament final, Umpire Farah files a conduct note (verbal abuse by fielder); organizer reviews with scorer testimony; the player's Sportsmanship Score drops one band; the player is notified with appeal option (7-day window).

## 2.8 Coach

- **Purpose:** Develop players; bridge academies and teams.
- **Responsibilities:** Plan sessions, mark attendance, log drill performance, publish player progress notes (private to player + guardian if minor).
- **Permissions:** Create training sessions with attendance QR; assign drills & fitness targets; view attached players' full analytics (with player consent toggle, default ON for academy students, OFF for adult team attachments); write endorsements; recommend players to teams/selectors (recommendation card carries coach's credential weight).
- **Restrictions:** No match/team admin powers unless separately appointed; cannot see players' expenses/wallet; progress notes for minors visible to guardian account.
- **Visible modules:** Coach Console, student roster, session planner, progress tracker.
- **Hidden modules:** Team treasuries, tournament finance.
- **Upgrade path:** → Academy Owner.
- **Example:** Coach Meera assigns "20 min throwdowns, 3×/week"; players check in via session QR; her console shows completion rings per student; she publishes a monthly progress card that the student can showcase (opt-in) on their profile.

## 2.9 Team Owner

- **Purpose:** Ultimate authority and continuity anchor for a team (usually its creator/financier).
- **Permissions:** Everything Captain has, plus: transfer/assign captaincy; transfer team ownership (7-day cooling period, notified to all members); delete/archive team (only when balances settled & no active tournaments); set team-level policies (expense approval threshold, join policy, dual-approval mode); manage sponsor contracts; access full historical treasury.
- **Restrictions:** Cannot silently change match results; cannot erase members' historical stats (archiving preserves records as read-only).
- **Business rule:** If an Owner account is inactive 180 days, Captain can petition ownership transfer; petition notifies Owner across channels with 30-day response window.

## 2.10 Academy Owner

- **Purpose:** Run a cricket academy as a business: batches, fees, coaches, talent pipeline.
- **Permissions:** Academy profile & verification; create batches (age groups, schedules, fees); enroll students (guardian consent flow for minors); assign coaches; fee collection ledger with due-date reminders; publish trials/events; showcase academy achievements; talent showcase board visible to Team Owners/Organizers (student opt-in).
- **Restrictions:** Cannot view student data beyond academy context; minor data is guardian-gated; cannot message minors directly (messages route through guardian-visible channel).
- **Visible modules:** Academy Console (batches, fees, staff, trials, progress).
- **Example:** Sunrise Academy posts U-16 trials; 40 registrations arrive with guardian consent; selected students get enrollment offers; monthly fees auto-appear in guardian ledgers.

## 2.11 Ground Owner

- **Purpose:** Monetize and manage a ground.
- **Permissions:** Ground profile (photos, pitch types, facilities, pricing, rules); availability calendar; accept/decline bookings; block slots for maintenance; respond to reviews (one response per review); staff sub-accounts (caretaker: check-in powers only); view revenue dashboard, occupancy analytics, and Ground Records leaderboard for their ground; offer promotional pricing (off-peak discounts).
- **Restrictions:** Cannot delete genuine reviews (only report); cannot see teams' internal finances; cancelling a confirmed booking < 48h before slot triggers auto-penalty per platform policy (refund + reliability score drop, visible on listing).
- **Visible modules:** Ground Console.
- **Example:** Green Park Turf sets Sat–Sun 6–9 AM at ₹2,400/slot; a team books; caretaker checks the team in via QR; fee flows into the team's match expense automatically.

## 2.12 Tournament Organizer

- **Purpose:** Design and run tournaments end-to-end.
- **Permissions:** Create tournaments (format, rules, fees, prizes); approve team registrations; generate & edit fixtures (edits notify all affected + log reason); manage points table overrides (e.g., walkover — reason mandatory & public); appoint official scorers/umpires; run auctions; manage sponsors & streaming links; publish results & awards; tournament wallet (entry fees in, prizes/fees out — every line itemized and visible to registered captains).
- **Restrictions:** Cannot edit ball-by-ball data; cannot change a completed match result without both captains + scorer acknowledgment (or documented committee ruling, which is publicly logged); prize payouts require winner confirmation.
- **Reputation:** Organizer Score (on-time fixtures, payout speed, dispute rate) shown on every tournament listing.
- **Example:** Monsoon Cup: 16 teams, ₹3,000 entry, group + knockout; fixtures auto-generated respecting ground availability; a rained-out match rescheduled with one tap, all 30 players notified.

## 2.13 Club Owner

- **Purpose:** Govern a multi-team institution (club with A/B/veterans/women's teams, membership, facilities).
- **Permissions:** Club profile; create/link teams under club banner; membership tiers & subscription ledger; club-wide announcements; internal tournaments; club treasury (separate from team treasuries; inter-wallet transfers require both treasurers' confirmation); recognition board (Wall of Fame); assign club admins.
- **Restrictions:** Cannot override team captains' selection; team treasuries remain team-controlled unless team opts into club-managed finance.
- **Example:** Lions CC runs 4 teams; ₹500/mo membership auto-reminders; monthly "Clubman of the Month" chosen from cross-team analytics.

## 2.14 Fan

- **Purpose:** Follow, watch, celebrate.
- **Permissions:** Follow players/teams/tournaments/grounds; react, comment (where allowed), share; predictions & fan polls on live matches; fan leaderboards (prediction accuracy, superfan streaks); redeem fan-tier coins (earned via predictions, watching, streaks) for fan merchandise/coupons.
- **Restrictions:** No team/match/expense modules; comment-throttled on non-followed content; cannot message players who haven't enabled fan messages.
- **Upgrade path:** → Player anytime ("I play too").
- **Example:** A father follows his son's team; gets lineup, live wickets, and the post-match summary; his "predicted MVP correctly" streak hits 5, earning a scratch card.

## 2.15 Sponsor

- **Purpose:** Fund cricket in exchange for visibility.
- **Permissions:** Sponsor profile; browse sponsorship marketplace (teams/tournaments/grounds seeking sponsors, with audience stats); make offers (amount, duration, asset: jersey/boundary/trophy/stream overlay); view campaign dashboard (impressions of sponsored surfaces, engagement); sponsored badge on funded entities.
- **Restrictions:** No feed ads; sponsorship appears only on agreed assets; cannot access follower personal data (aggregates only); all sponsorships labeled "Sponsored by."
- **Example:** A local sports shop sponsors Lions CC jerseys for a season; logo appears on team profile, match cards, and MVP graphics; dashboard shows 12,400 profile views during the season.

## 2.16 Admin (Platform)

- **Purpose:** Trust & safety, dispute resolution, content moderation, verification approvals.
- **Permissions:** Review reports; suspend content/accounts with reason codes; adjudicate expense/score disputes escalated past peer resolution; approve ground/academy verifications; adjust wrongly-awarded coins (logged, user-notified with appeal path).
- **Restrictions:** Every action logged and visible to Super Admin; cannot alter stats except via dispute rulings; cannot access private messages except reported threads (reported excerpt only).

## 2.17 Super Admin

- **Purpose:** Platform governance: policy, economy tuning, admin oversight.
- **Permissions:** All Admin powers; configure coin economy rates, XP curves, fee policies, feature flags per region; view platform analytics; manage Admin accounts; final appeal authority.
- **Restrictions:** Dual-control for economy changes (second Super Admin co-sign); public changelog for policy changes affecting users' coins/fees.

---
# 3. Complete Navigation Structure

## 3.1 Bottom Navigation (always visible, 5 tabs)

| Tab | Icon | Default Screen | Badge Logic |
|---|---|---|---|
| **Home** | House | Home Dashboard | Red dot if any priority widget has action |
| **Matches** | Bat & ball | My Matches (Upcoming ▸ Live ▸ Recent) | Count = live matches involving me/my teams |
| **+ (Create)** | Plus (raised FAB-in-bar) | Create sheet | — |
| **Community** | People | Feed | Count = new posts from close graph since last visit (cap 9+) |
| **Profile** | Avatar | My Profile | Dot if profile completeness < 80% or pending verifications |

**Behavior:** Re-tapping an active tab scrolls to top; second re-tap refreshes. Tabs persist scroll position when switching. Long-press Matches → quick jump to a pinned live match. Long-press Profile → account switcher (multi-role identities, e.g., "Deepak – Scorer view").

**Role adaptations:** Ground Owners see **Bookings** replacing Community if they enable "Business mode" toggle; Fans see **Live** replacing Matches.

## 3.2 Top Navigation (contextual app bar)

- **Left:** Screen title / entity name; back arrow on pushed screens.
- **Right (Home):** Search icon → Global Search; Bell → Notification Center (badge = unread count, 99+ cap); Coin chip showing balance → tapping opens Wallet (coin chip animates +N on new earnings).
- **Right (entity screens):** Context menu (⋮) with entity actions (Share, QR, Report, Mute…).
- Top bar collapses on scroll-down, reappears on scroll-up (except during Live Scoring, where it is pinned).

## 3.3 Side Navigation (drawer, swipe from left edge or avatar tap on Home)

Sections (rendered only if role applies):
1. **My Identity:** Profile, Wallet & Coins, Rewards, Achievements, Activity Calendar, Year in Review.
2. **My Cricket:** My Teams (list w/ role chips), My Matches, My Tournaments, My Bookings, My Academy, Availability settings.
3. **Consoles (role-gated):** Captain Console, Manager/Treasury, Scorer Console, Umpire Console, Coach Console, Ground Console, Academy Console, Organizer Console, Club Console, Sponsor Console.
4. **Money:** Expenses, Settlements, Reports.
5. **Settings:** Privacy, Notifications, Language, Help, Report a Problem, Log out.
Footer: App version, policy links, "Refer & earn" card.

## 3.4 Floating Actions & Create Sheet

Tapping **+** opens a role-aware bottom sheet:
- Everyone: **Post**, **Story**, **Reel**, **Poll**.
- Player+: **Start a Match**, **Challenge a Friend**, **Add Expense**, **Find a Game (free agent)**.
- Captain/Owner: **Create Team**, **Practice Session**, **Announcement**.
- Organizer: **Create Tournament**.
- Ground Owner: **Block Slot**, **Add Offer**.
Recently used create-actions float to the top (max 2 pinned by recency).

## 3.5 Quick Actions (contextual chips)

- Home header chips (dynamic, max 3): "Respond: Sunday match?", "Pay ₹120 to Arjun", "Confirm scorecard".
- App icon long-press (launcher shortcuts): Start Scoring, My Next Match, Scan QR, New Expense.

## 3.6 Profile Menu (tap own avatar anywhere)

Mini-sheet: View Profile · Edit Profile · Share Profile QR · Switch Role View · Availability toggle (Available/Busy/Injured, with optional end date) · Settings.

## 3.7 Notification Center

- Two tabs: **For You** (personal: mentions, payments, selections, confirmations) and **Following** (teams/tournaments/players you follow).
- Grouping: by entity ("Lions CC — 3 updates") expandable inline.
- Inline actions on notification cards: Accept/Decline, Pay, Confirm, RSVP, Mark read.
- Filters row: All · Mentions · Money · Matches · Rewards.
- Long-press a notification: Mute this type · Mute this entity (8h/1w/forever) · Turn off.
- "Clear all read" and per-section mark-read. Priority notifications (payment due today, match starting) pin to top with colored edge.

## 3.8 Search — entry points & structure

- Global Search from top bar anywhere. Structure detailed in §16.
- Scoped search inside modules (e.g., searching inside Expenses only searches expenses).

## 3.9 Filters (universal pattern)

Filter sheet pattern used across lists: chips row (quick) + "All filters" sheet (full). Active filter count shown on the filter icon. "Reset" always visible. Filter state persists per screen per session; saved filter sets can be named (e.g., "Weekend turf grounds < ₹2,500").

## 3.10 Shortcuts

- **QR everywhere:** every profile/team/ground/match/tournament has a QR; scanner lives in Global Search bar.
- **Deep links:** shareable links open the exact object honoring viewer permissions.
- Keyboard "/" on tablet/web focuses search.

## 3.11 Context Menus (⋮) — canonical contents by object

- **Post:** Save · Share · Copy link · Follow author · Mute author · Hide · Report · (own: Edit/Delete/Pin/Archive · view insights).
- **Match card:** Share · Add to calendar · Set reminder · Copy scorecard link · Report score issue.
- **Player:** Message · Invite to team (if captain) · Endorse · Compare with me · QR · Block · Report.
- **Expense:** Remind · View proof · Dispute · Split details · Export line.

## 3.12 Long-Press Actions

- Message bubble → React · Reply · Copy · Forward · Pin · Delete-for-me / Delete-for-all (10-min window) · Report.
- Feed post → peek preview + quick reactions.
- Team in "My Teams" → Set default team · Mute · Leave.
- Coin chip → last 5 coin transactions popover.
- Calendar day → day's events peek.

## 3.13 Swipe Actions

- Notification: swipe right = done/read; swipe left = snooze (1h/tonight/tomorrow options).
- Expense row: right = Pay/Settle; left = Remind (if owed to me) or Dispute.
- Chat list: right = read/unread toggle; left = mute/pin.
- Availability poll card: right = Available; left = Unavailable (with confirm haptic; undo snackbar 5s).
- Match list: left = share; right = pin to top.
- All destructive swipes show undo snackbar (5 s) before commit.

---

# 4. Home Dashboard

**Layout model:** Vertical stack of widgets. Order = (1) pinned by user, (2) urgency score (action needed > time-sensitive > informational), (3) recency. "Edit Home" mode (long-press any widget or via ⋮) allows reorder, hide, pin (max 3 pinned). Hidden widgets reachable under "More for you" footer. Every widget has: header (title + ⋮), body, and at most 2 action buttons. Pull-to-refresh refreshes all. First-launch default order differs by role (Player-first vs Fan-first vs Owner-first presets).

For each widget below: **P**=Purpose, **I**=Info shown, **A**=Actions, **V**=Visibility, **S**=Sorting, **St**=States.

### 4.1 Upcoming Matches
- **P:** Never miss a game. **I:** Next 3 matches: opponent, date/time, ground, my availability status, weather glyph, squad-lock countdown. **A:** Respond availability (inline chips), Directions, View match, Add to calendar. **V:** Users with ≥1 team or booked match. **S:** Soonest first; matches needing my response outrank. **St:** Empty ("No upcoming matches — Find a game / Create one"); Response-needed (amber edge); Locked-in (green tick); Cancelled (struck-through with reason, dismissible).

### 4.2 Recent Performance
- **P:** Instant self-worth loop after matches. **I:** Last match line (e.g., "38 (22) & 1/24"), rating given, MVP flag, XP/coins earned chips. **A:** View scorecard, Share performance card (auto-designed graphic), Post about it. **V:** Players with ≥1 completed match; hidden for pure Fans. **S:** Most recent match. **St:** Fresh (celebration confetti once, within 24h of match); Stale (>7 days: swaps to "Season so far" mini-summary); Disputed (grey with "stats pending confirmation").

### 4.3 Today's Activity
- **P:** Day-at-a-glance. **I:** Today's events: match, practice, booking, tournament fixture, coach session; each with time + place + status chip. **A:** Check-in (when at venue window ±1h), View, Navigate. **V:** All logged-in users; hidden if empty *and* user disabled "show empty day". **St:** Empty ("Rest day 🏝️ — nearby matches to watch?"), In-progress (live pulse), Done (checkmarks accumulate).

### 4.4 Expense Summary
- **P:** Money clarity in 3 seconds. **I:** Net position ("You are owed ₹450" / "You owe ₹300"), top counterparty, pending count. **A:** Settle up (opens settlement flow pre-filtered), Remind, View all. **V:** Users with ≥1 expense relationship; amount hidden behind tap if "Privacy blur" enabled. **S:** Largest absolute balance first in expanded view. **St:** All-settled (green "All square ✓"); Overdue (red accent + days count); Dispute-open (info banner).

### 4.5 Coin Balance
- **P:** Reward visibility. **I:** Balance, this week's earnings, next redemption unlock ("240 more → ₹100 voucher"). **A:** Earn (opens missions), Redeem (marketplace), History. **V:** All members. **St:** Streak-bonus available (glowing rim); Expiring coins (countdown chip, e.g., "300 expire in 5d").

### 4.6 Rewards
- **P:** Surfacing claimables. **I:** Unclaimed items: scratch cards, spin tokens, level-up chest. **A:** Claim/Open (inline animation), View all. **V:** Only when ≥1 unclaimed (self-hides otherwise). **St:** Single vs stacked ("3 rewards waiting").

### 4.7 Challenges
- **P:** Active goals. **I:** Up to 2 active challenges with progress bars ("Score 100 runs this month — 64/100"), time left. **A:** View, Find more, Nudge rival (friend challenges). **St:** Near-complete (pulsing bar at ≥80%); Completed-unclaimed; Failed (soft grey, "Try again next month").

### 4.8 Suggested Friends / 4.9 Suggested Teams / 4.10 Suggested Grounds
- **P:** Graph growth. **I:** Horizontal cards: mutuals count / "Needs an opener" tag / distance + price + rating. **A:** Follow/Add · Request to join · View & Book. **V:** Collapses automatically once user's graph is dense (≥50 follows) to weekly digest card. **S:** Relevance (mutual teammates > same tournaments > same locality). **St:** Dismiss removes and improves future suggestions ("Show fewer like this").

### 4.11 Nearby Matches
- **P:** Discovery & spectating. **I:** Live/today matches within radius (user-set, default 10 km): teams, over, venue distance. **A:** Watch live, Directions, Follow match. **V:** Requires location permission; else shows "Enable location to find cricket around you." **St:** Nothing nearby → widens radius suggestion.

### 4.12 Live Matches
- **P:** My graph's live action. **I:** Matches of my teams / followed entities: score ticker updating in place, key-moment chips ("Wicket!"). **A:** Open live view, Mute this match. **V:** Only during live matches (self-hides). **S:** My team > followed teams > followed tournaments. **St:** Innings break; Rain delay; Last-over highlight (red pulse).

### 4.13 Weather
- **P:** Play/no-play planning. **I:** Forecast for *my next match's ground & time* (not generic city): rain %, heat, "pitch likely damp" advisory. **A:** View hourly, Notify captain (one-tap share into team chat). **V:** Users with upcoming outdoor events. **St:** Severe alert (red banner, suggests reschedule flow to captains).

### 4.14 Tournament Updates
- **P:** Track competitions. **I:** My/followed tournaments: next fixture, points-table position delta ("↑2 to 3rd"), pending actions (squad submission due). **A:** View table, View fixtures, Complete action. **St:** Action-required outranks informational.

### 4.15 Followers / 4.16 Messages / 4.17 Invitations
- **Followers:** weekly delta + notable follower ("A verified coach followed you"); action: View. Self-hides if no change.
- **Messages:** top 2 unread threads with preview; actions: Reply inline (quick text), Open. Hidden if zero unread.
- **Invitations:** team invites, match invites, tournament invites, academy offers as decision cards; actions: Accept · Decline · View; each shows expiry countdown. State: expiring <24h flagged.

### 4.18 Unread Notifications
- Compact digest ("5 unread · 2 need action") only when Notification Center badge ≥5 and untouched >12h. Action: Open center.

### 4.19 Pending Payments
- **P:** Debt-specific urgency (distinct from 4.4 summary). **I:** Individual dues with payee avatar + context ("Ground fee · Sunday vs Titans"). **A:** Pay/Settle, Snooze (once per item per 48h), Dispute. **V:** Payer only; payees see mirror "Awaiting from…" in Expense module. **St:** Overdue escalation: amber >3d, red >7d (red state also nudges Trust Score warning tooltip).

### 4.20 Recent Posts
- **P:** Social pull-through. **I:** 1–2 top posts from close graph since last visit. **A:** React inline, Open feed. **V:** Hidden if user opened Community tab in last 6h (anti-duplication rule).

### 4.21 Recent Achievements
- **I:** Latest badge/milestone of mine or close friends ("Rahul unlocked 100 Wickets!"). **A:** Congratulate (one-tap reaction), View badge, Share mine. **St:** Mine (celebration style) vs friend's (social style).

### 4.22 Player Ranking
- **I:** My city/format rank + weekly movement ("#42 in Delhi T20 batting, ↑5"). **A:** View leaderboard, See what moves rank (explainer sheet). **V:** Players with ≥5 verified matches (below that: progress-to-ranked bar "3 more matches to get ranked"). **St:** New personal-best rank (gold shimmer once).

### 4.23 Fitness Progress
- **I:** Weekly training ring (sessions attended/target), streak, coach-assigned drill completion. **A:** Log activity, View plan. **V:** Users attached to a coach/academy or who enabled fitness tracking. **St:** Ring closed (burst animation); broken streak (gentle "Start a new streak" — never shaming copy).

### 4.24 Attendance
- **I:** My attendance % this season (matches + practices), team average comparison. **A:** View history. **V:** Team members. **St:** ≥90% shows "Iron Player" chip; <60% shows neutral improvement tip (visible only to self).

**Dashboard edge cases:** Brand-new user sees an onboarding checklist widget (Complete profile → Join/create team → Play first match → Settle first expense; each grants coins) replacing most widgets until 2 items complete. Offline: widgets render last-loaded data with "Updated 2h ago" stamps; action buttons that need connectivity grey out with "You're offline — will retry" queued-action toasts where safe (e.g., availability response queues; payments never queue).

---
# 5. Player Profile

**Structure:** Header (cover, avatar, name, roles, badges strip) → Action row → Stats tabs → Content tabs. Viewer-relative rendering: the same profile renders differently for Self, Teammate/Friend, Follower, Public, and Blocked (blocked users get "Profile unavailable").

## 5.1 Basic Information
Name (real name required for verified stats; display nickname optional), photo, cover, city, age band (exact DOB private by default; minors never show age publicly), languages, bio (150 chars), joined date, roles chips (Player · Scorer · Captain @ Lions CC). Validation: name change limited to 2×/year (log kept); profanity filter on bio.

## 5.2 Playing Information
Batting style (RHB/LHB), bowling style (pace/spin subtype), primary role (Batter/Bowler/All-rounder/WK), preferred position (opener/middle/finisher), preferred formats (T10/T20/30-over/Test-style), jersey number & name, active teams list with role chips. Editable anytime; format preferences feed matchmaking.

## 5.3 Career Statistics
Split by format tabs. Batting: M, Inns, Runs, HS, Avg, SR, 50s, 100s, 4s, 6s, ducks, not-outs. Bowling: O, W, Best, Avg, Econ, SR, 3W/5W, maidens, dots%. Fielding: catches, run-outs, stumpings. Keeping split shown only for WKs. Each stat tappable → underlying verified match list. **Verified vs Unverified split:** stats from dual-confirmed scorecards carry a ✔; self-scored/unconfirmed sit in a separate "Unverified" toggle (default hidden to public). Manual "pre-app career" entry allowed but permanently labeled "Self-reported" and excluded from rankings.

## 5.4 Awards / 5.5 Records / 5.6 Achievements
- **Awards:** MVPs, Best Batter/Bowler of tournaments, Fair Play awards — each links to its source match/tournament (tamper-proof provenance).
- **Records:** Personal bests (fastest fifty, best figures) + any Ground/Tournament records held ("Highest score at Green Park: 112*") with "record holder" crown; if broken by someone else, moves to "Former records" (self-view only).
- **Achievements:** badge wall (see §13/§18), filterable by category, each with earn date + the triggering match link.

## 5.7 Performance Charts
Runs/wickets by match (last 10/season/career), form curve, SR vs Avg scatter per bowling type faced, dismissal-type pie, scoring-zone wagon aggregate. Charts are interactive (tap a point → that match). Public sees season-level; detailed opposition splits are Self + Teammate view.

## 5.8 Playing Style / Strengths / Weaknesses
- **Style tags:** self-selected (max 5: "Anchor", "Death-over hitter", "New-ball swing").
- **Strengths:** endorsement-driven — teammates/captains/coaches endorse skills ("Fielding", "Yorkers"); count shown; endorser avatars on tap; coach endorsements weighted with a whistle icon.
- **Weaknesses:** *private by default*; visible to Self + explicitly shared coaches only. Auto-suggested from data ("47% dismissals to left-arm spin") with "keep private / share with coach" choice. Never publicly displayed — business rule to prevent sledging fuel.

## 5.9 Followers / Following / 5.10 Posts / Reels / Photos / Videos / Story Highlights
Standard social tabs (behavior in §12). Media auto-albums per match ("vs Titans, 12 Jan"). Story highlights: named circles under bio (max 10). Follower list visibility configurable (Everyone/Followers/Only me).

## 5.11 Badges / Coin Balance
Badge strip: top 3 chosen by user pinned; full wall in Achievements. **Coin balance is Self-only** (never public — prevents status toxicity); others can see badge *tiers*, not currency.

## 5.12 Activity Calendar
GitHub-style heat grid: darker = more cricket that day (match=3, practice=2, scoring/umpiring=2, social-only=0). Tap day → activity list. Visibility: Public shows density only; Friends see event types; Self sees everything.

## 5.13 Favorites (Teams / Grounds / Tournament / Players)
Curated shelves (max 5 each) shown as tappable cards; drives suggestion engine.

## 5.14 Recent Form
Last-5 string (e.g., "45* · 12 · 3/20 · DNB · 61") with W/L color underline; hover/tap expands.

## 5.15 Player Rating / Trust Score / Sportsmanship Score
- **Player Rating (0–100 per discipline):** computed from verified performances, opposition strength, recency-weighted. Public. Movement arrows weekly.
- **Trust Score (bands: Building → Reliable → Rock Solid):** inputs = availability answered on time, showed up when confirmed, paid dues on time, scorecards confirmed promptly. Shown as band (not raw number) to Captains evaluating join requests & organizers evaluating teams. Self sees factor breakdown + how to improve. Drops decay-forgiven over 90 clean days.
- **Sportsmanship Score (bands: Fair → Exemplary; can drop to Under Review):** umpire conduct reports, opponent post-match fair-play votes, dispute behavior. Appealable (§17). "Exemplary" streak feeds Fair Play awards.

## 5.16 Availability / 5.17 Attendance
- Availability master toggle (Available / Busy until {date} / Injured — injured pauses streak penalties). Weekly template ("generally free Sun AM"). Visible to own captains only.
- Attendance: season % for matches & practices per team; team-visible; historical graph self-view.

## 5.18 Expense Summary / Rewards Earned / Challenges Completed
Self-only: net position, lifetime settled, on-time %; rewards ledger; challenge history with completion rate.

## 5.19 Level & XP / History / Timeline
Level ring on avatar (subtle). Timeline tab = life-in-cricket feed: joined team, debut, first fifty, captaincy, championships — auto-generated, each entry sharable; user can hide individual entries.

## 5.20 Privacy & Views
Profile Visibility presets: **Public** (discoverable, stats + public content), **Community** (only logged-in members), **Private** (followers approved manually; public sees name, avatar, city, "Private profile").
Per-section overrides (stats, media, followers list, activity calendar): Everyone / Followers / Teammates / Only me.
**Public View preview** button lets users see their profile as Public/Follower/Teammate. Minors: forced Private+, no public messaging, guardian co-notification on new follower requests.

---

# 6. Team Module

## 6.1 Create Team
Flow: Name (unique within city; suggestions if taken) → Logo (upload/generated monogram) → City & home ground (optional link) → Format focus → Join policy (Open / Request / Invite-only) → Colors. Creator becomes **Team Owner + Captain** (can reassign). Creation grants "Founder" badge + 100 XP. Validation: profanity filter; 3-char min; team limit 5 owned per user (raise via support).

## 6.2 Edit Team
Owner/Captain edit identity fields; edits to Name/Logo notify members and keep a change log ("Formerly known as…" for 90 days on public profile to prevent reputation laundering). Manager edits logistics fields only.

## 6.3 Invite Players & 6.4 Player Requests
- Invite via: search, QR, share-link (expiring 7d, revocable), contact suggestion, "free-agent board".
- Invite card shows role offered ("Join as: Player / WK needed"). Invitee sees team profile + Trust context (team's payment reliability, activity level). Accept → joins; Decline (optional reason to captain).
- Requests (for Request-policy teams): requester's card shows stats, Trust band, mutuals; Captain/VC Approve/Deny; deny optionally with canned reasons; auto-expire 14d.
- Business rules: a player can be in max 10 teams; joining a *direct rival in same active tournament* requires organizer visibility flag.

## 6.5–6.7 Captain / VC / Manager Permissions
See §2.3–2.5. Team Settings screen exposes a **Permission Matrix** table (rows=actions, columns=roles, checkmarks) so every member can see who can do what. Owner can toggle 6 configurable cells (e.g., "VC can approve expenses": on/off; "Manager can create matches": off by default).

## 6.8 Announcements
Captain/VC/Manager post announcements → pinned in team space + push (bypasses feed algorithm; respects member's "announcements only urgent" setting). Read-receipts list visible to poster ("Seen by 11/15"). Members can react but comments toggleable per announcement. Max 1 push-priority announcement per 6h (anti-spam).

## 6.9 Practice Sessions & 6.10 Attendance
Create session: date/time, venue, focus tags (nets/fielding/fitness), capacity, RSVP deadline. RSVPs mirror match availability UI. On-site check-in: session QR (any RSVP'd member scans) or captain's manual roll-call sheet (tap names). Attendance writes to §5.17 and grants Attendance coins. No-show after "Yes" logs a Trust ding (captain can excuse with reason — excused = neutral). Session recap card auto-posts to team space (attendee count, photos slot).

## 6.11 Player Availability
Availability Matrix screen (Captain view): rows=members, columns=upcoming events, cells = ✅/❌/❓/⏳(no response). Sortable by response, role, attendance %. One-tap "Nudge all pending" (max 1 nudge/12h/event). Members set advance defaults ("auto-❌ weekday matches").

## 6.12 Jersey
Jersey board: design image, size-collection form (members submit size/name/number; conflicts on number flagged with claim-by-seniority suggestion), order status tracker (Collecting sizes → Ordered → Arrived → Distributed), linked jersey expense with per-member split. Members see own size submission; Manager sees full sheet.

## 6.13 Sponsors
Sponsor slots on team profile (jersey/banner/trophy). Manager/Owner create sponsorship record: sponsor entity, asset, duration, amount → sponsor logo renders on agreed surfaces; income entry auto-drafted to treasury. Marketplace listing toggle: "Open to sponsors" with asking range.

## 6.14 Expenses / 6.15 Collection / 6.16 Shared Wallet
Team-scope views of §11: team ledger, collections (e.g., "Season fund ₹500×15" with paid/pending grid), and Team Wallet (balance, inflow/outflow lines, dual-approval payouts above threshold). Every member sees the ledger (transparency by default; Owner may restrict amounts-only-to-payers mode, which shows entries but blurs amounts you're not party to).

## 6.17 Statistics / 6.18 History / 6.19 Milestones
Team stats: W/L by format/season, win % batting first vs chasing, top run-scorer/wicket-taker boards, best partnerships, streaks. History: full match archive with filters. Milestones auto-detected (50th win, 100th match, first championship) → milestone card + team-wide celebration post + commemorative badge to all members on roster at that time.

## 6.20 Followers / 6.21–6.23 Posts, Photos, Videos / 6.24 Achievements
Public team page mirrors player social tabs. Followers get match alerts. Team achievements shelf (trophies with tournament links).

## 6.25 Recruitment / 6.26 Transfers
- Recruitment board: team posts "Need: Left-arm spinner, Sun mornings, North Delhi" → visible in free-agent discovery; applicants tracked in a mini-pipeline (Applied → Trial invited → Offered → Joined).
- Transfers: player moving between teams keeps personal stats; *team* aggregates freeze at departure. Transfer during a tournament follows the tournament's transfer-window rule (organizer-set; default: locked after fixtures publish). Rival-transfer triggers courtesy notification to former captain.

## 6.27 Player Ratings / 6.28 Team Chemistry
- Internal post-match peer ratings (optional, anonymous, 1–5 stars + tags) roll into a private "coach's view" for Captain; individual raters never revealed; visible to rated player only as aggregate after ≥3 raters (anti-identification rule).
- Chemistry score (team-private): composite of attendance, availability response rate, settlement speed, roster stability. Trends chart helps captains spot decay ("Chemistry down 12% — 4 unsettled expenses > 2 weeks").

## 6.29 Season Summary
Auto-generated season wrap: record, top performers, best win, chemistry trend, money summary (collected/spent/per-head cost), awards ceremony mode (full-screen reveal cards Captain can present at team dinner). Shareable as public highlight (money slide excluded from public version automatically).

**Team edge cases:** Last member leaving ≠ delete — team auto-archives (read-only, stats preserved). Captain leaving without transfer → ownership escalation prompt to Owner; if Owner=Captain leaving, forced transfer wizard blocks exit until resolved or team archived with balances settled.

---

# 7. Match Module

## 7.1 Match Creation
Entry: + → Start a Match. Types: **Friendly** (my team vs opponent team / vs ad-hoc "guest team" created inline), **Challenge** (send/accept a challenge card), **Tournament fixture** (organizer-generated; captains cannot create). Fields: format (overs, players/side, wide/no-ball rules preset with editable sub-rules: rebowl on/off, runs per extra), date/time, ground (linked or free-text), ball type (tennis/leather/other — affects stat pools: tennis and leather stats never merge), match visibility (Public/Community/Private), scorer assignment (self/member/hire from Gig Board), umpires (optional), expense preset toggle ("auto-create standard expenses"). Creating notifies opponent captain → Accept/Propose changes (diff view)/Decline. Match is **Draft** until both accept.

## 7.2 Ground Selection
Inline ground picker: map + list, filters (distance, price, pitch, availability at chosen time). Selecting a listed ground with booking enabled → booking sub-flow (slot hold 15 min, fee quote flows into expense preset). Unlisted ground: free-text + pin drop (prompt: "Invite this ground to CricUnity").

## 7.3 Player Selection / 7.4 Availability / 7.5 Lineup
Availability poll auto-sent on match confirm (deadline default 24h before start; captain-editable). Selection board: available players as draggable cards → Playing XI/XII + bench; role-balance meter warns ("No wicketkeeper selected"). Publish lineup → selected/benched get distinct notifications; lineup locks at toss (post-lock changes = "replacement" flow requiring opponent captain acknowledgment, logged).

## 7.6 Toss
Toss screen at match start: digital coin flip (either captain taps; animation; result recorded) *or* manual entry ("Real coin used: Titans won, chose to bat"). Toss result posts to match timeline + notifies followers.

## 7.7 Live Scoring (Scorer Console)
- **Main pad:** run buttons (0–6), extras (Wd/Nb/B/Lb with run steppers), wicket button → dismissal sheet (type, fielder, new batter), swap-strike, end-over auto-advance with next-bowler picker (bowler-overs limits enforced per format rules).
- **Every ball entry** takes ≤2 taps for common outcomes. Undo stack (unlimited within current over; prior overs via correction flow §2.6).
- **Companion strips:** current over beads, batter/bowler live figures, target/required-rate (2nd innings), DLS-style par toggle for reduced-over matches (simple par table, organizer-preset).
- **Interruptions:** Rain/Delay button pauses match clock, notifies followers, offers revised-overs calculator.
- **Offline UX:** scoring continues seamlessly; banner "Saving locally — will sync"; viewers see "Score paused — scorer offline" freshness stamp.
- **States:** Not started → Live → Innings break → Live → Completed → Confirmed. Abandoned/Walkover states with mandatory reason.

## 7.8 Commentary
Auto-generated text per ball ("FOUR! Priya drives through covers") with scorer quick-edit; scorer can add custom notes; fans see commentary stream in live view; key moments auto-flagged (wicket, fifty, hat-trick chance).

## 7.9 Wagon Wheel / 7.10 Partnerships / 7.11 Run Rate / 7.12 Field Map / 7.13 Ball Timeline
- Wagon wheel: optional per-scoring-shot direction tap (skippable; completeness % shown); renders per batter/innings.
- Partnerships: bar list with runs/balls per wicket stand; live current-stand widget.
- Run-rate worm + Manhattan per over; chase view overlays required rate.
- Field map: optional captain tool to log field placements per phase (private to team by default — usable for tactics review).
- Ball timeline: scrubbable strip of every ball; tap → full detail (who, what, commentary, any media clip attached to that ball).

## 7.14 Scorecard
Full innings cards (batting order w/ dismissal text, bowling figures, extras, fall of wickets). Post-match it becomes the **canonical record**: both captains + scorer confirm (auto-confirm 48h if unchallenged). Confirmed = ✔ stamp; feeds every downstream system.

## 7.15 Photos / Videos / Highlights
Match gallery: any squad member uploads; captain can feature/hide items; fans can view public gallery. Clips can be pinned to specific balls ("attach to: 14.3") → appear in ball timeline + auto-compile into a Highlights reel (wickets/boundaries ordered) that the captain can publish.

## 7.16 Awards
MVP auto-suggested (performance-index) but decided by: opposing captain pick (preferred, prompts them) or auto. Additional: Best Batter/Bowler/Fielder optional. Awards mint profile entries + coins.

## 7.17 Expenses / Collection / Payments / Coins / Rewards (match scope)
On match completion the **expense preset** finalizes: ground fee, ball, scorer/umpire fees split per rules (§11) across *final squad* (availability-aware). Payment states visible on match page (paid grid). Coins/XP distribute per §13 rules (performance, participation, role bonuses) only **after scorecard confirmation** (anti-fraud gate).

## 7.18 Post Match Summary
Auto card: result line, scores, MVP, top performers, best moments; one-tap share (public matches) → generates feed post attributed to team page.

## 7.19 AI Insights
Plain-language takeaways: "Middle overs (7–14) cost you: 4 wickets for 31", "Bowling change at over 12 swung momentum", per-player notes ("First time crossing 40 vs leather"). Visible: team members for team insights; each player for own notes. Tone rules: constructive, never ridiculing; insights on minors visible to self+coach+guardian only.

## 7.20 Player Ratings / 7.21 MVP / 7.22 Attendance / 7.23 Match Timeline
Peer ratings window opens 1h post-match for 48h (§6.27). Attendance auto-marks from final lineup + check-ins (bench attended too). Match timeline: chronological event log (created → accepted → toss → innings → confirmations → settlements) — the audit spine.

## 7.24 Sharing / Public vs Private View
Share sheet: live link, scorecard image, performance cards per player. **Public view:** scores, cards, public media. **Private match:** link-holders must be approved; search-hidden; stats still count (verification unaffected by privacy). Guest viewers get register-prompt overlays on interaction attempts.

**Match ripple (explicit interactions):** Confirmed match → updates player & team stats → recalculates rankings (§14/§19) → finalizes expense split & opens settlements (§11) → awards XP/coins/badges (§13) → writes attendance (§5.17) → checks achievements & records (ground/tournament) → drafts social summary post (§12) → updates Trust (paid? showed up?) & Sportsmanship (fair-play votes) → feeds AI insights & analytics.

---

# 8. Tournament Module

## 8.1 Creation
Wizard: Identity (name, logo, banner, city, dates) → Format (league/groups+knockout/pure knockout; overs; ball; players/side; squad size caps) → Rules (points scheme editable: win/tie/NR/bonus; tie-breakers ordered list: points→H2H→NRR→toss of coin; over-rate penalties on/off; transfer window) → Money (entry fee, prize structure, umpire/scorer provisioning: organizer-paid vs per-match split) → Registration (open/invite; team cap; docs required; deadline) → Publish (Draft→Published; edits post-publish are versioned & notify registrants).

## 8.2 Registration
Team applies with squad list (min/max enforced), pays entry fee into **tournament wallet (escrow)** — refund rules displayed upfront (full refund if rejected/cancelled; organizer-set sliding scale for withdrawal). Organizer reviews (squad eligibility flags: duplicate player across two registered teams is auto-flagged and blocked until resolved). Waitlist auto-promotes on dropout.

## 8.3 Fixtures / 8.4 Points Table / 8.5 Groups / 8.6 Knockout
- Auto-generator honors: ground availability windows, team blackout dates (teams may submit up to 2), rest gaps, double-header limits. Manual drag-adjust with conflict warnings. Publishing notifies all squads; any change → change-record with reason + re-notify affected.
- Points table live-updates on match confirmation; NRR computed & tappable to see formula inputs; manual adjustments (penalties/walkovers) badge-marked with public reason.
- Group standings roll into knockout seeding automatically per rules; bracket view with tappable slots; "path to final" view for each team.

## 8.7 Auction
Optional player-auction mode: player pool (registered free agents with base price), team purses, live auction room (organizer as auctioneer; bid buttons with increments; timer per lot; unsold pool re-rounds), results roster auto-forms teams. Spectator mode for fans. All bids logged; purse math enforced (can't bid beyond purse minus minimum-squad reserve).

## 8.8 Sponsors / 8.9 Streaming
Sponsor slots: title sponsor (name prefix), trophy, MVP award, boundary/stream overlay — each rendering on defined surfaces. Streaming: attach live-stream links per match; "Watch" button on live fixtures; stream schedule page; view counts on organizer dashboard.

## 8.10 Statistics / 8.11 Awards / 8.12 Leaderboards
Tournament stat hub: most runs (Orange list), most wickets (Purple list), best SR/Econ (min qualifications organizer-set), best figures, team stats. Awards page: auto-computed nominees; organizer confirms winners at closing; awards mint to profiles with tournament provenance. Leaderboards live-update; final versions freeze at tournament close.

## 8.13 Expenses / 8.14 Revenue
Organizer ledger: inflows (entry fees, sponsors) / outflows (grounds, officials, prizes, trophies) — line-itemized. **Transparency rule:** registered captains see the categorized summary (not sponsor contract values if marked confidential — but the prize pool total & payout status is always visible). Prize payout tracker: winner confirms receipt; unconfirmed >7d flags Organizer Score.

## 8.15 Followers / Updates / Posts / Media
Tournament public page: follow → fixture alerts, results digest (daily during tournament), announcement posts, media hub (official + tagged community media, organizer-curated featured strip).

## 8.16 History / Records
Multi-season container: past editions list, hall of champions, evergreen tournament records ("Highest total in Monsoon Cup history") — auto-checked every confirmed match; record broken → notification to old holder + celebration post draft.

**Edge cases:** Rain-abandoned finals → organizer chooses per pre-declared rule (shared trophy / reserve day / league-position winner) — rule must be set at creation, shown at registration. Team withdrawal mid-league → past results stand or void per pre-declared rule. Organizer abandonment (inactive 14d mid-event) → Admin intervention path visible to captains.

---

# 9. Club Module

- **Club Dashboard (Owner/Admins):** headline tiles — active members, teams, this-month revenue vs dues outstanding, upcoming events, pending join requests; recent activity stream across all club teams.
- **Members:** directory with tier chips (Playing/Social/Junior/Honorary), join dates, dues status (green/amber/red), roles; bulk actions (message tier, export list); member profile shows cross-team club stats.
- **Teams:** teams under the banner; create/link/unlink (linking requires that team Owner's acceptance); club-branded surfaces on linked teams; inter-team friendly scheduler.
- **Grounds:** club-owned/partner grounds with member-priority booking windows & member pricing.
- **Revenue:** subscriptions, event income, sponsor income, facility income — dashboards + drill-down ledgers; treasurer role assignable.
- **Sponsors:** club-level sponsor slots cascade optionally onto linked teams (with each team's consent toggle).
- **Announcements & Events:** club-wide posts; events (annual day, trials, dinners) with RSVP, ticketing (paid events feed revenue), attendance QR.
- **Membership & Subscriptions:** tier definitions (price, cadence, benefits list); renewal reminders (7d/1d), grace period (owner-set), lapse state (benefits pause, never data deletion); family bundles; pro-rated upgrades.
- **Recognition:** Wall of Fame (curated), Clubman of the Month (auto-nominee list from cross-team analytics; committee picks), long-service badges (5/10/20-year member).
- **Achievements / Posts / Photos / Videos:** club trophy cabinet; social tabs as elsewhere.
- **Expenses:** club treasury per §11 patterns with dual-approval payouts; annual report auto-draft (income/expense summary shareable at AGM).

---

# 10. Ground Module

## 10.1 Ground Profile (public)
Name, verified-owner tick, photos/360 gallery, location + directions, **facilities checklist** (floodlights, washrooms, parking, pavilion, drinking water, kit rental, café — each with yes/no/paid tag), **pitch types** (turf/matting/cement/astro; count of pitches), **boundary size** (straight/square meters, badge "Big ground"/"Small ground"), surface condition self-declared + review-derived tag, rules (spikes allowed? tennis only?), pricing table by slot/day-type, cancellation policy.

## 10.2 Booking
Availability calendar (green/amber-held/red). Flow: pick slot → party size & purpose (match/practice) → price quote incl. deposits → request or instant-book (owner setting) → confirmation → booking card (QR check-in, directions, reschedule/cancel per policy). Booking auto-attaches to a match if created from match flow; ground fee auto-enters expense split. Reschedule: both parties confirm; policy-based fees shown before confirming. No-show handling: owner marks no-show (with grace 30 min) → deposit per policy + team reliability note.

## 10.3 Reviews & Ratings
Only completed-booking teams can review (verified-stay model): stars + facets (pitch, facilities, staff, value) + photos. Owner single reply per review. Report abusive review → Admin queue. Rating = weighted recent-first average; facet bars on profile.

## 10.4 Followers / Weather / Upcoming Matches
Follow a ground → new-slot alerts, price-drop alerts, records news. Weather strip (next 3 days at this ground). Upcoming public matches here listed ("Watch cricket at this ground").

## 10.5 Ground Records
Auto-maintained per ground from verified matches: highest team total, best individual score, best figures, fastest fifty. Record holder crowns + "Set at this ground" links. This is the Strava-segment analog — players chase named ground records.

## 10.6 Owner Dashboard
Occupancy % by weekpart, revenue trends, repeat-team rate, review sentiment, price-suggestion nudges ("Sat 6 AM books out in 2h — consider +10%"), payout ledger. **Maintenance:** block slots with reason (public sees "Maintenance"); recurring blocks. **Staff:** caretaker sub-accounts (check-in/no-show marking only; no pricing/finance). **Gallery:** manage photos; community photo submissions approve/feature. **Ground Expenses/Revenue:** internal cost log (mowing, rolling, staff) vs income → profit view (private).

---
# 11. Expense Module (Splitwise-inspired, cricket-native)

**Design principle:** Money should be *pre-structured by cricket context*. The app knows who played, who organized, who officiated — so splits build themselves; humans only confirm.

## 11.1 Expense Object (anatomy)
Every expense: Title · Category (below) · Amount · Currency · Paid by (one or many) · Split among (people/roles) · Split method · Context link (match/tournament/session/team/none) · Date · Receipt/proof (photo, optional but incentivized: +5 coins) · Notes · Approval state (if above team threshold) · Settlement states per participant.

## 11.2 Category behaviors (each is a first-class type, not a mere label)
- **Ground Fees:** auto-drafted from booking; default split = final squad equally; captain toggle "team wallet pays".
- **Ball Purchase:** quantity + type; suggestion engine ("You buy ~2 balls/match — add to preset?"); optional "losing team pays" rule toggle agreed pre-match by both captains.
- **Umpire Fees / Scorer Fees:** auto-drafted from assignment at agreed fee; split per match rules (both teams half-half is the cross-team default — creates a rare *inter-team* split object visible to both captains).
- **Travel:** per-vehicle sub-groups ("Rahul's car: 4 riders, ₹600 fuel → riders split; driver exempt toggle").
- **Food:** post-match chai/dinner; supports "attendees only" auto-list from check-ins; itemized mode (assign items to people) or equal.
- **Equipment / Jersey:** durable-goods flag → can amortize ("₹9,000 kit ÷ season across members; joiners mid-season pay pro-rata toggle"); jersey links to size-sheet (§6.12), per-member exact price incl. personalization.
- **Tournament (Entry fee):** team-level; split = squad or wallet; refund events auto-reverse proportionally.
- **Penalty / Fine:** captain-issued (late arrival, kit violation) per team's published fine chart (fines require the chart to exist — no ad-hoc amounts); finee gets notification + accept/contest (contest → team vote or captain-waive); collected fines default into Team Wallet earmarked "team fund".
- **Prize Money (income):** negative-expense type; distribution methods: equal / playing-XI weighted / performance-weighted (uses match points) / to wallet; every member sees distribution math.

## 11.3 Split Methods
Equal · Custom amounts · Shares/weights · Percentages · Itemized · **Role-based** (e.g., "guests pay double", "scorer exempt") · **Attendance-based** (auto from check-ins). Validation: parts must total exactly; rounding remainder assigned to payer by default (setting: rotate remainder).

## 11.4 Auto Split (the flagship)
Match creation spawns a **draft expense bundle** from the team's preset (ground+ball+officials). At match confirmation, bundle finalizes against the *final squad*: marked-unavailable players auto-excluded; last-minute replacements auto-included; MVP-exempt rule applied if team enabled it. Captain reviews one summary sheet ("₹3,400 across 12 players = ₹283.33 each; remainder ₹0.04 → payer") and taps Finalize → everyone notified with their exact share + context.

## 11.5 Collection & Contribution
Collections = planned inflows ("Season fund: ₹500 × 15 by 10 Aug"): progress bar, paid grid (avatars green/grey), auto-reminders at deadline-7/1/0, partials allowed if enabled. Contributions ledger shows lifetime per member (feeds Trust).

## 11.6 Settlement / Pending / Partial Payments
- **Who Owes Whom:** graph-simplified net ledger ("Instead of 7 payments, settle with 3") — the simplification is *suggested*, never forced; users can settle raw pairs.
- Settle flow: pick counterpart → amount (full/partial/custom) → method note (cash/UPI/other — app records the *claim*) → counterpart confirms receipt (single tap; auto-confirm 72h with reminder at 48h; declined confirmation opens a mini-dispute). Both sides' ledgers update simultaneously; settlement grants "On-time settler" streak credit if within 7 days of expense.
- Partial payments tracked per pair with running balance; **Pending** views: "I owe" / "Owed to me" tabs with age chips.

## 11.7 Receipts / Proof / Approval / Disputes
- Proof gallery per expense; zoomable; edit-locked once any settlement occurs (edits after → versioned with everyone re-notified and settlements recomputed only with all-payers consent).
- Approval: team threshold (default ₹1,000) → Captain approve before shares go live; self-created captain expenses above threshold → VC/Owner approves (no self-approval).
- Disputes: any participant disputes a line (reason mandatory) → expense freezes for that person; resolution: creator amends / creator+captain uphold (disputer may escalate to Admin after 7d). Dispute history is private to participants; chronic frivolous disputes ding Trust; upheld disputes ding creator's Trust.

## 11.8 Wallets
- **Team Wallet:** ledger of member contributions & team income (fines, prizes, sponsor cash) vs payouts; payouts above threshold need dual approval (Captain+Manager or Owner); statement view monthly; leaving members' unspent earmarked contributions handled per team policy set at wallet creation (refund / donate to team — shown to every contributor upfront).
- **Tournament Wallet:** §8.13 escrow with public categorized summary.

## 11.9 Reports / Graphs / Insights
- Monthly & yearly reports (per person / per team): total spent, by category donut, per-match average cost, cost trend line, top counterparties, settlement speed metric. Export as image/PDF-style share card.
- Insights: "Your cricket costs ₹1,140/month, 22% below team average"; "Ground fees rose 15% — 2 cheaper grounds within 4 km"; "3 members cause 80% of pending dues" (captain-only, phrased neutrally in any shared surface).

## 11.10 Reminders & Notifications
Auto-reminder cadence for a due share: T+3d gentle, T+7d firm, weekly after (payer can see the schedule; payee can send 1 manual/day). Reminder copy is polite & contextual ("₹250 for Sunday's ground vs Titans"). Payer can Snooze once/48h. All money notifications are "Money" channel (§15) — mutable separately.

**Empty/edge:** No expenses ever → explainer + "Add your first expense" with template picker. Deleting an expense with settlements → blocked; must reverse settlements first (guided). Participant leaves team → their open balances persist person-to-person (leaving never erases debt).

---

# 12. Social Module (Facebook-inspired, cricket-structured)

## 12.1 Feed
Ranked stream of: friend/teammate posts, followed teams/tournaments/grounds/players, auto match summaries, achievement cards, nearby-cricket highlights. Ranking = relationship closeness × cricket relevance × recency; **"Latest" toggle** gives pure-chronological. Inline "Why am I seeing this?" on every non-followed item. No third-party ads; sponsored-entity posts appear only to that entity's followers, labeled.

## 12.2 Posting
Composer: text (2,000 chars) · up to 10 images · video (≤3 min feed) · **attach cricket object** (match, performance line, ground, tournament, achievement — attaching renders a rich live card, e.g., a performance attachment shows verified stat chip) · feeling/activity tags · location · audience selector (Public / Followers / Teams (pick) / Only me) — audience is per-post sticky-default. Edit window: unlimited, "Edited" label with version history viewable by tapper. Delete: soft (author) with 30-day self-restore.

## 12.3 Stories & Reels
Stories: 24h, media + stickers (score sticker pulls live match score into the story and stays live!), poll/quiz stickers, viewers list, reply-via-DM, highlight-save. Reels: ≤90s vertical, cricket audio library, remix-allowed toggle, auto-suggested from match highlight clips ("Turn your 3 sixes into a reel?").

## 12.4 Live Streaming
Go-live from a match page (squad members/organizer only, so streams anchor to real matches) or profile. Live chat with slow-mode toggle, pinned comment, moderator assignment; viewers count; auto-save VOD to match gallery; report-live escalates to priority moderation.

## 12.5 Polls / Events / Groups & Communities
- Polls: 2–6 options, duration, results visibility (live/after vote/after close), audience.
- Events: cricket-y templates (screening night, trials, tournament ceremony) with RSVP, co-hosts, discussion tab, reminder cadence.
- Groups: interest communities ("North Delhi Tennis-ball Cricket") — public/private/hidden; admin/mod roles; join questions; rules pinned; post approval toggle; group events & polls; member list privacy per settings.

## 12.6 Comments / Replies / Reactions / Shares / Mentions / Tags / Hashtags
Comments (threaded 2 levels), author can pin 1 comment, delete-on-own-post rights, like counts. Reactions: 👏 (well played) ❤️ 🔥 😂 😮 🏆 — reaction totals + breakdown on tap. Shares: reshare to feed (with commentary) / story / message / external link. Mentions @user (notifies; mentionability per privacy), tag people in photos (tagged person approves before it shows on *their* profile), team-tag on match media. Hashtags → tag pages with Top/Recent.

## 12.7 Bookmarks / Saved
Save any post to private collections (folders); saved tab in profile (self-only); "saved from" context retained.

## 12.8 Graph
Follow (asymmetric) everywhere; "Friends" = mutual follow, unlocking friend-tier visibility & friend challenges. Suggested friends/players/teams rails (§4.8) with dismiss-learning. Follower management: remove follower, restrict (they see public-only without knowing).

## 12.9 Messenger
1:1 + group chats (team chat auto-provisioned per team; membership syncs with roster — leaver drops out, history retained for others). Features: text, images/video, **voice notes** (hold-to-record, slide-cancel, 2× playback), GIFs, cricket sticker packs, share any app object as rich card (expense card in chat shows live paid/pending state!), polls-in-chat, reply/quote, forward (limit 5 chats at once), typing indicator, delivered/read receipts (per-user toggle; turning off hides others' too), online/last-seen (same reciprocity), pinned chats (max 5), starred messages, per-chat mute/wallpaper/nickname, disappearing-messages toggle for 1:1. Message requests inbox for non-connections; minors receive requests only from teammates/coaches (guardian-visible).

## 12.10 Announcements / Notifications / Moderation / Privacy / Blocking / Reporting
Announcements (§6.8) render atop team chat + feed. Moderation: report flows on every object (reason tree: spam/abuse/nudity/harassment/fake score/other) → triage SLA badges ("reviewed within 24h"); repeat-offender ladder: warn → mute 24h → suspend 7d → ban (each with notice + appeal). Blocking: blocker & blocked become invisible to each other everywhere except co-membership surfaces (same team roster shows name-only, no interaction) — blocking someone on your team prompts "You share a team — captain won't be notified." Profanity auto-filter with user-level "hide offensive comments" default ON.

---

# 13. Rewards System (CRED-inspired, original economy)

**Two currencies, one ladder:**
- **XP** (permanent, never spendable) → drives **Level** (1–60, curve steepens; level ring on avatar; levels gate cosmetic perks & some marketplace tiers).
- **Coins** (spendable; expire 12 months after earning, FIFO burn; expiry warnings at 30/7 days) → redeemed in Marketplace.
**Anti-fraud gate:** all match-derived earnings release only after scorecard confirmation; anomaly checks (same 4 players "playing" daily) flag to review; coins from a match voided if match ruled fake (participants notified with appeal).

## 13.1 Earning table (canonical, Super-Admin tunable; values indicative)
| Action | Coins | XP | Notes |
|---|---|---|---|
| Play a verified match | 20 | 50 | Bench/12th: 10/25 |
| Win bonus | 10 | 20 | Team-wide |
| Fifty / Century | 25 / 75 | 60 / 150 | Per innings |
| 3W / 5W | 25 / 75 | 60 / 150 | |
| MVP | 40 | 100 | |
| Practice attendance | 8 | 15 | Cap 4/week |
| Score a match (scorer) | 30 | 60 | +10 if zero disputes |
| Umpire a match | 30 | 60 | |
| Organize a completed match | 15 | 30 | Captain bonus |
| Tournament organized (per completed match) | 10 | 20 | Organizer bonus |
| Volunteer (drinks/kit duty logged by captain) | 5 | 10 | Volunteer bonus |
| Settle expense ≤48h | 5 | 5 | On-time settler |
| Daily login | 2 | 2 | See streaks |
| Referral (referee plays 1st verified match) | 100 | 100 | Referee gets 50/50 |

## 13.2 Streaks & periodic rewards
- **Login streak:** day 7 = +20 coins, day 30 = scratch card; missing a day offers 1 "streak shield" per month (auto-applies).
- **Playing streak:** consecutive weeks with ≥1 cricket activity; milestones at 4/12/26/52 weeks (badge + chest). Injury-mode pauses streaks without breaking.
- **Daily rewards:** 3 daily missions (e.g., react to a teammate's post, respond to availability, watch 5 overs live) — small coins.
- **Weekly:** weekly chest at 5/7 mission-days. **Monthly:** performance recap chest scaled to activity tier. **Season rewards:** end-of-season tier (Bronze→Legend by season XP) with exclusive profile frames.

## 13.3 Milestones / Challenges / Badges / Achievements
- Milestones: career counters (100 matches, 1,000 runs, 100 wickets, 50 matches scored, 25 grounds visited) → permanent badges + coin chest + timeline entry + shareable card.
- Challenges: monthly global ("October: 200 runs"), club challenges, friend head-to-head (stake optional: winner takes both entry-coin stakes; capped 50 coins to keep friendly).
- Badges taxonomy: Performance · Consistency · Leadership · Service (scorer/umpire/volunteer) · Community · Collector (grounds/tournaments) · Special (founder, season-exclusive). Tiered where countable.

## 13.4 Luck layer
- **Scratch cards** (earned via streaks/chests): reveal coins (10–500 weighted low), vouchers, or "better luck" (never >2 blanks in a row per user — pity rule).
- **Spin wheel:** 1 free spin/day at Level 5+; segments = small coins, XP, scratch card, rare voucher; odds page publicly viewable (transparency rule).
- **Lucky draw:** monthly ticket per 500 coins earned (not spent) that month; prizes = partner merchandise; winners announced with entry-count disclosure.

## 13.5 Marketplace & Redemption
Catalog: **Coupons/Gift cards** (sports retail, food), **Merchandise** (app + partner kit; sized items use saved jersey size), **Partner offers** (ground-slot discounts, academy trial passes, physio sessions), **Exclusive events** (meetups, coaching clinics, local-legend matches — entry via coins, limited seats, waitlist), **Cosmetics** (profile frames, scorecard themes). Each listing: coin price, stock, level/tier requirement (if any), terms, expiry. Redemption flow: confirm → coin deduction → voucher code in "My Rewards" with copy/redeem-by date; failed fulfillment auto-refunds coins with apology bonus (+10). Fair-use: redemption caps per item per user per month.

## 13.6 Premium tier ("CricUnity Pro" — reward-adjacent)
Optional subscription: advanced analytics, unlimited highlight reels, ad-free… (n/a — no ads anyway), profile themes, priority gig-board placement for scorers/umpires, 1.25× coin multiplier (capped). **Rule:** Pro never affects rankings, Trust, or verification — competitive integrity is unbuyable.

---

# 14. Recognition System (Strava-inspired, team-sport native)

- **Activity Feed (recognition lens):** verified activities of your graph as celebration cards ("Deepak scored his 50th match as scorer") with context-rich reactions; "Give props" = cricket kudos; props received counter on profile.
- **Performance Timeline:** every player's chronological verified performances, filterable, each expandable to scorecard.
- **Achievements & Milestones:** §13.3 surfaced socially — milestone posts auto-drafted (user approves before publishing; "auto-publish milestones" opt-in).
- **Records:** three record scopes — Personal Bests (auto-tracked, celebrated privately-first with share option), **Ground Records** (§10.5, the segment analog), Tournament Records (§8.16). Record-broken flow: new holder celebration + respectful "record passed to…" notification to previous holder (with their historical entry preserved).
- **Challenges:** Monthly global (join → progress bar → finisher badge), **Club Challenges** (club-scoped, club leaderboard, e.g., "Lions January Fielding Drive"), **Friend Challenges** (1:1, same-metric, live head-to-head bar in both homes, trash-talk quick-chat stickers, result card auto-drafted).
- **Leaderboards:** scopes (Friends / Team / Club / City / Ground / Tournament / Global) × metrics (runs, wickets, MVPs, XP, attendance %, props) × windows (week/month/season/all-time). Friends scope is default (Strava lesson: local comparison motivates; global demoralizes). Minimum-activity qualifications stop one-match wonders topping averages. Self row always pinned visible with rank even off-screen.
- **Awards (periodic, auto+curated):** Consistency (played every week of month), **Fair Play** (Exemplary sportsmanship + zero conduct flags, opponent-voted), Fitness (session streaks), Attendance (Iron Player ≥95% season), Volunteer (most service actions), Community (most helpful: props given, scoring gigs, new-player onboarding). Winners announced monthly per city/club with certificate cards.
- **Performance Graphs & Comparison:** trend lines; **Compare** tool: me vs a friend/teammate side-by-side (both must have comparison enabled; comparisons of private profiles blocked); radar chart across batting/bowling/fielding/consistency/availability.
- **Heatmaps:** my grounds-played map (pins sized by matches), city cricket heatmap (public aggregate).
- **Activity Calendar & Progress Rings:** §5.12 + weekly rings (Play / Train / Contribute) with user-set targets; ring-close streaks.
- **Year in Review:** auto-generated December story-format recap: matches, runs/wickets, favorite ground, longest streak, best performance, props received, money fair-share stat ("settled 100% on time"), badges earned — swipeable, music, one-tap share; every stat card individually excludable before sharing.
- **Personal Bests:** dedicated shelf; PB detection announces in post-match summary ("New PB: best figures 4/18!").

---
# 15. Notification System

**Channels (user-mutable independently):** Matches · Money · Team · Social · Rewards · Tournaments · Bookings · Safety/Account (unmutable).
**Priorities:** P0 (push + persistent card; e.g., match starts in 1h and you're in XI), P1 (push; e.g., payment reminder), P2 (in-app badge only; e.g., new follower), P3 (digest-only; e.g., weekly ranking movement).
**Grouping:** entity-rollups ("Lions CC — 4 updates"); event-thread rollups (all pings about one match collapse to one updating card).
**Quiet hours:** user-set (default 23:00–07:00) — P1↓ held & delivered after; P0 breaks through only for same-day match logistics.
**Actions inline** wherever a decision exists; acting marks read; **Mute** ladder per type/entity (8h/1w/forever); **Reminders**: any notification long-press → "Remind me" (1h/tonight/tomorrow); **Follow-ups:** unactioned decision notifications auto-follow-up once at 24h then stop (except money cadence §11.10 and availability, which follows the captain's deadline).

**Canonical catalog (excerpt — Who / When / Priority / Actions):**

| Notification | Who | When | Pri | Inline actions |
|---|---|---|---|---|
| Availability poll | Squad | Match confirmed | P1 | Yes/No/Maybe |
| Availability deadline nearing | Non-responders | Deadline −12h | P1 | Yes/No |
| You're in the XI / benched | Selected/bench | Lineup published | P1/P2 | View |
| Match starts soon | Playing squad | −24h & −2h | P0 (−2h) | Directions, Check-in |
| Match cancelled/rescheduled | All involved | On change | P0 | View reason, Re-RSVP |
| Toss done / Innings break / Result | Followers of match | Live events | P2 | Watch |
| Wicket/fifty by followed player | Their followers | Live | P2 (batchable) | Watch |
| Scorecard confirmation needed | Both captains, scorer | Match end | P1 | Confirm, Dispute |
| Your share finalized (₹X) | Each payer | Split finalized | P1 | Pay, View |
| Payment reminder | Debtor | §11.10 cadence | P1 | Pay, Snooze |
| Payment received — confirm | Payee | Debtor marks paid | P1 | Confirm, Not received |
| Expense disputed | Creator+captain | On dispute | P1 | Review |
| Team invite / join request | Invitee / captain | On event | P1 | Accept, Decline |
| Announcement | Team members | On post | P1 | View |
| Practice reminder | RSVP'd yes | −3h | P2 | Check-in |
| Coins credited / badge earned | Earner | On grant | P2 | View, Share |
| Streak at risk | Streak holder | 20:00 if unmet | P2 | Do a mission |
| Coins expiring | Holder | −30d/−7d | P2 | Redeem |
| Level up / rank PB | User | On event | P2 | Share |
| Challenge overtaken | Trailing friend | On flip | P2 | View |
| New follower / mention / comment / props | User | On event | P2 | View/Reply |
| Message received | Recipient | On msg | P1 (P2 if muted chat) | Reply |
| Booking confirmed / slot reminder | Booker team | On confirm; −1d | P1 | QR, Directions |
| Review reply | Reviewer | On reply | P3 | View |
| Tournament fixture published/changed | Squads | On publish/change | P1 | View |
| Registration approved / waitlist promoted | Team admins | On event | P1 | View |
| Prize payout sent | Winning captain | On send | P1 | Confirm receipt |
| Record broken (yours) | Old holder | On confirm | P2 | View |
| Conduct report filed on you | Player | After review opens | P1 | Respond/Appeal |
| Account/safety alerts | User | On event | P0 | Review |

**Examples:** *"🏏 Sunday 7 AM vs Titans — are you in? [Yes] [No] [Maybe]"* · *"₹283 finalized for yesterday's match (ground+ball+umpire). [Pay] [Details]"* · *"🔥 Deepak just passed you in the January runs challenge — 12 behind. [View]"*.

---

# 16. Search

- **Global Search (top bar / launcher):** single field; results grouped by type (Players, Teams, Tournaments, Grounds, Clubs, Posts, Groups) with "See all {type}"; typo-tolerant; respects privacy (private profiles show minimal card; blocked users never appear).
- **Zero-state:** Recent searches (removable, "clear all"), **Suggestions** (people you may know, your grounds), **Trending** in your city (tournaments, hashtags).
- **Advanced Search:** filter sheet per type —
 · **Player:** role, batting/bowling style, city+radius, age band, rating range, Trust band, "free agent", availability day.
 · **Team:** city, format, recruiting-now, activity level, follower count.
 · **Tournament:** city, dates, format, ball, entry fee range, registration open, organizer score.
 · **Ground:** distance, price range, pitch type, facilities (multi), rating, available-on {date/slot}.
 · **Club:** city, membership open, teams count.
 · **Post:** by author, tag, hashtag, attached-object type, date.
 · **Expense (scoped inside module):** counterparty, category, amount range, status, date, has-receipt.
 · **Message (scoped inside chat/messenger):** keyword, sender, chat, media-only.
- **Voice Search:** mic in field; language auto-detect (supports vernacular); transcription shown editable before executing.
- **QR Search:** camera icon → scan any CricUnity QR (profile/team/ground/match/tournament) → jump straight to object; also reads booking check-in QRs.
- Search analytics feed suggestions ("People also searched"). Result actions inline: Follow, Message, Book, Register.

---

# 17. Privacy

**Model:** every surface has an audience dial (Everyone → Members → Followers → Teammates/Friends → Only me), sensible defaults per sensitivity, previews to verify, and *minors get locked-stricter defaults*.

| Surface | Default | Options / rules |
|---|---|---|
| Profile discoverability | Everyone | §5.20 presets |
| Posts | Followers | Per-post override; audience shown on post |
| Photos/videos & tags | Followers | Tag-approval ON by default |
| Followers list | Followers | Everyone/Followers/Only me |
| Messages — who can DM | Friends+Teammates | +Followers/Everyone(requests)/Nobody |
| Expenses & wallet | Participants only | Never public, ever (hard rule) |
| Payment activity | Counterparties | Hard rule |
| Statistics | Everyone (verified only) | Community/Followers/Only me; ranked players' *ranking stats* stay public (fairness rule; opting stats fully private removes you from public leaderboards) |
| Match history | Everyone | Follows stats setting; private matches always hidden |
| Team membership | Everyone | Hide specific teams (except within tournaments you're registered in — organizers/opponents must see eligibility) |
| Tournament history | Everyone | Follows match history |
| Online status / last seen | Friends | Reciprocity: hide = can't see others' |
| Activity calendar detail | Density public, detail Friends | §5.12 |
| Read receipts | On | Reciprocity rule |
| Comparison opt-in | On (adults) | Off = nobody can pull you into compare |

- **Blocking:** §12.10 semantics; block list manageable in settings; blocking severs follows both ways and hides all past interactions from each other.
- **Reporting:** every object; status tracker for your reports ("Reviewed — action taken"); false-report abuse ladder.
- **Verification:** blue-tick verification for notable figures/organizations (document-based, Admin-reviewed); **green verified-record tick** for Ground/Academy listings (ownership proof); scorer/umpire credential badges are activity-earned (§2.6) — three visually distinct marks.
- **Data controls:** view/download my data summary; deactivate (profile hidden, stats preserved in opponents' verified records as "Deactivated player" — competitive-integrity rule disclosed at signup); delete account (30-day grace; personal content removed; verified scorecard *lines* persist anonymized, since a match's opponents own the shared record too).
- **Guardian layer:** minors → guardian link mandatory; guardian sees followers/messages surface, approves media tagging, receives coach notes.

---

# 18. Gamification (system-of-record for §13/§14 mechanics)

- **XP sources & curve:** table §13.1; Level N requires 100×N^1.35 cumulative XP (tunable). No XP loss ever (positive-only philosophy).
- **Levels → perks:** L5 spin wheel; L10 profile frames; L15 custom scorecard theme; L20 "Veteran" title track; L30 marketplace tier-2; L45 exclusive-event access priority; L60 "Immortal" cosmetic set.
- **Badges:** taxonomy §13.3; each badge page shows earn criteria, rarity % ("held by 2.1% of players"), holders you know.
- **Titles:** equipable single title next to name (earned: "Streak Master", "Iron Player", "Guardian of the Ground" for record holders; seasonal titles expire with a collector's archive).
- **Ranks:** competitive percentile bands per city+format+discipline (Bronze→Silver→Gold→Platinum→Elite); soft decay for 60-day inactivity (bands only, historical peaks preserved); rank ≠ level (rank = skill, level = journey) — explained in-product.
- **Missions:** Daily (3, rotate at midnight local), Weekly (3, one social/one playing/one service), Monthly (2 bigger), Season (1 epic, e.g., "Play at 5 different grounds"). Mission board with progress, claim buttons, refresh-one-daily token. All missions completable by non-batters (role-fair design rule: scorer/umpire/fan variants exist).
- **Leaderboards:** §14 scopes; anti-gaming: only verified activity counts; leaderboard-eligible matches require ≥2 distinct teams and ≥12 distinct verified participants.
- **Challenges & Rewards & Recognition:** cross-referenced §13/§14 — Gamification is the *engine*; Rewards is the *economy*; Recognition is the *social display*.

---

# 19. Analytics

Each analytics surface: time filters (match/month/season/career), compare-to (self past, team avg, city avg), export share-card, and an **Insights strip** (plain-language findings) + **Recommendations strip** (next best actions). Data source: verified activity only; unverified shown only to self with toggle.

- **Player Analytics:** batting (phase-wise SR, dismissal patterns, vs pace/spin, entry-point analysis), bowling (phase economy, lengths proxy via outcome mix, vs LHB/RHB), fielding contributions, form index, fatigue signal (games/week), availability-vs-performance correlation. *Rec:* "You average 41 opening vs 18 at #4 — discuss role with captain."
- **Captain Analytics:** toss decisions vs outcomes, bowling-change impact index, selection stability, win % by lineup cluster, availability-response health of squad. *Rec:* "Teams you chase against: 71% wins — consider bowling first."
- **Team Analytics:** §6.17 + margin distributions, collapse frequency, ground-wise record, chemistry trend.
- **Tournament Analytics (organizer):** registration funnel, fixture on-time %, avg match duration, dispute rate, viewer engagement per match, payout speed.
- **Ground Analytics (owner):** §10.6 occupancy, revenue, demand curve, review facets.
- **Expense Analytics:** §11.9.
- **Social Analytics:** post reach/engagement by content type, follower growth, best posting windows.
- **Rewards Analytics (self):** coins earned/spent/expiring, mission completion rate. (Platform-level economy analytics: Super Admin.)
- **Attendance Analytics:** individual & team trends, no-show patterns by weekday/venue distance ("no-shows spike when ground >15 km — pick closer grounds?").
- **Engagement/Growth (Admin & entity owners):** DAU-style entity metrics for teams/clubs/tournaments (follower growth, active member %).

---

# 20. Complete Screen List

*(Format: Screen — Purpose | Primary / Secondary actions | Key components | Permissions | States & edge cases. Navigation is per §3 unless noted.)*

**A. Onboarding & Identity**
1. **Splash/Welcome** — value carousel | Continue / Explore as guest | brand, 3 slides | all | offline: cached slides.
2. **Registration** — create account | Continue | phone/email step, OTP, name | guest | errors: invalid OTP (3 retries → cooldown), existing account → login suggest.
3. **Role & Interest Picker** — tailor experience | "I play / I'm a fan / I run things" multiselect | chips | new users | skippable (defaults Fan).
4. **Profile Setup Wizard** — completeness | Save & continue / Skip | photo, city, playing info | owner | each skip lowers completeness meter; minors → guardian-link step (blocking).
5. **Permissions Primer** — explain location/notification asks | Allow / Later | rationale cards | all | denial fallbacks defined per feature.

**B. Core**
6. **Home Dashboard** — §4 | widget actions | widgets | logged-in | new-user checklist state; offline stamps.
7. **Notification Center** — §3.7 | inline decisions / mark read | tabs, groups | logged-in | empty: "All caught up 🎉".
8. **Global Search & Results** — §16 | open result / follow / filter | grouped lists | all (guest read-only) | no-results: spelling suggestion + broaden-radius offer.
9. **QR Scanner** — jump-to-object & check-ins | scan | viewfinder, torch | logged-in | invalid code error; expired invite state.
10. **Create Sheet** — §3.4 | pick action | role-aware grid | logged-in | —

**C. Profile & Identity**
11. **My Profile / Public Profile** — §5 | edit (self) / follow, message, invite (other) | header, tabs | viewer-relative | private-profile limited card; blocked = unavailable.
12. **Edit Profile** — maintain identity | save | field groups, validation | self | unsaved-changes guard.
13. **Achievements/Badge Wall** — trophy room | share badge | grid, rarity | per privacy | empty: nearest-badge suggestions.
14. **Activity Calendar** — §5.12 | day peek | heat grid | per privacy | —
15. **Year in Review** — §14 | share / exclude cards | story player | self (share=choice) | <5 activities: "light year" variant.
16. **Wallet & Coins** — balance & ledger | redeem / earn | balance, history, expiring strip | self | zero-state explainer.
17. **Rewards Marketplace / Listing Detail / My Rewards** — §13.5 | redeem / copy code | catalog, filters, terms | level-gated items visibly locked | out-of-stock, expired-voucher states.
18. **Missions Board** — §18 | claim / refresh-one | daily/weekly/monthly tabs | logged-in | all-claimed state.
19. **Settings hub (+ Privacy, Notifications, Blocked list, Language, Help)** — control center | toggle/save | per §15/§17 | self | safety channel toggles disabled-with-explainer.

**D. Team**
20. **My Teams** — switcher | open / create | team cards with role chips | member | empty: create/join CTAs.
21. **Team Home (public & member views)** — §6 | follow / post / open consoles | header, tabs (Feed, Matches, Members, Media, Stats, Money*, Settings*) *=member/role-gated | viewer-relative | archived team = read-only banner.
22. **Create/Edit Team** — §6.1–6.2 | save | wizard | owner/captain | name-taken suggestions.
23. **Members & Roles** — roster governance | invite / approve / change role / remove | list, permission matrix link | captain+ | removal reason modal; last-admin guard.
24. **Availability Matrix** — §6.11 | nudge / lock squad | grid | captain/VC | all-pending state.
25. **Selection Board & Lineup** — §7.3–7.5 | publish / lock | drag lists, balance meter | captain/VC | replacement flow post-lock.
26. **Practice Session (create/detail)** — §6.9 | RSVP / check-in / roll-call | details, attendee grid | members; create=capt/VC/mgr | past-session read-only.
27. **Team Treasury** — §6.14–6.16 | approve / add expense / statements | wallet, ledgers, collections | all-see, role-gated actions | dual-approval pending state.
28. **Jersey Board** — §6.12 | submit size / manage order | design, size sheet, tracker | members / mgr | number-conflict resolver.
29. **Recruitment Board** — §6.25 | post need / apply / manage pipeline | listings, pipeline | captains / free agents | expired-listing state.
30. **Season Summary / Awards Ceremony mode** — §6.29 | present / share | wrap cards | members | insufficient-data variant.

**E. Match**
31. **My Matches** — hub | open / filter | Upcoming/Live/Recent tabs | member | empty per tab.
32. **Create Match wizard** — §7.1 | send to opponent | steps | captain/VC (+mgr if enabled) | draft-saved state.
33. **Match Detail (pre-live)** — logistics | RSVP / directions / edit* | info, availability, expense preview | squad+viewers per visibility | cancelled state w/ reason.
34. **Toss** — §7.6 | flip / record | animation, result | captains | manual-entry fallback.
35. **Live Scoring Console** — §7.7 | ball entry / undo / interrupt | pad, strips | assigned scorer | offline banner; handover-scorer flow (both captains approve).
36. **Live Match View (spectator)** — follow live | react / predict (fans) / open tabs | score header, commentary, wagon, partnerships, worm, timeline | per visibility | delayed-data stamp.
37. **Scorecard (final)** — canonical record | confirm / dispute / share | innings cards, ✔ stamps | confirm=captains+scorer | disputed banner.
38. **Match Gallery & Highlights** — §7.15 | upload / pin-to-ball / publish reel | grid, reel builder | squad upload; captain curate | processing state.
39. **Post-Match Summary & Insights** — §7.18–7.19 | share / rate players / pick MVP | result card, insights, rating sheet | role-gated | ratings-window-closed state.
40. **Match Expense Sheet** — §7.17 | finalize / pay | split summary, paid grid | captain finalize; payers pay | pre-finalize draft state.

**F. Tournament**
41. **Discover Tournaments** — find & register | filter / open | cards w/ fee, dates, organizer score | all | none-nearby → widen.
42. **Tournament Home (public)** — follow & track | follow / register / tabs (Fixtures, Table, Stats, Media, Info) | header, sponsor strip | all | pre-fixture "coming soon" states.
43. **Organizer Console** — run event | manage registrations / fixtures / wallet / officials / awards | dashboards | organizer(+staff roles) | dispute-queue state.
44. **Registration Flow** — §8.2 | submit squad & pay | squad picker, fee, rules ack | team captain/owner | waitlist state; eligibility-flag blockers.
45. **Fixture / Bracket views** — schedule clarity | add-to-calendar / open match | list+bracket toggle, my-team filter | all | TBD-slots state.
46. **Points Table** — standings | tap-NRR explain | table w/ movement arrows | all | adjusted-entry badges.
47. **Auction Room** — §8.7 | bid / pass | lot card, purses, timer | team bidders; spectators read-only | connection-lost re-entry grace.
48. **Tournament Wallet & Payouts** — §8.13 | record lines / send payout | ledger, payout tracker | organizer; captains summary-view | unconfirmed-payout flag.

**G. Ground / Club / Academy**
49. **Ground Discovery (map+list)** — find grounds | filter / open | map pins, cards | all | location-off fallback (city picker).
50. **Ground Profile** — §10.1 | book / follow / review* | gallery, facilities, calendar, records | all; review=verified bookers | fully-booked state.
51. **Booking Flow & My Bookings** — §10.2 | select slot / pay context / manage | calendar, quote, policy, booking cards w/ QR | logged-in | held-slot timer; reschedule flow.
52. **Ground Owner Console** — §10.6 | accept / block / price / staff | dashboards, calendar admin | owner+staff scopes | verification-pending banner.
53. **Club Home & Club Console** — §9 | join / renew / admin tabs | dashboard tiles, members, treasury | viewer-relative; console=owner/admins | dues-lapsed member state.
54. **Academy Home & Console** — §2.10 | enroll / trials / batches / fees / progress | rosters, schedules, ledgers | owner/coaches; guardians see child scope | consent-pending blockers.
55. **Coach Console** — §2.8 | plan session / assign drills / notes | student rings, planner | coach | student-consent-off masking.

**H. Money**
56. **Expenses Home** — §11 | add / settle / filter | I-owe / Owed-to-me / All tabs, net header | participants | all-square celebration.
57. **Add/Edit Expense** — capture spend | save (+approval if needed) | category picker (behavior-aware forms), split editor, proof | role rules §11 | validation errors (split≠total).
58. **Expense Detail** — single source of truth | pay / remind / dispute / view proof | line breakdown, per-person states, activity log | participants | frozen-in-dispute state.
59. **Settle Up** — §11.6 | confirm settlement | counterparty picker, simplify suggestion, amount | pair | awaiting-confirmation state.
60. **Reports & Insights** — §11.9 | change period / export | charts, insight cards | self/team-scope | insufficient-data.

**I. Social**
61. **Feed** — §12.1 | react / comment / share / compose | ranked stream, Latest toggle | logged-in | caught-up interstitial.
62. **Composer (post/story/reel/poll/live)** — create | publish | media tools, object-attach, audience | per role rules | draft autosave; upload-retry.
63. **Post Detail / Comments** — discussion | comment / react / moderate* | thread | per audience | deleted-post tombstone.
64. **Stories Viewer** — ephemeral | reply / react / skip | tap-nav, stickers | per audience | expired story gone.
65. **Reels Player** — vertical video | like / share / remix | swipe feed | per audience | sensitive-content interstitial when flagged.
66. **Groups (list/home/manage)** — §12.5 | join / post / mod tools | rules, approvals | per group privacy | join-question pending.
67. **Events (list/detail/create)** — §12.5 | RSVP / ticket / discuss | details, attendee list | per audience | sold-out; cancelled.
68. **Messenger (list/thread/new/requests)** — §12.9 | send / react / share object | rich cards, voice notes | connections per settings | request-inbox; blocked-thread lock.
69. **Hashtag / Explore pages** — discovery | follow tag | Top/Recent | all | low-content state.

**J. Officials & Gigs**
70. **Gig Board (scorer/umpire)** — find paid work | accept / set radius & fee | gig cards w/ distance, fee, teams' Trust | credentialed roles | no-gigs state.
71. **Scorer/Umpire Console & Earnings** — §2.6–2.7 | manage assignments / ledger | calendar, ratings, dispute inbox | role-holder | rating-appeal state.

**K. Leaderboards & Recognition**
72. **Leaderboards Hub** — §14 | switch scope/metric/window | pinned self-row | logged-in | unranked → qualification progress.
73. **Challenges Hub / Challenge Detail** — join & track | join / nudge / claim | progress bars, H2H view | logged-in | ended-challenge archive.
74. **Records pages (Ground/Tournament/PB)** — motivation | view holder / attempt-context | record lists w/ provenance | all | vacant-record "Be the first".

**L. Sponsor & Admin**
75. **Sponsor Marketplace & Campaign Dashboard** — §2.15 | make offer / track | listings, metrics | sponsor role | offer-declined state.
76. **Moderation & Admin Consoles** — trust & safety | act on queues | report queues, audit logs, dispute tools | Admin/Super Admin | SLA-breach flags.
77. **Report Flow (modal)** — user safety | submit report | reason tree, evidence attach | all | duplicate-report merge notice.

**Global cross-cutting states (apply to every screen):** Loading (skeletons, never blank), Empty (guidance + primary CTA), Error (plain-language + retry + "report a problem"), Offline (cached data + freshness stamp; queue-safe actions queue with visible pending pill; money & irreversible actions never queue), Success (confirmation with next-step suggestion), Permission-denied (explains *why* + path to gain access, e.g., "Only captains can lock lineups — ask Arjun").

---

# Appendix A. Acceptance Criteria Pattern (applied per feature)

Every feature above is testable via this template — example for **Auto Split (§11.4)**:
- Given a confirmed match with 12 final squad members and preset expenses totaling ₹3,400, when the captain finalizes, then 12 shares of ₹283.33 are created, remainder ₹0.04 assigns to payer, and 12 P1 notifications with inline Pay are sent within the same session.
- Given a selected player marked Unavailable before lock, when the bundle finalizes, then they receive no share and appear in the "excluded (unavailable)" list on the sheet.
- Given the team's MVP-exempt rule is ON and an MVP exists, then MVP's share = 0 and the difference redistributes equally with the sheet showing the rule chip.
- Given the match is later ruled fake, then all shares void, settlements reverse-request, and coins claw back with user notifications and appeal links.

# Appendix B. Cross-Module Interaction Map (summary)

Match → Stats, Rankings, Expenses, Coins/XP, Attendance, Achievements, Records, Feed, Trust, Insights.
Expense settlement → Trust, On-time-settler streak, Coins, Notifications.
Practice attendance → Attendance %, Fitness rings, Coins, Chemistry.
Scoring/Umpiring gig → Earnings, Credential tier, Match expense line, Service badges.
Booking → Match expense, Ground revenue, Reviews eligibility, Ground records exposure.
Tournament result → Team achievements, Player awards, Records, Organizer Score, Prize distribution (expense income).
Social props/fair-play votes → Sportsmanship, Community awards.
Referral → Coins both sides upon referee's first verified match.

— End of PRD v1.0 —
