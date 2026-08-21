#!/bin/bash
# Build SDL2 + satellite libs from source (via release tarballs) into a
# workspace-local prefix. Native arm64. No git, no Homebrew, no writes
# outside the workspace. Works entirely inside the sandbox.
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
DEPS="$ROOT/deps"
SRC="$DEPS/src"
PREFIX="$DEPS/prefix"
JOBS="$(sysctl -n hw.ncpu 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 6)"
export MACOSX_DEPLOYMENT_TARGET=11.0

mkdir -p "$SRC" "$PREFIX"
CMAKE_COMMON=(
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_INSTALL_PREFIX="$PREFIX"
  -DCMAKE_PREFIX_PATH="$PREFIX"
  -DCMAKE_OSX_ARCHITECTURES=arm64
  -DBUILD_SHARED_LIBS=ON
  -DCMAKE_INSTALL_RPATH="$PREFIX/lib"
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
)

log() { echo ""; echo "======== $* ========"; }

# fetch <url> <tarball-name> <extracted-dir-name>
fetch() {
  local url="$1" tarball="$2" dir="$3"
  if [ -d "$SRC/$dir" ]; then echo "[$dir] already present"; return 0; fi
  echo "[fetch] $url"
  curl -fL --retry 3 --max-time 180 -o "$SRC/$tarball" "$url" || { echo "DOWNLOAD FAILED: $url"; exit 5; }
  tar -xzf "$SRC/$tarball" -C "$SRC" || { echo "EXTRACT FAILED: $tarball"; exit 6; }
}

CL="https://codeload.github.com"

######################## FreeType (for SDL2_ttf) ########################
log "FreeType: fetch"
fetch "$CL/freetype/freetype/tar.gz/refs/tags/VER-2-13-3" freetype.tgz freetype-VER-2-13-3
log "FreeType: configure"
cmake -S "$SRC/freetype-VER-2-13-3" -B "$SRC/freetype-VER-2-13-3/build" "${CMAKE_COMMON[@]}" \
  -DFT_DISABLE_HARFBUZZ=ON -DFT_DISABLE_BROTLI=ON -DFT_DISABLE_BZIP2=ON \
  -DFT_DISABLE_PNG=ON -DFT_DISABLE_ZLIB=ON || { echo "freetype configure FAILED"; exit 10; }
log "FreeType: build+install"
cmake --build "$SRC/freetype-VER-2-13-3/build" -j"$JOBS" --target install || { echo "freetype build FAILED"; exit 11; }

######################## SDL2 core ########################
log "SDL2 core: fetch"
fetch "$CL/libsdl-org/SDL/tar.gz/refs/tags/release-2.30.9" SDL.tgz SDL-release-2.30.9
log "SDL2 core: configure"
cmake -S "$SRC/SDL-release-2.30.9" -B "$SRC/SDL-release-2.30.9/build" "${CMAKE_COMMON[@]}" -DSDL_TEST=OFF \
  || { echo "SDL configure FAILED"; exit 20; }
log "SDL2 core: build+install"
cmake --build "$SRC/SDL-release-2.30.9/build" -j"$JOBS" --target install || { echo "SDL build FAILED"; exit 21; }

######################## SDL2_image (STB backend; PCX/TGA/BMP built-in) ########################
log "SDL2_image: fetch"
fetch "$CL/libsdl-org/SDL_image/tar.gz/refs/tags/release-2.8.2" SDL_image.tgz SDL_image-release-2.8.2
log "SDL2_image: configure"
cmake -S "$SRC/SDL_image-release-2.8.2" -B "$SRC/SDL_image-release-2.8.2/build" "${CMAKE_COMMON[@]}" \
  -DSDL2IMAGE_VENDORED=OFF -DSDL2IMAGE_BACKEND_STB=ON \
  -DSDL2IMAGE_DEPS_SHARED=OFF -DSDL2IMAGE_SAMPLES=OFF -DSDL2IMAGE_TESTS=OFF \
  -DSDL2IMAGE_INSTALL=ON || { echo "SDL_image configure FAILED"; exit 30; }
log "SDL2_image: build+install"
cmake --build "$SRC/SDL_image-release-2.8.2/build" -j"$JOBS" --target install || { echo "SDL_image build FAILED"; exit 31; }

