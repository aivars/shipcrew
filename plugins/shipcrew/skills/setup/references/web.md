# Web recipe (draft)

Nobody has run this recipe end to end yet. If you use it, send a pull request with the script that worked and what you had to change.

## How to drive

1. **URLs and seed data.** One URL per state, against a database seeded by script. If a state needs clicks to reach, add a debug route or a query parameter in development builds.
2. **A browser driver** (Playwright is the usual choice) for screenshots and for flows that need clicks.
3. **A hands-on browser tool** for exploring. Poor as repeatable proof.

## The script, in outline

- `doctor`: dependencies installed, the dev build matches the checkout (same build stamp idea: commit plus a hash of uncommitted source), the port is free.
- `build`: install and build, then write the stamp.
- `shoot <name> [--viewport WxH] [--scheme light|dark] [--wait ms] <path>`: start the server on its own port with its own database or data folder, wait for it to answer, open the path in a fresh browser profile, fail on a page error or a 5xx, save a screenshot and a manifest line.
- `state`: print the stamp of the checkout as it is now, untracked files included.
- `replay [name ...]`: shoot each name again on the current build, with the arguments its manifest line recorded.
- `cleanup`: stop the server the script started, by the process id it saved. Never kill by port or by name.

Hold a lock per checkout for `build`, `shoot` and `replay`, and never overwrite a screenshot that already exists.

## Expect to handle

- Fonts and images that load late: wait for network idle or a known element, not a fixed sleep.
- Animations: disable them or wait for them to end.
- Auth: a seeded session cookie or a development-only login route.
- States worth a shot: mobile and desktop widths, dark scheme, empty data, a long name, a slow or failed request.

## Out of reach

Real payment providers, email delivery, third-party sign-in, real devices.
