#!/bin/bash

# install java / dependencies
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git build-essential cmake gcc-arm-linux-gnueabihf openjdk-19-jdk

# enable arm hard float architecture / install dependencies
sudo dpkg --add-architecture armhf && sudo apt update
sudo apt install -y libc6:armhf libncurses5:armhf libstdc++6:armhf

# clone and build Box86
git clone https://github.com/ptitSeb/box86
cd box86 && mkdir -p build && cd build
cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j$(nproc)
sudo make install
sudo systemctl restart systemd-binfmt
cd ../..

# clone and build Box64
git clone https://github.com/ptitSeb/box64.git
cd box64 && mkdir -p build && cd build
cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j$(nproc)
sudo make install
sudo systemctl restart systemd-binfmt
cd ../..

# steamcmd setup
mkdir steamcmd && cd steamcmd
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# update steamcmd
./steamcmd.sh +quit > /dev/null

# set up and download zomboid server
sudo mkdir -p /opt/zomboid-server/
sudo chown -R $USER:$USER /opt/zomboid-server/
./steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +force_install_dir /opt/zomboid-server/ +app_update 380870 validate +quit > /dev/null

# create symlinks for the files on the home of the user so that we can access it all from our server folder
read -p "Please start the server manually and set the password. Press Enter when that's done..."
find ~ -type f -mmin -60 -exec ln -s {} /opt/zomboid-server/ \;
find ~ -type d -mmin -60 -exec ln -s {} /opt/zomboid-server/ \;

# sets up zomboid as a systemd service
sudo tee /etc/systemd/system/zomboid-server.service > /dev/null <<EOL
[Unit]
Description=Servidor de Zomboid
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=/opt/zomboid-server
ExecStart=/opt/zomboid-server/start-server.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
source /usr/share/bash-completion/completions/systemctl

 # open firewall ports
sudo ufw allow 16261/udp
sudo ufw allow 16262/udp

# reload the firewall
sudo ufw reload
