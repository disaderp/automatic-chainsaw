#!/bin/bash
set -ev

sudo apt-get -y install mono-complete

wget ftp://icarus.com/pub/eda/verilog/v10/verilog-10.1.1.tar.gz -O v.tar.gz
tar -xzf v.tar.gz
cd verilog-10.1.1
./configure
make
sudo make install
