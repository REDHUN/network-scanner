#!/bin/bash

echo "========================================"
echo "Building IP Tools : Network Scanner"
echo "for Google Play Store Upload"
echo "========================================"
echo

echo "[1/5] Cleaning previous builds..."
flutter clean
if [ $? -ne 0 ]; then
    echo "ERROR: Flutter clean failed!"
    exit 1
fi

echo "[2/5] Getting dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "ERROR: Flutter pub get failed!"
    exit 1
fi

echo "[3/5] Building App Bundle (AAB) for Play Store..."
flutter build appbundle --release
if [ $? -ne 0 ]; then
    echo "ERROR: App Bundle build failed!"
    echo "Make sure you have set up signing configuration!"
    exit 1
fi

echo "[4/5] Building APK for testing..."
flutter build apk --release
if [ $? -ne 0 ]; then
    echo "ERROR: APK build failed!"
    exit 1
fi

echo "[5/5] Build completed successfully!"
echo

echo "========================================"
echo "BUILD OUTPUTS:"
echo "========================================"
echo "App Bundle (for Play Store): build/app/outputs/bundle/release/app-release.aab"
echo "APK (for testing):          build/app/outputs/flutter-apk/app-release.apk"
echo

echo "File sizes:"
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(stat -f%z "build/app/outputs/bundle/release/app-release.aab" 2>/dev/null || stat -c%s "build/app/outputs/bundle/release/app-release.aab" 2>/dev/null)
    echo "AAB: $AAB_SIZE bytes"
fi

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(stat -f%z "build/app/outputs/flutter-apk/app-release.apk" 2>/dev/null || stat -c%s "build/app/outputs/flutter-apk/app-release.apk" 2>/dev/null)
    echo "APK: $APK_SIZE bytes"
fi

echo
echo "========================================"
echo "NEXT STEPS:"
echo "========================================"
echo "1. Test the APK on real devices"
echo "2. Upload the AAB file to Google Play Console"
echo "3. Complete store listing and submit for review"
echo
echo "Ready for Play Store upload! 🚀"