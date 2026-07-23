#!/bin/bash
pip install requests
BIN_PATH="$PREFIX/bin/star"
cat << EOF2 > "$BIN_PATH"
#!/bin/bash
cd "$(pwd)"
python run.py
EOF2
chmod +x "$BIN_PATH"
echo "[ ✓ ] Installed. Type 'star' to run."
