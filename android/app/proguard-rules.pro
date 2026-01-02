# FitnessOS ProGuard Rules
# Optimized for ML Kit Pose Detection + Flutter

# ========================================
# ML KIT POSE DETECTION
# ========================================
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-dontwarn com.google.android.gms.internal.**

# Keep pose landmark types
-keep class com.google.mlkit.vision.pose.** { *; }
-keep interface com.google.mlkit.vision.pose.** { *; }

# ========================================
# FLUTTER & DART
# ========================================
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ========================================
# CAMERA & MEDIA
# ========================================
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# ========================================
# SENSORS (for gyroscope calibration)
# ========================================
-keep class android.hardware.Sensor { *; }
-keep class android.hardware.SensorEvent { *; }
-keep class android.hardware.SensorManager { *; }

# ========================================
# PERFORMANCE OPTIMIZATIONS
# ========================================
# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Optimize math operations
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Preserve line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
