#!/bin/bash
set -ev

git clone https://github.com/steveicarus/iverilog.git
cd iverilog
./configure
make