# فلورابيت (Florabit) — دليل المشروع الشامل

هذا الملف هو **المرجع الوحيد** لشرح المشروع وتشغيله. يجمع الفكرة، المزايا، البنية، الأكواد المهمة، وخطوات التشغيل للواجهة الخلفية والموقع وتطبيق Flutter.

**فهرس الأقسام:** (1) الفكرة — (2) المزايا — (3) الهيكل — (4) ملفات مهمة — (5) قاعدة البيانات — (6–8) متطلبات وتشغيل — (9) سيناريو كامل — (10) أخطاء شائعة — (11) خاتمة — **(12) معجم مصطلحات — (13) جداول SQLite تفصيلاً — (14) الداتاسيت والمعالجة — (15) مرجع app.py — (16) مرجع plant_model.py — (17) Flutter — (18) أمثلة — (19) ملفات مساندة — (20) حدود المشروع — (21) قاعدة بيانات علائقية (مدن وكتالوج) — (22) الداتاسيت والذكاء الاصطناعي بالتفصيل — (23) لوحة التحكم (الموقع) — (24) تطبيق Flutter بالتفصيل.**

---

## 1. الفكرة والهدف

**فلورابيت** نظام ذكي رقمي للعناية بالنباتات المنزلية يجمع:

- **تطبيق جوال (Flutter)** لإدارة النباتات، التعرف بالصورة، التنبيهات، وسجل العناية.
- **موقع ويب (لوحة تحكم)** لعرض وإدارة البيانات عبر المتصفح.
- **خادم API (Flask + Python)** مع **SQLite** لتخزين المستخدمين والنباتات وسجلات العناية.
- **نموذج تعلم آلي** (مدرب) للتعرف على النبات من الصورة، مع احتياطي لوني عند غياب النموذج.

الهدف: إرشادات مخصصة، مواعيد ري وتسميد، تنبيهات، تتبع للعناية، وواجهة عربية واضحة.

---

## 2. المزايا الرئيسية

### أ) تطبيق الجوال (Flutter)

| الميزة | الوصف |
|--------|--------|
| تسجيل ودخول | بريد وكلمة مرور (تخزين مشفّر على الخادم) |
| الرئيسية | قائمة النباتات، **ملخص عناية ذكي** (مؤشر، تأخيرات، سلسلة أيام، نصيحة يومية) |
| معرض النباتات | كتالوج مع توصيات حسب المدينة ونوع المنزل |
| التعرف بالكاميرا/المعرض | إرسال الصورة للخادم وتحليلها بالنموذج المدرب |
| إضافة نبتة | يدوياً أو من نتائج التعرف أو من المعرض |
| تفاصيل النبتة | إرشادات، ري، تسميد، **تسجيل إضاءة/موقع**، سجل عناية، باركود |
| التنبيهات | تذكيرات محلية مرتبطة بمواعيد العناية |

### ب) الموقع (لوحة المسؤولين)

الواجهة الافتراضية للمتصفح مخصّصة **للمسؤولين فقط**؛ المستخدمون العاديون يستخدمون تطبيق Flutter. `index.html` يوجّه إلى `login.html` أو `dashboard.html` حسب الجلسة.

| الصفحة | الوظيفة |
|--------|---------|
| `index.html` | توجيه ذكي (مدير → لوحة التحكم، غير ذلك → صفحة تسجيل الدخول) |
| `login.html` | تسجيل دخول المسؤول |
| `dashboard.html` | إحصاءات واختصارات |
| `plants.html` | إدارة النباتات |
| `plant_details.html` | تفاصيل وري/تسميد |
| `catalog.html` | كتالوج النباتات |
| `reports.html` | تقارير ومواعيد قادمة |
| `users.html` | المستخدمون |
| `care_logs.html` | سجل العناية |
| `about.html` | عن النظام |
| `project.html` | نبذة عامة عن المشروع (للزوار، بدون دخول) |

### تابع: الحسابات والوصول

- **تسجيل المستخدم العادي**: من **تطبيق Flutter** فقط (`POST /api/users` بدون جلسة ويب) — لا توجد صفحة تسجيل على الموقع.
- **إنشاء مستخدم من لوحة المسؤول**: من صفحة `users.html` مع جلسة `admin`.
- **حساب مسؤول جاهز للتطوير**: بعد تهيئة قاعدة البيانات، شغّل من مجلد `web`:
  `python seed_admin.py`
  - ينشئ أو يحدّث مستخدماً بالبريد وكلمة المرور التالية (غيّرها في الإنتاج):

| البريد | كلمة المرور |
|--------|-------------|
| `admin@florabit.local` | `FlorabitAdmin2026` |

- **إن لم تُشغّل `seed_admin.py`**: عند أول تشغيل وعدم وجود أي `admin`، يُرفَع تلقائياً من يطابق `FLORABIT_ADMIN_EMAIL` أو المستخدم ذو **أصغر `id`** في `users`.

### ج) الخادم والذكاء

- **REST API** تحت المسار `/api/...` مع CORS للتطبيق.
- **كتالوج نباتات عربي** في `web/plant_model.py` (مدن، أنواع، فترات، نصائح `smart_tip`).
- **التعرف على الصورة**: `RandomForest` على ميزات مستخرجة من الصور، مدرب على مجموعة **flower_photos** (انظر `web/ml/train_plant_classifier.py`).
- **ملخص ذكي**: `GET /api/user/smart-summary?user_id=` — مؤشر صحة، تأخيرات، سلسلة أيام، نصيحة يومية.
- **لوحة المسؤول — رسوم**: `GET /api/admin/chart-insights` — توزيع سجلات العناية حسب النوع، وعدد السجلات يومياً (14 يوماً) لرسم الخطوط والأنواع.

بعد `seed_admin.py` يمكن تشغيل `python seed_demo_data.py` من مجلد `web` لزيادة بيانات تجريبية تُعرَض في لوحة التحكم والتقارير.

---

## 3. هيكل المجلدات (المهم للمطور)

```
florabit/
├── README.md                 ← هذا الدليل
├── app/app/                  ← مشروع Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── api_service.dart      ← عنوان الخادم baseUrl وكل الطلبات
│   │   ├── user_provider.dart
│   │   ├── notification_service.dart
│   │   └── screens/              ← الشاشات
│   ├── android/              ← Gradle، Manifest، إعدادات أندرويد
│   └── pubspec.yaml
├── web/
│   ├── app.py                ← Flask، SQLite، نقاط النهاية
│   ├── seed_admin.py         ← إنشاء/تحديث حساب المسؤول الافتراضي (بريد وكلمة مرور في الملف)
│   ├── seed_demo_data.py     ← بيانات تجريبية (مستخدمون demo، نباتات، سجلات عناية) للرسوم والإحصاء
│   ├── plant_model.py        ← الكتالوج، التعرف، النصائح، المدن
│   ├── catalog_db.py         ← إنشاء جداول المدن/الكتالوج والتهيئة الأولى
│   ├── requirements.txt
│   ├── ml/
│   │   ├── train_plant_classifier.py
│   │   └── DATASET_SOURCES.txt
│   ├── models/               ← plant_rf.joblib و class_names.json بعد التدريب
│   ├── data/
│   ├── static/
│   └── *.html
└── database.db               ← يُنشأ عند أول تشغيل داخل web/ عادة
```

