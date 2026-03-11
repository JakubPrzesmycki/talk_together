# Flutter / Dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# App package (MainActivity, Flutter embedding)
-keep class com.atmaze.talktogether.** { *; }

# Google Fonts, easy_localization and other reflection-based libs
-dontwarn io.flutter.embedding.**
