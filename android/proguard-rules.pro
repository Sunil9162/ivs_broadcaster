# Keep AWS IVS SDK classes
-keep class com.amazonaws.** { *; }

# Keep OkHttp classes
-keep class okhttp3.** { *; }

# Keep Chromium Cronet classes
-keep class org.chromium.** { *; }

# Prevent warnings
-dontwarn okhttp3.**
-dontwarn org.chromium.**
-dontwarn com.amazonaws.**

# Keep all public classes in the project
-keep public class * {
    public protected *;
}

# Keep all annotations
-keepattributes *Annotation*

