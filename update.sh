#!/data/data/com.termux/files/usr/bin/bash
cd $HOME
rm -rf start
git clone https://github.com/paingzin3521-ux/start
cd start
bash build.sh
bash install.sh
