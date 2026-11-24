# Changelog

## 0.3.0

### verify-ios.sh

- **The build stamp covers new files.** It used to hash only the names of untracked files, so editing a new `.swift` file after a build left the stamp unchanged and the screenshots came from old code. The stamp now has a `new:` part hashing their contents. Existing stamps no longer match: run `verify.sh build` once.
- **One simulator and build folder per checkout.** Names now end in a short hash of the repo path (`Verify-<app>-<hash>`), so worktrees no longer install over each other. The old `Verify-<app>` simulator is left alone; delete it with `xcrun simctl delete`.
- **Runs take turns.** `build`, `shoot`, `replay` and `cleanup` hold a lock per checkout, so parallel testers queue instead of uninstalling each other's app.
- **Evidence is never overwritten.** A second shot with the same name is saved as `<name>-2.png`, and so on.
- **`--at` no longer leaks.** A shot without it clears the simulated location.
- **Stricter crash check.** `com.x.App` no longer counts as running when only `com.x.AppWidget` is.
- **`doctor` fails when the evidence folder is not git-ignored.**
- **New commands:** `state` prints the checkout's stamp, `replay [name ...]` reruns recorded shots on the current build, and `cleanup --delete` removes the simulator.
- `shoot` prints only the evidence path on stdout. Screenshot errors are no longer hidden.
- **Manifest format:** column 4 also holds the evidence file name, and column 5 holds the shoot arguments quoted for `replay`. Manifests written before 0.3.0 cannot be replayed.

### Skills

- `ship`: commit before handing over, check with `state` that the tester left the checkout unchanged, use the roles file's Claude `tester:` model in plain Claude Code, replay earlier runs before a recheck, and bring back evidence from another machine.
- `ship`, `learn` and `setup` start only when asked, or when another shipcrew skill hands over, instead of on any change that touches a screen.
- `tester` agent: loads `shipcrew:qa` by name and falls back to the file path.
- `setup`: the script contract adds `state`, `replay`, a lock, evidence that is never overwritten and a git-ignore check. Optional link for `.agents/skills/`.

### Repo

- CI: manifest validation, shellcheck, and tests for `verify-ios.sh` with `xcrun` stubbed, on Linux and on macOS's bash 3.2.
- The version lives only in `plugin.json`.

## 0.2.0

First public release: `setup`, `ship`, `qa`, `learn` and the `tester` agent.
