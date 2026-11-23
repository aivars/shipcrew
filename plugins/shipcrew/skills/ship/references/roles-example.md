# Roles

Copy to `~/.config/shipcrew/roles.md` and edit. A `.shipcrew/roles.md` in a repo overrides it for that repo. One line per role: `role: provider/model option=value`.

On T3 Code the provider and model are the ids `orchestrator_capabilities` lists, and each line maps to a `delegate_task` target. In plain Claude Code only Claude lines apply, and the tester runs as the plugin's `tester` agent.

```
builder: claudeAgent/claude-opus-5-5 effort=high
tester: codex/gpt-6.2-astra reasoningEffort=high
second-opinion: grok/grok-4.7
```

- **builder** writes the change and runs the loop.
- **tester** tests the running app. Pick a different provider than the builder: models from different makers miss different things.
- **second-opinion** joins only on high-risk changes. A third maker is best; a second model from the builder's maker is the fallback. Leave it out to skip it.

Model ids go stale. If a role names a model the provider no longer lists, say so and use that provider's current default.

## Defaults when no roles file exists

- builder: the model of the current session.
- tester on T3 Code: the first enabled provider that is not the builder's. With only one provider, a fresh thread on the same model.
- tester elsewhere: the `tester` agent, a fresh subagent with none of the builder's context.
- second-opinion: none.
