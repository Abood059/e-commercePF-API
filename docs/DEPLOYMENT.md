# Deployment Guide - E-Commerce API

دليل شامل لنشر متجر إلكتروني (Node.js/Express + MongoDB) على VPS باستخدام Docker Compose و GitHub Actions.

## 📋 المتطلبات الأساسية

### على VPS (DigitalOcean)
- Ubuntu 20.04 أو أحدث
- 1 CPU, 1GB RAM, 25GB Storage
- SSH Access باستخدام مفتاح ed25519
- مستخدم deployer مع صلاحيات Docker

### على الجهاز المحلي
- Git
- SSH Client
- حساب GitHub مع Repository

## 🚀 خطوات النشر الأولي

### 1. تهيئة VPS

```bash
# الاتصال بـ VPS كـ root
ssh -i ~/.ssh/id_ed25519_digitalocean root@134.122.77.174

# تشغيل سكربت التهيئة
sudo bash setup-vps.sh
```

سيقوم السكربت بـ:
- تحديث النظام
- تثبيت Docker و Docker Compose
- إعداد Firewall (UFW)
- إنشاء مستخدم deployer
- تكوين Fail2Ban
- تفعيل SSH Hardening
- تحسين النظام لموارد محدودة

### 2. إضافة SSH Key لمستخدم deployer

```bash
# على جهازك المحلي
cat ~/.ssh/id_ed25519_digitalocean.pub | ssh root@134.122.77.174 "mkdir -p /home/deployer/.ssh && cat >> /home/deployer/.ssh/authorized_keys"

# تعديل الصلاحيات
ssh root@134.122.77.174 "chown -R deployer:deployer /home/deployer/.ssh && chmod 700 /home/deployer/.ssh && chmod 600 /home/deployer/.ssh/authorized_keys"
```

### 3. نسخ الملفات إلى VPS

```bash
# على جهازك المحلي
rsync -avz -e ssh \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude 'logs' \
  --exclude 'backups' \
  . deployer@134.122.77.174:/home/deployer/ecommerce-api/
```

### 4. إعداد متغيرات البيئة

```bash
# الاتصال بـ VPS كـ deployer
ssh -i ~/.ssh/id_ed25519_digitalocean deployer@134.122.77.174

# نسخ ملف البيئة
cd /home/deployer/ecommerce-api
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
MONGO_PASSWORD=your_secure_password
MONGO_DATABASE=ecommerce
SECRET_KEY=your_jwt_secret
RESET_PASSWORD_KEY=your_reset_key
AUTH_GOOGLE_CLIENT=your_google_client_id
STRIPE_SECRET_KEY=your_stripe_key
EMAIL_USER=your_email
EMAIL_PASS=your_email_password
CACHE_TTL=300
```

### 5. إعداد Cron Jobs

```bash
cd /home/deployer/ecommerce-api/scripts
bash setup-cron.sh
```

### 6. تشغيل التطبيق

```bash
cd /home/deployer/ecommerce-api

# بناء الصور
docker-compose build

# تشغيل الخدمات
docker-compose up -d

# التحقق من الحالة
docker-compose ps
docker-compose logs -f
```

## 🔧 GitHub Actions CI/CD

### إعداد GitHub Secrets

في GitHub Repository، أضف الـ Secrets التالية:

```
SSH_PRIVATE_KEY - محتوى مفتاح SSH الخاص
DEPLOY_HOST - 134.122.77.174
DEPLOY_USER - deployer
MONGO_USERNAME - admin
MONGO_PASSWORD - كلمة مرور MongoDB
MONGO_DATABASE - ecommerce
SECRET_KEY - JWT secret key
RESET_PASSWORD_KEY - Reset password key
AUTH_GOOGLE_CLIENT - Google Client ID
STRIPE_SECRET_KEY - Stripe Secret Key
EMAIL_USER - Email username
EMAIL_PASS - Email password
CLIENT_URL - http://134.122.77.174
SNYK_TOKEN - (اختياري) Snyk API token
```

### CI/CD Pipeline

الـ Pipeline يتضمن 6 مراحل:

1. **Validation**: Linting, Formatting, Type Checking
2. **Testing**: Unit Tests مع MongoDB
3. **Security**: npm audit, Snyk scan, Trivy scan, Secret detection
4. **Build**: بناء Docker Image
5. **Deploy**: نشر على VPS باستخدام Blue-Green
6. **Post-Deploy**: Smoke tests و cleanup

### تشغيل CI/CD

عند الدفع إلى `main` branch:
```bash
git add .
git commit -m "Release v1.0.0"
git push origin main
```

## 🔄 استراتيجية Blue-Green Deployment

### كيف تعمل

1. **Blue Environment**: يعمل على port 3000
2. **Green Environment**: يعمل على port 3001
3. **Nginx**: يوجه الطلبات إلى البيئة النشطة
4. **التبديل**: يتم بدون توقف (zero-downtime)

### النشر اليدوي

```bash
cd /home/deployer/ecommerce-api
bash scripts/deploy.sh
```

### التراجع (Rollback)

```bash
cd /home/deployer/ecommerce-api
bash scripts/rollback.sh backup_20240129_120000
```

## 💾 النسخ الاحتياطي والاستعادة

### النسخ الاحتياطي اليدوي

