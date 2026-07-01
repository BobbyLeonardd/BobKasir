# ProGuard rules for BobKasir
# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in C:\Users\Bobby Leonardo\AppData\Local\Android\Sdk/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.kts.

# Keep Flutter generated classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Fix R8 missing classes for Google Play Core
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
