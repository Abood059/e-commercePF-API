# Runbooks - E-Commerce API

إجراءات تشغيلية للتعامل مع السيناريوهات الطارئة والصيانة الروتينية.

## 🚨 Runbook: Rollback بعد فشل النشر

### السيناريو
فشل النشر الأخير والتطبيق غير متاح.

### الخطوات

1. **تحديد النسخة المراد التراجع إليها**
```bash
ssh -i ~/.ssh/id_ed25519_digitalocean deployer@134.122.77.174
cd /home/deployer/ecommerce-api/scripts
./rollback.sh
# اختر النسخة من القائمة
```

2. **التحقق من الحالة**
```bash
cd /home/deployer/ecommerce-api
docker-compose ps
curl http://localhost/health
```

3. **إذا فشل الـ Rollback**
```bash
# إيقاف جميع الحاويات
docker-compose down

# استعادة يدوياً من النسخة الاحتياطية
cp -r /home/deployer/backups/backup_YYYYMMDD_HHMMSS/current /home/deployer/ecommerce-api/

# إعادة التشغيل
docker-compose up -d
```

4. **التحقيق في سبب الفشل**
```bash
# عرض سجلات النشر
tail -f /home/deployer/logs/deployment.log

# عرض سجلات Docker
docker-compose logs api-blue
```

## 🗄️ Runbook: استعادة قاعدة البيانات

### السيناريو
فقدان أو تلف بيانات MongoDB.

### الخطوات

1. **إيقاف التطبيق**
```bash
cd /home/deployer/ecommerce-api
docker-compose stop api-blue api-green
```

2. **اختيار النسخة الاحتياطية**
```bash
cd /home/deployer/ecommerce-api/scripts
./restore-mongodb.sh
# اختر النسخة من القائمة
```

3. **التحقق من الاستعادة**
```bash
docker exec -it ecommerce-mongodb mongosh
use ecommerce
db.products.countDocuments()
exit
```

4. **إعادة تشغيل التطبيق**
```bash
cd /home/deployer/ecommerce-api
docker-compose start api-blue
```

5. **اختبار التطبيق**
```bash
curl http://localhost/api/products
```

## 💾 Runbook: إنشاء نسخة احتياطية طارئة

### السيناريو
تحديثات كبيرة أو تغييرات خطيرة على قاعدة البيانات.

### الخطوات

1. **إنشاء نسخة احتياطية فورية**
```bash
cd /home/deployer/ecommerce-api/scripts
./backup-mongodb.sh
```

2. **التحقق من النسخة**
```bash
ls -lh /home/deployer/backups/mongodb/
gzip -t /home/deployer/backups/mongodb/mongodb_backup_*.gz
```

3. **توثيق الإجراء**
```bash
echo "Emergency backup created at $(date)" >> /home/deployer/logs/emergency-backups.log
```

## 🔥 Runbook: استجابة لاستهلاك عالي للموارد

### السيناريو
استهلاك عالي للـ CPU أو RAM يؤثر على الأداء.

### الخطوات

1. **تشخيص المشكلة**
```bash
# استخدام الموارد
free -h
top
docker stats

# تحديد الحاوية المسببة
docker ps --format "table {{.Names}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

2. **إجراءات فورية**
```bash
# إيقاف البيئة غير النشطة
docker-compose stop api-green

# إعادة تشغيل الحاوية المسببة
docker-compose restart api-blue

# تنظيف Docker
docker system prune -f
```

3. **إذا استمرت المشكلة**
```bash
# زيادة الـ Swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# تحديد حد للموارد
docker-compose up -d --scale api-blue=1
```

4. **المراقبة المستمرة**
```bash
# إضافة مراقبة مؤقتة
watch -n 5 'docker stats --no-stream'
```

## 🌐 Runbook: استجابة لـ Downtime

### السيناريو
التطبيق غير متاح للمستخدمين.

### الخطوات

1. **التشخيص السريع**
```bash
# التحقق من حالة الحاويات
docker-compose ps

# التحقق من Nginx
curl http://localhost/health

# التحقق من MongoDB
docker exec ecommerce-mongodb mongosh --eval "db.adminCommand('ping')"
```

2. **إعادة تشغيل الخدمات**
```bash
cd /home/deployer/ecommerce-api

# إعادة تشغيل Nginx
docker-compose restart nginx

# إعادة تشغيل API
docker-compose restart api-blue