---

## 4. أكواد وملفات يجب معرفتها

| الملف | الدور |
|--------|--------|
| `app/app/lib/api_service.dart` | عنوان الخادم `baseUrl` (للمحاكي غالباً `http://10.0.2.2:5000`) |
| `web/app.py` | تهيئة قاعدة البيانات، المسارات، تسجيل الدخول، النباتات، السجلات، الملخص الذكي |
| `web/plant_model.py` | بيانات النباتات، التعرف بالنموذج أو اللون، `get_tip_of_day`، كتالوج مع `smart_tip`؛ قراءة الكتالوج/المدن من SQLite عند التهيئة |
| `web/catalog_db.py` | جداول `cities` و`catalog_plants` و`catalog_plant_cities` والتهيئة من القوائم الافتراضية |
| `web/ml/train_plant_classifier.py` | تنزيل الداتاسيت وتدريب النموذج وحفظ `models/plant_rf.joblib` |
| `app/app/android/app/src/main/AndroidManifest.xml` | صلاحيات الإنترنت والكاميرا والتنبيهات |

---

## 5. قاعدة البيانات (SQLite)

- الملف الافتراضي: `web/database.db` (يُنشأ عند تشغيل `app.py`).
- الجداول: `users`، `plants`، `care_logs` مع حقول مثل `watering_interval_days`، `last_watering_date`، و`action_type` يشمل `watering` و`fertilizing` و`lighting`.

**إضافة علائقية (مدن وكتالوج):** بالإضافة إلى ما سبق، يوجد الآن مخطط يضم **`cities`** (قائمة المدن الرسمية)، و**`catalog_plants`** (صفوف نباتات الكتالوج مع ألوان وميزات JSON)، و**`catalog_plant_cities`** (ربط كثير-لكثير: أي نبتة كتالوج مناسبة لأي مدينة). حقل **`users.city_id`** يربط المستخدم بصف في `cities` مع الإبقاء على **`users.city`** كنص للتوافق مع التطبيق. التهيئة الأولى تتم من `web/catalog_db.py` عند تشغيل `init_db()` إذا كان الكتالوج في القاعدة فارغاً. **الشرح الموسّع والعلاقات في القسم 21.**

---

## 6. المتطلبات والإصدارات المعتمدة

| المكوّن | الإصدار المعتمد |
|---------|-----------------|
| **Python** | **3.10.16** |
| Flutter / Dart | حسب `pubspec.yaml` (مثلاً Dart ^3.8) |
| **Gradle (Android)** | **8.5** (عبر Gradle Wrapper) |

### بيئة بناء Gradle (مرجعية)

الإصدارات التالية تُعرض كمرجع لبيئة بناء متوافقة مع **Gradle 8.5**:

```
Build time:   2023-11-29 14:08:57 UTC
Revision:     28aca86a7180baa17117e0e5ba01d8ea9feca598

Kotlin:       1.9.20
Groovy:       3.0.17
Ant:          Apache Ant(TM) version 1.10.13 compiled on January 4 2023
JVM:          21.0.7 (Amazon.com Inc. 21.0.7+6-LTS)
OS:           Windows 11 10.0 amd64
```

> **ملاحظة:** في المشروع مفعّل **Android Gradle Plugin 8.3.2** و**Kotlin 1.9.22** ليتوافقا مع **Gradle 8.5** (القيم في المربع أعلاه مرجعية لبيئة بناء قريبة؛ الفرق الطفيف في رقم Kotlin طبيعي بين الأجهزة).

---

## 7. تثبيت متطلبات بايثون وتشغيل الخادم والموقع

### 7.1 تثبيت Python 3.10.16

- ثبّت **Python 3.10.16** من الموقع الرسمي لبايثون.
- عند التثبيت على ويندوز، فعّل خيار إضافة بايثون إلى **PATH** إن وُجد.

تحقق من الإصدار:

```powershell
python --version
```

يُفترض أن يظهر: `Python 3.10.16`

### 7.2 تثبيت حزم المشروع

من مجلد المشروع الرئيسي:

```powershell
pip install -r web/requirements.txt
```

### 7.3 تشغيل خادم Flask (الموقع + API)

```powershell
cd web
python app.py
```

- الموقع وواجهة API: **http://127.0.0.1:5000** أو **http://localhost:5000**
- اختبار سريع: افتح في المتصفح `http://localhost:5000/api/cities` يجب أن يعيد قائمة مدن بصيغة JSON.

### 7.4 (اختياري) تدريب نموذج التعرف على الصور

بعد تثبيت المتطلبات، من مجلد `web`:

```powershell
python ml/train_plant_classifier.py
```

يحمّل أرشيف الصور المعتمد في السكربت ويولّد ملفات النموذج تحت `web/models/`. بدون هذه الملفات قد يعمل التعرف بالاحتياطي اللوني فقط.

---

## 8. تثبيت Flutter وتشغيل التطبيق

### 8.1 Flutter SDK

- ثبّت Flutter حسب التوثيق الرسمي لنظامك.
- نفّذ:

```powershell
flutter doctor
```

### 8.2 Gradle 8.5

يستخدم المشروع **Gradle Wrapper**. تأكد أن الملف `app/app/android/gradle/wrapper/gradle-wrapper.properties` يشير إلى توزيعة **Gradle 8.5** (يتم ضبطها في المشروع).

عند أول بناء أندرويد، يُحمّل Gradle تلقائياً حسب الرابط في ذلك الملف.

### 8.3 تبعيات التطبيق والتشغيل

```powershell
cd app\app
flutter pub get
flutter run
```

- للمحاكي الأندرويد الافتراضي، عنوان الخادم في `api_service.dart` غالباً:

```dart
const String baseUrl = 'http://10.0.2.2:5000';
```

- للهاتف الحقيقي على نفس شبكة الـ Wi‑Fi: غيّر `baseUrl` إلى **عنوان IP** لجهاز الكمبيوتر الذي يشغّل Flask (مثلاً `http://192.168.1.10:5000`)، مع بقاء الخادم قيد التشغيل وجدار النظام يسمح بالمنفذ 5000.

---

## 9. تشغيل المشروع كاملاً (سيناريو عملي)

1. **طرفية 1 — الخادم**

```powershell
cd web
python app.py
```

2. **طرفية 2 — التطبيق**

```powershell
cd app\app
flutter run
```

3. افتح المتصفح على `http://localhost:5000` للوحة الويب، وشغّل التطبيق على المحاكي أو الجهاز.

---

## 10. استكشاف أخطاء شائعة

| المشكلة | ما يمكن فعله |
|---------|----------------|
| التطبيق لا يتصل بالخادم | تأكد أن `app.py` يعمل، وجرب `baseUrl` بـ IP الحاسوب للجهاز الحقيقي |
| الكاميرا لا تعمل | صلاحيات أندرويد في `AndroidManifest`، وطلب الإذن من التطبيق عند التصوير |
| التعرف ضعيف | درّب النموذج أو راجع وجود `plant_rf.joblib` و`class_names.json` في `web/models/` |

---

## 11. خاتمة (ملخص تشغيلي)

