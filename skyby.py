import os, re, sys, time, json, uuid, socket, hashlib, base64, string, random, shutil, subprocess, urllib3, requests
from datetime import datetime
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Colors
C = "\033[1;36m"
Y = "\033[1;33m"
G = "\033[1;32m"
R = "\033[1;31m"
W = "\033[1;37m"
B = "\033[1;34m"
P = "\033[1;35m"
RESET = "\033[0m"

DEV_FILE = os.path.expanduser("~/.rj_devid")
SELECTED_MAC, SELECTED_NAME, PORTAL_URL = None, "Unknown", None

def get_device_id():
    if os.path.exists(DEV_FILE): return open(DEV_FILE).read().strip()
    dev_id = f"DEV-{hashlib.sha256(str(uuid.getnode()).encode()).hexdigest()[:12].upper()}"
    open(DEV_FILE, "w").write(dev_id); return dev_id

DEVICE_ID = get_device_id()

def get_wifi_info():
    ssid, gw = None, None
    try:
        out = subprocess.check_output(["termux-wifi-connectioninfo"], stderr=subprocess.DEVNULL).decode()
        ssid = json.loads(out).get("ssid", "").strip('"')
    except: pass
    try:
        out = subprocess.check_output("ip route show default", shell=True, stderr=subprocess.DEVNULL).decode()
        m = re.search(r'default via ([\d.]+)', out)
        if m: gw = m.group(1)
    except: pass
    return ssid, gw

def banner(expiry):
    os.system("clear")
    print(f"""{G}
  ____   _  __ __     __  ____   __     __
 / ___| | |/ / \ \   / / | __ )  \ \   / /
 \___ \ | ' /   \ \_/ /  |  _ \   \ \_/ / 
  ___) ||  <     \   /   | |_) |   \   /  
 |____/ |_|\_\    |_|    |____/     |_|   

         {Y}[ Wifi scan bypass ]
         Telegram -> @paing_3521{RESET}""")
    print(f"{Y}{'='*60}{RESET}")
    print(f"{G}[*] Device ID : {C}{DEVICE_ID}{RESET}")
    print(f"{G}[*] Expiry    : {G}{expiry}{RESET}")
    ssid, gw = get_wifi_info()
    if ssid: print(f"{G}[*] WiFi Name : {W}{ssid}{RESET}")
    if gw: print(f"{G}[*] Router IP : {W}{gw}{RESET}")
    if SELECTED_MAC: print(f"{G}[*] Target    : {Y}{SELECTED_MAC} ({SELECTED_NAME}){RESET}")
    if PORTAL_URL: print(f"{G}[*] Portal    : {C}{PORTAL_URL[:45]}...{RESET}")
    print(f"{Y}{'='*60}{RESET}")

def option_get_portal_link():
    global PORTAL_URL
    print(f"\n{Y}[*] Detecting Portal URL...{RESET}")
    try:
        r = requests.get("http://connectivitycheck.gstatic.com/generate_204", timeout=5, allow_redirects=True)
        if r.status_code != 204:
            PORTAL_URL = r.url
            print(f"{G}[ ✓ ] Found: {C}{PORTAL_URL}{RESET}")
        else: print(f"{R}[-] No Portal detected (Direct Internet).{RESET}")
    except: print(f"{R}[-] Connection Error.{RESET}")
    time.sleep(2)

def main():
    while True:
        banner("9999d 23h 59min")
        print(f"  {G}[1] WiFi Setup          {Y}[2] MAC Scan{RESET}")
        print(f"  {G}[3] Active Check        {Y}[4] Select Target{RESET}")
        print(f"  {C}[5] Get Portal Link     {Y}[6] Encode Session URL{RESET}")
        print(f"  {G}[7] Auto Bypass         {R}[8] Delete Key{RESET}")
        print(f"  {R}[0] Exit{RESET}")
        print(f"{Y}{'='*60}{RESET}")
        ch = input(f"  {C}Select Option : {RESET}").strip()
        if ch == "1": 
            print(f"\n{G}[*] WiFi Setup Complete.{RESET}"); time.sleep(1)
        elif ch == "5": option_get_portal_link()
        elif ch == "0": break

if __name__ == "__main__":
    main()
