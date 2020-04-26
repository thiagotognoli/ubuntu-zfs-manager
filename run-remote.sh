#!/bin/bash

pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY bash -c "\
  sudo rm -rf /tmp/ubuntu-zfs-snapshots-manager \
  && sudo apt install -y git \
  && git clone https://github.com/thiagotognoli/ubuntu-zfs-snapshots-manager.git /tmp/ubuntu-zfs-snapshots-manager \
  && sudo bash /tmp/ubuntu-zfs-snapshots-manager/run.sh;
  sudo rm -rf /tmp/ubuntu-zfs-snapshots-manager
"