هذا المشروع يجمع واجهة ويب للمسؤولين، وتطبيق Flutter للمستخدمين، وخادم Flask مع SQLite، ومسار تعلم آلي للتعرف على الصور مع احتياطي لوني. **تشغيل المشروع ومراجعته يبدآن من هذا الملف.**

---

## 12. معجم مصطلحات (للمبتدئين)

| المصطلح | معنى عملي في فلورابيت |
|--------|------------------------|
| **API / REST** | عناوين URL يستدعيها التطبيق أو المتصفح لقراءة أو تعديل البيانات (مثل `/api/plants`). الطلب غالباً JSON. |
| **JSON** | نص منظم `{ "مفتاح": قيمة }` يتبادله الخادم والتطبيق. |
| **Flask** | إطار بايثون يستقبل الطلبات HTTP ويرد بصفحات أو JSON. |
| **SQLite** | ملف قاعدة بيانات واحد (`database.db`) بدون خادم قاعدة منفصل؛ مناسب للتطوير والمشاريع الصغيرة. |
| **CORS** | قواعد تسمح للمتصفح أو التطبيق بطلب موارد من نطاق مختلف؛ الخادم يضيف ترويسات `Access-Control-*`. |
| **الجلسة (Session)** | ملف تعريف ارتباط في المتصفح يحفظ من سجّل دخوله في لوحة الويب (`session['user_id']`). تطبيق Flutter لا يعتمد على الكوكيز؛ يمرّر `X-User-Id`. |
| **SHA-256** | دالة تجزئة؛ كلمة المرور تُخزَّن كقيمة طويلة غير قابلة للعكس المباشر (ليس تشفيراً متزامناً كاملاً لكنه المعتاد في المشاريع التعليمية). |
| **Random Forest** | مجموعة أشجار قرار؛ يتعلم من جدول ميزات `X` وتسميات `y`. |
| **ميزات (Features)** | أرقام تُستخرج من الصورة (هستوغرام ألوان + متوسط/انحراف قنوات RGB) بدل الصورة الخام. |
| **Histogram** | عدّ تكرار درجات اللون في فترات؛ يعطي توزيعاً للون. |
| **احتياطي لوني (Color fallback)** | إذا لم يوجد نموذج ML، يُقارن لون الصورة المتوسط مع ألوان نباتات الكتالوج في الذاكرة. |
| **joblib** | تنسيق حفظ/تحميل نموذج scikit-learn في ملف `.joblib`. |
| **Flutter / Widget** | واجهة التطبيق مبنية من مكوّنات مثل `Scaffold` و`ListView`. |
| **Pigeon (في السياق)** | جسر منصة بين Dart والكود الأصلي؛ أحياناً يفشل بعد Hot Restart مع `SharedPreferences`. |

---

## 13. قاعدة البيانات SQLite — الجداول والأعمدة

الملف: `web/database.db` (يُنشأ عند `init_db()` أول تشغيل لـ `app.py`).

### 13.1 جدول `users`

| العمود | النوع | الوصف |
|--------|--------|--------|
| `id` | INTEGER PK | رقم المستخدم تلقائياً. |
| `name` | TEXT | الاسم الظاهر. |
| `email` | TEXT UNIQUE | البريد (فريد). |
| `password` | TEXT | تجزئة SHA-256 لكلمة المرور (إن وُجدت). |
| `city` | TEXT | المدينة (اختياري؛ للتوصيات؛ يبقى متزامناً مع الاسم المعروض). |
| `city_id` | INTEGER | (اختياري) مفتاح أجنبي منطقي إلى `cities.id`؛ يُملأ عند التطابق مع اسم مدينة في الجدول. |
| `home_type` | TEXT | نوع المنزل: شقة، فيلا، إلخ. |
| `created_at` / `updated_at` | TEXT | طوابع وقت نصية. |
| `role` | TEXT | `user` أو `admin`. |
| `suspended_until` | TEXT | نهاية التعليق إن وُجد. |
| `is_active` | INTEGER | 1 نشط، 0 موقوف. |

**قواعد:** تسجيل مستخدم عادي من التطبيق يضع `role = user`. أول مدير يُضبط عبر `seed_admin.py` أو `_ensure_admin_exists`. لا يُحذف آخر `admin`.

### 13.2 جدول `plants`

| العمود | النوع | الوصف |
|--------|--------|--------|
| `id` | INTEGER PK | رقم النبتة. |
| `user_id` | INTEGER FK | يشير إلى `users.id`. |
| `catalog_id` | INTEGER | ربط اختياري بصف في كتالوج `plant_model` (1-based في المخرجات). |
| `name`, `type` | TEXT | الاسم والنوع (مثل داخلي/زينة). |
| `indoor_outdoor` | TEXT | داخلي أو خارجي. |
| `watering_interval_days` / `fertilizing_interval_days` | INTEGER | أيام بين الري والتسميد. |
| `last_watering_date` / `last_fertilizing_date` | TEXT | آخر تاريخ مسجّل. |
| `notes` | TEXT | ملاحظات. |
| `latitude` / `longitude` | REAL | إحداثيات اختيارية من التطبيق. |
| `created_at` / `updated_at` | TEXT | طوابع وقت. |

**قواعد:** حذف نبتة يحذف سجلات `care_logs` المرتبطة أولاً. التعديل يتطابق مع صاحب النبتة أو `X-User-Id` أو جلسة admin.

### 13.3 جدول `care_logs`

| العمود | النوع | الوصف |
|--------|--------|--------|
| `id` | INTEGER PK | رقم السجل. |
| `plant_id` | INTEGER FK | النبتة. |
| `action_type` | TEXT | `watering` أو `fertilizing` أو `lighting`. |
| `action_date` | TEXT | وقت الحدث. |
| `notes` | TEXT | ملاحظة اختيارية. |

**قواعد:** مسارات `/water` و`/fertilize` و`/light` تُدرج سجلاً وتُحدّث حقول `last_*` عند الري والتسميد فقط.

### 13.4 جدول `cities`

| العمود | النوع | الوصف |
|--------|--------|--------|
| `id` | INTEGER PK | معرّف المدينة. |
| `name` | TEXT UNIQUE NOT NULL | الاسم بالعربية (كما يظهر في القوائم و`/api/cities`). |
| `sort_order` | INTEGER | ترتيب العرض (الافتراضي 0). |

### 13.5 جدول `catalog_plants`

| العمود | النوع | الوصف |
|--------|--------|--------|
| `id` | INTEGER PK | معرّف صف الكتالوج (يُستخدم كـ `catalog_id` في التطبيق عند الربط). |
| `name` | TEXT UNIQUE NOT NULL | اسم النبتة بالعربية. |
| `type`, `indoor_outdoor` | TEXT | التصنيف والداخل/الخارج. |
| `watering`, `fertilizing` | INTEGER | فترات الري والتسميد بالأيام. |
| `light` | TEXT | وصف الإضاءة. |
| `colors_json` | TEXT | مصفوفة `[R,G,B]` للاحتياطي اللوني (JSON). |
| `home_types_json` | TEXT | قائمة أنواع المنازل المناسبة (JSON). |
| `name_en` | TEXT | الاسم الإنجليزي (اختياري؛ مطابقة ERD). |
| `scientific_name` | TEXT | الاسم العلمي (اختياري). |
| `description` | TEXT | وصف نصي (اختياري). |
| `care_level` | TEXT | سهل / متوسط / صعب (يُملأ من المنطق أو التهيئة). |
| `created_at` / `updated_at` | TEXT | طوابع وقت الصف. |

