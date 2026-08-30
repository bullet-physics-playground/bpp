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
    # Match by framework name regardless of Homebrew prefix (Intel
    # /usr/local, Apple Silicon /opt/homebrew, or a Cellar keg path).
    */QtOpenGL.framework/*) install_name_tool -change "$dep" @executable_path/../Frameworks/QtOpenGL.framework/Versions/5/QtOpenGL "$QGLVIEWER_LIB" 2>/dev/null || true ;;
    */QtWidgets.framework/*) install_name_tool -change "$dep" @executable_path/../Frameworks/QtWidgets.framework/Versions/5/QtWidgets "$QGLVIEWER_LIB" 2>/dev/null || true ;;
    */QtGui.framework/*) install_name_tool -change "$dep" @executable_path/../Frameworks/QtGui.framework/Versions/5/QtGui "$QGLVIEWER_LIB" 2>/dev/null || true ;;
    */QtCore.framework/*) install_name_tool -change "$dep" @executable_path/../Frameworks/QtCore.framework/Versions/5/QtCore "$QGLVIEWER_LIB" 2>/dev/null || true ;;
  esac
done

echo "Deploy complete. QGLViewer bundled and paths fixed."
