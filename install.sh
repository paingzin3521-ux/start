#!/data/data/com.termux/files/usr/bin/bash
# ============================================
#  SKYBY TOOL — Termux Installer
#  Telegram: @paing_3521
# ============================================

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[1;31m'
RESET='\033[0m'

echo -e "${CYAN}"
echo "   _____   _  __ __     __   ____   __     __"
echo "  / ____| | |/ / \ \   / /  |  _ \  \ \   / /"
echo " | (___   | ' /   \ \_/ /   | |_) |  \ \_/ / "
echo "  \___ \  |  <     \   /    |  _ <    \   /  "
echo "  ____) | | . \     | |     | |_) |    | |   "
echo " |_____/  |_|\_\    |_|     |____/     |_|   "
echo -e "${RESET}"
echo -e "${YELLOW}  [ Wifi scan bypass — Termux Installer ]${RESET}"
echo -e "${GREEN}  Telegram -> @paing_3521${RESET}"
echo "  ────────────────────────────────────"
echo ""

# -- Package dependencies --
echo -e "${CYAN}[*] Installing required packages...${RESET}"
pkg update -y -q 2>/dev/null
pkg install -y python nmap net-tools iproute2 2>/dev/null

echo -e "${CYAN}[*] Installing Python dependencies...${RESET}"
pip install -q requests pycryptodome urllib3 2>/dev/null

# -- Create tool directory --
mkdir -p "$HOME/.skyby"

# -- Download main script --
echo -e "${CYAN}[*] Downloading skyby tool...${RESET}"
curl -sL "https://raw.githubusercontent.com/paingzin3521-ux/start/start/skyby.py"      -o "$HOME/.skyby/skyby.py"

if [ ! -f "$HOME/.skyby/skyby.py" ]; then
    echo -e "${RED}[-] Download failed! Check internet connection.${RESET}"
    exit 1
fi

# -- Create launcher --
cat > "$PREFIX/bin/skyby" << 'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash
exec python3 "$HOME/.skyby/skyby.py" "$@"
LAUNCHER
chmod +x "$PREFIX/bin/skyby"

echo ""
echo -e "${GREEN}  ┌─────────────────────────────────────┐${RESET}"
echo -e "${GREEN}  │   ✓  Installation Complete!          │${RESET}"
echo -e "${GREEN}  │   Run: skyby                         │${RESET}"
echo -e "${GREEN}  │   Telegram: @paing_3521              │${RESET}"
echo -e "${GREEN}  └─────────────────────────────────────┘${RESET}"
echo ""
