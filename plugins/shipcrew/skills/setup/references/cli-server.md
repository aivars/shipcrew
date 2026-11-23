# CLI and server recipe (draft)

Nobody has run this recipe end to end yet. If you use it, send a pull request with the script that worked and what you had to change.

## How to drive

Run the real binary or the real server, never a function call into its internals. Evidence is text: output, exit code, response body, log lines.

## The script, in outline

- `doctor`: the build matches the checkout (commit plus a hash of uncommitted source), needed tools exist, the port is free.
- `build`: build, then write the stamp.
- `run <name> -- <command or request>`: start from a fresh temp directory or database. For a server, start it on its own port and wait until it answers. Run the command, then save stdout, stderr, the exit code and the relevant log lines to `<name>.txt`, plus a manifest line.
- `cleanup`: stop what the script started, by saved process id. Remove temp data, keep evidence.

## Expect to handle

- Output that changes each run (times, ids, ports): note which lines are stable enough to compare.
- States worth a run: empty input, malformed input, a missing file, a second run over the first one's data, a killed-and-restarted server.

## Out of reach

Production data, real third-party services, load.
