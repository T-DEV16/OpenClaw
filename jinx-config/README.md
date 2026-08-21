# Jinx (OpenClaw gateway) config patches

These JSON5 fragments are **not** part of the Captain Claw game. They document how Tarun Devesetti configured the **Node.js OpenClaw assistant** (“Jinx”) on his Mac.

OpenClaw home: `~/.openclaw/`  
Telegram bot: `@trawtdotbot` (owner ID `7842220023`)

## How to apply

Merge each patch into the matching section of `~/.openclaw/openclaw.json` (or use OpenClaw’s patch/merge workflow if your install supports it). Restart the gateway LaunchAgent after changes:

```bash
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
```

**Never commit** live `openclaw.json`, API keys, or gateway tokens to git.

## Files

| Patch | Purpose |
|---|---|
| `model-chain.patch.json5` | Gemini model ladder → local `ollama/gemma4` fallback |
| `sandbox-tools.patch.json5` | Extra tools allowed inside Docker sandbox |
| `secretary.patch.json5` | Heartbeat schedule (PT), elevated exec for Telegram owner |
| `stt.patch.json5` | Local whisper.cpp transcription for voice notes |
| `tts.patch.json5` | Gemini TTS (inbound only) + macOS `say` fallback |

Paths inside patches use `/Users/tarundevesetti/...` — adjust if your username differs.
