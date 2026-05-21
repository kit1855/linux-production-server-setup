# Поиск и устранение неисправностей

Типовые проблемы и их решения.

## 1. Не открывается сайт по HTTPS

**Симптом:** Браузер выдаёт ошибку «Сайт недоступен» или «Соединение не защищено».

**Вероятные причины:**
- Nginx не запущен
- Docker-контейнер остановлен
- SSL-сертификат не получен или истёк
- Firewall блокирует порт 443

**Проверка:**

```bash
sudo systemctl status nginx
sudo systemctl status docker
docker ps
sudo certbot certificates
sudo ufw status | grep 443
```

**Решение:**

```bash
# Запустить Nginx
sudo systemctl start nginx

# Запустить контейнер
docker start test-app

# Перевыпустить сертификат
sudo certbot --nginx -d ваш-домен --force-renew
```

---

## 2. Не работает перенаправление HTTP → HTTPS

**Симптом:** При открытии `http://ваш-домен` сайт не перенаправляется на HTTPS.

**Причина:** Неправильная конфигурация Nginx.

**Проверка:**

```bash
sudo nginx -T | grep -A 10 "server {"
curl -I http://ваш-домен
```

**Решение:** В конфиге Nginx должен быть блок:

```nginx
server {
    listen 80;
    server_name ваш-домен;
    return 301 https://$server_name$request_uri;
}
```

После исправления:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 3. Ошибка 502 Bad Gateway

**Симптом:** Сайт возвращает ошибку 502.

**Причина:** Docker-контейнер не запущен или не слушает порт 3000.

**Проверка:**

```bash
docker ps
curl http://localhost:3000
```

**Решение:**

```bash
# Запустить контейнер
docker start test-app

# Настроить автозапуск
docker update --restart=unless-stopped test-app
```

---

## 4. Не получается подключиться по SSH

**Симптом:** Ошибка `Permission denied (publickey)` или `Connection refused`.

**Вероятные причины:**
- Неправильный ключ
- SSH-сервис остановлен
- UFW блокирует порт 22
- Fail2ban заблокировал IP

**Проверка:**

```bash
sudo systemctl status sshd
sudo ufw status | grep 22
sudo fail2ban-client status sshd
```

**Решение:**

```bash
# Проверить ключи на сервере
ls -la ~/.ssh/authorized_keys

# Удалить IP из блокировки Fail2ban
sudo fail2ban-client set sshd unbanip ВАШ-IP

# Разрешить порт 22 в UFW
sudo ufw allow 22/tcp
```

---

## 5. Не открываются метрики Node Exporter

**Симптом:** Страница `http://ваш-домен:9100/metrics` не открывается.

**Вероятные причины:**
- Node Exporter не запущен
- Порт 9100 закрыт в UFW

**Проверка:**

```bash
sudo systemctl status node_exporter
sudo ufw status | grep 9100
curl http://localhost:9100/metrics | head
```

**Решение:**

```bash
# Запустить Node Exporter
sudo systemctl start node_exporter

# Открыть порт в UFW
sudo ufw allow 9100/tcp
sudo ufw reload
```

---

## 6. Ошибка Certbot: Network is unreachable

**Симптом:** Certbot не может получить сертификат.

**Причина:** Проблемы с сетью или DNS.

**Проверка:**

```bash
ping -c 4 8.8.8.8
nslookup ваш-домен
sudo ufw status
```

**Решение:**

```bash
# Принудительно использовать IPv4
certbot --nginx -d ваш-домен --preferred-challenges http

# Временно отключить UFW
sudo ufw disable
# ... выполнить certbot ...
sudo ufw enable
```

---

## 7. Бэкап не создаётся

**Симптом:** В папке `/home/user/backups/` нет файлов.

**Проверка:**

```bash
ls -la /home/user/backups/
crontab -l
journalctl -u cron --since "yesterday" | grep backup
```

**Решение:**

```bash
# Запустить скрипт вручную
/home/user/backup.sh

# Добавить задачу в cron
crontab -e
# Добавить строку:
0 3 * * * /home/user/backup.sh
```
```

---

