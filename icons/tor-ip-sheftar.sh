#!/bin/bash

# =========[ tor-ip-shifter.sh ]=========
# سكربت لتغيير الـ IP الخارجي باستخدام Tor
# الإصدار: 1.0 - المطور: زكرياء
# =======================================

# التأكد من تشغيل السكربت بصلاحيات root
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[91m[!] يجب تشغيل هذا السكربت بصلاحيات root.\e[0m"
  exit 1
fi

# عرض شعار السكربت
banner() {
cat << "EOF"
 _______              _____ _____  _____  _     _ _____ 
|__   __|     /\     |_   _|  __ \|  __ \| |   (_)  __ \
   | | ___   /  \      | | | |__) | |__) | |__  _| |__) |
   | |/ _ \ / /\ \     | | |  ___/|  ___/| '_ \| |  ___/
   | | (_) / ____ \   _| |_| |    | |    | | | | | |    
   |_|\___/_/    \_\ |_____|_|    |_|    |_| |_|_|_|    
                                                       
EOF
echo -e "\e[94m[*] سكربت تغيير عنوان IP الخارجي باستخدام Tor...\e[0m"
}

# تثبيت الأدوات المطلوبة تلقائيًا
install_dependencies() {
  REQUIRED_PKGS=(tor curl jq socat)
  echo "[*] التحقق من الأدوات المطلوبة..."
  for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
      echo "[+] تثبيت $pkg..."
      if command -v apt &>/dev/null; then
        apt update && apt install -y "$pkg"
      elif command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm "$pkg"
      elif command -v yum &>/dev/null; then
        yum install -y "$pkg"
      else
        echo "[!] نظام غير مدعوم تلقائيًا. قم بتثبيت $pkg يدويًا."
        exit 1
      fi
    fi
  done
}

# تشغيل خدمة Tor
start_tor() {
  echo "[*] تشغيل خدمة Tor..."
  if systemctl is-active tor &>/dev/null; then
    systemctl restart tor
  else
    systemctl start tor || service tor start
  fi
  sleep 5
}

# جلب عنوان IP الخارجي عبر Tor
get_ip() {
  curl --silent --socks5-hostname 127.0.0.1:9050 https://api64.ipify.org
}

# إرسال أمر تغيير الهوية لـ Tor بدون netcat
send_newnym() {
  printf 'AUTHENTICATE ""\r\nSIGNAL NEWNYM\r\nQUIT\r\n' | socat - SOCKS4A:127.0.0.1:127.0.0.1:9051,socksport=9050 &>/dev/null
}

# تغيير الـ IP بشكل دوري
change_loop() {
  while true; do
    OLD_IP=$(get_ip)
    send_newnym
    sleep 2
    NEW_IP=$(get_ip)

    if [ "$NEW_IP" != "$OLD_IP" ]; then
      echo -e "\e[92m[+] تم تغيير IP: $NEW_IP\e[0m"
    else
      echo -e "\e[91m[!] لم يتم تغيير IP. المحاولة مجددًا...\e[0m"
    fi
    sleep 1
  done
}

# تنفيذ كل شيء
banner
install_dependencies
start_tor
change_loop