# إعادة تشغيل MongoDB
docker-compose restart mongodb
```

3. **إذا لم تنجح إعادة التشغيل**
```bash
# إعادة بناء وتش-gيل
docker-compose down
docker-compose up -d --build
```

4. **التحقق من الاتصال**
```bash
curl http://134.122.77.174/health
curl http://134.122.77.174/api/products
```

## 🔐 Runbook: استجابة لاختراق أمني محتمل

### السيناريو
نشاط مشبوه أو محاولة اختراق.

### الخطوات

1. **تقييم الوضع**
```bash
# عرض محاولات تسجيل الدخول الفاشلة
sudo fail2ban-client status sshd

# عرض سجلات الأمان
sudo tail -f /var/log/auth.log

# عرض سجلات التطبيق
tail -f /home/deployer/ecommerce-api/logs/security.log
```

2. **إجراءات فورية**
```bash
# حظر IPs مشبوهة
sudo ufw deny from SUSPICIOUS_IP

# تكثيف Fail2Ban
sudo nano /etc/fail2ban/jail.local
# قلل maxretry وزد bantime

sudo systemctl restart fail2ban
```

3. **تدوير الأسرار**
```bash
# تغيير كلمات مرور MongoDB
cd /home/deployer/ecommerce-api
nano .env
# حدّث MONGO_PASSWORD

# إعادة تشغيل MongoDB
docker-compose restart mongodb

# تحديث GitHub Secrets
# في GitHub Repository > Settings > Secrets
```

4. **مراجعة الصلاحيات**
```bash
# مراجعة المستخدمين
who
w

# مراجعة الاتصالات النشطة
ss -tulpn

# مراجعة العمليات
ps aux
```

## 🔄 Runbook: ترقية MongoDB

### السيناريو
تحديث MongoDB إلى إصدار أحدث.

### الخطوات

1. **النسخ الاحتياطي الإجباري**
```bash
cd /home/deployer/ecommerce-api/scripts
./backup-mongodb.sh
```

2. **تعديل docker-compose.yml**
```bash
cd /home/deployer/ecommerce-api
nano docker-compose.yml
# غيّر image: mongo:6.0 إلى mongo:7.0
```

3. **إيقاف الحاويات**
```bash
docker-compose stop api-blue api-green mongodb
```

4. **حذف الـ Volume القديم (اختياري)**
```bash
# احذر! هذا سيحذف البيانات
# docker volume rm ecommercepf-api_mongodb_data
```

5. **تشغيل النسخة الجديدة**
```bash
docker-compose up -d mongodb
```

6. **الترقية (إذا لزم الأمر)**
```bash
docker exec -it ecommerce-mongodb mongosh
use admin
db.adminCommand({setFeatureCompatibilityVersion: "7.0"})
exit
```

7. **إعادة تشغيل التطبيق**
```bash
docker-compose up -d api-blue
```

8. **الاختبار**
```bash
curl http://localhost/api/products
```

## 📦 Runbook: ترقية Node.js Dependencies

### السيناريو
تحديث المكتبات لإصلاحات أمنية أو ميزات جديدة.

### الخطوات

1. **على جهاز التطوير**
```bash
# تحديث المكتبات
npm update

# فحص الثغرات
npm audit

# إصلاح تلقائي
npm audit fix

