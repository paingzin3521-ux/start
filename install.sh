#!/bin/bash

# Get the absolute path of the current directory where install.sh is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install requirements
echo "[*] Installing requirements..."
pip install -r "$DIR/requirements.txt"

# Create the 'star' command in Termux's bin directory
echo "[*] Setting up 'star' command..."
BIN_DIR="$PREFIX/bin"
STAR_CMD="$BIN_DIR/star"

# Create the executable script for 'star' command
cat <<EOF > "$STAR_CMD"
#!/bin/bash
cd "$DIR"
python run.py
EOF

# Make it executable
chmod +x "$STAR_CMD"

echo "[✓] Setup complete! Now you can open the tool by typing: star"