```bash
cd /home/deployer/ecommerce-api/scripts
bash backup-mongodb.sh
```

### النسخ الاحتياطي التلقائي

يتم تلقائياً كل يوم أحد الساعة 2 صباحاً عبر Cron job.

### الاستعادة من النسخة

```bash
cd /home/deployer/ecommerce-api/scripts
bash restore-mongodb.sh mongodb_backup_20240129_120000.gz
```

### إدارة النسخ الاحتياطية

```bash
# عرض النسخ المتاحة
ls -lh /home/deployer/backups/mongodb/

# حذف نسخ قديمة يدوياً
find /home/deployer/backups/mongodb -name "mongodb_backup_*.gz" -mtime +30 -delete
```

## 🔍 المراقبة والتشخيص

### التحقق من حالة الخدمات

```bash
# حالة جميع الحاويات
docker-compose ps

# سجلات الخدمة
docker-compose logs -f api-blue
docker-compose logs mongodb
docker-compose logs nginx

# استخدام الموارد
docker stats
```

### Health Checks

```bash
# Health check عبر Nginx
curl http://134.122.77.174/health

# Health check مباشر للـ API
curl http://134.122.77.174:3000/health
```

### عرض السجلات

```bash
# سجلات التطبيق
tail -f /home/deployer/ecommerce-api/logs/app.log

# سجلات النسخ الاحتياطي
tail -f /home/deployer/logs/backup.log

# سجلات Docker
journalctl -u docker -f
```

## 🛠️ الصيانة الروتينية

### تنظيف Docker

```bash
# تنظيف الحاويات والصور غير المستخدمة
docker system prune -a --volumes

# تنظيف تلقائي (مجدول في Cron)
# يعمل كل يوم الساعة 3 صباحاً
```

### تحديث التطبيق

```bash
# عبر CI/CD (موصى به)
git push origin main

# أو يدوياً
cd /home/deployer/ecommerce-api
git pull origin main
bash scripts/deploy.sh
```

### تحديث Docker Images

```bash
cd /home/deployer/ecommerce-api
docker-compose pull
docker-compose up -d
```

## 🔒 الأمان

### إدارة الأسرار

- جميع الأسرار في `.env` file (gitignored)
- GitHub Secrets لـ CI/CD
- لا تضع أسرار في الكود أو Git

### Firewall Rules

```bash
# عرض القواعد الحالية
sudo ufw status verbose

# إضافة منفذ جديد
sudo ufw allow PORT/tcp

# حذف منفذ
sudo ufw delete allow PORT/tcp
```

### SSH Access

```bash
# تعطيل تسجيل الدخول بكلمة المرور
sudo nano /etc/ssh/sshd_config.d/security.conf
# تأكد من: PasswordAuthentication no

# إعادة تشغيل SSH
sudo systemctl restart sshd
```

## 🐛 استكشاف الأخطاء

### المشكلة: الحاوية لا تبدأ

```bash
# عرض سجلات الحاوية
docker-compose logs api-blue

# التحقق من حالة الحاوية
docker inspect ecommerce-api-blue

# إعادة بناء الصورة
docker-compose build --no-cache api-blue
docker-compose up -d api-blue
```

### المشكلة: MongoDB لا يتصل

```bash
# التحقق من حالة MongoDB
docker-compose logs mongodb

# الدخول إلى MongoDB
docker exec -it ecommerce-mongodb mongosh

# اختبار الاتصال
docker exec ecommerce-mongodb mongosh --eval "db.adminCommand('ping')"
```

### المشكلة: Nginx لا يعمل

```bash
# اختبار تكوين Nginx
docker-compose exec nginx nginx -t

# إعادة تحميل Nginx
docker-compose exec nginx nginx -s reload

# عرض سجلات Nginx
docker-compose logs nginx
tail -f /home/deployer/ecommerce-api/nginx/logs/access.log
```

### المشكلة: نفاد الذاكرة

```bash
# التحقق من استخدام الذاكرة
free -h
docker stats

# إيقاف حاويات غير ضرورية
docker-compose stop api-green

# زيادة Swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 📊 الأوامر الشائعة

### Docker Compose

```bash
# تشغيل جميع الخدمات
docker-compose up -d

# إيقاف جميع الخدمات
docker-compose down

# إيقاف وحذف جميع الخدمات والـ volumes
docker-compose down -v

# إعادة بناء وتشغيل
docker-compose up -d --build

# عرض سجلات
docker-compose logs -f [service_name]

# تنفيذ أمر في حاوية
docker-compose exec api-blue bash
```

### إدارة الحاويات

```bash
# عرض الحاويات النشطة
docker ps

# عرض جميع الحاويات
docker ps -a

# إيقاف حاوية
docker stop [container_name]

# بدء حاوية
docker start [container_name]

# حذف حاوية
docker rm [container_name]

# عرض سجلات حاوية
docker logs [container_name]
```

### إدارة الصور

```bash
# عرض الصور
docker images

# حذف صور غير مستخدمة
docker image prune -a

# حذف صورة محددة
docker rmi [image_name]
```

## 📞 الدعم

للمساعدة والدعم:
- راجع `docs/RUNBOOKS.md` للإجراءات الطارئة
- راجع `docs/CHECKLIST.md` قبل كل نشر
- افتح issue في GitHub Repository
