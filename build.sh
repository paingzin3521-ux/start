#!/data/data/com.termux/files/usr/bin/bash

echo ""
echo "  [*] SKYBY — Build Script"
echo "  [*] Cython compile + source protect"
echo ""

# --- dependencies ---
echo "  [*] Installing build deps..."
pkg install -y python clang libffi 2>/dev/null
pip install --quiet cython setuptools

# --- setup.py ---
cat > /tmp/_skyby_setup.py << 'SETUP'
from setuptools import setup
from Cython.Build import cythonize
setup(ext_modules=cythonize("skyby.pyx", compiler_directives={"language_level": "3"}))
SETUP

# --- compile ---
echo "  [*] Compiling skyby.pyx → .so ..."
python /tmp/_skyby_setup.py build_ext --inplace --quiet 2>&1 | tail -5

# --- rename .so ---
SO=$(ls skyby.cpython-*.so 2>/dev/null | head -1)
if [ -z "$SO" ]; then
    echo "  [!] Compile failed. Check errors above."
    exit 1
fi

mv "$SO" skyby.so
echo "  [✓] skyby.so created"

# --- remove source ---
rm -f skyby.pyx
rm -f /tmp/_skyby_setup.py
rm -rf build/ *.egg-info/
echo "  [✓] Source removed"

echo ""
echo "  ✅ Done! Run: star"
echo ""
