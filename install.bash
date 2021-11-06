#!/bin/bash

#testing internet connectivity

check_internet() {
  if ping -q -c 1 -W 1 'google.com' &> /dev/null; then
    echo "The network is up"
    timedatectl set-ntp true
  else
    echo "Installation requires active internet connection"
    exit -1
  fi
}
disk_partition() {
  echo the calculations done here are approximate
  echo enter the name of disk you want to use
  read diskname
  totalsize=$(($(lsblk -b --output SIZE -n -d $diskname) / $((1024 * 1024 * 1024))))
  echo the total size of $diskname is $totalsize GB
  echo we will use 512MiB for efi partition
  echo 'enter the size of swap partition (at least 10GiB should remain for root partition)'
  read swapsize
  root=$(($totalsize - $swapsize))
  echo -e "label:gpt\n,512MiB, U, *\n, ${swapsize}GiB, S, \n, ${root}GiB, L, \n"
}
format_partitions() {
  mkfs.ext4 $root_partition
  mkfs.fat  $boot_partition
  mkswap $swap_partiton
}

mount_partition() {
  mount $root_partition /mnt
  mkdir /mnt/boot;
  mount $boot_partition /mnt/boot
  swapon $swap_partition
}

pacstrap() {
  pacstrap /mnt base linux linux-firmware  
}

fstab() {
  genfstab -U /mnt >> /mnt/etc/fstab
}

chroot() {
  arch-chroot /mnt
}

timezone() {
  TZ=''
  until timedatectl set-timezone $TZ &> /dev/null;
  do
    echo 'Enter your timezone in format Asia/Kolkata (Repeats until correct timezone is supplied): '
    read TZ
  done
}
localisation() {
  #editing locale.gen file for eng_us has to come here
  locale-gen
  echo 'LANG=en_US.UTF-8' > /etc/locale.conf
}

network_conf() {
  echo "Give a hostname(machine name) for your machine : "
  read hostname
  until [[ -n $hostname ]]; do
    echo "Enter a non empty hostname: "
    read hostname
  done
  echo $hostname > /etc/hostname;
  echo '127.0.0.1        localhost\n::1              localhost\n\127.0.1.1        myhostname' > /etc/hosts
  echo Installing dhcpcd...
  pacman -Sy dhcpcd &> /dev/null
  systemctl enable dhcpcd & /dev/null
}

rootpasswd_setup() {
  echo "Enter password for root(administer) account : "
  read pass;
  until [[ -n $pass ]]; do
    echo "Enter a non empty passwd: "
    read pass
  done
  echo "root:$pass" | chpasswd
}

bootloader_setup() {
  echo "Installing bootloader..."
  pacman -S grub efiboomgr osprober &> /dev/null
  echo "Downloaded essential packages..."
  echo "Running commands..."
  grub-install --target=x86_64-efi --efi-directory=$bootdir --bootloader-id=GRUB &> /dev/null
  echo "Creating config file..."
  grub-mkconfig -o /boot/grub/grub.cfg &> /dev/null
}
#check_internet
#timezone
disk_partition
