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

# Step 5: Fix QGLViewer's dependencies to use bundled Qt frameworks
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

# Step 6: Verify the bundle is self-contained. Every Mach-O must resolve
# through the bundle (@executable_path, @rpath, @loader_path) or the OS;
# an absolute build-machine path crashes dyld at launch on other Macs.
BAD=""
while IFS= read -r f; do
  file -b "$f" | grep -q "Mach-O" || continue
  for dep in $(otool -L "$f" | awk '/\(compatibility version /{print $1}'); do
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

echo "Deploy complete. QGLViewer bundled, paths fixed, bundle self-contained."
