#!/bin/bash

wget https://cndl.synology.cn/download/Utility/ActiveBackupBusinessAgent/2.4.1-2321/Linux/x86_64/Synology%20Active%20Backup%20for%20Business%20Agent-2.4.1-2321-x64-rpm.zip

unzip Synology\ Active\ Backup\ for\ Business\ Agent-2.4.1-2321-x64-rpm.zip

./install.run

abb-cli -c

