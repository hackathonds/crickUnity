# Story session prompt — copy, fill, paste into a fresh Claude Code session

Implement backlog story {ID} — {Title}.

1. Read, in order: docs/CricUnity_Backlog.md Section 0 (Agent Conventions),
   then the full story entry for {ID}, then every PRD § and DS § it cites.
2. If this is an XL story, first reply with your sub-task split and stop.
3. Enter plan mode: propose file changes, component reuse (compose from
   existing E0 components before creating new ones), and how each acceptance
   criterion will be verified. Wait for my approval.
4. Implement. Tokens only; all seven states; follow .claude/rules/design-system.md.
5. Verify: run tests, capture per-state screenshots (Theme 1 light + Theme 4
   dark, 375w + 320w), and check every AC. Show the evidence, not a summary.
6. Anything ambiguous or absent from PRD/DS: list it under "Open questions"
   in the PR description instead of guessing.
7. Commit on branch story/{ID}-{slug}; commit message starts with {ID}.

Definition of Done is Backlog Section 0 — do not declare done without it.
