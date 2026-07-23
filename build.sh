#!/data/data/com.termux/files/usr/bin/bash

echo ""
echo "  [*] SKYBY — Build Script"
echo "  [*] Preparing environment..."
echo ""

# --- dependencies ---
echo "  [*] Installing dependencies..."
pkg install -y python 2>/dev/null
pip install --quiet requests pycryptodome 2>/dev/null

echo ""
echo "  ✅ Done! Run: star"
echo ""
