import os, re, sys, time, json, uuid, socket, hashlib, base64, string, random, shutil, subprocess, urllib3, requests
from datetime import datetime
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

CYAN, YELLOW, GREEN, RED, RESET, DG, CYAN_B = "\033[1;36m", "\033[1;33m", "\033[1;32m", "\033[1;31m", "\033[0m", "\033[0;32m", "\033[1;36m"
DEV_FILE, KEY_FILE, SESSION_FILE = os.path.expanduser("~/.rj_devid"), os.path.expanduser("~/.rj_key"), os.path.expanduser("~/.rj_session")
ADB_IP_FILE, ADB_GW_FILE, WIFI_SSID_FILE = os.path.expanduser("~/.rj_adb_ip"), os.path.expanduser("~/.rj_adb_gw"), os.path.expanduser("~/.rj_wifi_ssid")

SELECTED_MAC, SELECTED_NAME, PORTAL_URL, GATEWAY_IP = None, "Unknown", None, None

def get_device_id():
    if os.path.exists(DEV_FILE): return open(DEV_FILE).read().strip()
    dev_id = f"DEV-{hashlib.sha256(str(uuid.getnode()).encode()).hexdigest()[:12].upper()}"
    open(DEV_FILE, "w").write(dev_id); return dev_id

DEVICE_ID = get_device_id()

def get_wifi_ssid():
    try:
        out = subprocess.check_output(["termux-wifi-connectioninfo"], stderr=subprocess.DEVNULL).decode()
        return json.loads(out).get("ssid", "").strip('"')
    except: return None

def get_gateway_ip():
    try:
        out = subprocess.check_output("ip route", shell=True).decode()
        m = re.search(r'default via ([\d.]+)', out)
        return m.group(1) if m else None
    except: return None

def print_header(expiry):
    os.system("clear")
    print(f"\n{GREEN}   _____   _  __ __     __   ____   __     __")
    print(f"  / ____| | |/ / \ \   / /  |  _ \  \ \   / /")
    print(f" | (___   | ' /   \ \_/ /   | |_) |  \ \_/ / ")
    print(f"  \___ \  |  <     \   /    |  _ <    \   /  ")
    print(f"  ____) | | . \     | |     | |_) |    | |   ")
    print(f" |_____/  |_|\_\    |_|     |____/     |_|   {RESET}")
    print(f"\n{YELLOW}         [ Wifi scan bypass ] - @paing_3521{RESET}")
    print(f"{YELLOW}{'-'*60}{RESET}")
    print(f"{DG}[*] Device ID : {CYAN}{DEVICE_ID}{RESET}")
    print(f"{DG}[*] Expiry    : {GREEN}{expiry}{RESET}")
    ssid, gw = get_wifi_ssid(), get_gateway_ip()
    if ssid: print(f"{DG}[*] WiFi Name : {GREEN}{ssid}{RESET}")
    if gw: print(f"{DG}[*] Router IP : {GREEN}{gw}{RESET}")
    if SELECTED_MAC: print(f"{DG}[*] Target    : {YELLOW}{SELECTED_MAC} ({SELECTED_NAME}){RESET}")
    if PORTAL_URL: print(f"{DG}[*] Portal    : {CYAN}{PORTAL_URL[:50]}...{RESET}")
    print(f"{YELLOW}{'-'*60}{RESET}")

def option_get_portal_link():
    global PORTAL_URL
    print(f"\n{YELLOW}[*] Detecting Portal URL...{RESET}")
    try:
        r = requests.get("http://connectivitycheck.gstatic.com/generate_204", timeout=5, allow_redirects=True)
        if "wifidog" in r.url or "portal" in r.url:
            PORTAL_URL = r.url
            print(f"{GREEN}[ ✓ ] Found: {CYAN}{PORTAL_URL}{RESET}")
        else: print(f"{RED}[-] Not found.{RESET}")
    except: print(f"{RED}[-] Error detecting.{RESET}")
    time.sleep(2)

def main():
    while True:
        print_header("9999d")
        print(f"  {GREEN}[1] WiFi Setup{RESET}")
        print(f"  {YELLOW}[2] MAC Scan{RESET}")
        print(f"  {GREEN}[3] Active Check{RESET}")
        print(f"  {YELLOW}[4] Select Target{RESET}")
        print(f"  {CYAN}[5] Get Portal Link{RESET}")
        print(f"  {YELLOW}[6] Encode Session URL{RESET}")
        print(f"  {GREEN}[7] Auto Bypass{RESET}")
        print(f"  {RED}[0] Exit{RESET}")
        print(f"{YELLOW}{'-'*60}{RESET}")
        ch = input(f"  {CYAN}Select Option : {RESET}").strip()
        if ch == "1": 
            print(f"\n{GREEN}[*] WiFi Setup Complete.{RESET}"); time.sleep(1)
        elif ch == "5": option_get_portal_link()
        elif ch == "0": break

if __name__ == "__main__": main()
