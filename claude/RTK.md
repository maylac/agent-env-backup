# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy for common development commands.

## Meta Commands

Always call RTK directly for RTK's own commands:

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze command history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering, for debugging
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work, not "command not found"
which rtk             # Verify the expected binary
```

If `rtk gain` fails, check for a name collision with a different `rtk` binary.

## Hook-Based Usage

In Claude/Codex tool sessions, Bash commands are rewritten by configured
`PreToolUse` hooks when RTK has an equivalent command.

Example:

```bash
git status
# hook rewrite: rtk git status
```

This is not a shell alias. Commands run directly in an ordinary terminal may
not be rewritten unless that environment has its own RTK integration.

## Known Limits

- Prefer `rg` or `rg --files` for search when possible.
- Use `/usr/bin/find` directly for compound predicates or actions, such as
  `\( -name A -o -name B \)` or `-exec`. Local `rtk find` does not support
  those forms and can reject an otherwise valid filesystem search.
