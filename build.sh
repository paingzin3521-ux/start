#!/data/data/com.termux/files/usr/bin/bash
# ============================================
#  SKYBY — Termux Build Script
#  Run once: bash build.sh
#  Then run: python run.py
# ============================================

set -e

echo -e "\033[1;36m[*] Installing dependencies...\033[0m"
pip install requests pycryptodome cython setuptools --quiet

echo -e "\033[1;36m[*] Compiling skyby.pyx → .so ...\033[0m"
python setup.py build_ext --inplace 2>&1 | grep -v "^running\|^creating\|^copying"

# Rename built .so to skyby.so for easy identification
SO=$(ls skyby*.so 2>/dev/null | head -1)
if [ -n "$SO" ] && [ "$SO" != "skyby.so" ]; then
    cp "$SO" skyby.so
fi

echo ""
if ls skyby*.so 1>/dev/null 2>&1; then
    echo -e "\033[1;32m[ ✓ ] Build successful!\033[0m"
    echo -e "\033[1;32m[ ✓ ] Run the tool with:\033[0m  \033[1;37mpython run.py\033[0m"
else
    echo -e "\033[1;31m[-] Build failed. Check errors above.\033[0m"
    exit 1
fi
