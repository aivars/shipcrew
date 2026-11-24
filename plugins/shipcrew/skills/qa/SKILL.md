---
name: qa
description: Test someone else's change on the real running product and report only what a run proves. Use when handed a brief and a diff to test, or for "QA this", "test this change", "try to break this".
---

# QA

You did not write this change. Your job is to find where it fails to do what the brief says, on the real running product. You report. You do not fix.

## Rules

- **Run it.** Read the diff to decide where to look, then drive the product with the repo's verify skill (`.claude/skills/verify-<project>/SKILL.md`). A finding from reading alone is a guess; leave it out.
- **Evidence or nothing.** Each finding carries the exact command, what it produced (a screenshot you looked at, a log line, a response body, a failing test), and what the brief requires in its place.
- **Change nothing in the checkout.** No fixes, no refactors, no formatting. A failing test or a repro script may be the evidence; put it outside the repo or in the verify skill's evidence folder. The builder compares the checkout's `state` before and after you, and any change voids the run.
- **Stay on the brief.** Style, naming, structure and "this could break later" are out. A real bug outside the brief goes in a separate list.
- **No findings is a valid result.** Do not pad.

## Steps

1. Read the brief: "done means", the states to check, what is out of reach.
2. Run the verify skill's doctor. If the build is stale or missing, build first. Evidence from another build is worthless.
3. Check "done means" in its plain state. If that fails, report it and stop: nothing else matters yet.
4. Check each state the brief lists. Then try what the builder likely did not: the neighbouring screen or endpoint that shares the changed code, the same one with no data, with too much data, at the largest text size, in the other appearance, on a small screen.
5. Open every piece of evidence you cite and look at it. Compare it with the feature map's "proof it works" line.
6. For logic nothing displays, run the tests for the changed files. A test that still passes with the change reverted proves nothing: say so.

## Report

- **Verdict:** pass, or fail with the count of findings.
- **Findings:** for each, a title, the command, the evidence path, what it shows, what the brief requires.
- **Checked and fine:** each state with its evidence path.
- **Not checked:** what you could not run and why.
- **Outside the brief:** real bugs seen on the way, with evidence.
- **Build:** the stamp the evidence came from.
