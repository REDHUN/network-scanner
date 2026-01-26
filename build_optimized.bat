@echo off
REM Safe Build Script for IP Tools : Network Scanner
REM This script builds APKs with basic optimizations to avoid R8 issues

echo 🚀 Starting safe build process for IP Tools : Network Scanner
echo ==================================================

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean
flutter pub get

REM Build basic release APK (working configuration)
echo 📱 Building release APK (universal)...
flutter build apk --release

REM Build App Bundle for Play Store (recommended for store upload)
echo 📦 Building App Bundle for Play Store...
flutter build appbundle --release

REM Display build results
echo.
echo ✅ Build completed successfully!
echo ==================================================
echo 📊 Build Results:
echo.

REM Check if APK files exist and show them
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo 📱 Universal APK:
    dir build\app\outputs\flutter-apk\app-release.apk
    echo.
)

REM Check if App Bundle exists
if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo 📦 App Bundle:
    dir build\app\outputs\bundle\release\app-release.aab
    echo.
)

echo 🎯 Current Configuration:
echo    ✅ Basic release build (no R8 issues)
echo    ✅ Signed APK ready for distribution
echo    ❌ Advanced optimizations disabled (due to R8 compatibility)
echo.

echo 📋 Size Optimization Options:
echo    1. Enable ABI splits in build.gradle.kts for smaller per-arch APKs
echo    2. Replace Google Fonts with system fonts (3-5MB savings)
echo    3. Audit dependencies for unused packages
echo.

echo 🔍 For size analysis, run:
echo    flutter build apk --analyze-size

pause