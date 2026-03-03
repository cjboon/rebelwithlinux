#!/bin/bash

# Configuration
WEBSITE="https://rebelwithlinux.com"
PACKAGE_NAME="com.rebelwithlinux.app"
APP_NAME="Rebel With Linux"
OUTPUT_DIR="./apk-output"
ICON_PATH="./android-chrome-192x192.png"

echo "=== Web2APK Builder for Rebel With Linux ==="
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed"
    exit 1
fi

# Check if python3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed"
    exit 1
fi

# Check if pip is installed
if ! command -v pip &> /dev/null; then
    echo "Error: pip is not installed"
    exit 1
fi

# Clone web2apk if not exists
if [ ! -d "web2apk" ]; then
    echo "Cloning web2apk repository..."
    git clone https://github.com/dwip-the-dev/web2apk.git
fi

cd web2apk

# Install dependencies
echo "Installing dependencies..."
pip install -e . --quiet

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build the APK
echo "Building APK..."
echo "  Website: $WEBSITE"
echo "  Package: $PACKAGE_NAME"
echo "  App Name: $APP_NAME"
echo ""

python3 -m web2apk \
    --website "$WEBSITE" \
    --package-name "$PACKAGE_NAME" \
    --app-name "$APP_NAME" \
    --icon "$ICON_PATH" \
    --output-dir "$OUTPUT_DIR" \
    --version "1.0.0" \
    --version-code 1

echo ""
echo "=== Build Complete ==="
if [ -d "$OUTPUT_DIR" ]; then
    echo "APK files in $OUTPUT_DIR:"
    ls -la "$OUTPUT_DIR"/*.apk 2>/dev/null || echo "No APK found"
else
    echo "Error: Output directory not created"
fi
