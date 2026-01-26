# App Signing Setup for Play Store Upload

## 🔐 Create Signing Key

### 1. Generate Upload Keystore
Run this command in your project root:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important Information to Provide:**
- **Keystore password**: Choose a strong password (save it!)
- **Key password**: Choose a strong password (save it!)
- **First and last name**: Your name or company name
- **Organizational unit**: Your department/team
- **Organization**: Your company name
- **City**: Your city
- **State**: Your state/province
- **Country code**: Your country code (e.g., US, IN, UK)

### 2. Store Keystore Securely
- Move `upload-keystore.jks` to `android/app/` directory
- **NEVER commit this file to version control**
- Keep backup copies in secure locations

### 3. Create Key Properties File
Create `android/key.properties` with your keystore information:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

**Replace with your actual passwords!**

### 4. Update build.gradle.kts
Add this configuration to `android/app/build.gradle.kts`:

```kotlin
// Add at the top after plugins block
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing configuration ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            minifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

### 5. Update .gitignore
Add these lines to your `.gitignore`:

```
# Signing files
android/key.properties
android/app/upload-keystore.jks
*.jks
*.keystore
```

## 🚀 Build Signed Release

After setting up signing:

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build signed App Bundle (recommended)
flutter build appbundle --release

# Or build signed APK
flutter build apk --release
```

## 📁 Output Locations
- **App Bundle**: `build/app/outputs/bundle/release/app-release.aab`
- **APK**: `build/app/outputs/flutter-apk/app-release.apk`

## ⚠️ Security Notes
- **Never share your keystore or passwords**
- **Keep multiple secure backups of your keystore**
- **If you lose your keystore, you cannot update your app on Play Store**
- **Use different passwords for keystore and key**

## 🔄 For Future Updates
Always use the same keystore for app updates. Google Play will reject updates signed with different keys.