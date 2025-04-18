#!/bin/bash

TOR_PASSWORD="mypassword"

# ألوان
RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
CYAN="\e[36m"
RESET="\e[0m"

# بانر جميل ومرعب
banner() {
    clear
    echo -e "${RED}"
    echo "    ██████████████████████████████████████"
    echo "    █▄─▄▄▀█─▄▄─█▄─▄█─▄▄▄▄█─▄▄─█─▄▄▄─█▄─▄█"
    echo "    ██─██─█─██─██─██▄▄▄▄─█─██─█─███▀██─██"
    echo "    ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▀"
    echo -e "${YELLOW}"
    echo "   ★ أداة تبديل IP و MAC و hostname عبر Tor ★"
    echo -e "${GREEN}"
    echo "       > المطور: زكرياء الأمني"
    echo "       > github.com/zack-sec"
    echo -e "${RESET}"
}

# التحقق وتثبيت الحزم
install_dependencies() {
    echo -e "${CYAN}[*] التحقق من الحزم المطلوبة...${RESET}"
    for pkg in tor macchanger net-tools curl netcat; do
        if ! dpkg -s $pkg &>/dev/null; then
            echo -e "${YELLOW}[!] تثبيت $pkg...${RESET}"
            sudo apt install -y $pkg
        fi
    done
}

# تغيير MAC address
change_mac() {
    sudo ifconfig "$INTERFACE" down
    sudo macchanger -r "$INTERFACE" | grep "New MAC"
    sudo ifconfig "$INTERFACE" up
}

# تغيير hostname
change_hostname() {
    NEW_NAME="anon-$(openssl rand -hex 2)"
    sudo hostnamectl set-hostname "$NEW_NAME"
    echo -e "${CYAN}[*] تم تعيين اسم وهمي: $NEW_NAME${RESET}"
}

# إعداد Tor مع كلمة سر
setup_tor() {
    echo -e "${CYAN}[*] إعداد Tor...${RESET}"
    if ! grep -q "ControlPort 9051" /etc/tor/torrc; then
        HASHED=$(tor --hash-password "$TOR_PASSWORD" | grep -o '16:.*')
        echo -e "\nControlPort 9051\nHashedControlPassword $HASHED" | sudo tee -a /etc/tor/torrc
    fi
    sudo systemctl restart tor
    sleep 3
}

# تجديد IP عبر Tor
renew_ip() {
    echo "authenticate \"$TOR_PASSWORD\"\nsignal NEWNYM\nquit" | nc 127.0.0.1 9051 > /dev/null
}

# جلب IP الجديد
get_ip() {
    curl -s --socks5-hostname 127.0.0.1:9050 https://api.ipify.org || echo "IP غير متاح"
}

# البرنامج الرئيسي
main() {
    banner
    install_dependencies

    echo -ne "${YELLOW}[?] أدخل اسم واجهة الشبكة (eth0 أو wlan0): ${RESET}"
    read INTERFACE

    if ! ip link show "$INTERFACE" &>/dev/null; then
        echo -e "${RED}[!] الواجهة $INTERFACE غير موجودة! تحقق منها.${RESET}"
        exit 1
    fi

    change_hostname
    setup_tor

    while true; do
        change_mac
        renew_ip
        CURRENT_IP=$(get_ip)
        echo -e "${GREEN}[+] IP الجديد عبر Tor: $CURRENT_IP${RESET}"
        sleep 5
    done
}

main