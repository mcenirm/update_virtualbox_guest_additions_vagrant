#!/bin/bash

set -e
set -u


Usage () { cat >&2 <<EOF
Usage: $0 [existing-work-folder]
EOF
}


loglevel=4
TRACE () { _log 6 TRACE "$@" ; }
DEBUG () { _log 5 DEBUG "$@" ; }
INFO  () { _log 4 INFO  "$@" ; }
WARN  () { _log 3 WARN  "$@" ; }
ERROR () { _log 2 ERROR "$@" ; }
FATAL () { _log 1 FATAL "$@" ; }
_log () {
  local level=$1
  local label=$2
  shift 2

  if [ "$loglevel" -ge "$level" ] ; then
    echo >&2 "$label": "$@"
  fi
}


if [ $# -gt 0 ] ; then
  if [ -d "$1"/.vagrant ] ; then
    work=$1
  else
    Usage
    exit 1
  fi
else
  work=$( mktemp -d )
fi


scripts=$( cd "$(dirname "$0")" && /bin/pwd )
INFO $"Using scripts folder:" "$scripts"

INFO $"Using work folder:" "$work"
cd "${work}"

if ! [ -f Vagrantfile ] ; then
  INFO $"Initializing Vagrantfile."
  ( set -x ; vagrant init -m centos/6 )
fi

INFO $"Starting virtual machine."
( set -x ; vagrant up --provider virtualbox default )
uuid=$( cat .vagrant/machines/default/virtualbox/id )
INFO $"uuid:" "$uuid"

if vagrant ssh -c '[ -d /vagrant/.vagrant ]' default ; then
  INFO $"Shared folder is working. Attempting `updateguestadditions`."
  ( set -x ; VBoxManage guestcontrol $uuid updateguestadditions )
  exit $?
fi

if ! vagrant ssh -c '[ -f /tmp/VBoxGuestAdditions.iso ]' default ; then
  iso=$( VBoxManage list dvds | sed -n -e 's#^Location:[ ]*\(.*/VBoxGuestAdditions.iso\)$#\1#p' | head -n 1 )
  INFO $"Using guest additions ISO:" "$iso"

  INFO $"Copying guest additions ISO to machine."
  ( set -x ; vagrant scp "$iso" default:/tmp/VBoxGuestAdditions.iso )
fi

( set -x ; vagrant scp "$scripts/update_virtualbox_guest_additions_centos_6.bash" default:/tmp/update_virtualbox_guest_additions_centos_6.bash )

( set -x ; vagrant ssh -c 'bash /tmp/update_virtualbox_guest_additions_centos_6.bash /tmp/VBoxGuestAdditions.iso' )