### 13.6 جدول `catalog_plant_cities` (ربط كتالوج ↔ مدن)

| العمود | النوع | الوصف |
|--------|--------|--------|
| `catalog_plant_id` | INTEGER FK | يشير إلى `catalog_plants.id`. |
| `city_id` | INTEGER FK | يشير إلى `cities.id`. |
| (مفتاح مركّب) | | (`catalog_plant_id`, `city_id`) يمنع التكرار. |

**قواعد:** حذف مدينة من `cities` يُرفض من واجهة الإدارة إن وُجد مستخدمون يشير `city_id` إليها؛ ويُحذف ربطها من `catalog_plant_cities` تلقائياً عند السماح بالحذف. تعديل «أي مدينة تصلح لأي نبتة» يتم بإدراج/حذف صفوف في **`catalog_plant_cities`** (أو عبر مسارات `/api/admin/catalog-plant-cities` مع جلسة admin).

### 13.7 جدول `reminders` (مطابقة ERD)

| العمود | النوع | الوصف |
|--------|--------|--------|
| `id` | INTEGER PK | معرّف التذكير. |
| `plant_id` | INTEGER FK | نبات المستخدم (`plants.id`)، حذف متتالي `ON DELETE CASCADE`. |
| `reminder_type` | TEXT | مثل `watering`، `fertilizing`، `other`، `lighting`. |
| `due_date` | TEXT | موعد التذكير. |
| `is_sent` | INTEGER | 0/1 هل وُسجّل إرسال/تنفيذ. |
| `notes` | TEXT | ملاحظات. |
| `created_at` / `updated_at` | TEXT | طوابع وقت. |

**واجهات:** `GET /api/reminders?plant_id=` أو `?user_id=`، `POST /api/reminders`، `DELETE /api/reminders/<id>`. التطبيق الحالي يعتمد غالباً على **تنبيهات محلية**؛ هذا الجدول جاهز للمزامنة أو التقارير.

### 13.8 عرض `plant_catalog` (VIEW)

- في SQLite يُنشأ **`VIEW plant_catalog`** كقراءة مريحة لصفوف **`catalog_plants`** بأسماء أعمدة قريبة من الـ ERD: `name_ar` (من `name`)، `watering_days`، `fertilizing_days`، `light_requirement`، إلخ.
- الجدول الفعلي للتعديل هو **`catalog_plants`**؛ العرض للاستعلام والتوثيق.

### 13.9 تكميل `care_logs` و`plants`

- **`care_logs`:** أعمدة **`created_at`** و **`updated_at`** تُملأ عند إدراج سجل من الـ API.
- **`plants`:** فهرس فريد **`idx_plants_user_name_unique`** على (`user_id`, `name`) يمنع تكرار نفس الاسم لنفس المستخدم (قد يفشل الإنشاء إن وُجدت بيانات قديمة مكررة — يُعالج يدوياً).

---

## 14. الداتاسيت، الملفات المساعدة، ومسار المعالجة

### 14.1 مصدر التدريب (flower_photos)

- **المصدر:** أرشيف TensorFlow الرسمي (صور زهور، 5 مجلدات فئات بالإنجليزية: daisy, dandelion, roses, sunflowers, tulips).
- **الرابط في الكود:** `ARCHIVE_URL` داخل `web/ml/train_plant_classifier.py`.
- **التخزين المحلي بعد التنزيل:** `web/data/flower_photos_cache/flower_photos.tgz` ثم فك إلى `flower_photos/`.

### 14.2 خطوات المعالجة في `train_plant_classifier.py`

| الدالة | ماذا تفعل |
|--------|-----------|
| `extract_features_from_pil(img)` | تصغير الصورة إلى 128×128، RGB، تطبيع 0–1، هستوغرام 32 صندوقاً لكل قناة لون، ثم متوسط وانحراف معياري لكل قناة → متجه أرقام طوله ثابت. |
| `ensure_dataset()` | ينزّل الأرشيف إن لم يوجد، ويفك الضغط. |
| `load_samples(root, max_per_class=400)` | يمر على كل مجلد فئة، يقرأ حتى 400 صورة لكل فئة، يستخرج الميزات، ويُرجع `X`, `y`, `class_names`. |
| `main()` | يدرّب `RandomForestClassifier` (200 شجرة، `max_depth=24`, `class_weight='balanced_subsample'`)، يحفظ `web/models/plant_rf.joblib` و `class_names.json`، وينشئ `web/data/flower_class_map.json` إن لم يكن موجوداً (ربط إنجليزي → عربي افتراضي). |

**ملف `flower_class_map.json`:** يحوّل اسم الفئة الإنجليزي من النموذج إلى اسم عربي داخل `PLANT_DATABASE` (مثال: `roses` → `ورود`). إذا لم يُوجد تطابق، الكود قد يسقط إلى نبتة افتراضية مثل «صبار» في `plant_model._identify_plant_ml`.

### 14.3 وقت التشغيل (التعرف من التطبيق)

1. الصورة تصل كـ `multipart` أو Base64 في `POST /api/identify-plant`.
2. `identify_plant(image_data)` في `plant_model.py`:
   - يحاول `_identify_plant_ml`: تحميل joblib، استخراج نفس الميزات، `predict_proba`، أعلى 5 فئات، تحويل الأسماء عبر الخريطة، جلب صف من `PLANT_DATABASE`.
   - إن فشل أو لا يوجد نموذج: `_identify_plant_color_fallback` يقارن متوسط RGB للصورة مع حقل `colors` لكل نبتة في الذاكرة.

### 14.4 كتالوج النباتات العربي `PLANT_DATABASE`

- قائمة ثابتة في `plant_model.py`: كل عنصر فيه `name`, `type`, `indoor_outdoor`, `colors` [R,G,B], `watering`, `fertilizing`, `light`, `cities`, `home_types`.
- تُستخدم ك**مصدر تهيئة** وك**احتياطي** إذا كانت جداول الكتالوج في SQLite فارغة أو عند تعذّر القراءة؛ بعد التهيئة، **`get_plant_catalog` / `get_cities` / `get_recommendations`** و**`get_plant_rows()`** (للتعرف اللوني وML) تفضّل البيانات المخزّنة في **`catalog_plants` + `cities` + `catalog_plant_cities`** مع إبطال كاش عند التعديل عبر واجهات الإدارة (`invalidate_catalog_cache`).

### 14.5 مزامنة الكتالوج مع القاعدة

- عند أول تشغيل لـ `init_db()` ووجود جداول فارغة، يستدعي `web/catalog_db.py` **`seed_cities_and_catalog_if_empty`**: نسخ المدن من القائمة الافتراضية، ثم نسخ نباتات الكتالوج وروابط المدن من `PLANT_DATABASE`.
- **`migrate_users_city_id`**: يملأ `users.city_id` من `users.city` النصي عند تطابق الاسم مع `cities.name`.

---

## 15. مرجع `web/app.py` — دوال داخلية ونقاط النهاية

