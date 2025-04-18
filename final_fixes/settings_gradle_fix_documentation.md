# توثيق إصلاح مشكلة ترتيب كتلة pluginManagement في ملف settings.gradle

## المشكلة
ظهرت مشكلة جديدة في المشروع عند محاولة بناء التطبيق في Android Studio:

```
The pluginManagement {} block must appear before any other statements in the script.
```

هذا الخطأ يشير إلى أن كتلة pluginManagement يجب أن تكون في بداية ملف settings.gradle قبل أي تعليمات أخرى، بينما في التعديل السابق تم وضعها بعد سطر include ':app'.

## الحل المطبق

تم إعادة ترتيب الكود في ملف settings.gradle بحيث تكون كتلة pluginManagement في البداية:

```gradle
// قبل التعديل
include ':app'

pluginManagement {
    gradle.ext.javaVersion = JavaVersion.VERSION_17
    
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

// بعد التعديل
pluginManagement {
    gradle.ext.javaVersion = JavaVersion.VERSION_17
    
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

include ':app'
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

1. **ترتيب الكود في ملف settings.gradle**: وفقاً لتوثيق Gradle، يجب أن تكون كتلة pluginManagement في بداية الملف قبل أي تعليمات أخرى.

2. **تنظيف ذاكرة التخزين المؤقت لـ Gradle**: لا تزال هذه الخطوة ضرورية بعد إجراء التغييرات على ملفات الإعدادات.

## ملخص التغييرات

1. تم إعادة ترتيب الكود في ملف settings.gradle بحيث تكون كتلة pluginManagement في البداية قبل أي تعليمات أخرى.

هذا التغيير البسيط يحل مشكلة "The pluginManagement {} block must appear before any other statements in the script" ويسمح للمشروع بالعمل بشكل صحيح مع JDK 24.
