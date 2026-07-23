#!/bin/bash

# Get the current directory
DIR=$(pwd)

# Install requirements
echo "[*] Installing requirements..."
pip install -r requirements.txt

# Create the 'star' command in Termux's bin directory
echo "[*] Setting up 'star' command..."
BIN_DIR="$PREFIX/bin"
STAR_CMD="$BIN_DIR/star"

echo "#!/bin/bash" > $STAR_CMD
echo "cd $DIR" >> $STAR_CMD
echo "python run.py" >> $STAR_CMD

chmod +x $STAR_CMD

echo "[✓] Setup complete! Now you can open the tool by typing: star"