### دوال مساعدة (غير مسارات)

| الدالة | الغرض |
|--------|--------|
| `_parse_dt(s)` | تحويل نص تاريخ/وقت إلى `datetime` أو None. |
| `_plant_health_score(p, now)` | درجة 0–100 من تأخير الري والتسميد مقارنة بالفترات. |
| `_health_status_ar(score)` | ترجمة الدرجة إلى نص عربي (ممتاز / جيد / …). |
| `_care_streak_days(conn, user_id)` | عد الأيام المتتالية (من اليوم للخلف) التي فيها أي سجل عناية. |
| `_cors(response)` | إضافة ترويسات CORS للرد. |
| `add_cors_headers` | مهيأ بعد كل طلب (`@app.after_request`). |
| `admin_required(f)` | ديكور يتحقق `session['role'] == 'admin'`. |
| `_account_block_reason(row_dict)` | سبب منع الدخول (موقوف/معلّق). |
| `_plant_access_denied(plant_id)` | هل الطلب مسموح لصاحب النبتة أو admin أو `X-User-Id`. |
| `_ensure_admin_exists(conn)` | ترقية مستخدم إلى admin إن لم يوجد أي admin. |
| `get_db()` | اتصال SQLite بـ `row_factory=Row`. |
| `init_db()` | إنشاء الجداول وتطبيق `ALTER` الاختيارية ثم `_ensure_admin_exists`. |
| `_fetch_admin_report_bundle()` | تجميع إحصاءات وجداول للتصدير. |
| `_sqlesc_sql` / `_bundle_to_txt` / `_bundle_to_sql` / `_bundle_to_csv_bytes` / `_bundle_to_xlsx_bytes` / `_pdf_ascii` / `_bundle_to_pdf_bytes` | تحضير ملفات التقرير بصيغ مختلفة. |

### مسارات API (ملخص)

| المسار | الطريقة | ملاحظة |
|--------|---------|--------|
| `/api/<path>` | OPTIONS | CORS preflight. |
| `/api/users` | GET | قائمة مستخدمين — **admin فقط**. |
| `/api/users` | POST | تسجيل؛ كلمة مرور ≥ 4؛ يحدد المدير `role` إن كانت جلسة admin. |
| `/api/users/<id>` | GET/PUT/DELETE | GET عام للمستخدم؛ PUT يشترط المالك أو admin؛ DELETE admin مع قيود حذف آخر مدير. |
| `/api/users/<id>/suspend` | POST | تعليق — admin. |
| `/api/users/<id>/activate` | POST | تفعيل — admin. |
| `/api/login` | POST | بريد + كلمة مرور؛ يملأ الجلسة للويب. |
| `/api/logout` | POST | مسح الجلسة. |
| `/api/auth/me` | GET | حالة الجلسة للويب. |
| `/api/plants` | GET | `?user_id=` للمستخدم؛ بدونها admin فقط. |
| `/api/plants` | POST | إنشاء نبتة؛ يدعم `latitude`/`longitude`. |
| `/api/plants/<id>` | GET/PUT/DELETE | قراءة/تعديل/حذف مع فحص الصلاحية. |
| `/api/plants/<id>/water` | POST | سجل ري + تحديث `last_watering_date`. |
| `/api/plants/<id>/fertilize` | POST | تسميد. |
| `/api/plants/<id>/light` | POST | سجل إضاءة فقط (لا يحدّث last_watering/fertilizing). |
| `/api/identify-plant` | POST | ملف `image` أو JSON `image_base64`. |
| `/api/plants/arabic-list` | GET | أسماء عربية من الكتالوج الثابت. |
| `/api/plant-catalog` | GET | الكتالوج الكامل مع `smart_tip`. |
| `/api/plants/recommendations` | GET | `?city=&home_type=` |
| `/api/cities`, `/api/home-types` | GET | قوائم للواجهات (`cities` من SQLite). |
| `/api/admin/cities` | GET/POST | إدارة المدن (جلسة admin). |
| `/api/admin/cities/<id>` | DELETE | حذف مدينة إن لم يُربط بها مستخدمون. |
| `/api/admin/catalog-plants` | GET | قائمة نباتات الكتالوج مع معرفاتها (admin). |
| `/api/admin/catalog-plant-cities` | POST/DELETE | ربط أو فك ربط نبتة كتالوج بمدينة. |
| `/api/admin/stats`, `/api/admin/chart-insights`, `/api/admin/user-analytics`, `/api/admin/report-export` | GET | إدارة وتصدير (معظمها admin). |
| `/api/plants/upcoming-care` | GET | `?user_id=` — مواعيد مقبلة وتأخيرات للتنبيهات. |
| `/api/user/smart-summary` | GET | `?user_id=` — ملخص ذكي + نصيحة اليوم. |
| `/api/care-logs` | GET/POST | قراءة أو إنشاء سجل يدوي. |
| `/api/reminders` | GET/POST | تذكيرات جدول `reminders` (`plant_id` أو `user_id` للقراءة). |
| `/api/reminders/<id>` | DELETE | حذف تذكير (صلاحية صاحب النبتة). |

### خدمة الملفات الثابتة والصفحات

- `/` → `index.html`
- `/<path>` → ملفات HTML أو ثابتة من مجلد `web`.

---

## 16. مرجع `web/plant_model.py`

| الاسم | نوعه | الوصف |
|--------|------|--------|
| `_extract_ml_features` | دالة | ميزات الصورة مثل التدريب (يجب أن تطابق أبعاد النموذج). |
| `_load_flower_map` | دالة | قراءة `data/flower_class_map.json`. |
| `_find_plant_row` | دالة | البحث عن نبتة بالاسم العربي في `PLANT_DATABASE`. |
| `_load_ml` | دالة | تحميل joblib + `class_names` مرة واحدة (كاش). |
| `_identify_plant_ml` | دالة | التنبؤ بالنموذج وإرجاع حتى 5 نتائج بثقة ومقاطع من الكتالوج. |
| `SAUDI_CITIES`, `HOME_TYPES`, `CITY_REGIONS_META` | ثوابت | قوائم للمدن وأنواع المنازل وتجميع جغرافي. |
| `PLANT_DATABASE` | قائمة | بيانات النباتات الكاملة. |
| `_get_dominant_colors` / `_color_distance` | دوال | للاحتياطي اللوني. |
| `_identify_plant_color_fallback` | دالة | ترتيب النباتات حسب قرب اللون. |
| `identify_plant` | دالة عامة | ML ثم احتياطي لوني. |
| `get_all_plants_arabic` | دالة | أسماء مبسطة. |
| `GENERAL_TIPS` | قائمة | نصائح عامة. |
| `smart_tip_for_plant` | دالة | نصيحة مبنية على حقول نبتة. |
| `get_tip_of_day` | دالة | نصيحة حسب يوم السنة. |
| `_city_regions_for_plant` / `_care_level_for_plant` / `_catalog_entry` | دوال | بناء مدخلات الكتالوج. |
| `get_plant_catalog` / `get_recommendations` | دوال | كتالوج كامل أو مفلتر (من SQLite عند التوفر). |
| `get_cities` / `get_home_types` | دوال | قوائم للـ API؛ المدن من جدول `cities` عند التوفر. |
| `get_plant_rows` / `invalidate_catalog_cache` | دوال | تحميل صفوف الكتالوج للتعرف؛ إبطال الكاش بعد تعديل القاعدة. |

