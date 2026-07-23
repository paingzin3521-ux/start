#!/bin/bash

# Get the absolute path of the current directory
DIR=$(cd "$(dirname "$0")" && pwd)

# Install requirements
echo "[*] Installing requirements..."
pip install -r "$DIR/requirements.txt"

# Create the 'star' command in Termux's bin directory
echo "[*] Setting up 'star' command..."
BIN_DIR="$PREFIX/bin"
STAR_CMD="$BIN_DIR/star"

# Use a simpler and more direct way to create the star command
echo "#!/bin/bash" > "$STAR_CMD"
echo "cd $DIR" >> "$STAR_CMD"
echo "python run.py" >> "$STAR_CMD"

# Make it executable
chmod +x "$STAR_CMD"

echo "[✓] Setup complete! Now you can open the tool by typing: star"
