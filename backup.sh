#!/bin/bash

LOG_FILE="backup.log"
CONF_FILE="backup.conf"
RETENTION_DAYS=7
EMAIL="you@example.com"

function run_backup() {
  read -p "📁 مسیر جستجوی فایل‌ها: " SEARCH_PATH
  read -p "📄 فرمت فایل‌ها (مثلاً txt): " FILE_EXT
  read -p "📦 مسیر ذخیره بکاپ‌ها: " BACKUP_DIR

  mkdir -p "$BACKUP_DIR"

  DATE=$(date +%Y-%m-%d_%H-%M-%S)
  DEST_FILE="$BACKUP_DIR/backup_$DATE.tar.gz"

  echo "📋 در حال جستجو در $SEARCH_PATH برای فایل‌های *.$FILE_EXT ..."
  find "$SEARCH_PATH" -type f -name "*.$FILE_EXT" > "$CONF_FILE"

  if [ ! -s "$CONF_FILE" ]; then
    echo "❌ هیچ فایلی با فرمت .$FILE_EXT پیدا نشد"
    echo "[$(date)] خطا: هیچ فایل بکاپی پیدا نشد" >> "$LOG_FILE"
    echo "Backup FAILED" | mail -s "❌ Backup FAILED" "$EMAIL"
    return
  fi

  START=$(date +%s)
  tar -czf "$DEST_FILE" -T "$CONF_FILE"
  STATUS=$?
  END=$(date +%s)
  DURATION=$((END - START))
  SIZE=$(du -h "$DEST_FILE" | cut -f1)

  if [ $STATUS -eq 0 ]; then
    echo "✅ بکاپ ساخته شد: $DEST_FILE ($SIZE در ${DURATION}s)"
    echo "[$(date)] موفق: $DEST_FILE ($SIZE - ${DURATION}s)" >> "$LOG_FILE"
    echo "Backup OK: $DEST_FILE" | mail -s "✅ Backup Success" "$EMAIL"
  else
    echo "❌ خطا در بکاپ‌گیری"
    echo "[$(date)] خطا: بکاپ ناموفق" >> "$LOG_FILE"
    echo "Backup FAILED" | mail -s "❌ Backup FAILED" "$EMAIL"
  fi

  echo "🧹 حذف بکاپ‌های قدیمی‌تر از $RETENTION_DAYS روز..."
  find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +$RETENTION_DAYS -exec rm {} \;
}

function dry_run() {
  read -p "📁 مسیر جستجو: " SEARCH_PATH
  read -p "📄 فرمت فایل‌ها: " FILE_EXT
  echo "📝 فایل‌های پیدا شده:"
  find "$SEARCH_PATH" -type f -name "*.$FILE_EXT"
}

function schedule_cron() {
  SCRIPT_PATH=$(realpath "$0")
  echo "0 3 * * * $SCRIPT_PATH >> ~/cron.log 2>&1" | crontab -
  echo "⏰ زمان‌بندی انجام شد (روزانه ساعت ۳ صبح)"
}

function main_menu() {
  while true; do
    echo "=============================="
    echo "       منوی پشتیبان‌گیری"
    echo "=============================="
    echo "1) اجرای بکاپ"
    echo "2) dry-run"
    echo "3) زمان‌بندی با cron"
    echo "4) خروج"
    read -p "انتخاب: " CHOICE

    case $CHOICE in
      1) run_backup ;;
      2) dry_run ;;
      3) schedule_cron ;;
      4) echo "خروج..."; break ;;
      *) echo "❌ گزینه نامعتبر" ;;
    esac
    echo
  done
}

main_menu