---

## 17. تطبيق Flutter — ملفات أساسية

### 17.1 `lib/api_service.dart`

- **`baseUrl`:** عنوان الخادم (للمحاكي غالباً `http://10.0.2.2:5000`).
- **`_jsonHeadersWithUser()`:** يضيف `Content-Type: application/json` و`X-User-Id` من `UserProvider` عند الحاجة.
- **الدوال:** `register`, `login`, `identifyPlant`, `getArabicPlants`, `getPlants`, `getPlant`, `createPlant`, `waterPlant`, `fertilizePlant`, `getCareLogs`, `getPlantCatalog`, `getRecommendations`, `getCities`, `getHomeTypes`, `updateUser`, `updatePlant`, `getAdminStats`, `getUpcomingCare`, `logLightPlant`, `getSmartSummary` — كلها تطابق مسارات Flask الموضحة أعلاه.

### 17.2 `lib/user_provider.dart`

| عضو | الوصف |
|-----|--------|
| `currentUser` | خريطة المستخدم في الذاكرة (لا تُ persist تلقائياً بحد ذاتها). |
| `setUser` / `clearUser` / `mergeUser` | تعيين أو مسح أو دمج الحقول. |
| `userId`, `userName`, `city`, `homeType` | getters مريحة مع تحويل `id` إلى `int`. |

### 17.3 `lib/app_settings.dart` (ChangeNotifier)

| المفتاح الثابت | الغرض |
|----------------|--------|
| `keyCareNotifications` | تفعيل/تعطيل تذكيرات العناية. |
| `keyAvatarPath` | مسار صورة الملف الشخصي محلياً. |
| `keyThemeDark` | الوضع الداكن. |
| `load`, `setCareNotifications`, `setDarkMode`, `setAvatarPath` | قراءة/كتابة `SharedPreferences` مع `notifyListeners`. |

### 17.4 `lib/notification_service.dart`

- `initialize()`: تهيئة القناة على أندرويد، منطقة زمنية `Asia/Riyadh`، طلب إذن الإشعارات.
- `cancelAllCare()` / `syncCareReminders(userId)`: إلغاء أو جدولة تنبيهات بناءً على `getUpcomingCare` (تأخير ري/تسميد، وجدولة «غداً» عند `watering_days_until == 1` إلخ).

### 17.5 `lib/app_theme.dart`

- **ألوان ثابتة:** `primary`, `primaryLight`, `primaryDark`, `surfaceLight`, `cardBg`.
- **`lightTheme` / `darkTheme`:** إعدادات Material 3، خط IBM Plex Sans Arabic.
- **`slideRoute` / `fadeRoute`:** انتقالات تنقل مخصصة.

### 17.6 `lib/location_helper.dart`

- **`getCurrentPosition(context)`:** يتحقق من تشغيل GPS، أذونات الموقع، ثم `_resolvePosition()` (دقة متوسطة ثم منخفضة ثم آخر موقع معروف).

### 17.7 `lib/main.dart`

- `main()`: تهيئة إشعارات، `AppSettings`، اتجاه عمودي، `Provider`، `load()` بعد أول إطار.
- `FlorabitApp`: `MaterialApp` مع `locale: ar`، `themeMode` من الإعدادات، `AuthGate` كصفحة أولى.

### 17.8 `lib/session_store.dart`

| دالة | الوصف |
|------|--------|
| `save(user)` | حفظ JSON للمستخدم في `SharedPreferences` تحت المفتاح `florabit_user_session`. |
| `load()` | استرجاع الخريطة أو `null`. |
| `clear()` | حذف المفتاح (عند تسجيل الخروج). |

### 17.9 `lib/main_shell.dart`

- **`MainShell` (StatefulWidget):** `IndexedStack` بأربع صفحات: الرئيسية، الخريطة، حول، إعدادات؛ شريط تنقل سفلي `NavigationBar`.
- **`_onNavSelected`:** عند العودة للرئيسية يستدعي `HomeScreenState.refreshData()`؛ للخريطة `PlantsMapScreenState.refreshData()`.
- **خصائص الحالة:** `_index` (التاب الحالي)، `GlobalKey` للرئيسية والخريطة لاستدعاء التحديث.

### 17.10 `lib/screens/*` — وظيفة كل شاشة (ملخص)

| الملف | الدور |
|--------|--------|
| `auth_gate.dart` | عند الإقلاع: `SessionStore.load()` → إن وُجد مستخدم يفتح `MainShell` وإلا `LoginScreen`. |
| `login_screen.dart` | تسجيل الدخول عبر API وحفظ الجلسة. |
| `register_screen.dart` | تسجيل حساب جديد. |
| `home_screen.dart` | قائمة النباتات، الملخص الذكي، اختصارات للتعرف والمعرض وإضافة نبتة. |
| `add_plant_screen.dart` | نموذج إضافة نبتة مع اختيار من القائمة العربية وموقع اختياري. |
| `plant_details_screen.dart` | تفاصيل، ري/تسميد/إضاءة، سجل عناية، باركود. |
| `identify_plant_screen.dart` | كاميرا/معرض وإرسال الصورة للتعرف. |
| `plant_gallery_screen.dart` | توصيات الكتالوج حسب المدينة ونوع المنزل. |
| `plants_map_screen.dart` | خريطة نباتات المستخدم. |
| `settings_screen.dart` | الإعدادات، الوضع الداكن، التنبيهات، الصورة الشخصية. |
| `about_screen.dart` | معلومات عن التطبيق. |

**ملاحظة:** دوال وخصائص كل `State`/`Widget` داخل هذه الملفات (مثل `_water`، `build`، `initState`) هي تفاصيل واجهة؛ المرجع أعلاه يغطي الطبقة المشتركة (`ApiService` + الخادم). للاطلاع على كل دالة، افتح الملف في المحرر أو استخدم البحث في المشروع.

---

## 18. أمثلة واقعية سريعة

### طلب تسجيل مستخدم (Postman / curl)

```http
POST /api/users
Content-Type: application/json

{"name":"أحمد","email":"a@x.com","password":"1234","city":"الرياض","home_type":"شقة"}
```

### إضافة نبتة من التطبيق (فكرة الحقول)

```json
{
  "user_id": 1,
  "name": "بوتس ذهبي",
  "type": "داخلي",
  "watering_interval_days": 7,
  "fertilizing_interval_days": 30,
  "indoor_outdoor": "داخلي",
  "latitude": 24.7,
  "longitude": 46.6
}
```

### مثال «سلسلة أيام العناية»

إذا سجّل المستخدم رياً أو تسميداً أو إضاءة في أيام متتالية، `_care_streak_days` يزيد العدد من اليوم للخلف حتى يوم لا يوجد فيه سجل.

---

## 19. ملفات مساندة في المستودع

