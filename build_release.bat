@echo off
echo ========================================
echo Building IP Tools : Network Scanner
echo for Google Play Store Upload
echo ========================================
echo.

echo [1/5] Cleaning previous builds...
flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed!
    pause
    exit /b 1
)

echo [2/5] Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed!
    pause
    exit /b 1
)

echo [3/5] Building App Bundle (AAB) for Play Store...
flutter build appbundle --release
if %errorlevel% neq 0 (
    echo ERROR: App Bundle build failed!
    echo Make sure you have set up signing configuration!
    pause
    exit /b 1
)

echo [4/5] Building APK for testing...
flutter build apk --release
if %errorlevel% neq 0 (
    echo ERROR: APK build failed!
    pause
    exit /b 1
)

echo [5/5] Build completed successfully!
echo.
echo ========================================
echo BUILD OUTPUTS:
echo ========================================
echo App Bundle (for Play Store): build\app\outputs\bundle\release\app-release.aab
echo APK (for testing):          build\app\outputs\flutter-apk\app-release.apk
echo.
echo File sizes:
for %%f in ("build\app\outputs\bundle\release\app-release.aab") do echo AAB: %%~zf bytes
for %%f in ("build\app\outputs\flutter-apk\app-release.apk") do echo APK: %%~zf bytes
echo.
echo ========================================
echo NEXT STEPS:
echo ========================================
echo 1. Test the APK on real devices
echo 2. Upload the AAB file to Google Play Console
echo 3. Complete store listing and submit for review
echo.
echo Ready for Play Store upload! 🚀
pause