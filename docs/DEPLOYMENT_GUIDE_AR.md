# دليل النشر الشامل - E-Commerce API

## 📋 جدول المحتويات

1. [نظرة عامة](#نظرة-عامة)
2. [المتطلبات الأساسية](#المتطلبات-الأساسية)
3. [البنية التحتية](#البنية-التحتية)
4. [الإعداد الأولي](#الإعداد-الأولي)
5. [عملية النشر](#عملية-النشر)
6. [التحقق من النشر](#التحقق-من-النشر)
7. [الصيانة والتشغيل](#الصيانة-والتشغيل)
8. [استكشاف الأخطاء](#استكشاف-الأخطاء)
9. [التنظيف والإزالة](#التنظيف-والإزالة)

---

## نظرة عامة

هذا الدليل يشرح عملية نشر متجر إلكتروني (Node.js/Express + MongoDB) على VPS باستخدام Docker Compose و Nginx كـ reverse proxy.

### التقنيات المستخدمة

- **Backend**: Node.js 18, Express.js
- **Database**: MongoDB 6.0
- **Containerization**: Docker, Docker Compose
- **Reverse Proxy**: Nginx
- **VPS**: DigitalOcean (1 CPU, 1GB RAM, 25GB Storage)
- **OS**: Ubuntu 24.04 LTS

### البنية المعمارية

```
Internet → Nginx (Port 80/443) → API Blue (Port 8080) → MongoDB (Port 27017)
                                      ↓
                                 API Green (Port 8081) - Backup
```

---

## المتطلبات الأساسية

### على جهاز التطوير
- Git
- SSH Client
- محرر نصوص (VS Code, Nano, إلخ)

### على VPS
- Ubuntu 20.04 أو أحدث
- SSH Access باستخدام مفتاح ed25519
- مستخدم deployer مع صلاحيات Docker
- Docker و Docker Compose مثبتين

---

## البنية التحتية

### الموارد المخصصة

| المورد | التخصيص |
|--------|---------|
| CPU | 1 core |
| RAM | 1 GB |
| Storage | 25 GB |
| Ports | 80, 443, 8080, 8081, 27017 |

### Ports المستخدمة

| Port | الخدمة | الوصف |
|------|--------|-------|
| 80 | Nginx | HTTP |
| 443 | Nginx | HTTPS (مستقبلي) |
| 8080 | API Blue | بيئة الإنتاج النشطة |
| 8081 | API Green | بيئة الاحتياط |
| 27017 | MongoDB | قاعدة البيانات (داخلي) |

---

## الإعداد الأولي

### 1. إعداد SSH Access

```bash
# توليد مفتاح SSH (إذا لم يكن موجوداً)
ssh-keygen -t ed25519 -C "deployer@vps"

# نسخ المفتاح العام إلى VPS
ssh-copy-id -i ~/.ssh/id_ed25519_digitalocean deployer@134.122.77.174

# اختبار الاتصال
ssh -i ~/.ssh/id_ed25519_digitalocean deployer@134.122.77.174
```

### 2. إعداد VPS (مرة واحدة)

```bash
# الاتصال كـ root
ssh -i ~/.ssh/id_ed25519_digitalocean root@134.122.77.174

# تشغيل سكربت التهيئة
sudo bash setup-vps.sh
```

يقوم السكربت بـ:
- تحديث النظام
- تثبيت Docker و Docker Compose
- إعداد UFW Firewall
- إنشاء مستخدم deployer
- تكوين Fail2Ban
- SSH Hardening
- تحسين النظام لموارد محدودة

### 3. إضافة SSH Key لمستخدم deployer

```bash
# على جهازك المحلي
cat ~/.ssh/id_ed25519_digitalocean.pub | ssh root@134.122.77.174 "cat >> /home/deployer/.ssh/authorized_keys"

# تعديل الصلاحيات
ssh root@134.122.77.174 "chown -R deployer:deployer /home/deployer/.ssh && chmod 700 /home/deployer/.ssh && chmod 600 /home/deployer/.ssh/authorized_keys"
```

---

## عملية النشر

### الخطوة 1: إعداد الملفات محلياً

```bash
# الانتقال إلى مجلد المشروع
cd /home/abood/Project/e-commercePF-API

# التأكد من وجود الملفات المطلوبة
ls -la Dockerfile docker-compose.yml .env.example nginx/ scripts/
```

### الخطوة 2: إعداد متغيرات البيئة

```bash
# نسخ ملف القالب
cp .env.example .env

# تعديل المتغيرات
nano .env
```

المتغيرات المطلوبة:
```env
NODE_ENV=production
PORT=3000
CLIENT_URL=http://134.122.77.174
MONGO_USERNAME=admin
MONGO_PASSWORD=SecurePass123!
MONGO_DATABASE=ecommerce
SECRET_KEY=SuperSecretJWTKey2024!
RESET_PASSWORD_KEY=ResetPassKey2024!
AUTH_GOOGLE_CLIENT=your_google_client_id
STRIPE_SECRET_KEY=your_stripe_key
EMAIL_USER=your_email@example.com
EMAIL_PASS=your_email_password
CACHE_TTL=300
```

### الخطوة 3: نسخ الملفات إلى VPS

```bash
# إنشاء المجلدات على VPS
ssh -i ~/.ssh/id_ed25519_digitalocean deployer@134.122.77.174 \
  "mkdir -p /home/deployer/ecommerce-api/scripts /home/deployer/ecommerce-api/nginx/confd /home/deployer/ecommerce-api/nginx/logs /home/deployer/backups/mongodb /home/deployer/logs"

# نسخ السكربتات
scp -i ~/.ssh/id_ed25519_digitalocean scripts/* deployer@134.122.77.174:/home/deployer/ecommerce-api/scripts/

# نسخ ملفات Docker
scp -i ~/.ssh/id_ed25519_digitalocean Dockerfile docker-compose.yml .dockerignore .env.example deployer@134.122.77.174:/home/deployer/ecommerce-api/

# نسخ ملفات Nginx
scp -i ~/.ssh/id_ed25519_digitalocean -r nginx/ deployer@134.122.77.174:/home/deployer/ecommerce-api/

# نسخ التطبيق بالكامل
rsync -avz -e "ssh -i ~/.ssh/id_ed25519_digitalocean" \
  --exclude 'node_modules' --exclude '.git' --exclude 'logs' --exclude 'backups' \
  . deployer@134.122.77.174:/home/deployer/ecommerce-api/
```

### الخطوة 4: إعداد البيئة على VPS

```bash
# الاتصال بـ VPS
ssh -i ~/.ssh/id_ed25519_digitalocean deployer@134.122.77.174

# الانتقال إلى مجلد المشروع
cd /home/deployer/ecommerce-api

# نسخ ملف البيئة
cp .env.example .env

# تعديل المتغيرات
nano .env
```

### الخطوة 5: بناء Docker Images

```bash
cd /home/deployer/ecommerce-api

# بناء الصور
docker compose build
```

يقوم هذا الأمر بـ:
- سحب صورة Node.js 18 Alpine
- تثبيت dependencies
- بناء صورة production محسّنة
- إنشاء non-root user

### الخطوة 6: تشغيل الخدمات

```bash
# تشغيل MongoDB أولاً
docker compose up -d mongodb

# انتظار MongoDB ليصبح healthy
docker compose ps

# تشغيل API و Nginx
docker compose up -d api-blue nginx
```

### الخطوة 7: إعداد Cron Jobs

```bash
cd /home/deployer/ecommerce-api/scripts
bash setup-cron.sh
```

يقوم هذا بـ:
- إعداد backup أسبوعي (الأحد 2 صباحاً)
- إعداد Docker cleanup يومي (3 صباحاً)
- إعداد log rotation يومي (4 صباحاً)
- إعداد health check كل 15 دقيقة

---

## التحقق من النشر

### 1. التحقق من حالة الحاويات

```bash
docker compose ps
```

النتيجة المتوقعة:
```
NAME                 STATUS                    PORTS
ecommerce-api-blue   Up (healthy)              0.0.0.0:8080->3000/tcp
ecommerce-mongodb    Up (healthy)              27017/tcp
ecommerce-nginx      Up (health: starting)     0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

### 2. اختبار Health Check

```bash
curl http://134.122.77.174/health
```

النتيجة المتوقعة:
```
healthy
```

### 3. اختبار API Endpoint

```bash
curl http://134.122.77.174/api/products
```

النتيجة المتوقعة:
```json
{
  "success": true,
  "message": "Success",
  "data": []
}
```

### 4. التحقق من السجلات

```bash
# سجلات API
docker compose logs -f api-blue

# سجلات MongoDB
docker compose logs -f mongodb

# سجلات Nginx
docker compose logs -f nginx
```

### 5. التحقق من الموارد

```bash
# استخدام الموارد
docker stats

# استخدام القرص
df -h

# استخدام الذاكرة
free -h
```

---

## الصيانة والتشغيل

### أوامر Docker Compose الشائعة

```bash
cd /home/deployer/ecommerce-api

# عرض حالة الخدمات
docker compose ps

# عرض سجلات الخدمة
docker compose logs -f [service_name]

# إعادة تشغيل خدمة
docker compose restart [service_name]

# إيقاف خدمة
docker compose stop [service_name]

# بدء خدمة
docker compose start [service_name]

# إيقاف جميع الخدمات
docker compose down

# إيقاف وحذف جميع الخدمات والـ volumes
docker compose down -v

# إعادة بناء وتشغيل
docker compose up -d --build
```

### النسخ الاحتياطي

```bash
# يدوياً
cd /home/deployer/ecommerce-api/scripts
bash backup-mongodb.sh

# عرض النسخ المتاحة
ls -lh /home/deployer/backups/mongodb/

# استعادة من نسخة
bash restore-mongodb.sh mongodb_backup_YYYYMMDD_HHMMSS.gz
```

### النشر (Blue-Green)

```bash
# نشر يدوي
cd /home/deployer/ecommerce-api
bash scripts/deploy.sh

# التراجع
bash scripts/rollback.sh backup_YYYYMMDD_HHMMSS
```

### تنظيف Docker

```bash
# تنظيف شامل
docker system prune -a --volumes

# تنظيف الصور القديمة
docker image prune -a

# تنظيف الحاويات المتوقفة
docker container prune
```

---

## استكشاف الأخطاء

### المشكلة: الحاوية لا تبدأ

```bash
# عرض سجلات الحاوية
docker compose logs api-blue

# التحقق من حالة الحاوية
docker inspect ecommerce-api-blue

# إعادة بناء الصورة
docker compose build --no-cache api-blue
docker compose up -d api-blue
```

### المشكلة: MongoDB لا يتصل

```bash
# التحقق من حالة MongoDB
docker compose logs mongodb

# الدخول إلى MongoDB
docker exec -it ecommerce-mongodb mongosh

# اختبار الاتصال
docker exec ecommerce-mongodb mongosh --eval "db.adminCommand('ping')"
```

### المشكلة: Nginx لا يعمل

```bash
# اختبار تكوين Nginx
docker compose exec nginx nginx -t

# إعادة تحميل Nginx
docker compose exec nginx nginx -s reload

# عرض سجلات Nginx
docker compose logs nginx
```

### المشكلة: نفاد الذاكرة

```bash
# التحقق من استخدام الذاكرة
free -h
docker stats

# إيقاف حاويات غير ضرورية
docker compose stop api-green

# تنظيف Docker
docker system prune -f
```

### المشكلة: Port conflict

```bash
# عرض Ports المستخدمة
ss -tulpn

# تغيير Port في docker-compose.yml
# ثم إعادة النشر
docker compose up -d
```

---

## التنظيف والإزالة

### إيقاف الخدمات

```bash
cd /home/deployer/ecommerce-api

# إيقاف جميع الخدمات
docker compose down

# إيقاف وحذف جميع الخدمات والـ volumes
docker compose down -v
```

### حذف الملفات

```bash
# حذف مجلد المشروع
cd /home/deployer
rm -rf ecommerce-api

# حذف مجلد النسخ الاحتياطية
rm -rf backups

# حذف مجلد السجلات
rm -rf logs
```

### حذف Docker Images

```bash
# حذف الصور المخصصة
docker rmi ecommerce-api-api-blue

# تنظيف شامل
docker system prune -a --volumes
```

### إزالة Cron Jobs

```bash
# عرض Cron jobs الحالية
crontab -l

# تحرير وحذف
crontab -e

# أو إزالة بالكامل
crontab -r
```

### إزالة المستخدم (اختياري)

```bash
# كـ root
sudo userdel -r deployer
```

---

## الخلاصة

عملية النشر تتضمن:
1. إعداد VPS و Docker
2. نسخ الملفات إلى VPS
3. إعداد متغيرات البيئة
4. بناء Docker Images
5. تشغيل الخدمات
6. إعداد Cron Jobs
7. التحقق من النشر

النشر الناجح يعتمد على:
- التحقق من كل خطوة
- مراقبة السجلات
- اختبار الـ endpoints
- إعداد النسخ الاحتياطي
- الصيانة الدورية

---

**التاريخ**: 29 يوليو 2026  
**الإصدار**: 1.0.0  
**الحالة**: تم النشر والاختبار بنجاح
