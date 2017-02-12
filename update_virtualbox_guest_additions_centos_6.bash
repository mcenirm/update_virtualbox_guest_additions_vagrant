#!/bin/bash

set -e
set -u

iso=$1

sudo yum -y install kernel-{devel,headers}-$(uname -r) gcc perl
sudo mount -v -o loop,ro -t iso9660 "$iso" /mnt
( cd /mnt && sudo sh VBoxLinuxAdditions.run --nox11 )
sudo umount -v /mnt
