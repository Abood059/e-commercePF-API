# 🛒 E-Commerce API Platform

نظام تجارة إلكترونية متكامل مبني على Node.js و Express مع MongoDB، يوفر واجهة برمجة تطبيقات RESTful لإدارة المنتجات، الطلبات، المستخدمين، والمزيد.

## 📋 المحتويات

- [المميزات](#المميزات)
- [التقنيات المستخدمة](#التقنيات-المستخدمة)
- [المتطلبات](#المتطلبات)
- [التثبيت](#التثبيت)
- [التشغيل](#التشغيل)
- [متغيرات البيئة](#متغيرات-البيئة)
- [بنية المشروع](#بنية-المشروع)
- [واجهات برمجة التطبيقات](#واجهات-برمجة-التطبيقات)
- [الأمان](#الأمان)
- [الاختبارات](#الاختبارات)
- [التوثيق](#التوثيق)

## ✨ المميزات

- **إدارة المستخدمين**: تسجيل، تسجيل دخول، إدارة الأدوار (admin, client, moderator)
- **المصادقة**: JWT Token authentication + Google OAuth
- **إدارة المنتجات**: إنشاء، تحديث، حذف، بحث، تصفية، ترقيم صفحات
- **إدارة الفئات**: تنظيم المنتجات في فئات
- **إدارة الطلبات**: إنشاء الطلبات، تتبع الحالة، الدفع عبر Stripe
- **التقييمات**: نظام تقييم المنتجات من قبل المستخدمين
- **النشرة البريدية**: إدارة الاشتراكات وإرسال النشرات
- **الأمان**: Rate limiting, Helmet, CORS, Sanitization
- **التخزين المؤقت**: Node-cache لتحسين الأداء
- **التحقق من البيانات**: Joi و express-validator

## 🛠 التقنيات المستخدمة

### Backend
- **Node.js** - بيئة التشغيل
- **Express.js** - إطار عمل الويب
- **MongoDB** - قاعدة البيانات
- **Mongoose** - ODM لـ MongoDB

### الأمان
- **Helmet** - حماية HTTP headers
- **bcrypt** - تشفير كلمات المرور
- **jsonwebtoken** - JWT authentication
- **express-rate-limit** - الحد من الطلبات
- **sanitize-html** - تنظيف HTML من XSS
- **express-jwt** - التحقق من JWT

### الدفع والمصادقة
- **Stripe** - معالجة المدفوعات
- **google-auth-library** - Google OAuth

### الأدوات الأخرى
- **nodemailer** - إرسال البريد الإلكتروني
- **morgan** - تسجيل الطلبات
- **dotenv** - إدارة متغيرات البيئة
- **cors** - Cross-Origin Resource Sharing
- **joi** - التحقق من البيانات

## 📦 المتتطلبات

- Node.js (v14 أو أحدث)
- MongoDB (v4.4 أو أحدث)
- npm أو yarn

## 🚀 التثبيت

1. **استنساخ المشروع**
```bash
git clone <repository-url>
cd e-commercePF
```

2. **تثبيت المكتبات**
```bash
npm install
```

3. **إعداد متغيرات البيئة**
```bash
cp .env.example .env
# قم بتعديل ملف .env بإعداداتك
```

## ▶️ التشغيل

### وضع التطوير
```bash
npm run dev
```

### وضع الإنتاج
```bash
npm start
```

الخادم سيعمل على المنفذ 3000 (أو المنفذ المحدد في متغير PORT)

## 🔧 متغيرات البيئة

أنشئ ملف `.env` في جذر المشروع وأضف المتغيرات التالية:

```env
# Server
PORT=3000
NODE_ENV=development
CLIENT_URL=http://localhost:3000

# Database
MONGO_DB_URL=mongodb://localhost:27017/ecommerce

# JWT
SECRET_KEY=your-secret-key-here
RESET_PASSWORD_KEY=your-reset-password-key-here

# Google OAuth
AUTH_GOOGLE_CLIENT=your-google-client-id

# Stripe
STRIPE_SECRET_KEY=your-stripe-secret-key

# Email
EMAIL_USER=your-email@example.com
EMAIL_PASS=your-email-password

# Cache
CACHE_TTL=300
```

## 📁 بنية المشروع

```
e-commercePF/
├── src/
│   ├── app.js                 # إعداد Express application
│   ├── server.js              # نقطة دخول الخادم
│   ├── config/                # إعدادات التطبيق
│   ├── controllers/           # Controllers للتعامل مع الطلبات
│   ├── domain/                # كيانات قاعدة البيانات (Schemas)
│   ├── infrastructure/        # البنية التحتية (DB, Email, Payment)
│   ├── middlewares/           # Middlewares (Auth, Validation, Error)
│   ├── repositories/          # Repositories للوصول للبيانات
│   ├── routes/                # تعريف المسارات
│   ├── services/              # Business logic
│   └── utils/                 # وظائف مساعدة
├── test/                      # ملفات الاختبار
├── .env                       # متغيرات البيئة
├── .gitignore
├── package.json
└── README.md
```

## 🌐 واجهات برمجة التطبيقات

### المصادقة (Authentication)

#### تسجيل مستخدم جديد
```http
POST /api/auth/signup
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

#### تسجيل الدخول
```http
POST /api/auth/signin
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

#### تسجيل الدخول عبر Google
```http
POST /api/auth/googlelogin
Content-Type: application/json

{
  "tokenId": "google-token-id"
}
```

### المنتجات (Products)

#### الحصول على جميع المنتجات
```http
GET /api/products
```

#### الحصول على منتج بالمعرف
```http
GET /api/products/id/:id
```

#### البحث عن منتج بالاسم
```http
GET /api/products/name/:name
```

#### الحصول على المنتجات مع الترقيم
```http
GET /api/products/forPage?page=1&limit=10
```

#### إنشاء منتج جديد (يتطلب مصادقة)
```http
POST /api/products/create
Authorization: Bearer <token>
Content-Type: application/json

{
  "sku": "TS0001",
  "name": "T-Shirt",
  "description": "Cotton t-shirt",
  "price": 29.99,
  "quantity": 100,
  "isOnStock": true,
  "img": ["image-url-1", "image-url-2"],
  "category": ["clothing", "t-shirts"],
  "brand": "Nike"
}
```

#### تحديث منتج (يتطلب مصادقة)
```http
PUT /api/products/update/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "price": 34.99,
  "quantity": 50
}
```

#### حذف منتج (يتطلب مصادقة)
```http
DELETE /api/products/delete/:id
Authorization: Bearer <token>
```

### الفئات (Categories)

#### الحصول على جميع الفئات
```http
GET /api/categories
```

#### الحصول على فئة بالاسم
```http
GET /api/categories/:name
```

#### إنشاء فئة جديدة (يتطلب مصادقة)
```http
POST /api/categories/create
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Electronics",
  "description": "Electronic devices"
}
```

#### حذف فئة (يتطلب مصادقة)
```http
DELETE /api/categories/delete/:name
Authorization: Bearer <token>
```

### الطلبات (Orders)

#### إنشاء طلب جديد (يتطلب مصادقة)
```http
POST /api/orders/create
Authorization: Bearer <token>
Content-Type: application/json

{
  "products": [
    {
      "productId": "product-id",
      "quantity": 2,
      "price": 29.99,
      "name": "T-Shirt"
    }
  ],
  "totalAmount": 59.98,
  "shippingAddress": {
    "street": "123 Main St",
    "city": "New York",
    "country": "USA",
    "postalCode": "10001"
  }
}
```

#### الحصول على طلبات المستخدم (يتطلب مصادقة)
```http
GET /api/orders/user
Authorization: Bearer <token>
```

#### تحديث حالة الطلب (يتطلب مصادقة admin)
```http
PUT /api/orders/:id/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "shipped"
}
```

### التقييمات (Reviews)

#### إنشاء تقييم (يتطلب مصادقة)
```http
POST /api/review/create
Authorization: Bearer <token>
Content-Type: application/json

{
  "rating": 5,
  "description": "Great product!"
}
```

#### الحصول على تقييمات منتج
```http
GET /api/products/id/:id
```

### المستخدمين (Users)

#### الحصول على جميع المستخدمين (يتطلب مصادقة admin)
```http
GET /api/users
Authorization: Bearer <token>
```

#### الحصول على مستخدم بالمعرف (يتطلب مصادقة)
```http
GET /api/users/:id
Authorization: Bearer <token>
```

#### تحديث دور المستخدم (يتطلب مصادقة admin)
```http
PUT /api/users/update/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "role": "admin"
}
```

#### حذف مستخدم (يتطلب مصادقة admin)
```http
DELETE /api/users/delete/:id
Authorization: Bearer <token>
```

### النشرة البريدية (Newsletter)

#### الاشتراك/إلغاء الاشتراك (يتطلب مصادقة)
```http
PUT /api/users/suscribe
Authorization: Bearer <token>
Content-Type: application/json

{
  "newsLetter": true
}
```

#### إرسال نشرة بريدية (يتطلب مصادقة admin)
```http
POST /api/users/sendNewsletter
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "New Arrivals",
  "content": "Check out our new products!"
}
```

## 🔒 الأمان

يتميز المشروع بتدابير أمان متعددة:

- **Helmet**: حماية HTTP headers
- **CORS**: تكوين Cross-Origin Resource Sharing
- **Rate Limiting**: الحد من الطلبات لمنع الهجمات
- **JWT Authentication**: مصادقة قائمة على الرموز
- **Password Hashing**: تشفير كلمات المرور باستخدام bcrypt
- **Input Validation**: التحقق من صحة المدخلات باستخدام Joi
- **XSS Protection**: تنظيف HTML من هجمات XSS
- **HSTS**: HTTP Strict Transport Security

للمزيد من التفاصيل، راجع ملف `docs/SECURITY.md`

## 🧪 الاختبارات

يحتوي المشروع على مجموعة شاملة من الاختبارات:

```bash
# تشغيل جميع الاختبارات
cd test
./run_all_tests.sh

# اختبار المصادقة
./test_auth.sh

# اختبار المنتجات
./test_product.sh

# اختبار الطلبات
./test_order.sh

# اختبار الأمان
./test_security.sh
```

للمزيد من التفاصيل، راجع ملف `docs/TESTING.md`

## 📚 التوثيق

- **[توثيق قاعدة البيانات](docs/DATABASE.md)** - تفاصيل المخططات والعلاقات
- **[توثيق البنية البرمجية](docs/ARCHITECTURE.md)** - شرح البنية والوحدات
- **[توثيق الأمان](docs/SECURITY.md)** - تدابير الأمان والحماية
- **[توثيق الاختبارات](docs/TESTING.md)** - دليل الاختبارات

## 📝 الترخيص

ISC

## 👥 المساهمون

- فريق التطوير

## 📞 الدعم

للدعم والاستفسارات، يرجى فتح issue في المستودع. 





