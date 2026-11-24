# Contributing

Thanks for helping. The plugin is small on purpose; these rules keep it that way.

## What helps most

- **A recipe you have run.** Web, Android, macOS, a CLI. Add `plugins/shipcrew/skills/setup/references/<platform>.md` and, if you have one, the script. Say in the pull request which project type you ran it on and what the evidence looked like. Do not include anything private from that project.
- **A gotcha you paid for.** One line in the right recipe, with what goes wrong and what to do.
- **A report of the loop failing.** Open an issue with the step it failed at, the models in each role, and what the report said.

## Rules for changes

- **Run it.** A skill change comes with a note on the session you tried it in and what happened. Untested prose is marked "draft" in the file.
- **Keep skills short.** A skill is read mid-task by an agent with little context left. Cut before you add.
- **No hooks, no auto-run.** The plugin must not change sessions that did not ask for it.
- **Plain files in the user's repo.** Whatever `setup` writes must be readable and editable without the plugin installed.
- **No secrets, no personal paths, no real bundle ids** in templates or examples.

## Checking a change

```
claude plugin validate .
shellcheck plugins/shipcrew/skills/setup/references/verify-ios.sh tests/*.sh
bash tests/verify-ios.test.sh
```

CI runs the same on every pull request. The tests stub `xcrun` and `xcodebuild`, so they need no Mac. On a Mac, also run them with `/bin/bash` (3.2), which is what users have.

To try it locally: `/plugin marketplace add /path/to/your/clone`, then `/plugin install shipcrew@shipcrew`.
