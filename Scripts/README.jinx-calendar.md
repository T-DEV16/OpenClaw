# Jinx Calendar bridge

`jinx-calendar-mcp.mjs` is a local MCP server registered in Jinx as
`jinx-calendar-write`. It exposes only `calendar_create` and `calendar_update`
for the owner's primary Google Calendar. It does not expose Gmail, deletion,
attendee management, invitations, or arbitrary shell commands.

The bridge invokes `gog` with an exact command allowlist and `--gmail-no-send`.
Create and update accept a small set of validated fields. Update first reads
the target event and refuses events with attendees. The separate
`jinx-gmail-readonly` and `jinx-calendar-readonly` MCP servers use `gog
--readonly` and expose only read tools. Jinx's elevated host commands remain
disabled; its normal shell runs in a networkless Docker sandbox.

Run the non-mutating protocol and create dry-run test with:

```sh
node --test Scripts/jinx-calendar-mcp.test.mjs
```

The server imports the MCP SDK bundled with the local OpenClaw installation at
`/Users/tarundevesetti/.npm-global/lib/node_modules/openclaw`. After upgrading
or moving OpenClaw or this repository, rerun the test and `openclaw mcp probe
jinx-calendar-write --json`; update the configured server command path if this
script moves. Neither the OAuth credentials nor OpenClaw's live configuration
are stored in this repository.

No real Calendar mutation is included in the test. A real create/update should
be verified only with an approved, clearly labeled event. This bridge is not a
general restriction on other applications or on a browser that a user later
signs into Google; keep Jinx's browser isolated and review new integrations.
