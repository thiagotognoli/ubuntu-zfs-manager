#!/bin/bash

pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY bash -c "\
cd /tmp \
  && rm -rf ubuntu-zfs-snapshots-manager \
  && sudo apt install -y git \
  && git clone https://github.com/thiagotognoli/ubuntu-zfs-snapshots-manager.git \
  && sudo ./ubuntu-zfs-snapshots-manager/run.sh;
  sudo rm -rf /tmp/ubuntu-zfs-snapshots-manager
"
