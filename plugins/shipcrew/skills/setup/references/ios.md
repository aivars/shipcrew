# iOS recipe

Proven on a shipping SwiftUI app: nine screens driven and checked from one script.

## How to drive

Prefer, in order:

1. **Launch arguments.** One argument per state, with seeded data and no taps. Deterministic and fast. Read them with `ProcessInfo.processInfo.arguments` (or `UserDefaults`, which picks up `-key value` pairs) behind `#if DEBUG`. If the app has none, add one for the first feature and grow from there.
2. **A UI test target** for flows that need real taps in sequence.
3. **Interactive tools** (Xcode device tools, RocketSim, XcodeBuildMCP) for a hands-on pass. Good for exploring, poor as repeatable proof.

## The script

Copy `verify-ios.sh` to `.claude/skills/verify-<app>/scripts/verify.sh` and fill in the block at the top: bundle id, project or workspace, scheme, source paths, the arguments every launch needs, permissions to grant. `seed_app` is where seed files are copied into the app's container.

It gives you `doctor`, `build`, `shoot <name> [--wait s] [--appearance light|dark] [--at lat,lon] [--text-size s] [--keep] -- <launch args>` and `cleanup`.

## Gotchas already paid for

- **zsh and argument variables.** An unquoted `$ARGS` in zsh is passed as one argument. The app ignores it and the shot shows the default screen with no error. Write launch arguments out.
- **Waits.** Map snapshots and remote images need 12 s or more. A shot taken too early shows an empty panel that looks like a bug.
- **Seeded launches add data again.** Hence the clean install per shot. Use `--keep` only when a second launch must read the first one's data.
- **A state that needs another state.** Some arguments only work with a seeding argument beside them. Note the pair in the feature map.
- **`grep -q` in a pipe under `pipefail`** fails when grep closes the pipe early. Read command output into a variable first.
- **Builds and tests together.** Wall-clock tests can fail while another build runs. Do not build during a test run.
- **Text sizes** for `--text-size`: `extra-small`, `large`, `extra-extra-extra-large`, `accessibility-extra-large`.

## Out of reach on a simulator

Camera, other apps (share targets, Messages), real GPS and motion, tapping a system notification, StoreKit purchases against the real store. List these under "Not covered".
