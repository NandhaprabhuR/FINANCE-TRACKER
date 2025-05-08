# Keep TensorFlow Lite classes
-keep class org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }

# Keep GPU-related classes specifically
-keep class org.tensorflow.lite.gpu.** { *; }
-keepclassmembers class org.tensorflow.lite.gpu.** { *; }

# Prevent R8 from removing native methods
-keepclasseswithmembers class org.tensorflow.lite.** {
    native <methods>;
}

# Keep annotations and support classes
-keep class androidx.annotation.** { *; }
-keep @androidx.annotation.Keep class * { *; }

# Additional rules for TensorFlow Lite
-dontwarn org.tensorflow.lite.**
-keep class com.google.android.gms.** { *; }  # If using Google services with TFLite
-keepclassmembers class * {
    @org.tensorflow.lite.annotations.UsedByNative *;
}

# Keep classes that might be accessed via reflection
-keep class org.tensorflow.lite.support.** { *; }
-keepclassmembers class org.tensorflow.lite.support.** { *; }