# TRAW handoff — pick up from phone or cloud

**Owner:** Tarun Devesetti (`T-DEV16` on GitHub)  
**Last updated:** 2026-08-21  
**Fork:** https://github.com/T-DEV16/OpenClaw  
**Upstream (original game):** https://github.com/pjasicek/OpenClaw  

Read this file first if you are a **Cursor Cloud Agent**, the **Cursor iOS app**, or a fresh chat continuing Tarun’s work.

---

## Two different “OpenClaw” things (do not confuse them)

| Name | What it is | Where it lives |
|---|---|---|
| **This git repo** | C++ reimplementation of *Captain Claw* (1997) | `T-DEV16/OpenClaw` |
| **Jinx / OpenClaw gateway** | Node.js personal AI assistant (Telegram, Ollama, Gemini, etc.) | `~/.openclaw/` on Tarun’s Mac only |

This fork adds **macOS build tooling** and **Jinx config documentation**. It does **not** contain the running gateway, secrets, or Telegram tokens.

---

## What was done (Aug 2026 session summary)

### 1. GitHub fork and remotes

- Logged into GitHub CLI as **T-DEV16**
- Forked `pjasicek/OpenClaw` → `T-DEV16/OpenClaw`
- Local clone remotes:
  - `origin` → `https://github.com/T-DEV16/OpenClaw.git` (push here)
  - `upstream` → `https://github.com/pjasicek/OpenClaw.git` (read-only upstream)

### 2. macOS arm64 game build (M4 Mac)

Problem: Xcode Command Line Tools had empty libc++ headers; Homebrew SDL was unavailable in sandboxed builds.

**Fix in `CMakeLists.txt`:**
- Point clang at SDK C++ headers via `-isystem`
- On Apple, link against workspace-local SDL2 prefix at `deps/prefix/`

**Scripts added:**
- `build_deps.sh` — downloads SDL2, SDL_image, SDL_ttf, SDL_mixer, FreeType, SDL2_gfx; builds into `deps/prefix/` (arm64, no Homebrew)
- `run_openclaw.sh` — launches `Build_Release/openclaw` from a **GUI Terminal** (needs display; fails headless)

**Build steps (Mac Terminal, not sandbox):**

```bash
./build_deps.sh          # ~10–20 min first time; fetches sources into deps/src/
mkdir -p build && cd build
cmake .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build . -j
cd ..
./run_openclaw.sh
```

**Game data:** Copy legally-owned `CLAW.REZ` into `Build_Release/`. Without it the engine starts but cannot load levels. `CLAW.REZ` is **not** in git (copyright).

**Not committed (rebuild locally):**
- `Build_Release/openclaw` binary — build with cmake
- `deps/src/` source trees — recreated by `build_deps.sh` (large; omitted from git)

**Committed:**
- `deps/prefix/` — prebuilt SDL2 libs (speeds rebuild)
- `build_deps.sh`, `run_openclaw.sh`, `CMakeLists.txt` changes
- `Build_Release/ASSETS.ZIP` update

### 3. Jinx (OpenClaw assistant) — Mac only

Full runtime is on the Mac at `~/.openclaw/`. Config patch **templates** are in `jinx-config/patches/` (see `jinx-config/README.md`).

Highlights from that session:
- Gateway LaunchAgent: `gui/503/ai.openclaw.gateway`
- Telegram: `@trawtdotbot`, owner `7842220023`
- Models: Gemini ladder → local `ollama/gemma4`; ChatGPT Plus OAuth for Codex when configured
- Docker tool sandbox enabled; elevated host tools locked to owner Telegram ID
- Secretary skills: `remindctl`, `memo`, `gog` (Gmail/Calendar for `tarundevmail@gmail.com`)
- Hourly heartbeat 07:00–23:00 PT
- TTS: inbound-only Gemini; STT: local whisper.cpp
- **Never echo** tokens from `openclaw.json` in chat or commits

### 4. CS 7643 Deep Learning (OMSCS)

Course planning file copied to **`docs/CS7643.md`**. Use it as schedule source of truth.

