#!/usr/bin/env python3
import os
import time
import subprocess
import requests
from stem import Signal
from stem.control import Controller

# إعداد Tor Control Port
TOR_PASSWORD = "mypassword"

# تحميل الأدوات المطلوبة
def install_dependencies():
    print("[*] التأكد من وجود الحزم المطلوبة...")
    os.system("sudo apt update")
    os.system("sudo apt install -y tor macchanger net-tools")

    try:
        import stem
        import requests
    except ImportError:
        print("[*] تثبيت مكتبات Python...")
        os.system("pip3 install stem requests")

# تغيير الهوية في Tor
def renew_tor_ip():
    with Controller.from_port(port=9051) as controller:
        controller.authenticate(password=TOR_PASSWORD)
        controller.signal(Signal.NEWNYM)

# جلب IP الحالي
def get_ip():
    try:
        ip = requests.get("https://api.ipify.org", proxies={'http': 'socks5h://127.0.0.1:9050','https': 'socks5h://127.0.0.1:9050'}, timeout=5).text
        return ip
    except:
        return "IP غير متاح"

# تغيير MAC address لتغيير البصمة
def change_mac(interface="eth0"):
    subprocess.call(["sudo", "ifconfig", interface, "down"])
    subprocess.call(["sudo", "macchanger", "-r", interface])
    subprocess.call(["sudo", "ifconfig", interface, "up"])

# تغيير اسم الجهاز وهمياً
def change_hostname():
    new_name = f"user-{os.urandom(4).hex()}"
    subprocess.call(["sudo", "hostnamectl", "set-hostname", new_name])
    print(f"[*] تم تعيين اسم وهمي للجهاز: {new_name}")

# بدء Tor مع التحقق من الإعدادات
def start_tor():
    # التأكد من تفعيل ControlPort و Password
    torrc_path = "/etc/tor/torrc"
    with open(torrc_path, "a") as f:
        f.write("\nControlPort 9051\nHashedControlPassword " + generate_tor_hashed_password(TOR_PASSWORD) + "\n")
    os.system("sudo systemctl restart tor")

# توليد هاش كلمة مرور Tor للتحكم
def generate_tor_hashed_password(password):
    output = subprocess.check_output(["tor", "--hash-password", password])
    return output.decode().strip()

# الحلقة الرئيسية
def main():
    install_dependencies()
    change_hostname()
    start_tor()
    interface = input("[?] أدخل اسم واجهة الشبكة (مثل eth0 أو wlan0): ")
    
    while True:
        change_mac(interface)
        renew_tor_ip()
        print("[+] IP الحالي عبر Tor:", get_ip())
        time.sleep(1)

if __name__ == "__main__":
    main()