# تشغيل الاختبارات
npm test
```

2. **النشر**
```bash
git add .
git commit -m "Update dependencies"
git push origin main
# CI/CD سيتولى الباقي
```

3. **المراقبة بعد النشر**
```bash
ssh deployer@134.122.77.174
cd /home/deployer/ecommerce-api
docker-compose logs -f api-blue
```

## 🧹 Runbook: تنظيف القرص

### السيناريو
نفاد مساحة القرص.

### الخطوات

1. **تقييم الوضع**
```bash
df -h
du -sh /home/deployer/*
```

2. **تنظيف Docker**
```bash
# تنظيف شامل
docker system prune -a --volumes

# تنظيف الصور القديمة
docker image prune -a

# تنظيف الحاويات المتوقفة
docker container prune
```

3. **تنظيف السجلات**
```bash
# سجلات التطبيق
find /home/deployer/ecommerce-api/logs -name "*.log" -mtime +7 -delete

# سجلات النظام
sudo journalctl --vacuum-time=7d

# سجلات Docker
sudo journalctl -u docker --vacuum-time=7d
```

4. **تنظيف النسخ الاحتياطية القديمة**
```bash
find /home/deployer/backups -type d -mtime +30 -exec rm -rf {} +
```

5. **تنظيف Cache**
```bash
# npm cache
npm cache clean --force

# apt cache (على VPS)
sudo apt-get clean
sudo apt-get autoremove
```

## 🔧 Runbook: إضافة مستخدم جديد للنشر

### السيناريو
إضافة مطور جديد للوصول إلى VPS.

### الخطوات

1. **على جهاز المستخدم الجديد**
```bash
# توليد مفتاح SSH
ssh-keygen -t ed25519 -C "developer@example.com"
```

2. **على VPS**
```bash
ssh -i ~/.ssh/id_ed25519_digitalocean deployer@134.122.77.174

# إضافة المفتاح العام
nano ~/.ssh/authorized_keys
# ألصق المفتاح العام الجديد

# تعديل الصلاحيات
chmod 600 ~/.ssh/authorized_keys
```

3. **الاختبار**
```bash
# على جهاز المستخدم الجديد
ssh -i ~/.ssh/id_ed25519 deployer@134.122.77.174
```

## 📊 Runbook: تحليل الأداء

### السيناريو
تحسين أداء التطبيق.

### الخطوات

1. **جمع البيانات**
```bash
# استخدام الموارد
docker stats --no-stream

# استجابة الـ API
time curl http://localhost/api/products

# استعلامات MongoDB
docker exec ecommerce-mongodb mongosh
use ecommerce
db.getProfilingLevel()
db.setProfilingLevel(2)
# بعد فترة
db.system.profile.find().sort({ts:-1}).limit(10)
```

2. **تحليل السجلات**
```bash
# أوقات الاستجابة البطيئة
grep "slow" /home/deployer/ecommerce-api/logs/app.log

# الأخطاء المتكررة
grep "ERROR" /home/deployer/ecommerce-api/logs/app.log | sort | uniq -c
```

3. **تحسينات مقترحة**
```bash
# إضافة Redis للـ caching
# تحسين استعلامات MongoDB
# إضافة compression في Nginx
# تفعيل HTTP/2
```

## 📝 Runbook: توثيق الحوادث

### السيناريو
توثيق حادث لتحليل مستقبلي.

### الخطوات

1. **إنشاء تقرير الحادث**
```bash
nano /home/deployer/logs/incident_$(date +%Y%m%d).md
```

2. **محتوى التقرير**
```markdown
# Incident Report

## التاريخ والوقت
- البداية: YYYY-MM-DD HH:MM
- النهاية: YYYY-MM-DD HH:MM
- المدة: X hours

## الوصف
وصف مختصر للحادث

## التأثير
- عدد المستخدمين المتأثرين: X
- وقت التوقف: X minutes
- الخدمات المتأثرة: API, Database

## السبب الجذري
تحليل مفصل للسبب

## الإجراءات المتخذة
1. ...
2. ...

## الدروس المستفادة
- ...
- ...

## الإجراءات الوقائية المستقبلية
- ...
- ...
```

3. **المراجعة**
```bash
# إضافة إلى سجل الحوادث
echo "Incident documented at $(date)" >> /home/deployer/logs/incidents.log
```

## 🆘 Runbook: طلب مساعدة

### السيناريو
حالة طارئة تتطلب مساعدة خارجية.

### الخطوات

1. **تجميع المعلومات**
```bash
# حالة النظام
docker-compose ps > /tmp/system_status.txt
docker stats --no-stream >> /tmp/system_status.txt
df -h >> /tmp/system_status.txt
free -h >> /tmp/system_status.txt

# السجلات الأخيرة
docker-compose logs --tail=100 api-blue > /tmp/api_logs.txt
docker-compose logs --tail=100 mongodb > /tmp/mongodb_logs.txt
tail -100 /home/deployer/logs/deployment.log > /tmp/deployment_logs.txt
```

2. **إنشاء تقرير**
```bash
cat > /tmp/emergency_report.md << EOF
# Emergency Report

## الوقت
$(date)

## المشكلة
وصف المشكلة

## المرفقات
- system_status.txt
- api_logs.txt
- mongodb_logs.txt
- deployment_logs.txt

## الإجراءات المتخذة
1. ...
2. ...
EOF
```

3. **مشاركة المعلومات**
```bash
# نسخ الملفات
scp /tmp/*.txt user@backup-server:/tmp/
scp /tmp/emergency_report.md user@backup-server:/tmp/
```

## 📚 المراجع

- [Deployment Guide](DEPLOYMENT.md)
- [Pre-deployment Checklist](CHECKLIST.md)
- [Security Documentation](SECURITY.md)
