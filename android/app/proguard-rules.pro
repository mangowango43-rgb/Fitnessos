# Flutter Local Notifications - CRITICAL for scheduled alarms
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Gson (used by flutter_local_notifications)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep notification classes
-keep class * extends android.app.Activity
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.app.Service

# Keep AndroidX classes
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }

# Timezone data
-keep class org.threeten.** { *; }
-dontwarn org.threeten.**
