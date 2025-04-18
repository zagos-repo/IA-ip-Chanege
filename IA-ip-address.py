#!/usr/bin/env python3
import os
import time
import subprocess
import requests
from stem import Signal
from stem.control import Controller
from colorama import Fore, Style, init

init(autoreset=True)

# إعداد Tor Control Port
TOR_PASSWORD = "mypassword"

# عرض بانر ملون جميل ومخيف
def show_banner():
    banner = f"""
{Fore.RED}{Style.BRIGHT}
    ██████████████████████████████████████
    █▄─▄▄▀█─▄▄─█▄─▄█─▄▄▄▄█─▄▄─█─▄▄▄─█▄─▄█
    ██─██─█─██─██─██▄▄▄▄─█─██─█─███▀██─██
    ▀▄▄▄▄▀▀▄▄▄▄▀▄▄▄▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▄▀
{Fore.YELLOW}
       ★ أداة تبديل IP و MAC عبر شبكة Tor ★
       ★ تم تطويرها لاختبار التصفح المجهول ★
{Fore.GREEN}
       > المطور: زكرياء - باحث أمن معلوماتي
       > github.com/zack-sec
{Style.RESET_ALL}
    """
    print(banner)

# تحميل الأدوات المطلوبة
def install_dependencies():
    print("[*] التأكد من وجود الحزم المطلوبة...")
    os.system("sudo apt update")
    os.system("sudo apt install -y tor macchanger net-tools")

    try:
        import stem
        import requests
        import colorama
    except ImportError:
        print("[*] تثبيت مكتبات Python...")
        os.system("pip3 install stem requests colorama")

# تغيير الهوية في Tor
def renew_tor_ip():
    try:
        with Controller.from_port(port=9051) as controller:
            controller.authenticate(password=TOR_PASSWORD)
            controller.signal(Signal.NEWNYM)
    except Exception as e:
        print(f"{Fore.RED}[-] فشل في تجديد IP عبر Tor: {e}")

# جلب IP الحالي
def get_ip():
    try:
        ip = requests.get("https://api.ipify.org", proxies={
            'http': 'socks5h://127.0.0.1:9050',
            'https': 'socks5h://127.0.0.1:9050'
        }, timeout=5).text
        return ip
    except Exception as e:
        return f"{Fore.RED}IP غير متاح: {e}"

# تغيير MAC address لتغيير البصمة
def change_mac(interface="eth0"):
    subprocess.call(["sudo", "ifconfig", interface, "down"])
    subprocess.call(["sudo", "macchanger", "-r", interface])
    subprocess.call(["sudo", "ifconfig", interface, "up"])

# تغيير اسم الجهاز وهمياً
def change_hostname():
    new_name = f"user-{os.urandom(4).hex()}"
    subprocess.call(["sudo", "hostnamectl", "set-hostname", new_name])
    print(f"{Fore.CYAN}[*] تم تعيين اسم وهمي للجهاز: {new_name}")

# التأكد من إعدادات torrc
def ensure_torrc_settings():
    torrc_path = "/etc/tor/torrc"
    try:
        with open(torrc_path, "r") as f:
            content = f.read()
        if "ControlPort 9051" not in content or "HashedControlPassword" not in content:
            print("[*] تحديث إعدادات torrc...")
            hashed_pw = generate_tor_hashed_password(TOR_PASSWORD)
            with open(torrc_path, "a") as f:
                f.write(f"\nControlPort 9051\nHashedControlPassword {hashed_pw}\n")
    except Exception as e:
        print(f"{Fore.RED}[-] خطأ في إعداد torrc: {e}")

# بدء Tor مع التحقق من الإعدادات
def start_tor():
    ensure_torrc_settings()
    os.system("sudo systemctl restart tor")

# توليد هاش كلمة مرور Tor للتحكم
def generate_tor_hashed_password(password):
    output = subprocess.check_output(["tor", "--hash-password", password])
    return output.decode().strip()

# الحلقة الرئيسية
def main():
    install_dependencies()
    show_banner()
    change_hostname()
    start_tor()
    interface = input(f"{Fore.YELLOW}[?] أدخل اسم واجهة الشبكة (مثل eth0 أو wlan0): ")

    while True:
        change_mac(interface)
        renew_tor_ip()
        print(f"{Fore.GREEN}[+] IP الحالي عبر Tor: {get_ip()}")
        time.sleep(1)

if __name__ == "__main__":
    main()