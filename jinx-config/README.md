# Jinx (OpenClaw gateway) config patches

These JSON5 fragments are **not** part of the Captain Claw game. They document how Tarun Devesetti configured the **Node.js OpenClaw assistant** (“Jinx”) on his Mac.

OpenClaw home: `~/.openclaw/`
Telegram bot: `@trawtdotbot` (owner ID `7842220023`)

## Current state and safety

These are illustrative patches, not a full backup of live configuration. The
live gateway configuration is authoritative. As of 2026-10-02, OpenClaw CLI
2026.9.7 is running locally; the older macOS app bundle 2026.9.3 cannot read
its state database and needs a compatible app update. Do not install an older
CLI against that database.

Gmail is exposed to Jinx only through three read-only MCP tools, and the broad
`gog` skill is disabled. Calendar has a read-only MCP tool and a separate,
limited create/update bridge documented in
[`Scripts/README.jinx-calendar.md`](../Scripts/README.jinx-calendar.md).
Host-elevated commands are disabled, while ordinary commands run in a
networkless Docker sandbox. Browser control uses an isolated browser container,
not the personal Chrome profile. These restrictions govern Jinx's tools, not
the underlying Google OAuth grant or other apps on this Mac.

The hourly heartbeat is not yet reliable: its scheduled run failed after a
GPT authorization error and later Gemini quota error. Automatic routing starts at Codex (`openai/gpt-5.6-sol`), then Gemini 3.5
Flash, 2.5 Flash, 3.1 Flash-Lite, then local `ollama/gemma4`. Codex still
returns 403 until ChatGPT auth is fixed, so normal turns should land on
Gemini. A failure after a model has already answered in the same turn does
not restart that turn on the next model. The
nightly memory-promotion and weekly skill-review automations are enabled but
have not been end-to-end verified. Review automation changes before applying.

## How to apply

Review each patch against the live configuration before applying it. Do not
blindly merge old fragments. If a restart is required, use:

```bash
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
```

**Never commit** live `openclaw.json`, API keys, or gateway tokens to git.

## Files

| Patch | Purpose |
|---|---|
| `model-chain.patch.json5` | Current cloud model order → local `ollama/gemma4` fallback |
| `sandbox-tools.patch.json5` | Exact extra tools allowed inside Docker sandbox |
| `secretary.patch.json5` | Heartbeat schedule (PT), host-elevated exec disabled |
| `stt.patch.json5` | Local whisper.cpp transcription for voice notes |
| `tts.patch.json5` | Gemini TTS (inbound only) + macOS `say` fallback |

Paths inside patches use `/Users/tarundevesetti/...` — adjust if your username differs.
