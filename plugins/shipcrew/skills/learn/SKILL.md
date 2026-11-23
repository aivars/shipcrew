---
name: learn
description: Turn confirmed mistakes into checks so they cannot come back, and keep the repo's rule table. Use after QA findings, after the user corrects you, or for "learn from this", "make sure this never happens again".
---

# Learn

A mistake that was caught once will be made again by the next agent, which sees only the files it opens and copies the nearest example. Change the repo so the mistake fails on its own.

## Input

The kept findings from a `ship` run, a correction the user just gave, or a look back: recent reverts, fix commits, review files and the notes in the agent instruction file that explain a workaround. Group them into classes. A one-off stays a one-off; a class has happened twice or would be expensive once.

## Fix each class at the highest level that works

1. **Make it impossible.** One owner for the state, one supported way to do the task, the wrong path removed: a type that cannot hold the bad value, a constructor that is the only way in, private access on what should not be reached.
2. **Make it fail the build or lint.** A custom lint rule (SwiftLint, ESLint, Ruff, whatever the repo runs) or a stricter compiler setting. The message names what to use instead.
3. **Make a test fail.** Two kinds earn their keep. A rule test on pure logic. A guard test that scans the source for the pattern and lists each allowed exception with its reason, so a new case fails until someone decides.
4. **Write it down.** Only for judgment calls nothing can check. One line, in the rule table.

Prove each new check: it must fail on the real mistake (restore the bad code, watch it fail, put the fix back). A check that never failed is not a check.

## The rule table

Keep `docs/agent-rules.md` in the repo: one row per rule.

| Rule | Enforced by | Since | Why |
|---|---|---|---|

- "Enforced by" names a test, a lint rule or a type. "prose" means nothing enforces it; those rows are the backlog.
- When a prose rule is broken again, move it up a level in the same change.
- Delete a row once the mistake cannot happen at all.

Point the agent instruction file at the table in one line. Do not copy the rules into it: a status log that grows with every session is read by every future session and trusted by none.

## Reply

Each class with its evidence, the level chosen, why a higher level did not work, and proof the check fails on the mistake. Then the rows added, moved and removed.
