#!/bin/bash

# =========================
# 🟩 تابع نمایش منوی CLI
# =========================
show_menu() {
  clear
  echo "=============================="
  echo "       منوی پشتیبان‌گیری"
  echo "=============================="
  echo "1) اجرای بکاپ"
  echo "2) dry-run"
  echo "3) زمان‌بندی با cron"
  echo "4) خروج"
  echo -n "انتخاب: "
}

# =========================
# 🟦 تابع اجرای عملیات بکاپ
# =========================
run_backup() {
  echo "📁 مسیر پوشه‌ای که باید بکاپ‌گیری شود:"
  read source_dir
  echo "📄 فرمت فایل‌ها (مثلاً txt یا sh یا pdf):"
  read extension
  echo "📂 مسیر ذخیره‌سازی فایل‌های بکاپ:"
  read backup_dir

  # ساخت پوشه‌ی بکاپ در صورت نبود
  mkdir -p "$backup_dir"

  # تاریخ و زمان برای نام‌گذاری فایل‌ها
  timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  backup_name="backup_$timestamp"
  temp_dir="/tmp/$backup_name"
  mkdir -p "$temp_dir"

  # فایل گزارش
  log_file="backup.log"
  conf_file="backup.conf"
  echo "" > "$conf_file"
  echo "" > "$log_file"

  echo "🕒 شروع بکاپ‌گیری: $timestamp" | tee -a "$log_file"
  start_time=$(date +%s)

  # جستجوی فایل‌ها و کپی به پوشه‌ی موقت
  find "$source_dir" -type f -name "*.$extension" | while read file; do
    echo "$file" >> "$conf_file"
    cp --parents "$file" "$temp_dir"
  done

  # فشرده‌سازی
  tar -czf "$backup_dir/$backup_name.tar.gz" -C "/tmp" "$backup_name"

  # محاسبه زمان و حجم
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  size=$(du -sh "$backup_dir/$backup_name.tar.gz" | cut -f1)

  echo "✅ بکاپ با موفقیت انجام شد." | tee -a "$log_file"
  echo "🗂️ حجم فایل: $size" | tee -a "$log_file"
  echo "⏱️ مدت زمان: ${duration} ثانیه" | tee -a "$log_file"

  # حذف بکاپ‌های قدیمی‌تر از 7 روز
  echo "🧹 حذف بکاپ‌های قدیمی‌تر از 7 روز..." | tee -a "$log_file"
  find "$backup_dir" -type f -name "*.tar.gz" -mtime +7 -exec rm -v {} \; | tee -a "$log_file"

  # پاک کردن پوشه موقت
  rm -rf "$temp_dir"

  echo "📁 فایل‌های بکاپ ذخیره شدند در: $backup_dir/$backup_name.tar.gz"
  echo "📄 لیست فایل‌ها: $(realpath $conf_file)"
  echo "📝 گزارش: $(realpath $log_file)"
}

# =========================
# 🟨 تابع dry-run (فقط نمایش فایل‌هایی که بکاپ می‌شن)
# =========================
dry_run() {
  echo "📁 مسیر پوشه:"
  read source_dir
  echo "📄 فرمت فایل:"
  read extension

  echo "📋 فایل‌هایی که انتخاب می‌شن:"
  find "$source_dir" -type f -name "*.$extension"
}

# =========================
# 🟪 تابع زمان‌بندی با cron
# =========================
schedule_cron() {
  script_path=$(realpath "$0")
  (crontab -l 2>/dev/null; echo "0 3 * * * $script_path >> cron.log 2>&1") | crontab -
  echo "✅ اسکریپت هر روز ساعت ۳ صبح اجرا خواهد شد."
}

# =========================
# 🔁 منوی اصلی
# =========================
while true; do
  show_menu
  read choice
  case $choice in
    1) run_backup ;;
    2) dry_run ;;
    3) schedule_cron ;;
    4) echo "👋 خداحافظ!"; exit ;;
    *) echo "❌ گزینه نامعتبر!" ;;
  esac

  echo -e "\nادامه بده؟ (Enter بزن)"
  read
done


