#!/bin/bash
# Launch OpenClaw. Run this from your normal macOS Terminal (a GUI login
# session) so the game can open a window. It will NOT work from a headless
# / remote / sandboxed shell ("video driver did not add any displays").
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT/Build_Release" || exit 1

if [ ! -f "openclaw" ]; then
  echo "ERROR: openclaw binary not found. Build it first:"
  echo "  ./build_deps.sh   (builds SDL2 + libs into deps/prefix)"
  echo "  cd build && cmake .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && cmake --build . -j"
  exit 1
fi

if [ ! -f "CLAW.REZ" ]; then
  cat <<'EOF'
------------------------------------------------------------------
NOTE: CLAW.REZ is missing.

OpenClaw is only the game ENGINE. To actually play, it needs the
original game data archive CLAW.REZ from a legally-owned copy of
Captain Claw (1997). Copy that file into:

    Build_Release/CLAW.REZ

Then run this script again. The engine will start but cannot load
levels/graphics without it.
------------------------------------------------------------------
EOF
fi

echo "Launching OpenClaw from: $(pwd)"
exec ./openclaw
