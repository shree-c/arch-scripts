#!/bin/bash

#setting up time
timedatectl set-ntp true

#testing internet connectivity

if ping -q -c 1 -W 1 'google.com' &> /dev/null; then
  echo "The network is up"
else
  echo "Installation requires active internet connection"
  exit -1
fi

