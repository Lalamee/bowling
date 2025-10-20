# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.engine.FlutterJNI

# Networking libraries
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Dio/retrofit-like adapters
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**

# Flutter secure storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# Pdfx / pdfium native integration
-keep class io.scer.pdfx.** { *; }
-dontwarn io.scer.pdfx.**
-keep class com.shockwave.** { *; }
-dontwarn com.shockwave.**

-keepattributes *Annotation*