- Instructor: Zsolt Kira
- Tarun has prior ML course; **does not need CS 7641** first
- Do **not** pair with GA or 7641 same term while at Oracle
- Project teams: **self-selected**, 2–4 people, find Pacific teammates early on Ed
- Refresher: CS231n + Prince UDL book + PS0 (see `docs/CS7643.md`)
- Honor code: learning code OK; no paste-submit to Gradescope

When Canvas dates arrive → update **`docs/CS7643.md`** Live Canvas schedule table (and sync to `~/.openclaw/workspace/CS7643.md` on Mac for Jinx).

### 5. Cursor cloud / phone access

Goal: continue this work from phone.

**What works:**
- **Cursor iOS app** (iOS 26+) or https://cursor.com/agents
- Pick repo **`T-DEV16/OpenClaw`**, branch **`master`**
- Connect GitHub at https://cursor.com/dashboard first

**What failed once:**
- `/in-cloud` hit GitHub **rate limit** when cloning `pjasicek/OpenClaw` anonymously. Using **your fork** + connected GitHub auth should help.

**Move to Cloud / Remote Control:**
- **Move to Cloud** — archives local session, continues on cloud VM (conversation history on cursor.com/agents)
- **Remote Control** (`/remote-control`) — agent loop in cloud, tools on Mac; Mac must stay awake

**What cloud agents get from this repo:**
- Game source, build scripts, Jinx patch docs, CS7643 notes
- **Not:** `~/.openclaw/`, secrets, `CLAW.REZ`, compiled `openclaw` binary

Cloud VMs are usually **Linux**. The macOS-specific `build_deps.sh` / `deps/prefix` path is for Tarun’s Mac; cloud agents should treat game build docs as reference unless the environment is macOS.

---

## Repo layout (TRAW additions)

```
docs/
  TRAW-HANDOFF.md     ← you are here
  CS7643.md           ← OMSCS course source of truth
jinx-config/
  README.md
  patches/            ← OpenClaw gateway JSON5 templates (apply on Mac)
build_deps.sh         ← fetch + build SDL2 into deps/prefix
run_openclaw.sh       ← launch game (GUI session)
deps/
  prefix/             ← committed prebuilt libs (macOS arm64)
  src/                ← NOT in git; run build_deps.sh to create
CMakeLists.txt        ← macOS SDK + deps/prefix hooks
```

---

## Secrets — never commit

- `~/.openclaw/openclaw.json` (gateway token, model keys)
- `.env`, credentials, OAuth tokens
- `CLAW.REZ` (copyrighted game assets)
- Telegram bot token, Gemini API keys

Patch files use `${GEMINI_API_KEY}` placeholder syntax where applicable.

---

## Quick starts for a new agent

### “Continue CS7643 planning”

Read `docs/CS7643.md`. Ask Tarun for Canvas dates if table still says TBD. Do not invent due dates. Short answers; honor code applies.

### “Build Captain Claw on Mac”

Read build section above. Requires Mac GUI session + `CLAW.REZ`. Do not push to `upstream`.

### “Help with Jinx on Mac”

Patches are in `jinx-config/patches/`. Live config is `~/.openclaw/` — not in this repo. User must run gateway on Mac.

### “Sync fork with upstream game”

```bash
git fetch upstream
git merge upstream/master   # or rebase, Tarun’s choice
git push origin master
```

---

## Tarun context

- Full-time **Oracle**, timezone **America/Los_Angeles**
- **OMSCS** Georgia Tech
- Mac: **M4**, macOS 15.5 (wake word / some features need macOS 26)
- GitHub: **T-DEV16**

---

## First message template (cloud agent)

When Tarun opens this repo on phone, confirm:

1. You are on **`T-DEV16/OpenClaw`**, not `pjasicek/OpenClaw`
2. You read **`docs/TRAW-HANDOFF.md`** and **`docs/CS7643.md`**
3. Jinx live state is Mac-only unless he pastes updates
4. Ask what he wants: **7643**, **game build**, or **Jinx config**

Keep it short.
