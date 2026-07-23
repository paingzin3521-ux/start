#!/data/data/com.termux/files/usr/bin/bash

# Create the launcher script
BIN_PATH="/data/data/com.termux/files/usr/bin/star"

cat > $BIN_PATH << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
cd $HOME/start && python run.py
EOF

chmod +x $BIN_PATH

echo ""
echo "  ✅ Installation Complete!"
echo "  🚀 You can now run the tool by typing: star"
echo ""
