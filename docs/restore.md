# Restore Notes

Use this repo as a public-safe blueprint, then restore secrets from Keychain,
1Password, environment variables, or provider dashboards.

## Skills

Dry-run:

```sh
scripts/install.sh
```

Apply skill symlinks into `~/.agents/skills`:

```sh
scripts/install.sh --apply
```

Then sync runtime mirrors with the local sync helper if available:

```sh
~/.agents/sync-skills.sh --dry-run
~/.agents/sync-skills.sh
```

## Claude Code

Review these directories before applying:

- `claude/agents`
- `claude/commands`
- `claude/hooks`
- `templates/claude-settings.public.json`

Do not copy auth, channel, session, project, telemetry, cache, or
`settings.local.json` state into this repo.

## Codex

Review these directories before applying:

- `codex/agents`
- `codex/hooks`
- `templates/codex-config.public.toml`

The live `~/.codex/config.toml` may contain MCP bearer tokens and local app
paths. Recreate those values manually from a secret manager instead of copying
the live file.

## Plugins

Plugin cache directories are not backed up. Use the inventories under
`claude/plugins` and `codex/plugins` to reinstall or enable plugins from their
marketplaces.

