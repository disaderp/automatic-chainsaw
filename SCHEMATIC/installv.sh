#!/bin/bash
set -ev

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
sudo apt install apt-transport-https
echo "deb https://download.mono-project.com/repo/ubuntu stable-trusty main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
sudo apt update
sudo apt-get -y install mono-complete
sudo apt-get -y install mono-runtime
sudo apt-get -y install libmono-system-core4.0-cil
sudo apt-get -y install libmono-corlib4.5-cil
sudo apt-get -y install mono-basic
sudo apt-get -y install libmono-microsoft-visualbasic10.0-cil

wget ftp://icarus.com/pub/eda/verilog/v10/verilog-10.1.1.tar.gz -O v.tar.gz
tar -xzf v.tar.gz
cd verilog-10.1.1
./configure
make
sudo make install
