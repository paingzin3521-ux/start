#!/bin/bash

echo "[*] Installing dependencies..."
pip install requests pycryptodome

echo "[*] Setting up 'star' command..."
BIN_PATH="$PREFIX/bin/star"
REPO_PATH=$(pwd)

cat << EOF2 > "$BIN_PATH"
#!/bin/bash
cd "$REPO_PATH"
python run.py
EOF2

chmod +x "$BIN_PATH"

echo "[ ✓ ] Installation complete!"
echo "[ * ] You can now run the tool by typing 'star' from anywhere."
