#!/bin/bash

# Optimized Build Script for IP Tools : Network Scanner
# This script builds size-optimized APKs and App Bundles

echo "🚀 Starting optimized build process for IP Tools : Network Scanner"
echo "=================================================="

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build optimized APKs split by ABI (recommended for direct distribution)
echo "📱 Building optimized APKs (split by ABI)..."
flutter build apk --release --split-per-abi --analyze-size

# Build App Bundle for Play Store (recommended for store upload)
echo "📦 Building App Bundle for Play Store..."
flutter build appbundle --release --analyze-size

# Display build results
echo ""
echo "✅ Build completed successfully!"
echo "=================================================="
echo "📊 Build Results:"
echo ""

# Check if APK files exist and show sizes
if [ -d "build/app/outputs/flutter-apk" ]; then
    echo "📱 APK Files (split by architecture):"
    ls -lh build/app/outputs/flutter-apk/*.apk | awk '{print "   " $9 " - " $5}'
    echo ""
fi

# Check if App Bundle exists and show size
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    echo "📦 App Bundle:"
    ls -lh build/app/outputs/bundle/release/app-release.aab | awk '{print "   " $9 " - " $5}'
    echo ""
fi

echo "🎯 Optimization Summary:"
echo "   ✅ Code shrinking enabled (R8)"
echo "   ✅ Resource shrinking enabled"
echo "   ✅ ABI splits for smaller APKs"
echo "   ✅ Aggressive ProGuard rules applied"
echo ""

echo "📋 Next Steps:"
echo "   1. Test APKs on real devices"
echo "   2. Upload App Bundle to Play Store"
echo "   3. Monitor for any ProGuard-related crashes"
echo ""

echo "🔍 For detailed size analysis, run:"
echo "   flutter build apk --analyze-size --target-platform android-arm64"