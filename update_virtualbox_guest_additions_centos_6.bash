#!/bin/bash

set -e
set -u

iso=$1

if ! sudo yum -y install kernel-{devel,headers}-$(uname -r) ; then
  sudo yum -y upgrade kernel
  echo ====
  echo ==== Upgraded kernel.
  echo ==== Rerun this script after reboot.
  echo ====
  sudo reboot
  exit
fi
sudo yum -y install gcc perl
sudo mount -v -o loop,ro -t iso9660 "$iso" /mnt
( cd /mnt && sudo sh VBoxLinuxAdditions.run --nox11 )
sudo umount -v /mnt
sudo reboot
