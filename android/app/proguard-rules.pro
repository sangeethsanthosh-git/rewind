# REWIND Native Android Proguard Rules

# Room Database
-keep class androidx.room.** { *; }
-dontwarn androidx.room.**
-keep class com.antigravity.rewind.data.local.entity.** { *; }
-keep class com.antigravity.rewind.data.local.dao.** { *; }

# Media3 & ExoPlayer
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Coil Image Loading
-keep class coil.** { *; }
-dontwarn coil.**

# Data Models
-keep class com.antigravity.rewind.model.** { *; }
