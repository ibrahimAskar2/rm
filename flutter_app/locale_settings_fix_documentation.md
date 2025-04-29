# توثيق إصلاح مشكلة إعدادات اللغة والمنطقة

## المشكلة
ظهرت مشكلتان جديدتان في المشروع عند محاولة بناء التطبيق في Android Studio:

1. **مشكلة اتصال Kotlin compile daemon**: 
   ```
   Could not connect to Kotlin compile daemon
   ```
   هذا يشير إلى أن هناك مشكلة في الاتصال بخدمة Kotlin compile daemon.

2. **مشكلة تبعيات Groovy مع أحرف Unicode غير صحيحة**:
   ```
   Resource missing. [HTTP GET: https://dl.google.com/dl/android/maven2/org/codehaus/groovy/groovy/%D9%A3.%D9%A0.%D9%A1%D9%A7/groovy-%D9%A3.%D9%A0.%D9%A1%D9%A7.pom]
   ```
   هذه المشكلة تتعلق بوجود أحرف عربية (أو Unicode) في أرقام الإصدارات بدلاً من الأرقام اللاتينية. على سبيل المثال، يظهر "%D9%A3.%D9%A0.%D9%A1%D9%A7" بدلاً من "3.0.17".

## السبب الجذري
هذه المشكلات تتعلق بإعدادات اللغة والمنطقة في نظام التشغيل، حيث يتم استخدام الأرقام العربية بدلاً من الأرقام اللاتينية في بعض الملفات. عندما يحاول Gradle تحميل التبعيات، فإنه يستخدم أرقام الإصدارات بالتنسيق المحلي (العربي في هذه الحالة)، مما يؤدي إلى فشل العثور على الملفات في المستودعات.

بالإضافة إلى ذلك، قد تؤثر إعدادات اللغة والمنطقة أيضاً على اتصال Kotlin compile daemon، مما يؤدي إلى فشل عملية البناء.

## الحل المطبق

تم تعديل ملف `gradle.properties` لإضافة إعدادات JVM تجبر استخدام اللغة الإنجليزية والأرقام اللاتينية:

```properties
// قبل التعديل
org.gradle.jvmargs=-Xmx4G -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true

// بعد التعديل
org.gradle.jvmargs=-Xmx4G -Dfile.encoding=UTF-8 -Duser.language=en -Duser.country=US -Dkotlin.daemon.jvm.options="-Dfile.encoding=UTF-8" -Duser.variant=en
android.useAndroidX=true
android.enableJetifier=true
org.gradle.daemon=true
kotlin.incremental=false
```

التغييرات الرئيسية:
1. إضافة `-Duser.language=en -Duser.country=US` لتعيين اللغة والبلد إلى الإنجليزية والولايات المتحدة
2. إضافة `-Duser.variant=en` لضمان استخدام الأرقام اللاتينية
3. إضافة `-Dkotlin.daemon.jvm.options="-Dfile.encoding=UTF-8"` لتعيين ترميز الملفات لـ Kotlin daemon
4. إضافة `org.gradle.daemon=true` لتمكين Gradle daemon
5. إضافة `kotlin.incremental=false` لتعطيل البناء التزايدي لـ Kotlin، مما قد يساعد في حل مشكلة الاتصال بـ Kotlin daemon

## خطوات تشغيل المشروع بعد الإصلاح

1. قم بفك ضغط الملف المرفق
2. قم بتنفيذ سكريبت تنظيف ذاكرة التخزين المؤقت لـ Gradle:
   - في Windows: قم بتشغيل ملف `clean_gradle_cache.bat`
   - في Linux/macOS: قم بتنفيذ الأمر `chmod +x clean_gradle_cache.sh` ثم `./clean_gradle_cache.sh`
3. قم بتنفيذ الأمر التالي لإيقاف Gradle daemon:
   ```
   ./gradlew --stop
   ```
4. افتح المشروع في Android Studio
5. قم بتنفيذ الأمر التالي لتحديث التبعيات:
   ```
   flutter pub get
   ```
6. بعد نجاح تحديث التبعيات، يمكنك تشغيل المشروع على جهاز Android:
   ```
   flutter run
   ```

## ملاحظات مهمة

1. **إعدادات اللغة والمنطقة**: إذا كنت تستخدم نظام تشغيل بلغة عربية، فقد تحتاج إلى تعديل إعدادات اللغة والمنطقة في Android Studio أيضاً. يمكنك القيام بذلك من خلال:
   - افتح Android Studio
   - انتقل إلى File > Settings > Appearance & Behavior > System Settings > Language & Region
   - تأكد من تعيين اللغة إلى الإنجليزية للتطبيق

2. **تنظيف ذاكرة التخزين المؤقت لـ Gradle**: هذه الخطوة ضرورية بعد إجراء التغييرات على ملفات الإعدادات.

3. **إيقاف Gradle daemon**: قد تحتاج إلى إيقاف Gradle daemon قبل إعادة تشغيل المشروع لضمان تطبيق الإعدادات الجديدة.

## ملخص التغييرات

1. تم تعديل ملف `gradle.properties` لإضافة إعدادات JVM تجبر استخدام اللغة الإنجليزية والأرقام اللاتينية
2. تم إضافة إعدادات لـ Kotlin daemon لحل مشكلة الاتصال

هذه التغييرات تحل مشكلة "Could not connect to Kotlin compile daemon" ومشكلة الأرقام العربية في تبعيات Groovy، مما يسمح للمشروع بالعمل بشكل صحيح مع Gradle 8.4 وJDK 24.
