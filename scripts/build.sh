#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_NAME=$(basename "$PROJECT_ROOT")
VERSION=$(cat "$PROJECT_ROOT/../../../../VERSION" 2>/dev/null || echo "0.0.0")
VERSION=$(echo "$VERSION" | tr -d '[:space:]')
ARCH="arm64"

# Create build directory
BUILD_DIR="$PROJECT_ROOT/build-cross"
mkdir -p "$BUILD_DIR"

# Create temporary directory for .deb package structure
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Package name
PACKAGE_NAME="${PROJECT_NAME}_${VERSION}_${ARCH}"
PACKAGE_DIR="$TEMP_DIR/$PACKAGE_NAME"

# Create Debian package structure
mkdir -p "$PACKAGE_DIR/DEBIAN"
mkdir -p "$PACKAGE_DIR$INSTALL_ROOT/$PROJECT_NAME"

# Copy files to package directory (exclude scripts directory)
echo "Copying project files..."
cd "$PROJECT_ROOT"
for item in *; do
    if [ "$item" != "scripts" ] && [ "$item" != "build-cross" ] && [ "$item" != "build-native" ]; then
        cp -r "$item" "$PACKAGE_DIR$INSTALL_ROOT/$PROJECT_NAME/"
    fi
done

# Create control file
cat > "$PACKAGE_DIR/DEBIAN/control" <<EOF
Package: $PROJECT_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: Project System Team
Description: Media Server for streaming applications
 MediaMTX media server with configuration files.
Priority: optional
Section: net
EOF

# Build the .deb package
echo "Building .deb package..."
dpkg-deb --build "$PACKAGE_DIR" "$BUILD_DIR/${PACKAGE_NAME}.deb"

echo "Package created: $BUILD_DIR/${PACKAGE_NAME}.deb"