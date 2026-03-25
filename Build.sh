#!/bin/bash

# MeshCore TEAM Build Script
# Builds Android APK, Android AAB, and/or iOS IPA with version management

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/compiled"

# Semver comparison: returns 0 (true) if $1 >= $2
version_gte() {
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=0; i<3; i++)); do
        if ((${ver1[i]:-0} > ${ver2[i]:-0})); then return 0; fi
        if ((${ver1[i]:-0} < ${ver2[i]:-0})); then return 1; fi
    done
    return 0
}

# ── Build target selection ──────────────────────────────────────────────

echo ""
echo "What do you want to build?"
echo "  1) Android APK"
echo "  2) Android AAB"
echo "  3) iOS IPA"
echo ""
echo "Select targets (e.g. 1,3 or 1,2,3 or just 3):"
read -p "> " TARGET_INPUT
TARGET_INPUT=${TARGET_INPUT:-1,2,3}

BUILD_APK=false
BUILD_AAB=false
BUILD_IPA=false

IFS=',' read -ra TARGETS <<< "$TARGET_INPUT"
for t in "${TARGETS[@]}"; do
    t=$(echo "$t" | tr -d ' ')
    case "$t" in
        1) BUILD_APK=true ;;
        2) BUILD_AAB=true ;;
        3) BUILD_IPA=true ;;
        *) echo "Unknown target: $t"; exit 1 ;;
    esac
done

BUILD_ANDROID=false
if $BUILD_APK || $BUILD_AAB; then
    BUILD_ANDROID=true
fi

if ! $BUILD_APK && ! $BUILD_AAB && ! $BUILD_IPA; then
    echo "Error: No build targets selected."
    exit 1
fi

echo ""
echo "Building:"
$BUILD_APK && echo "  ✓ Android APK"
$BUILD_AAB && echo "  ✓ Android AAB"
$BUILD_IPA && echo "  ✓ iOS IPA"

# ── Android keystore setup (only if building Android) ───────────────────

if $BUILD_ANDROID; then
    # Keystore path
    if [ -z "$ANDROID_KEYSTORE_PATH" ]; then
        echo ""
        read -p "Enter keystore path (or press Enter to skip signing): " ANDROID_KEYSTORE_PATH
        export ANDROID_KEYSTORE_PATH
    fi

    if [ -n "$ANDROID_KEYSTORE_PATH" ]; then
        if [ ! -f "$ANDROID_KEYSTORE_PATH" ]; then
            echo "Error: Keystore not found at $ANDROID_KEYSTORE_PATH"
            exit 1
        fi

        # Keystore password
        if [ -z "$SIGNING_STORE_PASSWORD" ]; then
            echo "Enter keystore password:"
            read -s SIGNING_STORE_PASSWORD
            export SIGNING_STORE_PASSWORD
        fi

        # Key password
        if [ -z "$SIGNING_KEY_PASSWORD" ]; then
            echo "Enter key password (or press Enter if same as keystore):"
            read -s SIGNING_KEY_PASSWORD
            if [ -z "$SIGNING_KEY_PASSWORD" ]; then
                SIGNING_KEY_PASSWORD="$SIGNING_STORE_PASSWORD"
            fi
            export SIGNING_KEY_PASSWORD
        fi
    fi
fi

# ── Version management ──────────────────────────────────────────────────

VERSION_FILE="$SCRIPT_DIR/.build_version"
if [ -f "$VERSION_FILE" ]; then
    LAST_VERSION=$(cat "$VERSION_FILE")
    echo ""
    echo "Current version: $LAST_VERSION"
else
    LAST_VERSION="1.0.0"
    echo ""
    echo "No .build_version found, assuming $LAST_VERSION"
fi

# Generate epoch for build number
EPOCH=$(date +%s)

# Release type
echo ""
echo "Release type?"
echo "  1) Dev  (MeshCore-TEAM-<epoch>)"
echo "  2) Production  (MeshCore-TEAM-x.y.z)"
echo ""
read -p "Select [1]: " RELEASE_TYPE
RELEASE_TYPE=${RELEASE_TYPE:-1}

