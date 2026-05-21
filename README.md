# Linux Production Server Setup

Production-сервер на Ubuntu VPS с Nginx, Docker, SSL, автоматическим бэкапом и мониторингом.

## Технологии

- Ubuntu 22.04 LTS
- Nginx (reverse proxy)
- Docker + Nginx container
- SSL (Let's Encrypt)
- UFW (firewall)
- Fail2ban
- Node Exporter (мониторинг)
- Bash + cron (бэкап)

## Быстрая проверка

| Что проверяем                | Адрес / команда                  |
|------------------------------|----------------------------------|
| Сайт по HTTPS                | `https://serv123.ru`             |
| Перенаправление HTTP → HTTPS | `http://serv123.ru`              |
| Метрики Node Exporter        | `http://serv123.ru:9100/metrics` |

### Статус сервера

```bash
sudo ufw status verbose
sudo fail2ban-client status sshd
docker ps
sudo systemctl status node_exporter
ls -la /home/user/backups/

## Структура репозитория
linux-production-server-setup/
├── README.md
├── ARCHITECTURE.md
├── SETUP.md
├── TROUBLESHOOTING.md
├── configs/
│ ├── nginx/
│ │ └── reverse-proxy.conf
│ ├── fail2ban/
│ │ └── jail.local
│ └── ssh/
│ └── sshd_config
├── scripts/
│ └── backup.sh
└── screenshots/
├── serv123.ru.png
├── ufw-status.png
├── fail2ban-status.png
├── docker-ps.png
├── backup-check.png
└── node-exporter.png

## Основные настройки

### SSH

- Root login: запрещён
- Парольная аутентификация: отключена
- Доступ: только по SSH-ключам

### Firewall (UFW)

Разрешённые порты: 22 (SSH), 80 (HTTP), 443 (HTTPS), 9100 (Node Exporter)

### Fail2ban

- Следит за `/var/log/auth.log`
- После 3 неудачных попыток → блокировка на 1 час

### Автоматический бэкап

- Скрипт: `/home/user/backup.sh`
- Расписание: ежедневно в 3:00 (cron)
- Хранилище: `/home/user/backups/`
- Очистка: удаляет бэкапы старше 7 дней

### Мониторинг

- Node Exporter на порту 9100
- Метрики: CPU, RAM, диск, сеть

## Скриншоты

| Скриншот | Что показывает |
|----------|----------------|
| [serv123.ru.png](./screenshots/serv123.ru.png) | Сайт по HTTPS, сертификат валиден |
| [ufw-status.png](./screenshots/ufw-status.png) | Статус UFW (firewall) |
| [fail2ban-status.png](./screenshots/fail2ban-status.png) | Статус Fail2ban (защита SSH) |
| [docker-ps.png](./screenshots/docker-ps.png) | Запущенные контейнеры |
| [backup-check.png](./screenshots/backup-check.png) | Созданные бэкапы |
| [node-exporter.png](./screenshots/node-exporter.png) | Метрики Node Exporter |
