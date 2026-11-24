# shipcrew plugin

A crew of independent agents for building apps: one builds, another tests the running app, and every confirmed miss becomes a check.

## Contents

- `skills/setup`: once per project, writes `.claude/skills/verify-<project>/` in the repo.
- `skills/ship`: runs a change through build, independent test and learn.
- `skills/qa`: what the tester follows. Also usable on its own.
- `skills/learn`: turns confirmed mistakes into checks and keeps `docs/agent-rules.md`.
- `agents/tester`: the independent tester, with fresh context and no edit tools. `ship` checks the checkout is unchanged after it reports.

Install and usage are in the [repository README](../../README.md).
