---
name: ship
description: Take a change from request to proven. One agent builds, an independent agent tests the real running app, and each confirmed miss becomes a check. Use for "ship this", "build this and test it", "run the crew on this", or any change that touches a screen, a flow or stored data.
---

# Ship

One agent builds. A different agent tests the real thing without seeing the builder's reasoning. A finding counts only with evidence from a run. Each confirmed miss ends as a check, so the crew gets better with every change.

You are the builder and you run the loop. The tester is always someone else.

## 0. Before the first run in a repo

The repo needs a verify skill: `.claude/skills/verify-<project>/`. If there is none, run the `setup` skill first. Without a scripted way to run the real thing there is nothing for a tester to run.

Read the roles file if one exists: `.shipcrew/roles.md` in the repo, else `~/.config/shipcrew/roles.md`. It names the model for each role. `references/roles-example.md` shows the format and the defaults.

## 1. Brief

Write the brief before any code. Show it to the user when the request left a choice open; otherwise go on.

- **Done means:** one sentence a tester can check on the running product.
- **Feature:** its name in the verify skill's feature map.
- **States to check:** the ones this change can break. Pick from: dark mode, the largest text size, empty data, too much data, a second item, a small screen, offline, a slow network, a logged-out user.
- **Out of reach:** what the verify skill cannot show (a real device, other apps, payments, push).
- **Risk:** `normal`, or `high` for stored data and migrations, purchases, auth, privacy, sync, or anything a user cannot undo.

## 2. Build

Make the change on its own branch or worktree. If the brief needs a state the product cannot be put into by script, add that hook and its entry in the feature map as part of the change.

## 3. Fast checks

Run what the repo already has, in this order, and stop at the first failure: build, types, lint, the tests for the files you touched. Fix and rerun. Nobody tests code that does not build.

## 4. Run it yourself

Drive the changed state with the verify skill and look at the evidence. If "done means" is not visibly true, go back to step 2. A tester's time is for what you could not see, not for what one run would have shown you.

## 5. Independent test

Hand the tester four things: the brief, the diff range, the path to the repo's verify skill, and the absolute path to this plugin's `skills/qa/SKILL.md` (next to this skill's folder). Do not send your plan, your reasoning, or your own summary of the change.

- **On T3 Code** (the `delegate_task` tool exists): start one child on the `tester` role's model, on a different provider than yours. Its task tells it to read the `qa` file first and follow it. A child on another provider cannot load a skill by name; it can read the file.
- **In Claude Code:** start the plugin's `tester` agent. It starts with none of this session's context.
- **Risk `high`:** add a second tester on the `second-opinion` role when the roles file has one. Otherwise say in the report that one model tested it.

The tester never edits the code. It returns findings, each with the command it ran and what the run showed.

## 6. Fix rounds

For each finding, rerun its command yourself. Keep it when the output shows the failure and the failure breaks "done means". Drop the rest and say why.

Fix the kept findings, rerun steps 3 and 4, and send the tester only the new diff and the findings to recheck. Three rounds at most. If round three still has a kept finding, stop and take it to the user with the evidence: three rounds of patches usually mean the design is wrong, and a fourth patch will not fix that.

## 7. Report

Lead with the verdict. Then:

- **Verified:** each state checked, with the path to its screenshot, log or test output, and the build it came from.
- **Not verified:** everything in "Out of reach", plus anything skipped, each with what would verify it.
- **Findings:** kept and fixed, kept and open, dropped with the reason.
- **Who did what:** the model that built and the models that tested.

Never say "done" for a state nobody ran.

## 8. Learn

Every kept finding is a mistake the builder made. Run the `learn` skill on them before closing: a finding that could come back gets a check, so the next tester does not have to find it again.
