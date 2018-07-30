#!/bin/bash
set -ev

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
