#!/bin/bash

sudo apt-get update

sudo apt-get install wget
sudo apt-get install libatomic1

wget https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_102.0.1245.39-1_amd64.deb

sudo dpkg -i microsoft-edge-stable_102.0.1245.39-1_amd64.deb

echo "edge安装完成......"

