# 🧪 توثيق الاختبارات

هذا المستند يوفر توثيقاً شاملاً للاختبارات في نظام التجارة الإلكترونية.

## 📋 المحتويات

- [نظرة عامة](#نظرة-عامة)
- [بنية الاختبارات](#بنية-الاختبارات)
- [تشغيل الاختبارات](#تشغيل-الاختبارات)
- [اختبارات الوحدات](#اختبارات-الوحدات)
- [اختبارات الأمان](#اختبارات-الأمان)
- [اختبارات التكامل](#اختبارات-التكامل)
- [تغطية الاختبارات](#تغطية-الاختبارات)
- [أفضل الممارسات](#أفضل-الممارسات)

---

## 🎯 نظرة عامة

يستخدم المشروع **Bash Scripts** للاختبار، مع التركيز على اختبار واجهات برمجة التطبيقات (API Testing) والأمان.

### أنواع الاختبارات

1. **اختبارات الوظائف (Functional Tests)**: اختبار وظائف الـ API
2. **اختبارات الأمان (Security Tests)**: اختبار الثغرات الأمنية
3. **اختبارات التكامل (Integration Tests)**: اختبار التكامل بين الوحدات

### الأدوات المستخدمة

- **curl**: لإرسال طلبات HTTP
- **Bash Scripts**: لأتمتة الاختبارات
- **Shell Functions**: لتنظيم الاختبارات

---

## 📁 بنية الاختبارات

```
test/
├── test_config.sh          # إعدادات الاختبارات المشتركة
├── run_all_tests.sh        # تشغيل جميع الاختبارات
├── api_test.sh             # اختبارات API شاملة
├── test_auth.sh            # اختبارات المصادقة
├── test_category.sh        # اختبارات الفئات
├── test_product.sh         # اختبارات المنتجات
├── test_order.sh           # اختبارات الطلبات
├── test_review.sh          # اختبارات التقييمات
├── test_user.sh            # اختبارات المستخدمين
├── test_newsletter.sh      # اختبارات النشرة البريدية
└── test_security.sh        # اختبارات الأمان
```

---

## ⚙️ إعدادات الاختبارات

### test_config.sh

ملف الإعدادات المشتركة يحتوي على:

```bash
# Configuration
BASE_URL="http://localhost:3000/api"
TOKEN=""
ADMIN_TOKEN=""
USER_ID=""
CATEGORY_ID=""
PRODUCT_ID=""
ORDER_ID=""
REVIEW_ID=""
```

#### وظائف مساعدة

```bash
print_header()    # طباعة عنوان القسم
print_success()   # طباعة رسالة نجاح (أخضر)
print_error()     # طباعة رسالة خطأ (أحمر)
print_warning()   # طباعة رسالة تحذير (أصفر)
print_info()      # طباعة رسالة معلومات (أزرق)
```

---

## 🚀 تشغيل الاختبارات

### المتطلبات

1. **الخادم يعمل**:
```bash
npm run dev
# أو
npm start
```

2. **قاعدة البيانات متصلة**:
```bash
# تأكد من تشغيل MongoDB
mongod
```

### تشغيل جميع الاختبارات

```bash
cd test
./run_all_tests.sh
```

### تشغيل اختبارات محددة

```bash
# اختبارات المصادقة
./test_auth.sh

# اختبارات المنتجات
./test_product.sh

# اختبارات الطلبات
./test_order.sh

# اختبارات الأمان
./test_security.sh
```

### التحقق من حالة الخادم

يقوم `run_all_tests.sh` بالتحقق من حالة الخادم تلقائياً:

```bash
health_check=$(curl -s -w "\n%{http_code}" "${BASE_URL}/health")
```

---

## 📦 اختبارات الوحدات

### 1. اختبارات المصادقة (test_auth.sh)

#### الاختبارات المتاحة

| # | الاختبار | الوصف | النتيجة المتوقعة |
|---|---------|-------|------------------|
| 1 | تسجيل مستخدم صالح | تسجيل مستخدم ببيانات صحيحة | 201 Created |
| 2 | كلمة مرور ضعيفة | محاولة تسجيل بكلمة مرور ضعيفة | 400 Bad Request |
| 3 | بريد إلكتروني غير صالح | محاولة تسجيل ببريد غير صالح | 400 Bad Request |
| 4 | حقن SQL | محاولة حقن SQL في الاسم | 400/422 |
| 5 | هجوم XSS | محاولة حقن XSS في الاسم | 400/422 |
| 6 | تسجيل دخول صالح | تسجيل دخول ببيانات صحيحة | 200 OK |
| 7 | كلمة مرور خاطئة | محاولة تسجيل دخول بكلمة خاطئة | 401 Unauthorized |
| 8 | مستخدم غير موجود | محاولة تسجيل دخول بمستخدم غير موجود | 401 Unauthorized |
| 9 | الحد من الطلبات | 6 محاولات تسجيل دخول فاشلة | 429 Too Many Requests |
| 10 | Google Login | محاولة تسجيل دخول عبر Google | 400/401 |
| 11 | نسيت كلمة المرور | طلب إعادة تعيين كلمة المرور | 200 OK |
| 12 | نسيت كلمة المرور - بريد غير موجود | طلب إعادة تعيين لبريد غير موجود | 200 OK (لعدم كشف الوجود) |
| 13 | إعادة تعيين كلمة المرور | محاولة إعادة تعيين بكود خاطئ | 400/401 |
| 14 | تفعيل الحساب | محاولة تفعيل بكود خاطئ | 400/404 |

#### مثال على الاختبار

```bash
# تسجيل مستخدم صالح
response=$(curl -s -w "\n%{http_code}" -X POST \
    "${BASE_URL}/auth/register" \
    -H "Content-Type: application/json" \
    -d '{
        "email": "testuser@example.com",
        "password": "SecurePass123!",
        "firstName": "Test",
        "lastName": "User"
    }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
    print_success "Registration successful"
else
    print_error "Registration failed with HTTP $http_code"
fi
```

---

### 2. اختبارات المنتجات (test_product.sh)

#### الاختبارات المتاحة

| # | الاختبار | الوصف | النتيجة المتوقعة |
|---|---------|-------|------------------|
| 1 | الحصول على جميع المنتجات | جلب قائمة المنتجات | 200 OK |
| 2 | الحصول على منتج بالمعرف | جلب منتج محدد | 200 OK |
| 3 | البحث عن منتج بالاسم | البحث باسم المنتج | 200 OK |
| 4 | إنشاء منتج (بدون مصادقة) | محاولة إنشاء بدون token | 401 Unauthorized |
| 5 | إنشاء منتج (مع مصادقة) | إنشاء منتج ببيانات صحيحة | 201 Created |
| 6 | تحديث منتج | تحديث منتج موجود | 200 OK |
| 7 | حذف منتج | حذف منتج موجود | 200 OK |
| 8 | الترقيم (Pagination) | جلب المنتجات مع الترقيم | 200 OK |
| 9 | الفلاتر (Filters) | تطبيق فلاتر على المنتجات | 200 OK |

---

### 3. اختبارات الفئات (test_category.sh)

#### الاختبارات المتاحة

| # | الاختبار | الوصف | النتيجة المتوقعة |
|---|---------|-------|------------------|
| 1 | الحصول على جميع الفئات | جلب قائمة الفئات | 200 OK |
| 2 | الحصول على فئة بالاسم | جلب فئة محددة | 200 OK |
| 3 | إنشاء فئة (بدون مصادقة) | محاولة إنشاء بدون token | 401 Unauthorized |
| 4 | إنشاء فئة (مع مصادقة) | إنشاء فئة ببيانات صحيحة | 201 Created |
| 5 | تحديث فئة | تحديث فئة موجودة | 200 OK |
| 6 | حذف فئة | حذف فئة موجودة | 200 OK |

---

### 4. اختبارات الطلبات (test_order.sh)

#### الاختبارات المتاحة

| # | الاختبار | الوصف | النتيجة المتوقعة |
|---|---------|-------|------------------|
| 1 | إنشاء طلب (بدون مصادقة) | محاولة إنشاء بدون token | 401 Unauthorized |
| 2 | إنشاء طلب (مع مصادقة) | إنشاء طلب ببيانات صحيحة | 201 Created |
| 3 | الحصول على طلبات المستخدم | جلب طلبات المستخدم الحالي | 200 OK |
| 4 | الحصول على طلب محدد | جلب طلب بالمعرف | 200 OK |
| 5 | تحديث حالة الطلب (client) | محاولة تحديث من قبل client | 403 Forbidden |
| 6 | تحديث حالة الطلب (admin) | تحديث من قبل admin | 200 OK |
| 7 | إلغاء الطلب | إلغاء طلب موجود | 200 OK |

---

### 5. اختبارات التقييمات (test_review.sh)

#### الاختبارات المتاحة

| # | الاختبار | الوصف | النتيجة المتوقعة |
|---|---------|-------|------------------|
| 1 | إنشاء تقييم (بدون مصادقة) | محاولة إنشاء بدون token | 401 Unauthorized |
| 2 | إنشاء تقييم (مع مصادقة) | إنشاء تقييم ببيانات صحيحة | 201 Created |
| 3 | تقييم مكرر | محاولة تقييم نفس المنتج مرتين | 400 Bad Request |
| 4 | تقييم خارج النطاق | تقييم برقم خارج 1-5 | 400 Bad Request |
| 5 | الحصول على تقييمات منتج | جلب تقييمات منتج محدد | 200 OK |
| 6 | تحديث تقييم | تحديث تقييم موجود | 200 OK |
| 7 | حذف تقييم | حذف تقييم موجود | 200 OK |

---

### 6. اختبارات المستخدمين (test_user.sh)

#### الاختبارات المتاحة

| # | الاختبار | الوصف | النتيجة المتوقعة |
|---|---------|-------|------------------|
| 1 | الحصول على جميع المستخدمين (client) | محاولة من client | 403 Forbidden |
| 2 | الحصول على جميع المستخدمين (admin) | جلب من admin | 200 OK |
| 3 | الحصول على مستخدم بالمعرف | جلب مستخدم محدد | 200 OK |
| 4 | تحديث دور المستخدم (client) | محاولة من client | 403 Forbidden |
| 5 | تحديث دور المستخدم (admin) | تحديث من admin | 200 OK |
| 6 | حذف مستخدم (client) | محاولة من client | 403 Forbidden |
| 7 | حذف مستخدم (admin) | حذف من admin | 200 OK |

---

### 7. اختبارات النشرة البريدية (test_newsletter.sh)

#### الاختبارات المتاحة

| # | الاختبار | الوصف | النتيجة المتوقعة |
|---|---------|-------|------------------|
| 1 | الاشتراك في النشرة | اشتراك في النشرة البريدية | 200 OK |
| 2 | إلغاء الاشتراك | إلغاء الاشتراك | 200 OK |
| 3 | إرسال نشرة (client) | محاولة من client | 403 Forbidden |
| 4 | إرسال نشرة (admin) | إرسال من admin | 200 OK |
| 5 | الحصول على المشتركين | جلب قائمة المشتركين | 200 OK |

---

## 🔒 اختبارات الأمان (test_security.sh)

### الاختبارات الأمنية المتاحة

| # | الاختبار | الوصف | النتيجة المتوقعة |
|---|---------|-------|------------------|
| 1 | حقن NoSQL | محاولة حقن NoSQL في معلمات الطلب | 400/404 |
| 2 | حقن Headers | محاولة حقن headers ضارة | 200 (معالج بشكل صحيح) |
| 3 | Payload كبير (DoS) | إرسال payload كبير جداً | 413/400 |
| 4 | IDOR | محاولة الوصول لطلب مستخدم آخر | 403/404 |
| 5 | تعديل المعلمات | محاولة تعديل معلمات غير مصرح بها | 400/403 |

### تفاصيل الاختبارات الأمنية

#### 1. NoSQL Injection Test

```bash
# محاولة حقن NoSQL
response=$(curl -s -w "\n%{http_code}" -X GET \
    "${BASE_URL}/products/507f1f77bcf86cd799439011%20OR%201%3D1")

# النتيجة المتوقعة: 400 أو 404
```

**الهدف**: التحقق من أن النظام يمنع حقن NoSQL

---

#### 2. Header Injection Test

```bash
# محاولة حقن header ضار
response=$(curl -s -w "\n%{http_code}" -X GET \
    "${BASE_URL}/products" \
    -H "X-Forwarded-For: <script>alert(1)</script>")

# النتيجة المتوقعة: 200 (معالج بشكل صحيح)
```

**الهدف**: التحقق من أن النظام يعالج headers بشكل آمن

---

#### 3. Large Payload Test (DoS)

```bash
# إرسال payload كبير جداً
large_payload='{"data":"'$(printf 'A%.0s' {1..100000})'"}'
response=$(curl -s -w "\n%{http_code}" -X POST \
    "${BASE_URL}/auth/register" \
    -H "Content-Type: application/json" \
    -d "$large_payload")

# النتيجة المتوقعة: 413 أو 400
```

**الهدف**: التحقق من الحماية من هجمات DoS

---

#### 4. IDOR Test (Insecure Direct Object References)

```bash
# محاولة الوصول لطلب مستخدم آخر
response=$(curl -s -w "\n%{http_code}" -X GET \
    "${BASE_URL}/orders/507f1f77bcf86cd799439011" \
    -H "Authorization: Bearer $TOKEN")

# النتيجة المتوقعة: 403 أو 404
```

**الهدف**: التحقق من منع الوصول غير المصرح به لموارد الآخرين

---

#### 5. Parameter Tampering Test

```bash
# محاولة تعديل حالة الطلب لقيمة غير مصرح بها
response=$(curl -s -w "\n%{http_code}" -X PUT \
    "${BASE_URL}/orders/507f1f77bcf86cd799439011/status" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"status": "admin_only_status"}')

# النتيجة المتوقعة: 400 أو 403
```

**الهدف**: التحقق من منع تعديل المعلمات غير المصرح بها

---

## 🔗 اختبارات التكامل

### اختبارات التكامل المتاحة

توجد في `api_test.sh` وتختبر التكامل بين الوحدات المختلفة:

#### سيناريوهات التكامل

1. **تسجيل → تسجيل دخول → إنشاء طلب**
   - تسجيل مستخدم جديد
   - تسجيل الدخول
   - إنشاء منتج
   - إنشاء طلب

2. **إنشاء منتج → إضافة تقييم**
   - إنشاء منتج جديد
   - تسجيل دخول مستخدم
   - إضافة تقييم للمنتج

3. **إدارة الطلب**
   - إنشاء طلب
   - تحديث الحالة (admin)
   - التحقق من الحالة

---

## 📊 تغطية الاختبارات

### التغطية الحالية

| الوحدة | التغطية | الحالة |
|--------|---------|--------|
| المصادقة (Auth) | ✅ عالية | مكتمل |
| المنتجات (Products) | ✅ عالية | مكتمل |
| الفئات (Categories) | ✅ متوسطة | مكتمل |
| الطلبات (Orders) | ✅ متوسطة | مكتمل |
| التقييمات (Reviews) | ✅ متوسطة | مكتمل |
| المستخدمين (Users) | ✅ متوسطة | مكتمل |
| النشرة البريدية (Newsletter) | ✅ منخفضة | مكتمل |
| الأمان (Security) | ✅ عالية | مكتمل |

### نقاط تحتاج تحسين

- إضافة اختبارات للـ edge cases
- اختبارات الأداء (Performance Tests)
- اختبارات الحمل (Load Tests)
- اختبارات الإجهاد (Stress Tests)
- اختبارات واجهة المستخدم (UI Tests)

---

## 📝 كتابة اختبارات جديدة

### هيكل اختبار جديد

```bash
#!/bin/bash

# ============================================
# [Module Name] Endpoints Tests
# ============================================

source "$(dirname "$0")/test_config.sh"

test_[module]_endpoints() {
    print_header "TESTING [MODULE NAME] ENDPOINTS"

    # Test 1: Description
    print_info "1. Testing [endpoint] - [description]"
    response=$(curl -s -w "\n%{http_code}" -X [METHOD] \
        "${BASE_URL}/[endpoint]" \
        -H "Content-Type: application/json" \
        -d '[JSON_DATA]')
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "[EXPECTED_CODE]" ]; then
        print_success "[success message]"
    else
        print_error "[error message] with HTTP $http_code"
        echo "Response: $body"
    fi
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_[module]_endpoints
fi
```

### قواعد كتابة الاختبارات

1. **التسمية**: استخدم أسماء واضحة وموصوفة
2. **التنظيم**: قم بتجميع الاختبارات المتعلقة ببعضها
3. **التوثيق**: أضف تعليقات توضح الغرض من كل اختبار
4. **التحقق**: تحقق من HTTP code والاستجابة
5. **الأمان**: أضف اختبارات أمنية لكل نقطة نهاية

---

## 🛠️ أدوات الاختبار

### curl

أداة سطر الأوامر لإرسال طلبات HTTP:

```bash
# طلب GET
curl -X GET "${BASE_URL}/products"

# طلب POST
curl -X POST "${BASE_URL}/products" \
    -H "Content-Type: application/json" \
    -d '{"name": "Product"}'

# طلب مع headers
curl -X GET "${BASE_URL}/products" \
    -H "Authorization: Bearer $TOKEN"
```

### jq (اختياري)

أداة لمعالجة JSON:

```bash
# تثبيت jq
sudo apt-get install jq

# استخراج قيمة من JSON
echo '{"name": "Product"}' | jq '.name'

# تنسيق JSON
curl "${BASE_URL}/products" | jq '.'
```

---

## 🐛 معالجة الأخطاء في الاختبارات

### أخطاء شائعة

#### 1. الخادم لا يعمل

```bash
# الحل: تأكد من تشغيل الخادم
npm run dev
```

#### 2. قاعدة البيانات غير متصلة

```bash
# الحل: تأكد من تشغيل MongoDB
mongod
```

#### 3. متغيرات البيئة غير معدة

```bash
# الحل: أنشئ ملف .env
cp .env.example .env
# قم بتعديل الإعدادات
```

#### 4. الاختبارات تفشل بسبب البيانات القديمة

```bash
# الحل: نظف قاعدة البيانات
mongo
use ecommerce
db.dropDatabase()
```

---

## 📈 تقارير الاختبارات

### تفسير النتائج

#### ✅ نجاح (أخضر)

- الاختبار مر بنجاح
- النتيجة المتوقعة مطابقة للنتيجة الفعلية

#### ⚠️ تحذير (أصفر)

- الاختبار مر لكن مع ملاحظات
- قد يحتاج لمراجعة

#### ❌ فشل (أحمر)

- الاختبار فشل
- النتيجة غير متوقعة
- يحتاج لإصلاح

### مثال على تقرير

```
========================================
TESTING AUTHENTICATION ENDPOINTS
========================================

ℹ 1. Testing POST /auth/register - Valid
✓ Registration successful
Response: {"token":"...","user":{...}}

ℹ 2. Testing POST /auth/register - Weak Password - Security Test
✓ Weak password rejected - Security working

ℹ 3. Testing POST /auth/register - SQL Injection - Security Test
✓ SQL Injection attempt blocked - Security working
```

---

## ✅ أفضل الممارسات

### 1. قبل تشغيل الاختبارات

- ✅ تأكد من تشغيل الخادم
- ✅ تأكد من اتصال قاعدة البيانات
- ✅ نظف قاعدة البيانات من البيانات القديمة
- ✅ تحقق من متغيرات البيئة

### 2. أثناء كتابة الاختبارات

- ✅ اكتب اختبارات للأمان لكل endpoint
- ✅ اختبر الحالات الإيجابية والسلبية
- ✅ اختبر edge cases
- ✅ استخدم بيانات واقعية

### 3. بعد تشغيل الاختبارات

- ✅ راجع النتائج بعناية
- ✅ أصلح الاختبارات الفاشلة
- ✅ حدّث التوثيق
- ✅ أضف اختبارات جديدة للميزات الجديدة

### 4. في CI/CD

- ✅ شغّل الاختبارات تلقائياً
- ✅ أوقف النشر إذا فشلت الاختبارات
- ✅ أرسل إشعارات بنتائج الاختبارات
- ✅ احتفظ بسجلات الاختبارات

---

## 🔄 التكامل مع CI/CD

### مثال GitHub Actions

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '14'
    
    - name: Install dependencies
      run: npm install
    
    - name: Start MongoDB
      uses: supercharge/mongodb-github-action@1.3.0
    
    - name: Start server
      run: npm start &
    
    - name: Wait for server
      run: sleep 10
    
    - name: Run tests
      run: cd test && ./run_all_tests.sh
```

---

## 📚 المراجع

- [REST API Testing Best Practices](https://restfulapi.net/testing-rest-api/)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [curl Documentation](https://curl.se/docs/)
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
