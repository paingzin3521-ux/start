#!/data/data/com.termux/files/usr/bin/bash
# ============================================
#  SKYBY TOOL — Termux Installer
#  Telegram: @paing_3521
# ============================================

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[1;31m'
WHITE='\033[1;37m'
RESET='\033[0m'

clear
echo ""
echo -e "${CYAN}   _____   _  __ __     __   ____   __     __${RESET}"
echo -e "${CYAN}  / ____| | |/ / \ \   / /  |  _ \  \ \   / /${RESET}"
echo -e "${CYAN} | (___   | ' /   \ \_/ /   | |_) |  \ \_/ / ${RESET}"
echo -e "${CYAN}  \___ \  |  <     \   /    |  _ <    \   /  ${RESET}"
echo -e "${CYAN}  ____) | | . \     | |     | |_) |    | |   ${RESET}"
echo -e "${CYAN} |_____/  |_|\_\    |_|     |____/     |_|   ${RESET}"
echo ""
echo -e "${YELLOW}  ════════════════════════════════════════${RESET}"
echo -e "${YELLOW}       Wifi Scan Bypass — Installer        ${RESET}"
echo -e "${YELLOW}  ════════════════════════════════════════${RESET}"
echo -e "${GREEN}         Telegram -> @paing_3521           ${RESET}"
echo ""

# ── Step 1: Storage permission ─────────────────────────────
echo -e "${CYAN}[1/5] Checking Termux storage...${RESET}"
if [ ! -d "$HOME/storage" ]; then
    termux-setup-storage 2>/dev/null || true
fi
echo -e "${GREEN}  ✓ Done${RESET}"

# ── Step 2: Update packages ────────────────────────────────
echo -e "${CYAN}[2/5] Updating package list...${RESET}"
pkg update -y -q 2>/dev/null
echo -e "${GREEN}  ✓ Done${RESET}"

# ── Step 3: Install required packages ─────────────────────
echo -e "${CYAN}[3/5] Installing packages (python, curl, nmap)...${RESET}"
pkg install -y python curl nmap net-tools iproute2 2>/dev/null
echo -e "${GREEN}  ✓ Done${RESET}"

# ── Step 4: Install Python dependencies ───────────────────
echo -e "${CYAN}[4/5] Installing Python libraries...${RESET}"
pip install -q --upgrade pip 2>/dev/null
pip install -q requests pycryptodome urllib3 2>/dev/null
echo -e "${GREEN}  ✓ Done${RESET}"

# ── Step 5: Download & install tool ───────────────────────
echo -e "${CYAN}[5/5] Installing SKYBY Tool...${RESET}"
mkdir -p "$HOME/.skyby"

curl -sL "https://raw.githubusercontent.com/paingzin3521-ux/start/start/skyby.py" \
     -o "$HOME/.skyby/skyby.py"

if [ ! -s "$HOME/.skyby/skyby.py" ]; then
    echo -e "${RED}  ✗ Download failed! Check internet connection.${RESET}"
    exit 1
fi

# Create launcher command
cat > "$PREFIX/bin/skyby" << 'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash
exec python3 "$HOME/.skyby/skyby.py" "$@"
LAUNCHER
chmod +x "$PREFIX/bin/skyby"

echo -e "${GREEN}  ✓ Done${RESET}"
echo ""
echo -e "${GREEN}  ╔══════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}  ║                                          ║${RESET}"
echo -e "${GREEN}  ║    ✓  Installation Complete!             ║${RESET}"
echo -e "${GREEN}  ║                                          ║${RESET}"
echo -e "${GREEN}  ║    Run command:  ${WHITE}skyby${GREEN}                   ║${RESET}"
echo -e "${GREEN}  ║    Telegram  :  ${WHITE}@paing_3521${GREEN}              ║${RESET}"
echo -e "${GREEN}  ║                                          ║${RESET}"
echo -e "${GREEN}  ╚══════════════════════════════════════════╝${RESET}"
echo ""
