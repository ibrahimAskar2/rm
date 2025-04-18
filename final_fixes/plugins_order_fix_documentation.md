# توثيق إصلاح مشكلة ترتيب كتلة plugins في ملف settings.gradle

## المشكلة
ظهرت مشكلة جديدة في المشروع عند محاولة بناء التطبيق في Android Studio:

```
only buildscript {}, pluginManagement {} and other plugins {} script blocks are allowed before plugins {} blocks, no other statements are allowed
```

هذا الخطأ يشير إلى أن كتلة plugins يجب أن تكون بعد pluginManagement مباشرة وقبل أي تعليمات أخرى في الملف. في التعديل السابق، تم وضع كتلة plugins بعد تعريف متغير flutterSdkPath وهذا غير مسموح به.

## الحل المطبق

تم إعادة ترتيب الكود في ملف settings.gradle بحيث تكون كتلة plugins مباشرة بعد pluginManagement وقبل أي تعليمات أخرى:

```gradle
// قبل التعديل
pluginManagement {
    gradle.ext.javaVersion = JavaVersion.VERSION_17
    
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

include ':app'

def localPropertiesFile = new File(rootProject.projectDir, "local.properties")
def properties = new Properties()

assert localPropertiesFile.exists()
localPropertiesFile.withReader("UTF-8") { reader -> properties.load(reader) }

def flutterSdkPath = properties.getProperty("flutter.sdk")
assert flutterSdkPath != null, "flutter.sdk not set in local.properties"

// تحديث طريقة تطبيق Flutter Gradle plugin من الأسلوب الإجرائي إلى الأسلوب الإعلاني
plugins {
    id 'dev.flutter.flutter-gradle-plugin' version '1.0.0' apply false
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

// تحديث طريقة تطبيق Flutter Gradle plugin من الأسلوب الإجرائي إلى الأسلوب الإعلاني
plugins {
    id 'dev.flutter.flutter-gradle-plugin' version '1.0.0' apply false
}

include ':app'

def localPropertiesFile = new File(rootProject.projectDir, "local.properties")
def properties = new Properties()

assert localPropertiesFile.exists()
localPropertiesFile.withReader("UTF-8") { reader -> properties.load(reader) }

def flutterSdkPath = properties.getProperty("flutter.sdk")
assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
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

1. **ترتيب الكتل في ملف settings.gradle**: وفقاً لتوثيق Gradle، يجب أن تكون كتلة plugins بعد pluginManagement مباشرة وقبل أي تعليمات أخرى في الملف.

2. **تنظيف ذاكرة التخزين المؤقت لـ Gradle**: لا تزال هذه الخطوة ضرورية بعد إجراء التغييرات على ملفات الإعدادات.

## ملخص التغييرات

1. تم إعادة ترتيب الكود في ملف settings.gradle بحيث تكون كتلة plugins مباشرة بعد pluginManagement وقبل أي تعليمات أخرى.

هذا التغيير يحل مشكلة "only buildscript {}, pluginManagement {} and other plugins {} script blocks are allowed before plugins {} blocks, no other statements are allowed" ويسمح للمشروع بالعمل بشكل صحيح مع Gradle 8.4 وJDK 24.
