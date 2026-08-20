# R8/ProGuard keep rules for the release build (isMinifyEnabled = true).
#
# Flutter's own embedding and most plugins ship their own consumer rules, which
# AGP applies automatically. These extra keeps guard the reflection-heavy bits
# that R8 can strip by mistake. Keep this list tight — add only what a real crash
# proves is needed.

# Flutter engine / embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Google Maps (google_maps_flutter) — accessed via the platform view registry
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.**

# Keep annotations / generic signatures used by JSON / reflection paths
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
