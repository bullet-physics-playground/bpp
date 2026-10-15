#!/bin/bash
set -e
APP="$1"
FRAMEWORKS_DIR="$APP/Contents/Frameworks"
QGLVIEWER_SRC="/Library/Frameworks/QGLViewer.framework"
QGLVIEWER_DEST="$FRAMEWORKS_DIR/QGLViewer.framework"
BINARY="$APP/Contents/MacOS/bpp"

# Step 1: Manually copy QGLViewer framework BEFORE macdeployqt
if [ -d "$QGLVIEWER_DEST" ]; then
  rm -rf "$QGLVIEWER_DEST"
fi
mkdir -p "$FRAMEWORKS_DIR"
cp -R "$QGLVIEWER_SRC" "$FRAMEWORKS_DIR/"

# Step 2: Fix QGLViewer framework's own install name so macdeployqt can resolve it
install_name_tool -id @executable_path/../Frameworks/QGLViewer.framework/Versions/3/QGLViewer "$QGLVIEWER_DEST/Versions/3/QGLViewer"

# Step 3: Fix binary's reference to QGLViewer (must point to bundled framework for macdeployqt)
install_name_tool -change QGLViewer.framework/Versions/3/QGLViewer @executable_path/../Frameworks/QGLViewer.framework/Versions/3/QGLViewer "$BINARY" 2>/dev/null || true
install_name_tool -change "$QGLVIEWER_SRC/Versions/3/QGLViewer" @executable_path/../Frameworks/QGLViewer.framework/Versions/3/QGLViewer "$BINARY" 2>/dev/null || true

# Step 4: Run macdeployqt to bundle Qt and other dependencies
macdeployqt "$APP"

# Step 5: Bundle SDL3. Homebrew's "sdl2" is now sdl2-compat, a shim that
# dlopen()s SDL3 in a constructor and abort()s the process when it can't
# find it. macdeployqt doesn't copy SDL3 (it's not a link dependency), and
# sdl2-compat looks first at @loader_path/libSDL3.dylib -- i.e. next to the
# shim in Frameworks.
SDL3_LIBDIR="$(brew --prefix)/opt/sdl3/lib"
if [ -d "$SDL3_LIBDIR" ]; then
  cp -f "$SDL3_LIBDIR"/libSDL3*.dylib "$FRAMEWORKS_DIR/"
  [ -e "$FRAMEWORKS_DIR/libSDL3.dylib" ] || \
    cp -f "$(ls "$FRAMEWORKS_DIR"/libSDL3*.dylib | head -1)" "$FRAMEWORKS_DIR/libSDL3.dylib"
fi

# Step 6: Fix QGLViewer's dependencies to use bundled Qt frameworks
QGLVIEWER_LIB="$QGLVIEWER_DEST/Versions/3/QGLViewer"
for dep in $(otool -L "$QGLVIEWER_LIB" | awk 'NR>1 {print $1}'); do
  case "$dep" in
    # Match every Qt framework regardless of Homebrew prefix (Intel
    # /usr/local, Apple Silicon /opt/homebrew, or a Cellar keg path).
    /*/Qt*.framework/*)
      rel=$(echo "$dep" | sed -E 's|^.*/(Qt[A-Za-z0-9]+\.framework/)|\1|')
      install_name_tool -change "$dep" "@executable_path/../Frameworks/$rel" "$QGLVIEWER_LIB" 2>/dev/null || true ;;
  esac
done

# Step 7: Point every bundled Mach-O at its bundled dependencies through
# the bundle. macdeployqt copies non-Qt libraries into Frameworks but can
# leave their cross-references (e.g. libSDL2_mixer -> libSDL2) as absolute
# Homebrew paths, which dyld can't resolve on another Mac.
while IFS= read -r f; do
  file -b "$f" | grep -q "Mach-O" || continue
  for dep in $(otool -L "$f" | awk '/\(compatibility version /{print $1}'); do
    case "$dep" in
      /*)
        base=$(basename "$dep")
        if [ -e "$FRAMEWORKS_DIR/$base" ]; then
          install_name_tool -change "$dep" "@executable_path/../Frameworks/$base" "$f" 2>/dev/null || true
        fi ;;
    esac
  done
done < <(find "$APP/Contents" -type f)

# Step 8: Verify the bundle is self-contained. Every Mach-O must resolve
# through the bundle (@executable_path, @rpath, @loader_path) or the OS;
# an absolute build-machine path crashes dyld at launch on other Macs.
BAD=""
while IFS= read -r f; do
  file -b "$f" | grep -q "Mach-O" || continue
  # otool -L lists a dylib's own install id first. Plugins are dlopen'd by
  # path and keep the id they were built with, which resolves nothing at
  # load time -- only a dependent's load command can break the bundle.
  ids=$(otool -D "$f" 2>/dev/null | awk '!/:$/ && NF')
  for dep in $(otool -L "$f" | awk '/\(compatibility version /{print $1}'); do
    if printf '%s\n' "$ids" | grep -Fxq "$dep"; then continue; fi
    case "$dep" in
      @*|/System/*|/usr/lib/*) ;;
      /*) BAD="$BAD
  ${f#$APP/}: $dep" ;;
    esac
  done
done < <(find "$APP/Contents" -type f)

if [ -n "$BAD" ]; then
  printf 'Error: bundle depends on paths outside the bundle:%s\n' "$BAD" >&2
  exit 1
fi

# Step 9: Copy the demo scenes and the shared includes into Contents/ so they
# ship inside the .app in the dmg (bpp resolves demo and includes relative to
# its own location). Done after the self-contained check above so its scanner
# doesn't walk the thousands of data files, and before the re-sign below so
# the new files are sealed.
SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
for d in demo includes; do
  if [ -d "$SRC_DIR/$d" ]; then
    rm -rf "$APP/Contents/$d"
    cp -R "$SRC_DIR/$d" "$APP/Contents/$d"
  fi
done

# Step 10: Re-sign the whole bundle. Every install_name_tool edit above (and
# macdeployqt's own copies) invalidated the code signatures; without a fresh
# ad-hoc signature dyld kills the app at launch with SIGKILL (Code Signature
# Invalid) on Apple Silicon.
codesign --force --deep --sign - "$APP"

echo "Deploy complete. QGLViewer bundled, paths fixed, demo/includes added, bundle self-contained."
