## 1. Предварительные требования

Перед началом развёртывания убедитесь, что у вас есть:

| Требование | Примечание |
|------------|------------|
| VPS с Ubuntu 22.04 LTS | Минимум 1 vCPU, 2 GB RAM, 25 GB диска |
| Домен, указывающий на IP сервера | A-запись домена должна вести на ваш VPS |
| SSH-ключ | Сгенерирован на вашем компьютере (Windows/Linux/Mac) |
| Доступ к серверу по SSH | Проверьте: `ssh user@IP-адрес` |

### Проверка перед началом

```bash
# Проверить версию Ubuntu
lsb_release -a
```
# Проверить, что домен смотрит на ваш сервер (выполнить на локальном компьютере)
```bash
nslookup ваш-домен.ru
```
# Проверить SSH-доступ
```bash
ssh user@IP-адрес
```
## 2. Безопасность SSH

### 2.1 Цель

Настроить безопасный доступ к серверу: создать обычного пользователя, отключить вход для root, запретить вход по паролю, оставив только вход по SSH-ключам.

### 2.2 Создание нового пользователя

Выполните команды от имени root:

# Создать пользователя (вместо user укажите своё имя)
```bash
adduser user
```
# Добавить пользователя в группу sudo (для выполнения административных команд)
```bash
usermod -aG sudo user
```
### 2.3 Копирование SSH-ключа

Скопируйте SSH-ключ из папки root в папку нового пользователя:

```bash
cp -r ~/.ssh /home/user/
chown -R user:user /home/user/.ssh
```
### 2.4 Редактирование конфига SSH

Откройте файл конфигурации SSH:

```bash
nano /etc/ssh/sshd_config
```
Найдите строки, указанные ниже. Если строка начинается с символа # — удалите его и пробел. Приведите параметры к нужным значениям:

PermitRootLogin — установите значение no
PasswordAuthentication — установите значение no

### 2.5 Перезапуск SSH

Примените изменения:

```bash
systemctl restart sshd
```
### 2.6 Проверка подключения

Не закрывайте текущую сессию root. Откройте новое окно терминала и выполните:

```bash
ssh user@IP-адрес
```
Если подключились без пароля — всё настроено правильно. Теперь root-сессию можно закрыть.

## 3. UFW Firewall

### 3.1 Цель

Настроить firewall: разрешить только необходимые порты, заблокировать всё остальное.

### 3.2 Установка UFW

```bash
apt install ufw -y

ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 9100/tcp
```
### 3.4 Включение UFW

```bash
ufw enable
```
При запросе подтвердите действие: y

### 3.5 Проверка статуса

```bash
ufw status verbose
```
Должны увидеть Status: active и список разрешённых портов.


## 4. Установка Fail2ban

### 4.1 Цель

Защитить сервер от брутфорс-атак: автоматически блокировать IP после нескольких неудачных попыток входа.

### 4.2 Установка

```bash
apt install fail2ban -y
```

### 4.3 Настройка

Скопируйте конфигурационный файл по умолчанию:

```bash
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```
Откройте файл для редактирования:

```bash
nano /etc/fail2ban/jail.local
```
Найдите секцию [sshd] и установите параметры:

```bash
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
```
### 4.4 Запуск и автозагрузка

```bash
systemctl restart fail2ban
systemctl enable fail2ban
```
### 4.5 Проверка статуса
```bash
fail2ban-client status sshd
```
Должны увидеть: Currently failed: 0, Currently banned: 0

## 5. Установка Docker

### 5.1 Цель

Установить Docker для запуска контейнеризованных приложений.

### 5.2 Установка Docker

```bash
apt install docker.io -y
```
### 5.3 Добавление пользователя в группу docker
```bash
usermod -aG docker user
```
Важно: После этой команды выйдите из сессии и зайдите заново, чтобы права применились.
```bash
exit
ssh user@IP-адрес
```
### 5.4 Запуск тестового контейнера
```bash
docker run -d --name test-app -p 3000:80 nginx
```

### 5.5 Проверка
```bash
docker ps
```
Должны увидеть контейнер test-app в статусе Up.

## 6. Настройка Nginx reverse proxy

### 6.1 Цель

Настроить Nginx на хосте для перенаправления трафика в Docker-контейнер и обработки HTTPS.

### 6.2 Установка Nginx

```bash
apt install nginx -y
```
### 6.3 Создание конфигурационного файла

```bash
nano /etc/nginx/sites-available/reverse-proxy
```
Вставьте содержимое (замените ваш-домен на ваш реальный домен):
```bash
server {
    listen 80;
    server_name ваш-домен;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name ваш-домен;

    ssl_certificate /etc/letsencrypt/live/ваш-домен/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ваш-домен/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### 6.4 Активация конфига

```bash
ln -s /etc/nginx/sites-available/reverse-proxy /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
```
### 6.5 Проверка и перезагрузка

```bash
nginx -t
systemctl reload nginx
```
### 6.6 Проверка работы

Откройте в браузере http://ваш-домен. Должно произойти перенаправление на https://serv123.ru (пока будет с ошибкой, так как SSL ещё не настроен).

## 7. Установка SSL (Let's Encrypt)

### 7.1 Цель

Получить бесплатный SSL-сертификат для работы сайта по HTTPS.

### 7.2 Установка Certbot

```bash
apt install certbot python3-certbot-nginx -y
```
7.3 Получение сертификата
```bash

certbot --nginx -d serv123.ru
```
7.4 Ответы на вопросы
Вопрос	Что ответить
Email для уведомлений	Введите вашу почту
Согласие с условиями	Y
Делиться email с EFF	N
Перенаправлять HTTP на HTTPS	2 (выбрать Redirect)

7.5 Проверка
```bash
certbot certificates
```
Должны увидеть информацию о сертификате и дату истечения.

7.6 Проверка в браузере

Откройте https://serv123.ru. В адресной строке должен быть зелёный замок или щит.

## 8. Мониторинг (Node Exporter)

### 8.1 Цель

Установить Node Exporter для сбора метрик сервера (CPU, RAM, диск, сеть).

### 8.2 Скачивание и установка

```bash
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvf node_exporter-1.7.0.linux-amd64.tar.gz
mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
```
8.3 Создание сервиса
```bash
nano /etc/systemd/system/node_exporter.service
```
Вставьте содержимое:
```bash
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
Group=nogroup
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
```
8.4 Запуск и автозагрузка
```bash
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
```
8.5 Проверка
```bash
systemctl status node_exporter
```
Должны увидеть active (running).

8.6 Проверка метрик
```bash
curl http://localhost:9100/metrics | head
```
Должны увидеть строки, начинающиеся с node_.
8.7 Проверка в браузере

Откройте http://serv123.ru:9100/metrics. Должна открыться страница с техническими метриками.


