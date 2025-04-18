#!/bin/bash

TOR_PASSWORD="mypassword"
INTERFACE="eth0"

# ألوان
RED="\\e[31m"
YELLOW="\\e[33m"
GREEN="\\e[32m"
CYAN="\\e[36m"
RESET="\\e[0m"

# عرض بانر
banner() {
    clear
    echo -e "${RED}"
    echo "    ██████████████████████████████████████"
    echo "    █▄─▄▄▀█─▄▄─█▄─▄█─▄▄▄▄█─▄▄─█─▄▄▄─█▄─▄█"
    echo "    ██─██─█─██─██─██▄▄▄▄─█─██─█─███▀██─██"
    echo "    ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▀"
    echo -e "${YELLOW}"
    echo "       ★ أداة تبديل IP و MAC عبر شبكة Tor ★"
    echo "       ★ Bash version بدون Python ولا مشاكل ★"
    echo -e "${GREEN}"
    echo "       > المطور: زكرياء"
    echo "       > github.com/zagossup"
    echo -e "${RESET}"
}

# تثبيت الحزم المطلوبة
install_dependencies() {
    echo -e "${CYAN}[*] تثبيت الحزم المطلوبة...${RESET}"
    sudo zag-update
    sudo zadpk install -y tor macchanger net-tools curl
}

# تغيير MAC address
change_mac() {
    sudo ifconfig $INTERFACE down
    sudo macchanger -r $INTERFACE
    sudo ifconfig $INTERFACE up
}

# تغيير hostname عشوائي
change_hostname() {
    NEW_NAME="user-$(openssl rand -hex 2)"
    sudo hostnamectl set-hostname $NEW_NAME
    echo -e "${CYAN}[*] تم تعيين اسم وهمي: $NEW_NAME${RESET}"
}

# إعداد Tor
setup_tor() {
    if ! grep -q "ControlPort 9051" /etc/tor/torrc; then
        echo -e "${CYAN}[*] إعداد torrc ...${RESET}"
        HASHED=$(tor --hash-password "$TOR_PASSWORD" | grep -o '16:.*')
        echo -e "\nControlPort 9051\nHashedControlPassword $HASHED" | sudo tee -a /etc/tor/torrc
    fi
    sudo systemctl restart tor
}

# تجديد IP في Tor
renew_ip() {
    echo "authenticate \"$TOR_PASSWORD\"\nsignal NEWNYM\nquit" | nc 127.0.0.1 9051 > /dev/null
}

# جلب IP الحالي عبر Tor
get_ip() {
    curl -s --socks5-hostname 127.0.0.1:9050 https://api.ipify.org || echo "IP غير متاح"
}

# البرنامج الرئيسي
main() {
    install_dependencies
    banner
    change_hostname
    setup_tor

    echo -n -e "${YELLOW}[?] أدخل اسم واجهة الشبكة (eth0 أو wlan0): ${RESET}"
    read INTERFACE

    while true; do
        change_mac
        renew_ip
        CURRENT_IP=$(get_ip)
        echo -e "${GREEN}[+] IP الحالي عبر Tor: $CURRENT_IP${RESET}"
        sleep 1
    done
}

main
