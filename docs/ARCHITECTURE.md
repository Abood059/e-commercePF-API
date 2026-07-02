# 🏗️ توثيق البنية البرمجية

هذا المستند يوفر توثيقاً شاملاً لبنية النظام البرمجية ووظائف الوحدات المختلفة في نظام التجارة الإلكترونية.

## 📋 المحتويات

- [نظرة عامة](#نظرة-عامة)
- [النمط المعماري](#النمط-المعماري)
- [بنية المجلدات](#بنية-المجلدات)
- [الوحدات الرئيسية](#الوحدات-الرئيسية)
- [تدفق البيانات](#تدفق-البيانات)
- [التصميم](#التصميم)

---

## 🎯 نظرة عامة

يتبع النظام نمط **MVC (Model-View-Controller)** مع طبقات إضافية للفصل بين المسؤوليات:

```
Client Request → Routes → Controllers → Services → Repositories → Database
                      ↓              ↓              ↓
                 Middlewares    Validation    Business Logic
```

### المبادئ المعمارية

1. **Separation of Concerns**: فصل واضح بين المسؤوليات
2. **Single Responsibility**: كل وحدة لها مسؤولية واحدة
3. **Dependency Injection**: حقن التبعيات لسهولة الاختبار
4. **Layered Architecture**: طبقات واضحة ومحددة
5. **RESTful API**: تصميم واجهات برمجة تطبيقات RESTful

---

## 📐 النمط المعماري

### الطبقات المعمارية

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (Routes, Controllers, Middlewares)                     │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                     Business Layer                       │
│  (Services, Validation, Business Logic)                  │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                    Data Access Layer                     │
│  (Repositories, Domain Entities)                         │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                   │
│  (Database, Email, Payment, Cache)                      │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 بنية المجلدات

```
src/
├── app.js                      # إعداد Express application
├── server.js                   # نقطة دخول الخادم
│
├── config/                     # إعدادات التطبيق
│   └── index.js               # مركزي للإعدادات
│
├── controllers/                # Controllers (معالجة الطلبات)
│   ├── auth.controller.js     # مصادقة المستخدمين
│   ├── category.controller.js # إدارة الفئات
│   ├── newsletter.controller.js # إدارة النشرة البريدية
│   ├── order.controller.js   # إدارة الطلبات
│   ├── product.controller.js # إدارة المنتجات
│   ├── review.controller.js  # إدارة التقييمات
│   └── user.controller.js     # إدارة المستخدمين
│
├── domain/                     # كيانات قاعدة البيانات (Schemas)
│   ├── category.entity.js     # مخطط الفئة
│   ├── newsletter.entity.js   # مخطط النشرة البريدية
│   ├── order.entity.js        # مخطط الطلب
│   ├── product.entity.js      # مخطط المنتج
│   ├── review.entity.js       # مخطط التقييم
│   └── user.entity.js         # مخطط المستخدم
│
├── infrastructure/             # البنية التحتية
│   ├── cache/                 # التخزين المؤقت
│   ├── database/              # اتصال قاعدة البيانات
│   ├── email/                 # خدمة البريد الإلكتروني
│   └── payment/               # خدمة الدفع
│
├── middlewares/                # Middlewares
│   ├── auth.middleware.js     # التحقق من المصادقة
│   ├── error.middleware.js    # معالجة الأخطاء
│   ├── rateLimit.middleware.js # الحد من الطلبات
│   └── validation.middleware.js # التحقق من البيانات
│
├── repositories/                # Repositories (الوصول للبيانات)
│   ├── base.repository.js     # Repository أساسي
│   ├── category.repository.js  # فئات
│   ├── newsletter.repository.js # نشرة بريدية
│   ├── order.repository.js     # طلبات
│   ├── product.repository.js   # منتجات
│   ├── review.repository.js    # تقييمات
│   └── user.repository.js      # مستخدمين
│
├── routes/                      # تعريف المسارات
│   ├── index.js               # تجميع جميع المسارات
│   ├── auth.routes.js          # مسارات المصادقة
│   ├── category.routes.js      # مسارات الفئات
│   ├── newsletter.routes.js    # مسارات النشرة البريدية
│   ├── order.routes.js          # مسارات الطلبات
│   ├── product.routes.js        # مسارات المنتجات
│   ├── review.routes.js         # مسارات التقييمات
│   └── user.routes.js           # مسارات المستخدمين
│
├── services/                    # Business Logic
│   ├── auth.service.js         # منطق المصادقة
│   ├── category.service.js     # منطق الفئات
│   ├── newsletter.service.js   # منطق النشرة البريدية
│   ├── order.service.js        # منطق الطلبات
│   ├── product.service.js      # منطق المنتجات
│   ├── review.service.js       # منطق التقييمات
│   └── user.service.js         # منطق المستخدمين
│
└── utils/                       # وظائف مساعدة
    ├── (helper functions)
```

---

## 🧩 الوحدات الرئيسية

### 1. نقطة الدخول (Entry Point)

#### server.js
**الوظيفة**: نقطة بدء تشغيل التطبيق

**المسؤوليات**:
- تحميل متغيرات البيئة
- تهيئة قاعدة البيانات
- تهيئة خدمة البريد الإلكتروني
- تشغيل الخادم على المنفذ المحدد
- معالجة الأخطاء غير المتوقعة

**الكود الرئيسي**:
```javascript
- تحميل إعدادات dotenv
- الاتصال بقاعدة البيانات
- تهيئة خدمة البريد الإلكتروني
- تشغيل Express app
- معالجة unhandledRejection و uncaughtException
```

---

### 2. إعداد التطبيق (Application Setup)

#### app.js
**الوظيفة**: إعداد وتكوين Express application

**المسؤوليات**:
- تكوين Helmet للأمان
- تكوين CORS
- تكوين body parser
- تكوين cookie parser
- تكوين Morgan للتسجيل
- تسجيل Middlewares
- تسجيل المسارات
- معالجة الأخطاء

**الإعدادات**:
- Content Security Policy
- HSTS (HTTP Strict Transport Security)
- CORS للسماح بالطلبات من المصادر المسموح بها
- Rate limiting للحد من الطلبات

---

### 3. طبقة الإعدادات (Configuration Layer)

#### config/index.js
**الوظيفة**: مركزي لإدارة جميع إعدادات التطبيق

**المسؤوليات**:
- تحميل متغيرات البيئة
- تنظيم الإعدادات حسب الفئات
- توفير واجهة موحدة للوصول للإعدادات

**الإعدادات المتاحة**:
- `database`: إعدادات قاعدة البيانات
- `server`: إعدادات الخادم (port, env)
- `jwt`: مفاتيح JWT
- `google`: إعدادات Google OAuth
- `stripe`: إعدادات Stripe
- `email`: إعدادات البريد الإلكتروني
- `client`: رابط العميل
- `cache`: إعدادات التخزين المؤقت

---

### 4. طبقة المسارات (Routes Layer)

#### routes/index.js
**الوظيفة**: تجميع وتصدير جميع المسارات

**المسؤوليات**:
- استيراد جميع ملفات المسارات
- تجميعها تحت `/api`
- تصدير المسارات المجمعة

#### المسارات الفردية
كل ملف مسار مسؤول عن:
- تعريف نقاط النهاية (endpoints)
- ربطها بالـ controllers المناسبة
- تطبيق middlewares عند الحاجة

**أمثلة**:
- `auth.routes.js`: `/api/auth/signup`, `/api/auth/signin`
- `product.routes.js`: `/api/products`, `/api/products/create`
- `order.routes.js`: `/api/orders/create`, `/api/orders/user`

---

### 5. طبقة Controllers (Controllers Layer)

Controllers مسؤولة عن:
- استقبال الطلبات من المسارات
- استخراج البيانات من الطلب
- استدعاء الـ services المناسبة
- إرجاع الاستجابات للعميل

#### auth.controller.js
**الوظائف**:
- `signup`: تسجيل مستخدم جديد
- `signin`: تسجيل الدخول
- `googleLogin`: تسجيل الدخول عبر Google

#### product.controller.js
**الوظائف**:
- `getAllProducts`: الحصول على جميع المنتجات
- `getProductById`: الحصول على منتج بالمعرف
- `getProductByName`: البحث عن منتج بالاسم
- `createProduct`: إنشاء منتج جديد
- `updateProduct`: تحديث منتج
- `deleteProduct`: حذف منتج
- `getProductsForPage`: الحصول على منتجات مع الترقيم

#### order.controller.js
**الوظائف**:
- `createOrder`: إنشاء طلب جديد
- `getUserOrders`: الحصول على طلبات المستخدم
- `updateOrderStatus`: تحديث حالة الطلب

---

### 6. طبقة الخدمات (Services Layer)

Services تحتوي على منطق الأعمال (Business Logic):

#### auth.service.js
**الوظائف**:
- `registerUser`: تسجيل مستخدم جديد مع التحقق
- `loginUser`: تسجيل الدخول والتحقق من كلمة المرور
- `verifyGoogleToken`: التحقق من رمز Google
- `generateToken`: إنشاء JWT token
- `verifyToken`: التحقق من JWT token

#### product.service.js
**الوظائف**:
- `getAllProducts`: جلب جميع المنتجات مع التصفية
- `getProductById`: جلب منتج بالمعرف
- `createProduct`: إنشاء منتج مع التحقق
- `updateProduct`: تحديث منتج
- `deleteProduct`: حذف منتج
- `applyFilters`: تطبيق الفلاتر على المنتجات
- `paginateProducts`: ترقيم صفحات المنتجات

#### order.service.js
**الوظائف**:
- `createOrder`: إنشاء طلب مع معالجة الدفع
- `processPayment`: معالجة الدفع عبر Stripe
- `updateOrderStatus`: تحديث حالة الطلب
- `validateOrder`: التحقق من صحة الطلب
- `updateProductQuantity`: تحديث كميات المنتجات

---

### 7. طبقة Repositories (Repositories Layer)

Repositories مسؤولة عن الوصول لقاعدة البيانات:

#### base.repository.js
**الوظيفة**: Repository أساسي يوفر وظائف مشتركة

**الوظائف المشتركة**:
- `findAll`: جلب جميع السجلات
- `findById`: جلب سجل بالمعرف
- `create`: إنشاء سجل جديد
- `update`: تحديث سجل
- `delete`: حذف سجل
- `findOne`: جلب سجل واحد بشروط

#### product.repository.js
**الوظائف الخاصة**:
- `findBySku`: البحث برمز المنتج
- `findByCategory`: البحث بالفئة
- `findByBrand`: البحث بالعلامة التجارية
- `searchByName`: البحث بالاسم
- `getProductsInStock`: جلب المنتجات المتوفرة

---

### 8. طبقة الكيانات (Domain Layer)

تحتوي على مخططات Mongoose:

#### user.entity.js
**الحقول**:
- name, email, passwordHash, role, resetLink, newsLetter

#### product.entity.js
**الحقول**:
- sku, name, description, price, quantity, isOnStock, img, category, rating, brand

#### order.entity.js
**الحقول**:
- userId, products (array), totalAmount, status, paymentStatus, shippingAddress

---

### 9. طبقة Middlewares (Middlewares Layer)

#### auth.middleware.js
**الوظيفة**: التحقق من مصادقة المستخدم

**المسؤوليات**:
- التحقق من وجود JWT token
- التحقق من صحة token
- استخراج معلومات المستخدم من token
- إضافة معلومات المستخدم لطلب الطلب

**الاستخدام**:
```javascript
router.get('/protected', authMiddleware, controller.handler);
```

#### validation.middleware.js
**الوظيفة**: التحقق من صحة البيانات المرسلة

**المسؤوليات**:
- التحقق من البيانات باستخدام Joi
- إرجاع خطأ إذا كانت البيانات غير صالحة
- تنظيف البيانات من المدخلات الضارة

#### rateLimit.middleware.js
**الوظيفة**: الحد من عدد الطلبات

**المسؤوليات**:
- تتبع عدد الطلبات من كل IP
- حظر الطلبات الزائدة
- منع هجمات DDoS

#### error.middleware.js
**الوظيفة**: معالجة الأخطاء centrally

**المسؤوليات**:
- التقاط جميع الأخطاء
- تسجيل الأخطاء
- إرجاع استجابات خطأ موحدة
- معالجة أخطاء التحقق

---

### 10. طبقة البنية التحتية (Infrastructure Layer)

#### database/connection
**الوظيفة**: إدارة اتصال قاعدة البيانات

**المسؤوليات**:
- الاتصال بـ MongoDB
- إدارة حالة الاتصال
- معالجة أخطاء الاتصال

#### email/email.service
**الوظيفة**: إرسال البريد الإلكتروني

**المسؤوليات**:
- تهيئة Nodemailer
- إرسال رسائل البريد الإلكتروني
- إرسال نشرات بريدية
- معالجة أخطاء الإرسال

#### payment/
**الوظيفة**: معالجة المدفوعات عبر Stripe

**المسؤوليات**:
- تهيئة Stripe
- إنشاء Payment Intents
- تأكيد المدفوعات
- معالجة الاستردادات

#### cache/
**الوظيفة**: التخزين المؤقت للبيانات

**المسؤوليات**:
- تخزين البيانات المؤقتة
- استرجاع البيانات المخزنة
- إدارة انتهاء الصلاحية

---

## 🔄 تدفق البيانات

### مثال: إنشاء منتج جديد

```
1. Client Request
   POST /api/products/create
   Body: { name, price, ... }
   Headers: { Authorization: Bearer token }

2. Route Layer (product.routes.js)
   - التحقق من المسار
   - تطبيق auth middleware
   - تطبيق validation middleware

3. Auth Middleware (auth.middleware.js)
   - التحقق من JWT token
   - استخراج userId
   - إضافة user للطلب

4. Validation Middleware (validation.middleware.js)
   - التحقق من صحة البيانات
   - تنظيف البيانات

5. Controller Layer (product.controller.js)
   - استخراج البيانات من الطلب
   - استدعاء service

6. Service Layer (product.service.js)
   - التحقق من منطق الأعمال
   - استدعاء repository

7. Repository Layer (product.repository.js)
   - إنشاء المستند في MongoDB
   - إرجاع النتيجة

8. Response
   - إرجاع المنتج المُنشأ
   - Status: 201 Created
```

### مثال: تسجيل الدخول

```
1. Client Request
   POST /api/auth/signin
   Body: { email, password }

2. Route Layer (auth.routes.js)
   - تطبيق validation middleware

3. Validation Middleware
   - التحقق من وجود email و password

4. Controller Layer (auth.controller.js)
   - استدعاء service

5. Service Layer (auth.service.js)
   - البحث عن المستخدم بالبريد
   - التحقق من كلمة المرور (bcrypt)
   - إنشاء JWT token
   - إرجاع token و user data

6. Response
   - { token, user: { id, name, email, role } }
   - Status: 200 OK
```

---

## 🎨 التصميم

### Dependency Injection

الخدمات تعتمد على Repositories، والـ Controllers تعتمد على Services:

```javascript
// Controller
const productController = {
  createProduct: async (req, res) => {
    const product = await productService.createProduct(req.body);
    res.status(201).json(product);
  }
};

// Service
const productService = {
  createProduct: async (data) => {
    const validated = validateProduct(data);
    return await productRepository.create(validated);
  }
};

// Repository
const productRepository = {
  create: async (data) => {
    return await Product.create(data);
  }
};
```

### Error Handling

معالجة أخطاء مركزية عبر error middleware:

```javascript
// في أي controller
try {
  const result = await service.doSomething();
  res.json(result);
} catch (error) {
  next(error); // يمرر الخطأ لـ error middleware
}

// error middleware يعالج جميع الأخطاء
app.use((error, req, res, next) => {
  console.error(error);
  res.status(error.status || 500).json({
    message: error.message || 'Internal Server Error'
  });
});
```

### Validation

التحقق من البيانات على مستويين:

1. **Middleware Level**: التحقق الأساسي
2. **Service Level**: التحقق من منطق الأعمال

```javascript
// Middleware
const validateProduct = (req, res, next) => {
  const schema = Joi.object({
    name: Joi.string().required(),
    price: Joi.number().min(0).required()
  });
  const { error } = schema.validate(req.body);
  if (error) return res.status(400).json({ error: error.details });
  next();
};

// Service
const createProduct = async (data) => {
  if (data.price < 0) {
    throw new Error('Price cannot be negative');
  }
  // ... منطق إضافي
};
```

---

## 📊 مخطط التسلسل

### تسجيل مستخدم جديد

```
Client → Route → Validation → Controller → Service → Repository → Database
  ↓        ↓         ↓           ↓          ↓          ↓          ↓
Request  Check     Validate  Extract   Business   Create    Save
         Route     Data       Data     Logic      Query    Document
  ↓        ↓         ↓           ↓          ↓          ↓          ↓
Response ← Route ← Validation ← Controller ← Service ← Repository ← DB
```

### إنشاء طلب

```
Client → Route → Auth → Validation → Controller → Service → Repository
  ↓        ↓      ↓        ↓           ↓          ↓          ↓
Request  Check  Verify   Validate   Extract   Process   Create
         Route  Token     Data       Data     Payment   Order
  ↓        ↓      ↓        ↓           ↓          ↓          ↓
Response ← Route ← Auth ← Validation ← Controller ← Service ← Repo
```

---

## 🔧 الصيانة والتطوير

### إضافة ميزة جديدة

1. **تحديث Domain Entity**: إضافة الحقول الجديدة للمخطط
2. **تحديث Repository**: إضافة وظائف الوصول للبيانات
3. **تحديث Service**: إضافة منطق الأعمال
4. **تحديث Controller**: إضافة معالج الطلب
5. **تحديث Route**: إضافة المسار الجديد
6. **تحديث Validation**: إضافة قواعد التحقق
7. **الاختبار**: كتابة اختبارات للميزة الجديدة

### تعديل ميزة موجودة

1. تحديد الطبقات المتأثرة
2. تعديل الطبقات بالترتيب (من الأسفل للأعلى)
3. تحديث الاختبارات
4. التحقق من عدم كسر الوظائف الأخرى

---

## 📚 أفضل الممارسات

### 1. فصل المسؤوليات
- كل طبقة لها مسؤولية واضحة
- لا تخلط بين منطق الأعمال والوصول للبيانات

### 2. قابلية الاختبار
- استخدام Dependency Injection
- عزل الوحدات لسهولة الاختبار
- استخدام mocks للتبعيات الخارجية

### 3. إعادة الاستخدام
- استخدام base repository للوظائف المشتركة
- إنشاء middlewares قابلة لإعادة الاستخدام
- تنظيم الوظائف المساعدة في utils

### 4. التوثيق
- توثيق كل وظيفة
- استخدام تعليقات واضحة
- تحديث التوثيق مع التغييرات

### 5. معالجة الأخطاء
- استخدام try-catch في جميع الوظائف غير المتزامنة
- تمرير الأخطاء لـ error middleware
- تسجيل الأخطاء للتدقيق

---

## 🔗 المراجع

- [Express.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [MVC Pattern](https://developer.mozilla.org/en-US/docs/Glossary/MVC)
