# Required by flutter_local_notifications <= v18 on Android release builds.
# Keeps Gson generic type metadata used by the plugin to persist scheduled
# notifications, otherwise release builds can fail with "Missing type parameter".

-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

-keep class com.dexterous.flutterlocalnotifications.** { *; }
