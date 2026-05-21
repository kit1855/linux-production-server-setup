#!/bin/bash

BACKUP_DIR="/home/user/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

tar -czf "$BACKUP_DIR/$BACKUP_NAME" \
    /etc/nginx \
    /etc/fail2ban \
    /home/user \
    /var/lib/docker/containers \
    2>/dev/null

find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_NAME"
