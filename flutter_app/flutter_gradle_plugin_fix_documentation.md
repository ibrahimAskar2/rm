# توثيق إصلاح مشكلة تطبيق Flutter Gradle Plugin

## المشكلة
ظهرت مشكلة جديدة في المشروع عند محاولة بناء التطبيق في Android Studio:

```
You are applying Flutter's app_plugin_loader Gradle plugin imperatively using the apply script method, which is not possible anymore. Migrate to applying Gradle plugins with the declarative plugins block: https://flutter.dev/to/flutter-gradle-plugin-apply
```

هذا الخطأ يشير إلى أن طريقة تطبيق Flutter Gradle plugin في ملف settings.gradle قديمة ويجب تحديثها لاستخدام كتلة plugins الإعلانية بدلاً من أسلوب apply الإجرائي.

## الحل المطبق

تم تحديث طريقة تطبيق Flutter Gradle plugin في ملف settings.gradle من الأسلوب الإجرائي إلى الأسلوب الإعلاني:

```gradle
// قبل التعديل
def flutterSdkPath = properties.getProperty("flutter.sdk")
assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
apply from: "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle"

// بعد التعديل
def flutterSdkPath = properties.getProperty("flutter.sdk")
assert flutterSdkPath != null, "flutter.sdk not set in local.properties"

// تحديث طريقة تطبيق Flutter Gradle plugin من الأسلوب الإجرائي إلى الأسلوب الإعلاني
plugins {
    id 'dev.flutter.flutter-gradle-plugin' version '1.0.0' apply false
}

// تطبيق Flutter plugin على المشروع
settingsEvaluated { settings ->
    settings.includeBuild("${flutterSdkPath}/packages/flutter_tools/gradle")
}
```

## خطوات تشغيل المشروع بعد الإصلاح

1. قم بفك ضغط الملف المرفق
2. قم بتنفيذ سكريبت تنظيف ذاكرة التخزين المؤقت لـ Gradle:
   - في Windows: قم بتشغيل ملف `clean_gradle_cache.bat`
   - في Linux/macOS: قم بتنفيذ الأمر `chmod +x clean_gradle_cache.sh` ثم `./clean_gradle_cache.sh`
3. افتح المشروع في Android Studio
4. قم بتنفيذ الأمر التالي لتحديث التبعيات:
   ```
   flutter pub get
   ```
5. بعد نجاح تحديث التبعيات، يمكنك تشغيل المشروع على جهاز Android:
   ```
   flutter run
   ```

## ملاحظات مهمة

1. **تحديث طريقة تطبيق Flutter Gradle plugin**: وفقاً لتوثيق Flutter، يجب استخدام الأسلوب الإعلاني (declarative plugins block) بدلاً من الأسلوب الإجرائي (imperative apply method) لتطبيق Flutter Gradle plugin.

2. **تنظيف ذاكرة التخزين المؤقت لـ Gradle**: لا تزال هذه الخطوة ضرورية بعد إجراء التغييرات على ملفات الإعدادات.

## ملخص التغييرات

1. تم تحديث طريقة تطبيق Flutter Gradle plugin في ملف settings.gradle من الأسلوب الإجرائي إلى الأسلوب الإعلاني.

هذا التغيير يحل مشكلة "You are applying Flutter's app_plugin_loader Gradle plugin imperatively using the apply script method, which is not possible anymore" ويسمح للمشروع بالعمل بشكل صحيح مع Gradle 8.4 وJDK 24.
