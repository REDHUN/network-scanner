# Optimized ProGuard rules for IP Tools : Network Scanner
# Conservative optimization while preserving functionality

# Basic optimization settings
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Keep line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Flutter Core - Keep essential classes
-keep class io.flutter.app.FlutterApplication { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Main Activity
-keep class com.unifydevelopers.iptools.MainActivity { *; }

# Network scanning essentials
-keep class java.net.InetAddress { *; }
-keep class java.net.NetworkInterface { *; }
-keep class java.nio.channels.DatagramChannel { *; }

# Plugin-specific optimizations
-keep class com.baseflow.connectivity_plus.ConnectivityPlusPlugin { *; }
-keep class dev.fluttercommunity.plus.network_info.NetworkInfoPlusPlugin { *; }
-keep class com.baseflow.permissionhandler.PermissionHandlerPlugin { *; }
-keep class dev.fluttercommunity.plus.share.SharePlusPlugin { *; }
-keep class io.flutter.plugins.pathprovider.PathProviderPlugin { *; }
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin { *; }
-keep class io.flutter.plugins.urllauncher.UrlLauncherPlugin { *; }

# Network Tools - Keep scanning methods
-keep class network_tools.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Remove debug logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Google Play Core - Handle missing classes
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Flutter Play Store Split Application
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# Deferred Components
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Suppress warnings for missing classes
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn sun.misc.Unsafe
-dontwarn java.lang.management.**
-dontwarn javax.naming.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Keep method parameters for debugging
-keepattributes MethodParameters

# Keep classes that might be accessed via reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Prevent R8 from optimizing away classes used via reflection
-keepclassmembers class * {
    public <init>(...);
}