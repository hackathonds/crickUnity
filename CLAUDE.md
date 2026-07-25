# CricUnity — Claude Code project memory

Mobile app for grassroots cricket: matches, verified scorecards, expense
splitting, rewards, social. We build strictly from three frozen documents.

## Source of truth (read these, never re-invent)

- `docs/CricUnity_PRD.md` — behavior and business rules (cited as PRD §x)
- `docs/CricUnity_Design_Spec.md` — visuals, motion, pixels (cited as DS §x)
- `docs/CricUnity_Backlog.md` — the stories we implement (E0-01 … E18-07)
- `docs/CricUnity_Backlog.csv` — story index with sizes and dependencies

Where the backlog summarizes, the cited PRD/DS sections win. If a detail is
genuinely absent from both documents, STOP and list the open question in the
PR description — never guess behavior.

## Stack and commands

<!-- FILL IN after the stack decision. Keep this section at the top of your
     attention: exact commands, no prose. Example shape:
Stack: Flutter 3.x, Riverpod, go_router
Run:    flutter run -d <device>
Test:   flutter test
Lint:   flutter analyze
Format: dart format .
Screenshot for evidence: <your command / MCP tool>
-->

## Non-negotiables (from Backlog Section 0)

1. Design tokens only. Raw hex, off-scale spacing (not 4/8/12/16/20/24/32/40/48),
   or non-token radius/elevation in a component is a defect, not a style choice.
2. Every UI story ships all seven states: Default, Empty, Loading (skeleton
   mirroring layout), Error (cause + retry + preserved input), Offline
   (freshness stamp; money actions disabled), Permission-denied, Success.
   States are in-scope of the story, never a follow-up ticket.
3. Tabular numerals on every mutable/aligned number (scores, money, stats).
4. Reserved colors: `live` red, `coin` amber, `verified` teal are semantic
   only — never decorative. Identical across all five themes.
5. Touch targets ≥ 44px. Primary actions in the bottom 40% of the screen.
6. Reduced-motion parity: nothing is information-only-in-motion.
7. Money surfaces: calm, bordered, no gamification color, no celebration
   animation over a financial decision (DS Pillar 4, DS §5.8 suppression).
8. Verified data renders visually distinct from unverified (DS Pillar 2).
9. Reward/XP releases only after scorecard confirmation (PRD §13 fraud gate).
10. Roles are activity-inferred. Never build a "choose your role" UI (PRD §2).

## Workflow

- One story per session. Build in epic order E0 → E18 honoring the
  dependency column; XL stories: enumerate your sub-task split in the PR
  before writing code.
- Plan first: research the cited PRD/DS sections, propose the plan, wait
  for approval, then implement.
- Evidence over assertion: PR must include test output and per-state
  screenshots (light Theme 1 + dark Theme 4, 375w and 320w).
- Branch `story/E0-01-design-tokens`; commit messages start with the story ID.
- Definition of Done lives in `docs/CricUnity_Backlog.md` Section 0 — read it
  at the start of every story.

## Lazy-loaded detail (do not inline here)

- `.claude/rules/design-system.md` — token tables, type ramp, motion values
  (loads for UI work)
- `docs/STORY_TEMPLATE.md` — the prompt wrapper for handing a story to a session

## When compacting

Always preserve: the current story ID, the list of modified files, open
questions raised, and the exact test/screenshot commands.
