# Keep Room-generated database implementations instantiable at runtime.
# WorkManager (used by androidx.glance) fails with
# "Failed to create an instance of androidx.work.impl.WorkDatabase"
# in release builds without these rules.
-keep class androidx.room.** { *; }
-keep class androidx.work.** { *; }
-keep @androidx.room.Database class * { *; }
-keepclassmembers class * extends androidx.room.RoomDatabase {
    <init>();
}