if [ "$RELEASE_TYPE" = "2" ]; then
    while true; do
        read -p "Enter version [$LAST_VERSION]: " VERSION_NUMBER
        VERSION_NUMBER=${VERSION_NUMBER:-$LAST_VERSION}

        if ! [[ "$VERSION_NUMBER" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Error: Version must be in X.Y.Z format (e.g. 1.0.0)"
            continue
        fi

        if ! version_gte "$VERSION_NUMBER" "$LAST_VERSION"; then
            echo "Error: Version must be >= $LAST_VERSION"
            continue
        fi

        break
    done

    echo "$VERSION_NUMBER" > "$VERSION_FILE"
    FILE_TAG="$VERSION_NUMBER"
else
    while true; do
        read -p "Enter target version [$LAST_VERSION]: " VERSION_NUMBER
        VERSION_NUMBER=${VERSION_NUMBER:-$LAST_VERSION}

        if ! [[ "$VERSION_NUMBER" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Error: Version must be in X.Y.Z format (e.g. 1.0.0)"
            continue
        fi

        if ! version_gte "$VERSION_NUMBER" "$LAST_VERSION"; then
            echo "Error: Version must be >= $LAST_VERSION"
            continue
        fi

        break
    done

    echo "$VERSION_NUMBER" > "$VERSION_FILE"
    FILE_TAG="$EPOCH"
fi

# ── Build ───────────────────────────────────────────────────────────────

ANDROID_DIR="$OUTPUT_DIR/Android"
IOS_DIR="$OUTPUT_DIR/iOS"

echo ""
echo "============================================"
echo "MeshCore TEAM Build"
echo "Version: $VERSION_NUMBER"
echo "Build number: $EPOCH"
echo "File tag: $FILE_TAG"
echo "============================================"
echo ""

mkdir -p "$ANDROID_DIR"
mkdir -p "$IOS_DIR"

STEP=0
TOTAL=0
$BUILD_APK && TOTAL=$((TOTAL + 1))
$BUILD_AAB && TOTAL=$((TOTAL + 1))
$BUILD_IPA && TOTAL=$((TOTAL + 1))

# Build Android APK
if $BUILD_APK; then
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL] Building Android APK..."
    flutter build apk --release \
        --build-name="$VERSION_NUMBER" \
        --build-number="$EPOCH"
    cp build/app/outputs/flutter-apk/app-release.apk "$ANDROID_DIR/MeshCore-TEAM-$FILE_TAG.apk"
    echo "✓ Built: MeshCore-TEAM-$FILE_TAG.apk"
    echo ""
fi

# Build Android AAB
if $BUILD_AAB; then
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL] Building Android AAB..."
    flutter build appbundle --release \
        --build-name="$VERSION_NUMBER" \
        --build-number="$EPOCH"
    cp build/app/outputs/bundle/release/app-release.aab "$ANDROID_DIR/MeshCore-TEAM-$FILE_TAG.aab"
    echo "✓ Built: MeshCore-TEAM-$FILE_TAG.aab"
    echo ""
fi

# Build iOS IPA
if $BUILD_IPA; then
    STEP=$((STEP + 1))
    echo "[$STEP/$TOTAL] Building iOS IPA..."
    flutter build ipa --release \
        --build-name="$VERSION_NUMBER" \
        --build-number="$EPOCH"
    # Flutter outputs the IPA with the app name from pubspec
    IPA_FILE=$(find build/ios/ipa -name "*.ipa" -print -quit 2>/dev/null)
    if [ -n "$IPA_FILE" ]; then
        cp "$IPA_FILE" "$IOS_DIR/MeshCore-TEAM-$FILE_TAG.ipa"
        echo "✓ Built: MeshCore-TEAM-$FILE_TAG.ipa"
    else
        echo "⚠ IPA build completed but .ipa file not found in build/ios/ipa/"
    fi
    echo ""
fi

# ── Summary ─────────────────────────────────────────────────────────────

echo "============================================"
echo "Build Complete!"
echo "Version: $VERSION_NUMBER"
echo "Build number: $EPOCH"
echo ""
echo "Outputs:"
$BUILD_APK && echo "  APK: $ANDROID_DIR/MeshCore-TEAM-$FILE_TAG.apk"
$BUILD_AAB && echo "  AAB: $ANDROID_DIR/MeshCore-TEAM-$FILE_TAG.aab"
$BUILD_IPA && echo "  IPA: $IOS_DIR/MeshCore-TEAM-$FILE_TAG.ipa"
echo "============================================"
