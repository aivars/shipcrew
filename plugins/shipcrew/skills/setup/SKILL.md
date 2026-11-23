---
name: setup
description: Give a repo a scripted way to run the real product and keep evidence, as a project skill with a feature map. Run once per project. Use for "set up shipcrew", "set up verification", or when a repo has no verify-<project> skill.
---

# Set up a project

The result is `.claude/skills/verify-<project>/` in the repo: a `SKILL.md`, one script, and a feature map. Builders and testers on any model use it to run the real thing. Write it for an agent that has never seen the project and reads it mid-task.

## 1. Read the repo, ask little

Find out from the code:

- **What it is:** an iOS app, a web app, a CLI, a server, or several of these. Each surface a user touches gets driven.
- **Build and run:** the commands, the scheme or script names, what tests need.
- **States:** how the product can be put into a known state without a human. Look for launch arguments, debug hooks, seed scripts, fixtures, test accounts, screenshot or preview harnesses, existing end-to-end tests.
- **Existing scripts:** capture or smoke scripts already in the repo. Reuse their method and flags; they hold waits and seeds someone already paid for.
- **Shared resources:** simulators, ports, databases other work is using. Never plan to drive those.
- **Out of reach:** what the product needs that a script cannot give it.

Ask the user only what the repo cannot answer.

## 2. Pick the recipe

Read the one that matches, in `references/`:

| Surface | Recipe | State |
|---|---|---|
| iOS app | `ios.md` and `verify-ios.sh` | Proven on a shipping app |
| Web app | `web.md` | Draft, no script yet |
| CLI or server | `cli-server.md` | Draft, no script yet |

For a draft recipe, write the script from its outline and tell the user this path is less travelled. For a surface with no recipe, keep the six properties below and say what you built.

## 3. Write the script

One script with four commands: `doctor`, `build`, a drive command (`shoot` for anything with pixels, `run` otherwise) and `cleanup`. Whatever the platform, keep these properties:

- **Its own sandbox:** a simulator, port, browser profile or temp database made for it and named for the project. It never touches one that other work is using.
- **A build stamp:** the commit plus a hash of uncommitted source. The drive command refuses a build that does not match the checkout.
- **A clean start per run** unless asked to keep data.
- **A crash check** before evidence is taken.
- **Evidence in a git-ignored folder** with one manifest line per run: name, time, build stamp, arguments.
- **Cleanup** that stops only what the script started and never deletes evidence.

## 4. Write the skill

`SKILL.md` with frontmatter (`name: verify-<project>`, a description that names the product and when to use it) and these sections, each with the repo's real commands: Launch, Doctor, Drive, Evidence, Cleanup, Not covered.

In Evidence, state the proof standards: look at every piece of evidence you cite; a claim needs the state that shows it; say what the script cannot show.

## 5. Seed the feature map

`features/README.md` plus one file for each of the three to five features users touch most. Each file, from the user's point of view: Sub-features, How to get to it, Driving it (real commands), a "Proof it works" line, Gotchas. List what is not mapped yet.

## 6. Prove it

Run the skill's own instructions once, end to end: doctor, build, one run per mapped feature, look at each piece of evidence, cleanup. Then confirm the evidence is still there. Fix what fails. Remove any command you could not make work, and say so. Record in the feature map which commands were run and on which build. A skill nobody ran is a draft.

## 7. Seed the rule table

Create `docs/agent-rules.md` (see the `learn` skill) from the checks the repo already has: guard tests, lint rules, tests named in the agent instruction file. Rules that exist only as prose go in with "prose" as their enforcement.

## 8. Hand over

Tell the user what was proven, what was not, and that `ship` is ready to use. Mention `references/roles-example.md` in the `ship` skill if they have more than one model provider.
