# إصلاح مشكلة الاتصال بمستودعات Maven وتعارض إصدارات Gradle

هذا الملف يوثق المشكلات التي تم اكتشافها في سجل الإطلاق وكيفية إصلاحها.

## المشكلات المكتشفة

1. **مشكلة الاتصال بمستودعات Google Maven**:
   - ظهرت رسائل "Resource missing" عند محاولة تنزيل التبعيات من مستودع Google Maven
   - النظام تمكن من العثور على هذه التبعيات في مستودع Maven Central، لكن هذا يؤدي إلى تأخير وعدم استقرار في عملية البناء

2. **مشكلة عدم توافق إصدارات Gradle**:
   - النظام يستخدم Gradle 8.4، لكنه يحاول تنزيل مكونات Gradle 8.7.3
   - هذا التعارض يمكن أن يؤدي إلى مشاكل في عملية البناء وتعارض في التبعيات

## الحلول المطبقة

### 1. إضافة مستودعات Maven متعددة

تم تعديل ملفات `build.gradle` و `settings.gradle` لإضافة مستودعات متعددة:

```gradle
repositories {
    google()
    mavenCentral()
    jcenter()
    maven { url 'https://maven.aliyun.com/repository/google' }
    maven { url 'https://maven.aliyun.com/repository/public' }
    maven { url 'https://maven.aliyun.com/repository/gradle-plugin' }
    maven { url 'https://jitpack.io' }
    gradlePluginPortal()
}
```

هذه المستودعات توفر مصادر بديلة لتنزيل التبعيات، مما يضمن استمرار عملية البناء حتى إذا كان أحد المستودعات غير متاح.

### 2. تحديد إصدار Gradle المستخدم

تم إضافة الإعداد التالي في ملف `gradle.properties`:

```properties
org.gradle.toolchains.versions.gradle=8.4
```

هذا يضمن استخدام Gradle 8.4 في جميع أنحاء المشروع، ويمنع محاولات تنزيل إصدارات أخرى.

### 3. تحسين إعدادات الشبكة

تم إضافة إعدادات إضافية في ملف `gradle.properties` لتحسين أداء الشبكة:

```properties
systemProp.org.gradle.internal.http.disableRedirectVerification=true
systemProp.org.gradle.internal.repository.max.tentatives=10
systemProp.org.gradle.internal.http.idleTimeout=360000
```

هذه الإعدادات تزيد من مرونة الاتصال بالشبكة وتقلل من احتمالية فشل تنزيل التبعيات.

### 4. إضافة إعدادات الوكيل (معلقة)

تم إضافة إعدادات الوكيل (معلقة) في ملف `gradle.properties`:

```properties
#systemProp.http.proxyHost=proxy.example.com
#systemProp.http.proxyPort=8080
#systemProp.https.proxyHost=proxy.example.com
#systemProp.https.proxyPort=8080
```

يمكن إزالة التعليق وتعديل القيم إذا كنت تستخدم وكيلاً للاتصال بالإنترنت.

## خطوات تشغيل المشروع بعد الإصلاح

1. قم بفك ضغط الملف المرفق
2. قم بتنفيذ سكريبت تنظيف ذاكرة التخزين المؤقت لـ Gradle
3. قم بتنفيذ الأمر التالي لإيقاف Gradle daemon: `./gradlew --stop`
4. افتح المشروع في Android Studio
5. قم بتنفيذ الأمر `flutter pub get` لتحديث التبعيات
6. قم بتنفيذ الأمر `flutter run` لتشغيل المشروع

## ملاحظات إضافية

- إذا استمرت مشكلات الاتصال بالشبكة، جرب تفعيل إعدادات الوكيل في ملف `gradle.properties`
- إذا واجهت مشكلات في تنزيل تبعيات معينة، يمكنك تجربة تنزيلها يدوياً ووضعها في مجلد `.gradle/caches`
- تأكد من أن لديك اتصالاً مستقراً بالإنترنت أثناء عملية البناء
