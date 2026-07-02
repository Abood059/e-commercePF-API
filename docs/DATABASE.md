# 📊 توثيق قاعدة البيانات

هذا المستند يوفر توثيقاً شاملاً لمخططات قاعدة البيانات والعلاقات بين الكيانات في نظام التجارة الإلكترونية.

## 📋 المحتويات

- [نظرة عامة](#نظرة-عامة)
- [الكيانات](#الكيانات)
- [العلاقات](#العلاقات)
- [الفهارس](#الفهارس)
- [أفضل الممارسات](#أفضل-الممارسات)

## 🎯 نظرة عامة

يستخدم النظام **MongoDB** كقاعدة بيانات NoSQL مع **Mongoose** كـ ODM (Object Data Mapper). قاعدة البيانات تحتوي على 6 كيانات رئيسية:

1. **User** - المستخدمين
2. **Product** - المنتجات
3. **Category** - الفئات
4. **Order** - الطلبات
5. **Review** - التقييمات
6. **Newsletter** - النشرة البريدية

## 📦 الكيانات

### 1. User (المستخدم)

يمثل مستخدمي النظام ويحتوي على معلومات الحساب والمصادقة.

#### المخطط

```javascript
{
  name: String,              // اسم المستخدم (مطلوب، أقصى 64 حرف)
  email: String,             // البريد الإلكتروني (مطلوب، فريد، lowercase)
  passwordHash: String,      // كلمة المرور المشفرة (مطلوب)
  role: String,              // الدور: 'admin' | 'client' | 'moderator' (افتراضي: 'client')
  resetLink: String,         // رابط إعادة تعيين كلمة المرور
  newsLetter: Boolean,       // الاشتراك في النشرة البريدية (افتراضي: false)
  createdAt: Date,           // تاريخ الإنشاء (تلقائي)
  updatedAt: Date            // تاريخ التحديث (تلقائي)
}
```

#### القيود

- `name`: مطلوب، أقصى 64 حرف، يتم تقليم المسافات
- `email`: مطلوب، فريد، يتم تحويله لحروف صغيرة
- `passwordHash`: مطلوب (يتم تخزينه مشفراً باستخدام bcrypt)
- `role`: أحد القيم: 'admin', 'client', 'moderator'

#### الفهارس

- `email`: فريد (unique index)

---

### 2. Product (المنتج)

يمثل المنتجات المتاحة في المتجر.

#### المخطط

```javascript
{
  sku: String,               // رمز المنتج (فريد، اختياري)
  name: String,              // اسم المنتج (مطلوب)
  description: String,       // وصف المنتج
  price: Number,             // السعر (مطلوب، ≥ 0)
  quantity: Number,          // الكمية المتاحة (مطلوب، ≥ 0، افتراضي: 0)
  isOnStock: Boolean,        // متوفر في المخزون (افتراضي: true)
  img: [String],             // صور المنتج (مصفوفة من روابط الصور)
  category: [String],         // الفئات التي ينتمي إليها المنتج
  rating: Number,            // التقييم المتوسط (0-5، افتراضي: 0)
  brand: String,             // العلامة التجارية
  createdAt: Date,           // تاريخ الإنشاء (تلقائي)
  updatedAt: Date            // تاريخ التحديث (تلقائي)
}
```

#### القيود

- `sku`: فريد، اختياري (sparse unique)
- `name`: مطلوب، يتم تقليم المسافات
- `price`: مطلوب، لا يمكن أن يكون سالباً
- `quantity`: مطلوب، لا يمكن أن يكون سالباً، افتراضي 0
- `rating`: بين 0 و 5

#### الفهارس

- `sku`: فريد (sparse unique index)

---

### 3. Category (الفئة)

يمثل الفئات التي يتم تصنيف المنتجات ضمنها.

#### المخطط

```javascript
{
  name: String,              // اسم الفئة (مطلوب، فريد)
  description: String,       // وصف الفئة
  products: [ObjectId],      // المنتجات في هذه الفئة (مرجع لـ Product)
  createdAt: Date,           // تاريخ الإنشاء (تلقائي)
  updatedAt: Date            // تاريخ التحديث (تلقائي)
}
```

#### القيود

- `name`: مطلوب، فريد، يتم تقليم المسافات

#### الفهارس

- `name`: فريد (unique index)

#### العلاقات

- `products`: مرجع لـ Product (one-to-many)

---

### 4. Order (الطلب)

يمثل طلبات الشراء التي يقوم بها المستخدمون.

#### المخطط الرئيسي

```javascript
{
  userId: ObjectId,          // معرف المستخدم (مطلوب، مرجع لـ User)
  products: [OrderItem],     // المنتجات في الطلب
  totalAmount: Number,       // المبلغ الإجمالي (مطلوب، ≥ 0)
  status: String,            // حالة الطلب
  paymentStatus: String,     // حالة الدفع
  paymentIntentId: String,   // معرف نية الدفع من Stripe
  shippingAddress: {         // عنوان الشحن
    street: String,
    city: String,
    country: String,
    postalCode: String
  },
  createdAt: Date,           // تاريخ الإنشاء (تلقائي)
  updatedAt: Date            // تاريخ التحديث (تلقائي)
}
```

#### مخطط OrderItem (منتج في الطلب)

```javascript
{
  productId: ObjectId,       // معرف المنتج (مطلوب، مرجع لـ Product)
  quantity: Number,          // الكمية (مطلوب، ≥ 1)
  price: Number,             // السعر عند الشراء (مطلوب)
  name: String               // اسم المنتج (مطلوب)
}
```

#### القيود

- `userId`: مطلوب، مرجع لـ User
- `totalAmount`: مطلوب، لا يمكن أن يكون سالباً
- `status`: أحد القيم: 'pending', 'processing', 'shipped', 'delivered', 'cancelled'
- `paymentStatus`: أحد القيم: 'pending', 'completed', 'failed', 'refunded'
- `products[].quantity`: مطلوب، ≥ 1

#### العلاقات

- `userId`: مرجع لـ User (many-to-one)
- `products[].productId`: مرجع لـ Product (many-to-one)

---

### 5. Review (التقييم)

يمثل تقييمات المستخدمين للمنتجات.

#### المخطط

```javascript
{
  user: ObjectId,            // معرف المستخدم (مطلوب، مرجع لـ User)
  id_product: ObjectId,      // معرف المنتج (مطلوب، مرجع لـ Product)
  rating: Number,            // التقييم (مطلوب، 1-5)
  description: String,       // وصف التقييم (مطلوب، 1-1000 حرف)
  createdAt: Date,           // تاريخ الإنشاء (تلقائي)
  updatedAt: Date            // تاريخ التحديث (تلقائي)
}
```

#### القيود

- `user`: مطلوب، مرجع لـ User
- `id_product`: مطلوب، مرجع لـ Product
- `rating`: مطلوب، بين 1 و 5
- `description`: مطلوب، بين 1 و 1000 حرف

#### الفهارس

- `user` + `id_product`: فريد (compound unique index) - يمنع المستخدم من تقييم نفس المنتج أكثر من مرة

#### العلاقات

- `user`: مرجع لـ User (many-to-one)
- `id_product`: مرجع لـ Product (many-to-one)

---

### 6. Newsletter (النشرة البريدية)

يمثل المشتركين في النشرة البريدية.

#### المخطط

```javascript
{
  email: String,             // البريد الإلكتروني (مطلوب، فريد، lowercase)
  isActive: Boolean,         // حالة الاشتراك النشط (افتراضي: true)
  createdAt: Date,           // تاريخ الإنشاء (تلقائي)
  updatedAt: Date            // تاريخ التحديث (تلقائي)
}
```

#### القيود

- `email`: مطلوب، فريد، يتم تحويله لحروف صغيرة
- `isActive`: افتراضي true

#### الفهارس

- `email`: فريد (unique index)

---

## 🔗 العلاقات

### مخطط العلاقات

```
User (1) ───────< (N) Order
  │
  │
  ├──────< (N) Review
  │
  └──────> (1) Newsletter (اختياري)

Category (1) ───────< (N) Product
  │
  └──────> (N) Product (مرجع)

Product (1) ───────< (N) Review
  │
  └──────< (N) OrderItem (ضمن Order)
```

### شرح العلاقات

1. **User ↔ Order**: علاقة one-to-many
   - مستخدم واحد يمكنه إنشاء طلبات متعددة
   - كل طلب ينتمي لمستخدم واحد

2. **User ↔ Review**: علاقة one-to-many
   - مستخدم واحد يمكنه كتابة تقييمات متعددة
   - كل تقييم ينتمي لمستخدم واحد
   - قيد: المستخدم لا يمكنه تقييم نفس المنتج أكثر من مرة

3. **User ↔ Newsletter**: علاقة one-to-one (اختيارية)
   - مستخدم واحد يمكنه الاشتراك في النشرة البريدية
   - يتم تتبع الاشتراك أيضاً في حقل `newsLetter` في User

4. **Category ↔ Product**: علاقة one-to-many
   - فئة واحدة تحتوي على منتجات متعددة
   - منتج واحد يمكنه الانتمي لفئات متعددة (من خلال مصفوفة category)

5. **Product ↔ Review**: علاقة one-to-many
   - منتج واحد يمكنه الحصول على تقييمات متعددة
   - كل تقييم ينتمي لمنتج واحد

6. **Product ↔ Order**: علاقة many-to-many (عبر OrderItem)
   - منتج واحد يمكن أن يكون في طلبات متعددة
   - طلب واحد يمكن أن يحتوي على منتجات متعددة

---

## 📇 الفهارس

### الفهارس المفردة

| الكيان | الحقل | النوع | الوصف |
|--------|-------|-------|-------|
| User | email | Unique | فهرس فريد للبريد الإلكتروني |
| Product | sku | Sparse Unique | فهرس فريد اختياري لرمز المنتج |
| Category | name | Unique | فهرس فريد لاسم الفئة |
| Newsletter | email | Unique | فهرس فريد للبريد الإلكتروني |

### الفهارس المركبة

| الكيان | الحقول | النوع | الوصف |
|--------|--------|-------|-------|
| Review | user + id_product | Unique | يمنع تكرار التقييم من نفس المستخدم لنفس المنتج |

### الفهارس التلقائية

جميع الكيانات تحتوي على:
- `_id`: فهرس تلقائي من MongoDB
- `createdAt`: فهرس تلقائي للترتيب الزمني
- `updatedAt`: فهرس تلقائي للترتيب الزمني

---

## ✅ أفضل الممارسات

### 1. التحقق من البيانات

- جميع الحقول المطلوبة محمية بـ validation
- استخدام `trim()` للحقول النصية
- استخدام `lowercase()` للبريد الإلكتروني

### 2. الأمان

- كلمات المرور مشفرة باستخدام bcrypt
- لا يتم تخزين كلمات المرور كنص صريح
- استخدام JWT للمصادقة

### 3. الأداء

- الفهارس المفردة والمركبة لتحسين الاستعلامات
- استخدام `sparse` للفهارس الاختيارية
- تجنب الاستعلامات غير الضرورية

### 4. التكامل

- استخدام المراجع (References) للعلاقات
- استخدام `populate()` لجلب البيانات المرتبطة
- التحقق من صحة المراجع قبل الحفظ

### 5. الصيانة

- `timestamps: true` لتتبع التغييرات
- `versionKey: false` لتجنب حقل __v غير المستخدم
- استخدام `timestamps` للمراجعة والتدقيق

---

## 📝 أمثلة الاستعلام

### الحصول على منتج مع تقييماته

```javascript
const product = await Product.findById(productId)
  .populate('reviews');
```

### الحصول على طلبات مستخدم مع تفاصيل المنتجات

```javascript
const orders = await Order.find({ userId: userId })
  .populate('products.productId');
```

### الحصول على تقييمات منتج مع بيانات المستخدم

```javascript
const reviews = await Review.find({ id_product: productId })
  .populate('user', 'name email');
```

### الحصول على منتجات فئة معينة

```javascript
const category = await Category.findOne({ name: categoryName })
  .populate('products');
```

---

## 🔧 الصيانة والتحديثات

### إضافة حقول جديدة

عند إضافة حقول جديدة، تأكد من:
- تحديد القيم الافتراضية المناسبة
- إضافة الفهارس إذا لزم الأمر
- تحديث التوثيق

### تعديل المخططات الموجودة

- استخدم Mongoose migrations للتعديلات الكبيرة
- احتفظ بنسخة احتياطية قبل التعديل
- اختبر التغييرات في بيئة التطوير أولاً

### حذف البيانات

- استخدم soft delete إذا أمكن
- احتفظ بسجلات الحذف للتدقيق
- احذف البيانات المرتبطة بحذر

---

## 📚 المراجع

- [Mongoose Documentation](https://mongoosejs.com/docs/)
- [MongoDB Indexing](https://docs.mongodb.com/manual/indexes/)
- [MongoDB Data Modeling](https://docs.mongodb.com/manual/data-modeling/)
