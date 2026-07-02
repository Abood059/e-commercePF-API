# 🔒 توثيق الأمان والحماية

هذا المستند يوفر توثيقاً شاملاً لتدابير الأمان والحماية في نظام التجارة الإلكترونية.

## 📋 المحتويات

- [نظرة عامة](#نظرة-عامة)
- [المصادقة والترخيص](#المصادقة-والترخيص)
- [الحماية من الهجمات](#الحماية-من-الهجمات)
- [إدارة الجلسات](#إدارة-الجلسات)
- [حماية البيانات](#حماية-البيانات)
- [التسجيل والمراقبة](#التسجيل-والمراقبة)
- [أفضل الممارسات](#أفضل-الممارسات)
- [الاختبارات الأمنية](#الاختبارات-الأمنية)

---

## 🎯 نظرة عامة

يتبع النظام نهجاً متعدد الطبقات للأمان (Defense in Depth) مع تدابير حماية على مستويات متعددة:

```
┌─────────────────────────────────────────────────────────┐
│              Network & Infrastructure Security          │
│  (HTTPS, Firewall, DDoS Protection)                     │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│              Application Security Layer                   │
│  (Helmet, CORS, Rate Limiting, Input Validation)         │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│              Authentication & Authorization              │
│  (JWT, Role-Based Access Control, Session Management)    │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│              Data Security Layer                         │
│  (Encryption, Hashing, Sanitization, Secure Storage)     │
└─────────────────────────────────────────────────────────┘
```

---

## 🔐 المصادقة والترخيص

### 1. JWT Authentication

يستخدم النظام **JSON Web Tokens (JWT)** للمصادقة.

#### التكوين

```javascript
// config/index.js
jwt: {
  secret: process.env.SECRET_KEY,        // مفتاح التوقيع السري
  resetPasswordSecret: process.env.RESET_PASSWORD_KEY  // مفتاح إعادة تعيين كلمة المرور
}
```

#### عملية المصادقة

1. **تسجيل الدخول**:
   - المستخدم يرسل البريد وكلمة المرور
   - النظام يتحقق من صحة البيانات
   - يتم إنشاء JWT token
   - يتم إرجاع token للمستخدم

2. **استخدام Token**:
   - يتم إرسال token في header: `Authorization: Bearer <token>`
   - يتم التحقق من token في كل طلب محمي
   - يتم استخراج معلومات المستخدم من token

#### تنفيذ الـ Middleware

```javascript
// src/middlewares/auth.middleware.js
const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader) {
    return next(new AppError('No token provided', 401));
  }

  const token = authHeader.split(' ')[1];
  
  jwt.verify(token, config.jwt.secret, { algorithms: ['HS256'] }, (err, user) => {
    if (err) {
      return next(new AppError('Invalid or expired token', 401));
    }
    req.user = user;
    next();
  });
};
```

#### مميزات JWT

- **Stateless**: لا حاجة لتخزين الجلسات على الخادم
- **Scalable**: مناسب للأنظمة الموزعة
- **Secure**: مشفر وموقّع رقمياً
- **Flexible**: يمكن تضمين بيانات إضافية في payload

#### التدابير الأمنية

- استخدام خوارزمية **HS256** للتوقيع
- مفتاح سري قوي (256-bit على الأقل)
- انتهاء صلاحية تلقائي للـ token
- تسجيل محاولات المصادقة الفاشلة

---

### 2. Role-Based Access Control (RBAC)

يستخدم النظام نظام التحكم في الوصول القائم على الأدوار.

#### الأدوار المتاحة

```javascript
enum: ['admin', 'client', 'moderator']
```

#### صلاحيات الأدوار

| الدور | الصلاحيات |
|-------|-----------|
| **admin** | - الوصول الكامل لجميع الموارد<br>- إدارة المستخدمين<br>- إدارة المنتجات<br>- إدارة الطلبات<br>- إرسال النشرات البريدية |
| **moderator** | - إدارة المنتجات<br>- إدارة الفئات<br>- مراجعة التقييمات<br>- إدارة الطلبات (محدود) |
| **client** | - إنشاء الطلبات<br>- كتابة التقييمات<br>- الاشتراك في النشرة البريدية<br>- عرض بياناته الخاصة |

#### تنفيذ الترخيص

```javascript
// src/middlewares/auth.middleware.js
const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return next(new AppError('You do not have permission', 403));
    }
    next();
  };
};

// الاستخدام
router.post('/admin/users', authenticateJWT, authorizeRoles('admin'), controller);
```

#### التدابير الأمنية

- التحقق من الدور قبل تنفيذ العملية
- تسجيل عمليات الـ admin للتدقيق
- منع تصعيد الصلاحيات (Privilege Escalation)

---

### 3. Password Security

#### تشفير كلمات المرور

يستخدم النظام **bcrypt** لتشفير كلمات المرور:

```javascript
const bcrypt = require('bcrypt');
const saltRounds = 10; // عدد جولات التشفير

// تشفير كلمة المرور
const hashPassword = async (password) => {
  return await bcrypt.hash(password, saltRounds);
};

// التحقق من كلمة المرور
const verifyPassword = async (password, hash) => {
  return await bcrypt.compare(password, hash);
};
```

#### مميزات bcrypt

- **Slow Hashing**: مصمم ليكون بطيئاً لمنع هجمات Brute Force
- **Salt**: يضيف salt عشوائي لكل كلمة مرور
- **Adaptive**: يمكن زيادة عدد الجولات مع الوقت
- **Battle-Tested**: مكتبة مجربة وموثوقة

#### متطلبات كلمات المرور

- الحد الأدنى: 8 أحرف
- يُنصح باستخدام: أحرف كبيرة، صغيرة، أرقام، رموز خاصة

---

### 4. Google OAuth

يدعم النظام تسجيل الدخول عبر Google OAuth 2.0.

#### التكوين

```javascript
google: {
  clientId: process.env.AUTH_GOOGLE_CLIENT
}
```

#### عملية المصادقة

1. المستخدم يرسل Google ID token
2. النظام يتحقق من token باستخدام Google Auth Library
3. يتم إنشاء أو تحديث المستخدم
4. يتم إرجاع JWT token

#### التدابير الأمنية

- التحقق من token مع Google servers
- التحقق من issuer و audience
- استخدام HTTPS فقط

---

## 🛡️ الحماية من الهجمات

### 1. Rate Limiting (الحد من الطلبات)

يستخدم النظام **express-rate-limit** للحد من عدد الطلبات.

#### التكوين

```javascript
// src/middlewares/rateLimit.middleware.js
const createRateLimiter = (windowMs = 15 * 60 * 1000, max = 100, message) => {
  return rateLimit({
    windowMs,    // نافذة الزمن (مللي ثانية)
    max,          // الحد الأقصى للطلبات
    message,      // رسالة الخطأ
    standardHeaders: true,
    legacyHeaders: false
  });
};
```

#### حدود الطلبات المختلفة

| النوع | النافذة الزمنية | الحد الأقصى | الاستخدام |
|-------|-----------------|--------------|-----------|
| **authLimiter** | 15 دقيقة | 5 طلبات | تسجيل الدخول/التسجيل |
| **generalLimiter** | 15 دقيقة | 100 طلب | جميع الطلبات العامة |
| **orderLimiter** | 15 دقيقة | 20 طلب | إنشاء الطلبات |
| **adminLimiter** | 15 دقيقة | 30 طلب | عمليات الـ admin |
| **newsletterLimiter** | ساعة واحدة | 5 طلبات | إرسال النشرات |

#### التدابير الأمنية

- تتبع الطلبات لكل IP
- تسجيل محاولات تجاوز الحد
- استجابة موحدة مع رمز 429
- منع هجمات DDoS و Brute Force

---

### 2. Input Validation (التحقق من المدخلات)

يستخدم النظام **Joi** للتحقق من صحة المدخلات.

#### التنفيذ

```javascript
// src/middlewares/validation.middleware.js
const validate = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,    // إرجاع جميع الأخطاء
      stripUnknown: true    // إزالة الحقول غير المعروفة
    });

    if (error) {
      const errors = error.details.map(detail => detail.message);
      return next(new AppError(errors.join(', '), 400));
    }

    req.body = sanitizeObject(value);
    next();
  };
};
```

#### أنواع التحقق

- **Body Validation**: التحقق من body الطلب
- **Query Validation**: التحقق من query parameters
- **Params Validation**: التحقق من URL parameters

#### أمثلة على قواعد التحقق

```javascript
// مثال: التحقق من بيانات المنتج
const productSchema = Joi.object({
  name: Joi.string().required().min(3).max(100),
  price: Joi.number().required().min(0),
  quantity: Joi.number().required().min(0).integer(),
  description: Joi.string().max(1000),
  category: Joi.array().items(Joi.string())
});
```

---

### 3. XSS Protection (الحماية من XSS)

يستخدم النظام **sanitize-html** لتنظيف HTML من هجمات XSS.

#### التنفيذ

```javascript
// src/middlewares/validation.middleware.js
const sanitizeObject = (obj) => {
  if (!obj || typeof obj !== 'object') return obj;
  
  for (const key in obj) {
    if (typeof obj[key] === 'string') {
      obj[key] = sanitizeHtml(obj[key], {
        allowedTags: [],        // عدم السماح بأي وسوم HTML
        allowedAttributes: {}  // عدم السماح بأي سمات
      });
    } else if (typeof obj[key] === 'object') {
      obj[key] = sanitizeObject(obj[key]);
    }
  }
  return obj;
};
```

#### التدابير الأمنية

- إزالة جميع وسوم HTML من المدخلات
- معالجة الكائنات المتداخلة recursively
- تطبيق التنظيف على جميع الحقول النصية

---

### 4. SQL/NoSQL Injection Protection

#### الحماية من NoSQL Injection

- استخدام **Mongoose** الذي يحمي تلقائياً من NoSQL Injection
- التحقق من صحة ObjectId قبل الاستخدام
- استخدام parameterized queries

#### التدابير الأمنية

```javascript
// ❌ غير آمن
const user = await User.findOne({ email: req.body.email });

// ✅ آمن - مع التحقق
const email = req.body.email;
if (!isValidEmail(email)) {
  throw new Error('Invalid email');
}
const user = await User.findOne({ email });
```

---

### 5. CSRF Protection

يستخدم النظام تدابير متعددة للحماية من CSRF:

- **SameSite Cookies**: `sameSite: 'strict'`
- **CORS Configuration**: تحديد المصادر المسموح بها
- **JWT in Headers**: استخدام Authorization header بدلاً من cookies

#### تكوين Cookies

```javascript
// src/app.js
app.use(cookieParser({
  httpOnly: true,              // منع الوصول عبر JavaScript
  secure: process.env.NODE_ENV === 'production',  // HTTPS فقط في الإنتاج
  sameSite: 'strict'          // منع إرسال cookies في cross-site requests
}));
```

---

### 6. HTTP Security Headers

يستخدم النظام **Helmet** لتأمين HTTP headers.

#### التكوين

```javascript
// src/app.js
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "https:", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,              // سنة واحدة
    includeSubDomains: true,       // يشمل النطاقات الفرعية
    preload: true                  // التضمين في HSTS preload list
  }
}));
```

#### Headers المضافة

| Header | الوصف |
|--------|-------|
| **X-Content-Type-Options** | منع MIME sniffing |
| **X-Frame-Options** | منع clickjacking |
| **X-XSS-Protection** | حماية XSS |
| **Strict-Transport-Security** | فرض HTTPS |
| **Content-Security-Policy** | التحكم في الموارد المسموح بها |

---

### 7. CORS Configuration

تكوين Cross-Origin Resource Sharing للتحكم في المصادر المسموح بها.

#### التكوين

```javascript
// src/app.js
app.use(cors({
  origin: process.env.CLIENT_URL || '*',  // المصادر المسموح بها
  credentials: true,                      // السماح بإرسال credentials
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

#### التدابير الأمنية

- تحديد المصادر المسموح بها صراحة
- السماح بالطرق المطلوبة فقط
- تحديد الـ headers المسموح بها
- تمكين credentials عند الحاجة فقط

---

### 8. Body Size Limit

تحديد حجم الطلب لمنع هجمات DoS.

#### التكوين

```javascript
// src/app.js
app.use(bodyParser.json({ limit: '10kb' }));
app.use(bodyParser.urlencoded({ limit: '10kb', extended: false }));
```

#### التدابير الأمنية

- الحد الأقصى: 10KB لكل طلب
- رفض الطلبات الكبيرة تلقائياً
- منع استهلاك الموارد

---

## 📝 إدارة الجلسات

### 1. JWT Token Management

#### إنشاء Token

```javascript
const generateToken = (user) => {
  return jwt.sign(
    { 
      id: user._id, 
      email: user.email, 
      role: user.role 
    },
    config.jwt.secret,
    { 
      expiresIn: '24h'  // انتهاء الصلاحية بعد 24 ساعة
    }
  );
};
```

#### انتهاء الصلاحية

- **Access Token**: 24 ساعة
- **Refresh Token**: (يمكن إضافتها مستقبلاً)
- **Reset Password Token**: ساعة واحدة

---

### 2. Cookie Security

#### إعدادات Cookies

```javascript
{
  httpOnly: true,              // منع الوصول عبر JavaScript
  secure: true,                // إرسال عبر HTTPS فقط
  sameSite: 'strict',          // منع cross-site requests
  maxAge: 24 * 60 * 60 * 1000  // 24 ساعة
}
```

---

## 🔒 حماية البيانات

### 1. Data Encryption

#### كلمات المرور

- تشفير باستخدام bcrypt (salt rounds: 10)
- عدم تخزين كلمات المرور كنص صريح
- عدم إمكانية فك التشفير (one-way hash)

#### البيانات الحساسة

- معلومات البطاقات: معالجة عبر Stripe فقط
- البيانات الشخصية: تشفير في REST (اختياري)
- البيانات في النقل: HTTPS فقط

---

### 2. Data Sanitization

#### تنظيف المدخلات

```javascript
// إزالة HTML tags
const sanitized = sanitizeHtml(input, {
  allowedTags: [],
  allowedAttributes: {}
});

// تقليم المسافات
const trimmed = input.trim();

// تحويل لحروف صغيرة (للبريد الإلكتروني)
const lowercased = input.toLowerCase();
```

---

### 3. Secure Storage

#### قاعدة البيانات

- استخدام MongoDB Atlas مع تكوين أمان
- تشفير الاتصال بقاعدة البيانات
- استخدام environment variables للبيانات الحساسة
- عدم تخزين secrets في الكود

#### Environment Variables

```env
# .env file (لا يتم رفعه في Git)
MONGO_DB_URL=mongodb://localhost:27017/ecommerce
SECRET_KEY=your-super-secret-key
STRIPE_SECRET_KEY=sk_test_...
EMAIL_PASS=your-email-password
```

---

## 📊 التسجيل والمراقبة

### 1. Security Logging

يستخدم النظام نظام تسجيل أمني متقدم.

#### أنواع السجلات

```javascript
// src/utils/securityLogger.js
- logFailedAuth: محاولات المصادقة الفاشلة
- logUnauthorizedAccess: محاولات الوصول غير المصرح بها
- logAdminOperation: عمليات الـ admin
- logRateLimitTriggered: تجاوز حدود الطلبات
```

#### معلومات السجلات

- timestamp
- user ID (إن وجد)
- IP address
- endpoint
- error details
- user agent

---

### 2. Error Handling

#### معالجة الأخطاء المركزية

```javascript
// src/middlewares/error.middleware.js
app.use((error, req, res, next) => {
  // تسجيل الخطأ
  console.error(error);
  
  // عدم إرجاع تفاصيل حساسة
  const response = {
    message: error.message || 'Internal Server Error',
    status: error.status || 500
  };
  
  // في الإنتاج، عدم إرجاع stack trace
  if (process.env.NODE_ENV === 'production') {
    delete response.stack;
  }
  
  res.status(response.status).json(response);
});
```

---

### 3. Request Logging

#### Morgan Configuration

```javascript
// src/app.js
app.use(morgan('dev'));  // تسجيل جميع الطلبات في التطوير
```

---

## ✅ أفضل الممارسات

### 1. للمطورين

#### كود آمن

- ✅ دائماً التحقق من المدخلات
- ✅ استخدام parameterized queries
- ✅ عدم تخزين secrets في الكود
- ✅ استخدام HTTPS في الإنتاج
- ✅ تحديث المكتبات بانتظام
- ✅ مراجعة الكود الأمني

#### تجنب

- ❌ استخدام eval()
- ❌ concatenation في SQL/NoSQL queries
- ❌ تخزين كلمات المرور كنص صريح
- ❌ تجاهل أخطاء التحقق
- ❌ استخدام مكتبات غير موثوقة

---

### 2. للإدارة

#### إدارة الأمان

- ✅ مراجعة السجلات بانتظام
- ✅ تحديث النظام بانتظام
- ✅ استخدام كلمات مرور قوية
- ✅ تفعيل 2FA إن أمكن
- ✅ عمل نسخ احتياطية منتظمة
- ✅ اختبار الاختراق دوري

---

### 3. للمستخدمين

#### أمان المستخدم

- ✅ استخدام كلمات مرور قوية
- ✅ عدم مشاركة credentials
- ✅ تسجيل الخروج بعد الانتهاء
- ✅ استخدام HTTPS فقط
- ✅ تحديث البرامج بانتظام

---

## 🧪 الاختبارات الأمنية

### 1. اختبارات الأمان

يحتوي المشروع على اختبارات أمنية شاملة في `test/test_security.sh`.

#### الاختبارات المتاحة

```bash
# NoSQL Injection
- اختبار حقن NoSQL في معلمات الطلب

# Header Injection
- اختبار حقن headers ضارة

# Large Payload (DoS)
- اختبار إرسال payload كبير

# IDOR (Insecure Direct Object References)
- اختبار الوصول لموارد مستخدمين آخرين

# Parameter Tampering
- اختبار تعديل معلمات الطلب
```

#### تشغيل الاختبارات

```bash
cd test
./test_security.sh
```

---

### 2. فحص الثغرات

#### أدوات موصى بها

- **npm audit**: فحص ثغرات المكتبات
- **Snyk**: فحص ثغرات الأمان
- **OWASP ZAP**: اختبار اختراق الويب
- **Burp Suite**: اختبار أمان التطبيقات

#### تشغيل npm audit

```bash
npm audit
```

---

### 3. Security Checklist

#### قبل النشر

- [ ] مراجعة جميع environment variables
- [ ] التحقق من تكوين HTTPS
- [ ] اختبار جميع middlewares الأمنية
- [ ] مراجعة سجلات الأمان
- [ ] اختبار rate limiting
- [ ] فحص dependencies للثغرات
- [ ] مراجعة صلاحيات المستخدمين
- [ ] اختبار CSRF protection
- [ ] مراجعة CORS configuration
- [ ] اختبار XSS protection

---

## 🚨 الاستجابة للحوادث

### 1. كشف الاختراق

#### علامات الاختراق

- زيادة غير طبيعية في الطلبات
- محاولات تسجيل دخول فاشلة متكررة
- وصول غير مصرح به للموارد
- تغييرات غير متوقعة في البيانات
- سلوك غريب في السجلات

---

### 2. خطوات الاستجابة

1. **الاحتواء**
   - عزل النظام المتأثر
   - تغيير كلمات المرور
   - إيقاف الخدمات المتأثرة

2. **التحقيق**
   - مراجعة السجلات
   - تحديد نطاق الاختراق
   - جمع الأدلة

3. **الإصلاح**
   - إصلاح الثغرات
   - تحديث النظام
   - استعادة البيانات من النسخ الاحتياطية

4. **التعافي**
   - استعادة الخدمات
   - مراقبة النظام
   - تحديث الإجراءات

---

## 📚 المراجع

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [Node.js Security Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Express Security](https://expressjs.com/en/advanced/best-practice-security.html)
- [Helmet Documentation](https://helmetjs.github.io/)