######################## SDL2_ttf (external freetype, no harfbuzz) ########################
log "SDL2_ttf: fetch"
fetch "$CL/libsdl-org/SDL_ttf/tar.gz/refs/tags/release-2.22.0" SDL_ttf.tgz SDL_ttf-release-2.22.0
log "SDL2_ttf: configure"
cmake -S "$SRC/SDL_ttf-release-2.22.0" -B "$SRC/SDL_ttf-release-2.22.0/build" "${CMAKE_COMMON[@]}" \
  -DSDL2TTF_VENDORED=OFF -DSDL2TTF_HARFBUZZ=OFF \
  -DSDL2TTF_SAMPLES=OFF -DSDL2TTF_INSTALL=ON \
  -DFREETYPE_LIBRARY="$PREFIX/lib/libfreetype.dylib" \
  -DFREETYPE_INCLUDE_DIRS="$PREFIX/include/freetype2" || { echo "SDL_ttf configure FAILED"; exit 40; }
log "SDL2_ttf: build+install"
cmake --build "$SRC/SDL_ttf-release-2.22.0/build" -j"$JOBS" --target install || { echo "SDL_ttf build FAILED"; exit 41; }

######################## SDL2_mixer (WAV only) ########################
log "SDL2_mixer: fetch"
fetch "$CL/libsdl-org/SDL_mixer/tar.gz/refs/tags/release-2.8.0" SDL_mixer.tgz SDL_mixer-release-2.8.0
log "SDL2_mixer: configure"
cmake -S "$SRC/SDL_mixer-release-2.8.0" -B "$SRC/SDL_mixer-release-2.8.0/build" "${CMAKE_COMMON[@]}" \
  -DSDL2MIXER_VENDORED=OFF \
  -DSDL2MIXER_MOD=OFF -DSDL2MIXER_MP3=OFF -DSDL2MIXER_MIDI=OFF \
  -DSDL2MIXER_OPUS=OFF -DSDL2MIXER_FLAC=OFF -DSDL2MIXER_VORBIS=OFF \
  -DSDL2MIXER_WAVPACK=OFF -DSDL2MIXER_GME=OFF \
  -DSDL2MIXER_SAMPLES=OFF -DSDL2MIXER_INSTALL=ON || { echo "SDL_mixer configure FAILED"; exit 50; }
log "SDL2_mixer: build+install"
cmake --build "$SRC/SDL_mixer-release-2.8.0/build" -j"$JOBS" --target install || { echo "SDL_mixer build FAILED"; exit 51; }

######################## SDL2_gfx (compile the .c files directly) ########################
log "SDL2_gfx: fetch"
fetch "$CL/ferzkopp/SDL2_gfx/tar.gz/refs/heads/master" SDL2_gfx.tgz SDL2_gfx-master
GFX="$SRC/SDL2_gfx-master"
log "SDL2_gfx: compile static+shared lib"
mkdir -p "$GFX/obj"
GFX_SRCS=(SDL2_gfxPrimitives.c SDL2_rotozoom.c SDL2_framerate.c SDL2_imageFilter.c)
GFX_OBJS=()
for f in "${GFX_SRCS[@]}"; do
  if [ -f "$GFX/$f" ]; then
    clang -arch arm64 -O2 -fPIC -I"$PREFIX/include" -I"$PREFIX/include/SDL2" -c "$GFX/$f" -o "$GFX/obj/${f%.c}.o" || { echo "gfx compile $f FAILED"; exit 60; }
    GFX_OBJS+=("$GFX/obj/${f%.c}.o")
  fi
done
ar rcs "$PREFIX/lib/libSDL2_gfx.a" "${GFX_OBJS[@]}" || { echo "gfx ar FAILED"; exit 61; }
clang -arch arm64 -dynamiclib -install_name "@rpath/libSDL2_gfx.dylib" \
  -o "$PREFIX/lib/libSDL2_gfx.dylib" "${GFX_OBJS[@]}" \
  -L"$PREFIX/lib" -lSDL2 || { echo "gfx dylib FAILED"; exit 62; }
mkdir -p "$PREFIX/include/SDL2"
cp "$GFX"/*.h "$PREFIX/include/SDL2/" 2>/dev/null || true

log "ALL DEPS BUILT SUCCESSFULLY"
echo "Installed SDL2 libraries:"
ls -1 "$PREFIX/lib" | grep -iE "libSDL2|libfreetype" | sort
echo "ALL_DEPS_DONE_OK"
