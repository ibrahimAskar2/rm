# توثيق إصلاح مشكلة انهيار خادم Gradle (Gradle Daemon)

## المشكلة
ظهرت مشكلة عند محاولة بناء التطبيق في Android Studio، حيث انهار خادم Gradle (Gradle Daemon) أثناء عملية البناء، مما أدى إلى فشل عملية البناء بالخطأ التالي:

```
Could not dispatch a message to the daemon.
Connection reset by peer
JVM crash log found: file:///C:/Users/Administrator/Desktop/25/final_fixes/android/hs_err_pid111956.log
```

## السبب الجذري
هذه المشكلة تتعلق بانهيار JVM أثناء عملية البناء، وقد تكون ناتجة عن:

1. **مشكلة في الذاكرة**: عدم كفاية الذاكرة المخصصة لـ Gradle أو JVM.
2. **مشكلة في تكوين JVM**: إعدادات JVM غير مناسبة لحجم المشروع.
3. **مشكلة في خادم Gradle**: انهيار خادم Gradle بسبب مشاكل في الاتصال أو التكوين.

## الحل المطبق

تم تنفيذ عدة تعديلات لحل هذه المشكلة:

### 1. تعديل ملف `gradle.properties`

تمت زيادة ذاكرة JVM المخصصة وإضافة خيارات JVM إضافية لتحسين الاستقرار:

```properties
# قبل التعديل
org.gradle.jvmargs=-Xmx4G -Dfile.encoding=UTF-8 -Duser.language=en -Duser.country=US -Dkotlin.daemon.jvm.options="-Dfile.encoding=UTF-8" -Duser.variant=en
android.useAndroidX=true
android.enableJetifier=true
org.gradle.daemon=true
kotlin.incremental=false

# بعد التعديل
org.gradle.jvmargs=-Xmx8G -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8 -Duser.language=en -Duser.country=US -Dkotlin.daemon.jvm.options="-Dfile.encoding=UTF-8 -Xmx4G" -Duser.variant=en -XX:+UseParallelGC
android.useAndroidX=true
android.enableJetifier=true
org.gradle.daemon=true
kotlin.incremental=false
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
# زيادة مهلة الاتصال
systemProp.org.gradle.internal.http.connectionTimeout=180000
systemProp.org.gradle.internal.http.socketTimeout=180000
# زيادة عدد محاولات إعادة المحاولة
systemProp.org.gradle.internal.repository.max.retries=5
systemProp.org.gradle.internal.repository.initial.backoff=500
# تقليل استخدام الذاكرة
org.gradle.jvmargs.append=-Dkotlin.daemon.jvmargs=-Xmx4G
```

### 2. التغييرات الرئيسية

1. **زيادة ذاكرة JVM المخصصة**:
   - تم زيادة الذاكرة المخصصة لـ JVM من 4G إلى 8G (`-Xmx8G`)
   - تم تحديد حجم ذاكرة PermGen بـ 512m (`-XX:MaxPermSize=512m`)

2. **إضافة خيارات JVM لتحسين الاستقرار**:
   - إنشاء ملف تفريغ الذاكرة عند حدوث خطأ نفاد الذاكرة (`-XX:+HeapDumpOnOutOfMemoryError`)
   - استخدام جامع القمامة المتوازي لتحسين الأداء (`-XX:+UseParallelGC`)

3. **تحسين إعدادات Gradle**:
   - تفعيل البناء المتوازي (`org.gradle.parallel=true`)
   - تفعيل التخزين المؤقت (`org.gradle.caching=true`)
   - تفعيل التكوين عند الطلب (`org.gradle.configureondemand=true`)

4. **زيادة مهلة الاتصال وعدد محاولات إعادة المحاولة**:
   - زيادة مهلة الاتصال إلى 180 ثانية
   - زيادة عدد محاولات إعادة المحاولة إلى 5

5. **تخصيص ذاكرة لخادم Kotlin**:
   - تخصيص 4G من الذاكرة لخادم Kotlin (`-Dkotlin.daemon.jvmargs=-Xmx4G`)

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
6. قم بتنفيذ الأمر التالي لبناء التطبيق:
   ```
   flutter build apk
   ```

## ملاحظات مهمة

1. **متطلبات الذاكرة**: تأكد من أن جهازك يحتوي على ذاكرة كافية (8GB على الأقل) لتشغيل عملية البناء بنجاح.

2. **إعدادات Android Studio**: قد تحتاج إلى زيادة الذاكرة المخصصة لـ Android Studio نفسه من خلال تعديل ملف `studio64.exe.vmoptions` (في Windows) أو `studio.vmoptions` (في macOS/Linux).

3. **تنظيف المشروع**: إذا استمرت المشكلة، جرب تنظيف المشروع بالكامل قبل إعادة البناء:
   ```
   flutter clean
   ```

4. **تحديث Flutter**: تأكد من استخدام أحدث إصدار من Flutter:
   ```
   flutter upgrade
   ```

## ملخص التغييرات

1. تم زيادة ذاكرة JVM المخصصة لـ Gradle
2. تم إضافة خيارات JVM إضافية لتحسين الاستقرار
3. تم تحسين إعدادات Gradle لتحسين الأداء
4. تم زيادة مهلة الاتصال وعدد محاولات إعادة المحاولة
5. تم تخصيص ذاكرة لخادم Kotlin

هذه التغييرات تهدف إلى حل مشكلة انهيار خادم Gradle وJVM أثناء عملية البناء، مما يسمح للمشروع بالعمل بشكل صحيح مع Gradle 8.4 وJDK 24.