| الملف | المحتوى |
|--------|---------|
| `web/ml/DATASET_SOURCES.txt` | روابط داتاسيتات بديلة (Plant Village، Oxford 102، Kaggle، Hugging Face) ونصائح للتوسع. |
| `web/seed_admin.py` | إنشاء حساب المسؤول الافتراضي. |
| `web/seed_demo_data.py` | بيانات تجريبية للوحة التحكم. |
| `web/data/flower_class_map.json` | يُولَّد أو يُحرَّر لربط أسماء الإنجليزية بأسماء الكتالوج العربي. |

---

## 20. حدود يجب ذكرها في أي تقرير

- **flower_photos** خمس فئات فقط بالإنجليزية؛ التعرف «حقيقي» على مستوى تلك الفئات، ثم يُعرَض اسم عربي من الخريطة والكتالوج.
- **الاحتياطي اللوني** لا يميّز شكل الورقة؛ مناسب للتجربة فقط.
- **كلمات المرور** مخزنة بتجزئة بسيطة؛ للإنتاج يُنصح بـ bcrypt/argon2 وHTTPS.
- **الموقع الجغرافي** في الجدول اختياري؛ التحليل الإداري في `/api/admin/user-analytics` يذكر أن المدينة نصية وليست GPS تلقائياً.

---

## 21. قاعدة البيانات العلائقية — المدن وكتالوج النباتات (التصميم المحدّث)

### 21.1 الفكرة

بدل الاعتماد على قوائم بايثون وحدها، أصبحت **المدن** و**صفوف كتالوج النباتات** و**علاقة «هذه النبتة مناسبة لهذه المدينة»** مخزّنة في SQLite، مع بقاء النص **`users.city`** للتوافق مع واجهات التطبيق الحالية ومع **`users.city_id`** كربط اختياري بجدول **`cities`**.

### 21.2 مخطط العلاقات (باختصار)

- **`cities`** (1) ←→ (N) **`users`** عبر `users.city_id` (اختياري).
- **`catalog_plants`** (1) ←→ (N) **`catalog_plant_cities`** ←→ (N) **`cities`**: أي صف في الجدول الوسيط يعني «هذه النبتة من كتالوج النظام مناسبة لهذه المدينة».
- **`plants`** (نباتات المستخدمين) تبقى مرتبطة بـ **`users`**؛ حقل **`catalog_id`** يشير اختيارياً إلى **`catalog_plants.id`** عند الإضافة من المعرض.

### 21.3 الملفات والتهيئة

- **`web/catalog_db.py`**: `create_catalog_tables` لإنشاء الجداول؛ `seed_cities_and_catalog_if_empty` لنسخ البيانات من `PLANT_DATABASE` و`SAUDI_CITIES` **مرة واحدة** عندما يكون جدول `catalog_plants` فارغاً؛ `migrate_users_city_id` لمزامنة الأعمدة النصية مع المعرفات؛ `resolve_city_id` لاستخدامها من `app.py` عند التسجيل والتحديث.
- **`init_db()` في `app.py`**: ينشئ الجداول، يشغّل التهيئة والمزامنة، ثم يستدعي **`invalidate_catalog_cache()`** من `plant_model` حتى تُعاد قراءة الكتالوج من القاعدة في الذاكرة المؤقتة.

### 21.4 تعديل البيانات لاحقاً

- **إضافة مدينة:** `POST /api/admin/cities` بجسم JSON `{ "name": "...", "sort_order": 0 }` (يتطلب جلسة مسؤول من `/api/login`).
- **حذف مدينة:** `DELETE /api/admin/cities/<id>` إذا لم يكن هناك مستخدمون يملكون `city_id` يشير إليها.
- **ربط نبتة كتالوج بمدينة:** `POST /api/admin/catalog-plant-cities` بـ `{ "catalog_plant_id": 1, "city_id": 2 }`.
- **فك الربط:** `DELETE /api/admin/catalog-plant-cities?catalog_plant_id=1&city_id=2`.
- **عرض نباتات الكتالوج مع المعرفات:** `GET /api/admin/catalog-plants`.

---

## 22. الداتاسيت والذكاء الاصطناعي — كيف يعمل المسار في المشروع

### 22.1 ماذا نعني بـ«الداتاسيت» هنا؟

- **داتاسيت التدريب:** مجموعة **flower_photos** (أرشيف TensorFlow): صور زهور مصنّفة إلى **خمس فئات إنجليزية** (daisy, dandelion, roses, sunflowers, tulips). تُنزَّل وتُفك عبر `web/ml/train_plant_classifier.py` وتُخزَّن محلياً تحت `web/data/flower_photos_cache/`.
- **الداتاسيت ليس** كتالوج النباتات العربي بالكامل؛ هو **مادّة تدريب** لتعلّم التمييز بين تلك الفئات الخمس فقط.

### 22.2 من الصورة إلى الأرقام (استخراج الميزات)

1. تُقرأ الصورة وتُصغَّر إلى **128×128** بثلاث قنوات RGB.
2. لكل قناة لونية يُحسب **هستوغرام** (32 خانة) بعد تطبيع الشدة إلى [0،1].
3. تُضاف **متوسطات** و**انحرافات معيارية** لقنوات RGB.
4. الناتج متجه أرقام ثابت الطول؛ **نفس التحويل** يُستخدم في التدريب وفي الاستدلال عبر `plant_model._extract_ml_features`.

### 22.3 التدريب (غير متصل بالتشغيل اليومي إلا إذا شغّلت السكربت)

- يُدرَّب **`RandomForestClassifier`** (غابة عشوائية من أشجار قرار) على الميزات `X` والتسميات `y` (رقم الفئة 0..4).
- يُحفظ النموذج في **`web/models/plant_rf.joblib`** مع **`feature_dim`**، وأسماء الفئات الإنجليزية في **`class_names.json`**.
- **`flower_class_map.json`**: يربط كل اسمه إنجليزي (مثل `roses`) باسم عربي في كتالوج النظام (مثل «ورود») حتى تُعرَض النتائج للمستخدم بالعربية.

### 22.4 وقت التشغيل (عند التقاط صورة من التطبيق)

1. التطبيق يرسل الصورة إلى **`POST /api/identify-plant`** (ملف أو Base64).
2. **`identify_plant()`** في `plant_model.py`:
   - **أولاً:** إن وُجد النموذج، تُحسب الميزات وتُستدعى **`predict_proba`**؛ تُؤخذ أعلى احتمالات؛ تُترجم الأسماء عبر الخريطة؛ تُجلب بيانات الري/التسميد من صف الكتالوج (من **`get_plant_rows()`** التي تقرأ من SQLite أو من القائمة الاحتياطية).
   - **ثانياً:** إن تعذّر ML، يُستخدم **الاحتياطي اللوني**: يُقارن متوسط لون الصورة مع **`colors_json`** لكل نبتة في الكتالوج ويُرتّب النتائج حسب القرب.
3. الرد JSON يحتوي قائمة **`predictions`** بأسماء عربية وثقة ومواعيد ري/تسميد مقترحة.

### 22.5 حدود علمية (للتوثيق)

- الدقة مرتبطة بأن التدريب على **5 فئات زهور** وليس بجميع الأنواع العربية في الكتالوج؛ الجسر لغوياً عبر الخريطة والكتالوج.
- بدون ملفات النموذج، النظام يعتمد على **اللون** فقط، وهو أضعف من تمييز الشكل.

---

