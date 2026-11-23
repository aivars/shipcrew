# shipcrew

A crew of independent agents for building apps, as a plugin for Claude Code and [T3 Code](https://github.com/pingdotgg/t3code).

One agent builds the change. A different agent, ideally a different model, tests the real running app without seeing the builder's reasoning. Every confirmed miss becomes a check in your repo, so the same mistake cannot come back.

## Install

Works from any folder. Do the steps in order, and **paste one command at a time**, pressing Enter after each. Pasting both together breaks it.

**Step 1.** Add the marketplace. Paste this, press Enter:

```
/plugin marketplace add aivars/shipcrew
```

If a box titled "Add marketplace" opens and asks for a source, type only `aivars/shipcrew` and press Enter.

**Step 2.** Install the plugin. Paste this, press Enter:

```
/plugin install shipcrew@shipcrew
```

**Step 3.** Load it. Paste this, press Enter (or restart Claude Code):

```
/reload-plugins
```

**Step 4.** Check it worked. Type `/shipcrew:` and you should see `setup`, `ship`, `qa` and `learn` in the list.

Prefer menus? Run `/plugin`, add `aivars/shipcrew` as a marketplace, then pick **shipcrew** from the Discover tab.

### First use

Open Claude Code inside the project you want to build in, then run:

```
/shipcrew:setup
```

That is the only setup step. It reads your repo, writes a script that runs your real app and keeps evidence, maps your main features, and proves the script works before it hands back.

After that:

```
/shipcrew:ship add a dark mode toggle to settings
```

### If something goes wrong

- **"not a valid GitHub owner/repo shorthand":** two commands got pasted into one box. Clear it, type only `aivars/shipcrew`, and run the install command separately.
- **`/shipcrew:` shows nothing:** run `/reload-plugins` or restart Claude Code.
- **Update later:** `/plugin marketplace update shipcrew`.

## The loop

1. **Brief.** One sentence saying what done looks like, and the states that could break.
2. **Build.** The builder makes the change.
3. **Fast checks.** Build, types, lint, the tests for the touched files.
4. **Run it yourself.** The builder runs the real thing and looks at the result.
5. **Independent test.** A second agent gets the brief and the diff, not the builder's reasoning. It runs the app and reports. It never fixes.
6. **Fix rounds.** Three at most, then it goes to you.
7. **Report.** What was verified, with evidence and the build it came from, and what was not.
8. **Learn.** Each kept finding becomes a type, a lint rule or a test. A written rule is the last resort.

## What is in it

| Piece | Use |
|---|---|
| `/shipcrew:setup` | Once per project. Writes `.claude/skills/verify-<project>/` in your repo. |
| `/shipcrew:ship` | Run a change through the loop. |
| `/shipcrew:qa` | What the tester follows. Also usable on its own on any change. |
| `/shipcrew:learn` | Turn mistakes into checks and keep `docs/agent-rules.md`. |
| `tester` agent | The independent tester in plain Claude Code: fresh context, cannot edit files. |

Everything it writes into your repo is plain files you own: a shell script, Markdown, and a rule table. Nothing runs in the background, and no hook changes your other sessions.

## Models

With Claude Code alone, the tester is a fresh subagent with none of the builder's context.

In T3 Code the tester runs on another provider, since models from different makers miss different things. Copy [`roles-example.md`](plugins/shipcrew/skills/ship/references/roles-example.md) to `~/.config/shipcrew/roles.md` to choose who builds, who tests, and who gives a second opinion on risky changes.

## Platforms

| Surface | State |
|---|---|
| iOS app (simulator, launch arguments) | Proven on a shipping app. Script included. |
| Web app | Draft recipe. No script yet. |
| CLI or server | Draft recipe. No script yet. |
| Android, macOS, others | Not written. |

## Status

0.2.0, early. The iOS verification script has been run end to end on one shipping app. The full loop, with a second model as tester, has not yet been run on a real change. Expect rough edges and tell me about them.

## Contributing

Issues and pull requests are welcome, most of all recipes for platforms you have actually run. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Credits

The ideas come from Lauren Tan's [pstack](https://github.com/cursor/plugins/tree/main/pstack) and her talk "All Code Is Slop (Except Mine)": verification artifacts over diff review, findings proven by a run, and corrections turned into checks. Federico Viticci's write-up of his tstack verification loop shaped the order of the steps. The text here is new and shares none of theirs. MIT.
