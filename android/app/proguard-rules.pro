# Flutter wrapper (no changes needed)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Services
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.common.internal.safeparcel.SafeParcelable {
    public static final *** NULL;
}

# Firebase Auth
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Sign-In with Apple (Added for compatibility)
-keep class com.sign_in_with_apple.** { *; }
-keepattributes *Annotation*

# Application classes that will be serialized/deserialized
-keep class com.example.biztrail.** { *; }

# Keep Parcelable classes
-keepnames class * implements android.os.Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final *** CREATOR;
}

# AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }

# Keep R classes
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Retrofit and OkHttp (optional, depending on your dependencies)
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Prevent stripping of Firebase Analytics code
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.android.gms.measurement.** { *; }

# Rules for dynamic features or fragments (ensure Flutter's fragments aren't stripped)
-keep class io.flutter.embedding.** { *; }

# Keep enums used in Google APIs (to avoid runtime crashes)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Prevent Play Core Library classes from being stripped
-keep class com.google.android.play.core.** { *; }
-keepclassmembers class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Prevent Flutter deferred components from being stripped
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keepclassmembers class io.flutter.embedding.engine.deferredcomponents.** { *; }