## 23. لوحة التحكم (الموقع الويب) — كيف تعمل بالتفصيل

### 23.1 الدور العام

الموقع مخصّص **للمسؤولين** بعد تسجيل الدخول عبر **جلسة متصفح (Cookie + session)**. المستخدمون العاديون لا يستخدمون هذه الصفحات للاستخدام اليومي؛ هم يستخدمون **تطبيق Flutter** الذي يتصل بـ **نفس الـ API** بدون الاعتماد على كوكيز الجلسة، ويمرّر **`X-User-Id`** عند الحاجة.

### 23.2 التدفق من المتصفح

1. **`index.html`**: يتحقق (عادةً عبر سكربت) إن كان هناك جلسة مسؤول؛ إن نعم يُوجَّه إلى **`dashboard.html`**، وإلا إلى **`login.html`**.
2. **`login.html`**: يرسل بريداً وكلمة مرور إلى **`POST /api/login`**. الخادم يتحقق من الجدول **`users`**، يضبط **`session['user_id']`** و**`session['role']`**، ويعيد بيانات المستخدم (بدون كلمة المرور الخام).
3. بقية الصفحات (`dashboard.html`, `users.html`, `plants.html`, …) تُحمَّل كملفات HTML ثابتة من Flask (`serve_page`) وتستخدم **JavaScript** (مثل `static/florabit-web.js`) لاستدعاء مسارات **`/api/admin/...`** و**`/api/...`** باستخدام **نفس أصل الموقع** (مثلاً `http://localhost:5000`)، مع إرسال الكوكيز تلقائياً للجلسة.

### 23.3 ماذا تعرض كل صفحة (منطقياً)

| الصفحة | الغرض التقني |
|--------|----------------|
| **لوحة التحكم** | غالباً تجلب **`/api/admin/stats`** و**`/api/admin/chart-insights`** لعرض أرقام ورسوم (توزيع أنواع العناية، نشاط يومي). |
| **المستخدمون** | CRUD عبر **`/api/users`** مع صلاحية admin؛ تعليق/تفعيل عبر **`/suspend`** و**`/activate`**. |
| **النباتات / التفاصيل** | قراءة **`/api/plants`** (مع `user_id` أو كامل للمدير) وتعديل الري/التسميد عبر مسارات **`/water`** و**`/fertilize`**. |
| **الكتالوج** | يمكن عرض **`/api/plant-catalog`** أو نسخة من البيانات؛ بعد التحديث العلائقي يعكس **قاعدة البيانات**. |
| **التقارير** | **`/api/plants/upcoming-care`** أو تقارير مخصّصة؛ **`/api/admin/report-export`** لتصدير JSON/CSV/SQL/PDF حسب الصيغة. |
| **التحليلات** | **`/api/admin/user-analytics`** (توزيع مدن، أنواع منازل، أكثر المستخدمين نباتات). |

### 23.4 الأمان على مستوى الواجهة

- مسارات **`/api/admin/*`** الحساسة محمية بـ **`@admin_required`**: بدون `session['role'] == 'admin'` يُرجع الخادم **403**.
- تصدير التقارير والإحصاءات الإدارية يتطلب نفس الجلسة.

---

## 24. تطبيق Flutter — كيف يعمل بالتفصيل

### 24.1 الإقلاع والتهيئة

- **`main.dart`**: يستدعي **`WidgetsFlutterBinding.ensureInitialized()`**، يهيئ **`NotificationService.initialize()`** (قنوات أندرويد، منطقة زمنية الرياض)، يضع **`AppSettings`** داخل **`ChangeNotifierProvider`**، يفرض اتجاهاً عمودياً، ويؤجّل **`settings.load()`** إلى بعد أول إطار لتقليل أخطاء قنوات المنصة مع **`SharedPreferences`**.
- **`MaterialApp`**: لغة **`ar`**، ثيم فاتح/داكن حسب **`AppSettings.themeMode`**، الاتجاه **RTL**، الصفحة الأولى **`AuthGate`**.

### 24.2 الجلسة في التطبيق (ليست كوكيز)

- **`AuthGate`**: يحاول **`SessionStore.load()`** من **`SharedPreferences`**؛ إن وُجد JSON مستخدم يُحمَّل إلى **`UserProvider.setUser`** ويُفتح **`MainShell`**؛ وإلا **`LoginScreen`**.
- بعد **`login`** أو **`register`** الناجحين، تُحفظ الخريطة عبر **`SessionStore.save`** لتبقى بعد إغلاق التطبيق.
- الطلبات للخادم تضيف **`X-User-Id`** تلقائياً من **`UserProvider.userId`** عبر **`ApiService._jsonHeadersWithUser()`** حيث يلزم تفويضاً.

### 24.3 الهيكل الرئيسي بعد الدخول

- **`MainShell`**: أربع تبويبات في **`IndexedStack`** (الرئيسية، الخريطة، حول، الإعدادات) مع **`NavigationBar`**؛ التبديل يستدعي **`refreshData`** للرئيسية والخريطة عند العودة لتحديث القوائم من الخادم.

### 24.4 تدفق البيانات من الشاشات إلى API

| الشاشة | استدعاءات تمثيلية |
|--------|---------------------|
| **الرئيسية** | `getPlants`, `getSmartSummary`, ثم **`syncCareReminders`** للتنبيهات المحلية. |
| **إضافة نبتة** | `getArabicPlants` أو اختيار يدوي؛ `createPlant`؛ اختيارياً موقع عبر **`LocationHelper`** و`updatePlant` للإحداثيات. |
| **التعرف** | قراءة بايتات الصورة؛ **`identifyPlant`** → نتائج؛ يمكن **`AddPlantScreen`** مع بيانات مقترحة. |
| **المعرض** | `getCities`, `getHomeTypes`, `getRecommendations` مع فلاتر المدينة ونوع المنزل؛ **`updateUser`** عند تطبيق الفلاتر لحفظ التفضيل. |
| **تفاصيل نبتة** | `getPlant`, `getCareLogs`, `waterPlant` / `fertilizePlant` / `logLightPlant`. |
| **الإعدادات** | `updateUser`, **`setDarkMode`** / **`setCareNotifications`** محلياً، **`setAvatarPath`**. |

### 24.5 التنبيهات

- **`NotificationService.syncCareReminders(userId)`** يجلب **`/api/plants/upcoming-care`** ويُجدول أو يُظهر إشعارات محلية (تأخير ري/تسميد، تذكير «غداً») إذا كانت التنبيهات مفعّلة في الإعدادات.

### 24.6 الفرق عن لوحة التحكم

- التطبيق **لا يعتمد** على `session` الخاص بالمتصفح؛ يعتمد على **معرف المستخدم** في الطلبات والتخزين المحلي.
- لوحة التحكم **تعتمد على الكوكيز** لنفس الخادم على المنفذ 5000؛ لذلك تسجيل الدخول من المتصفح منفصل عن تسجيل الدخول في التطبيق (حسابات يمكن أن تتطابق إذا استخدمت نفس البريد على الخادم نفسه).

---

*نهاية المرجع التفصيلي — الأقسام 1–10 أعلاه تبقى دليل التشغيل السريع؛ الأقسام 12–24 مرجع للكود والبيانات والواجهات.*
