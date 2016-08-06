---
title: Install Linux on a MacBook Air
teaser: >
  A start-to-finish guide to installing Linux on your Apple hardware.
robots: https://robots.thoughtbot.com/install-linux-on-a-macbook-air
---

I've been feeling the pull of desktop Linux for a while now.
The last time I tried to use Linux as my daily desktop
was almost 10 years ago.
It was a pretty big failure.

But after so many years of using,
and falling in love with,
Linux on the server,
I wanted to give it another chance.

So last week I hunkered down and,
over the course of a few days,
managed to build a functional
Linux environment on my laptop.
I took rigorous notes
as I struggled and encountered breakthroughs,
the results of which you'll find below.

The steps in this guide will take you from
a single-boot OS X install on a Macbook Air
to a dual-boot system with OS X and NixOS.
Many of the steps apply to installing
another Linux distribution, too,
in particular those dealing with
disk encryption (in OS X and Linux)
and the requirement for Broadcom drivers.

Other than that,
make sure you have any important bits saved somewhere safe,
and enjoy the path to Linux below!

## Table of Contents

  - [What is NixOS?](#what-is-nixos)
  - [Download minimal 64-bit NixOS livecd](#download-minimal-64-bit-nixos-livecd)
  - [(Optional) Disable OS X disk encryption](#optional-disable-os-x-disk-encryption)
  - [(Optional) Prepare Broadcom driver](#optional-prepare-broadcom-driver)
  - [Prepare livecd](#prepare-livecd)
  - [Prepare partition](#prepare-partition)
  - [Boot into livecd](#boot-into-livecd)
  - [(Optional) Install Broadcom driver](#optional-install-broadcom-driver)
  - [Create disk partitions](#create-disk-partitions)
  - [Configure disk encryption](#configure-disk-encryption)
  - [Format partitions](#format-partitions)
  - [Connect to wireless network](#connect-to-wireless-network)
  - [Configure and install system](#configure-and-install-system)
  - [OS X final steps](#os-x-final-steps)
  - [Where to go from here](#where-to-go-from-here)
  - [References and credits](#references-and-credits)

---

## What is NixOS?

There are many, many Linux distributions:
distrowatch.com tracks 278 at the moment.
Of those 278,
you've probably heard of some of the major ones:
Mint, Ubuntu, Arch, etc.
[NixOS][nixos] is not one of the major ones.

  [nixos]: http://nixos.org/

So why did I choose it?

I've experimented previously with
using the [Nix][nix] package manager,
on which NixOS is built,
and found it very interesting and powerful.

  [nix]: http://nixos.org/nix

I really like the idea
of having a handful of declarative
configuration files
from which my entire system can be built.
It means I can store it in git
and track the history of my configuration,
just like with my dotfiles.
It also means I can quickly
get up to speed on a new machine.

The ability to easily apply--
and later rollback--
configurations was also appealing,
since I knew it would take a lot of experimentation
to get the system working like I wanted.

I'd encourage you to read more about
[NixOS][about-nixos] and [Nix][about-nix],
especially if you intend to follow the guide below!

  [about-nixos]: http://nixos.org/nixos/about.html
  [about-nix]: http://nixos.org/nixos/about.html

## Download minimal 64-bit NixOS livecd

The steps below were performed
with the minimal installation CD
for NixOS version 14.12
found on the [NixOS Download page][nixos-download].

  [nixos-download]: http://nixos.org/nixos/download.html

## (Optional) Disable OS X disk encryption

If you're not using FileVault for full-disk encryption,
you can safely skip this step.

If you use FileVault to encrypt your disk,
you will not be able to use Disk Utility
to update your disk's partitions,
which will need to be done
in a later step.

Open FileVault and disable disk encryption,
following the on-screen instructions.
After rebooting,
re-open FileVault and wait
for the disk to be fully decrypted before continuing.
This will probably take a while—
for me, about 30 minutes.

## (Optional) Prepare Broadcom driver

Depending on your particular hardware configuration,
it may be necessary to use Broadcom's unfree drivers.
You'll need to follow the instructions below
for any Apple laptop from the last few years.

The steps that follow are almost certainly
not the quickest or easiest way
to prepare the Broadcom driver for installation.
But I had already written most of the steps
for a future blog post,
so it was something I understood how to do.

Attach your USB device,
and configure two partitions in Disk Utility:
`NIXOS_ISO` (600 MB), and `DATA` (the rest).
Each should be formatted as "MS-DOS (FAT)".

Eject the drive,
but keep it plugged in.

Now in the terminal,
we're going to create a VirtualBox VM running the NixOS livecd.
If you're more comfortable with the VirtualBox GUI,
you can do all of the following steps there instead.

You should be able to copy and paste the script below,
remembering to set `nixos_livecd`
to the path of the downloaded iso.

```shell
nixos_livecd=path/to/downloaded/iso

# create vm
VBoxManage createvm \
  --name nixos-livecd \
  --ostype Linux_64 \
  --register

# create a virtual disk
VBoxManage createhd \
  --filename "$HOME/VirtualBox VMs/nixos-livecd/nixos-livecd.vdi" \
  --size 8192

# create virtual disk/cd controller
VBoxManage storagectl nixos-livecd \
  --name IDE \
  --add ide \
  --controller PIIX4 \
  --portcount 2 \
  --hostiocache on \
  --bootable on

# attach disk image to VM
VBoxManage storageattach nixos-livecd \
  --storagectl IDE \
  --type hdd \
  --port 0 \
  --device 0 \
  --medium "$HOME/VirtualBox VMs/nixos-livecd/nixos-livecd.vdi"

# attach livecd
VBoxManage storageattach nixos-livecd \
  --storagectl IDE \
  --type dvddrive \
  --port 1 \
  --device 0 \
  --medium $nixos_livecd

# bump up memory and CPU
VBoxManage modifyvm nixos-livecd --memory 1024 --cpus 2

# enable usb port
VBoxManage modifyvm nixos-livecd --usb on

# start VM
VBoxManage startvm nixos-livecd --type gui
```

You should now be at a login prompt in a VM window,
which you can login to with root and no password.

From the menu bar,
select "Devices" and then
the name of your USB device to attach it.

Now in the VM window,
mount the device:

```shell
mount /dev/disk/by-label/DATA /mnt
```

Now we'll install the driver:

```shell
NIXPKGS_ALLOW_UNFREE=1 nix-env -iA nixos.pkgs.linuxPackages.broadcom_sta
```

Then we will export the driver and all of its dependencies

```shell
# find the installed driver in the nix store
driver=`find /nix/store -maxdepth 1 -name "*broadcom*" ! -name "*.drv"`
# query the driver's dependencies
driver_deps=`nix-store --query --requisites $driver`
# export driver and dependencies to USB drive
nix-store --export $driver_deps > /mnt/broadcom.closure
```

Finally,
unmount the USB drive and shutdown the VM:

```shell
# may take a while
umount /mnt
shutdown now
```

## Prepare livecd

Open "Disk Utility"
and change the USB partition name to `NIXOS_ISO`.

Mount the downloaded livecd,
and then copy its contents onto the USB device.

```shell
cp -R /Volumes/NIXOS_ISO\ 1/* /Volumes/NIXOS_ISO
```

Eject the ISO and the USB device.

## Prepare partition

Open Disk Utility,
click on "Macintosh HD",
add new partition,
choose size (e.g., half),
choose format as free space,
apply.

## Boot into livecd

Now reboot the machine,
with the USB device inserted,
and hold down the Option key.

You should be presented with three choices:
"Machintosh HD", "Recovery", and "EFI Boot".
Select EFI Boot.

## (Optional) Install Broadcom driver

Skip this if you didn't follow
the steps in "Prepare Broadcom driver".

First,
mount the USB device's `DATA` partition
and import the Broadcom driver and dependencies.

```shell
mount /dev/disk/by-label/DATA /mnt
nix-store --import < /mnt/broadcom.closure
umount /mnt
```

Now install the driver:

```shell
NIXPKGS_ALLOW_UNFREE=1 nix-env -iA nixos.pkgs.linuxPackages.broadcom_sta
```

Finally, load the driver:

```shell
modprobe b43
insmod $(find .nix-profile/lib/ -name wl.ko)
```

## Create disk partitions

We will be creating two new partitions
in the free space we made in the previous step.
The first will be 512MB,
and be used as our Linux boot partition.
The second will use the remaining free space
and be used for our Linux swap and root partitions.

```
$ gdisk /dev/sda
n       # new partition
<enter> # default partition #
<enter> # default start location
+512M   # size 512MB
ef00    # type boot

n       # new partition
<enter> # default partition #
<enter> # default start location
<enter> # size remaining space
<enter> # type default

w       # write partitions
y       # confirm
```

Make note of the partition numbers
assigned to the partitions.
You can always find them again
by running `fdisk -l`
and reading the device name of the last two entries,
whose types should be "EFI Boot" and "Linux Filesystem".

## Configure disk encryption

On OS X,
the standard for disk encryption is FileVault.
On Linux, it's [LUKS][luks].

We'll be using a strategy called [LVM On LUKS][lvm-on-luks],
where the partition we created above
is an encrypted LUKS partition,
on top of which we'll layer root and swap partitions with LVM.

  [luks]: https://gitlab.com/cryptsetup/cryptsetup/blob/master/README.md
  [lvm-on-luks]: https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS

```shell
root_partition=/dev/sda$PARTITION_NUMBER # e.g., /dev/sda5

cryptsetup luksFormat $root_partition
cryptsetup open --type luks $root_partition enc-pv
pvcreate /dev/mapper/enc-pv
vgcreate vg /dev/mapper/enc-pv
lvcreate -L 10G -n swap vg
lvcreate -l 100%VG -n root vg
```

## Format partitions

```shell
boot_partition=/dev/sda$PARTITION_NUMBER # e.g., /dev/sda4

mkfs.ext2 -L boot $boot_partition
mkfs.ext4 -j -L root /dev/vg/root
mkswap -L swap /dev/vg/swap
```

And then mount them:

```shell
mount /dev/vg/root /mnt
mkdir /mnt/boot
mount $boot_partition /mnt/boot
swapon /dev/vg/swap
```

You can recover back to this step,
by booting into the livecd
and running:

```shell
cryptsetup open --type luks $root_partition
lvchange -ay
```

## Connect to wireless network

You will need a network connection
to complete your NixOS installation.
The following commands will update your wireless configuration
to recognize your local wireless network.

```shell
wpa_passphrase "Network SSID" "passphrase" | grep -v "#psk" >> /etc/wpa_supplicant.conf
systemctl restart wpa_supplicant
```

Within a few seconds,
you should be connected
and a command like `ping -c 1 google.com`
should be successful.

## Configure and install system

Start by generating a template configuration:

```shell
nixos-generate-config --root /mnt
```

This will produce two files:

  - `/mnt/etc/nixos/configuration.nix`:
    the system's configuration file
  - `/mnt/etc/nixos/hardware-configuration.nix`:
    the system's hardware configuration

If you followed this guide's Broadcom instructions above,
you'll need to apply an edit to `hardware-configuration.nix`.
Find the line which starts with `boot.extraModulePackages`
and enable the Broadcom kernel module
by removing the surrounding quotes:

```nix
boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
```

Now we will need to edit `configuration.nix`
to contain the minimum requirements:

```nix
# enable support for broadcom_sta
nixpkgs.config.allowUnfree = true;

# load fbcon early in boot process
boot.initrd.kernelModules = [ "fbcon" ];

# register our root luks device
boot.initrd.luks.devices = [
  { name = "rootfs";
    device = "/dev/sda5";
    preLVM = true; }
];
```

Also, you should ensure that the grub device
is correct. For me, this was:

```nix
boot.loader.grub.device = "/dev/sda";
```

Now copy your wireless configuration:

```shell
cp /etc/wpa_supplicant.conf /mnt/etc
```

And then install!

```shell
nixos-install
```

If everything goes well,
`reboot` to boot into your new NixOS system!

## OS X final steps

When you updated the partition table with `gdisk`,
the recovery disk partition lost some metadata,
and shows up as "EFI Disk" instead of "Recovery".
If you go into Disk Utility,
and hit "Repair" on "Macintosh HD",
that will fix this.

Also, don't forget to re-enable FileVault
if you turned it off earlier!

## Where to go from here

At this point,
you should be able to dual-boot
into a functional, if not particularly useful,
NixOS system.

Now starts the fun part,
which I'm still going through myself,
of exploring Nix, NixOS, and Linux
to build your new environment.
I can recommend some resources
to help you on your way:

  - [NixOS Wiki](https://nixos.org/wiki/Main_Page)
  - [NixOS Options](nixos.org/nixos/options.html)—browser-based search and
    documentation for NixOS configuration options.
  - `man configuration.nix`—the same information as above,
    in your terminal.
  - GitHub code search—include `language:nix` in your search
    to turn up other user's configurations.
  - My current [system][bernerd-system-conf] and [user][bernerd-user-conf]
    Nix configurations.

  [bernerd-system-conf]: https://github.com/bernerdschaefer/dotfiles/blob/68f5210fc4aeb51aed3e4d1cb054082c25504427/nixos/configuration.nix
  [bernerd-user-conf]: https://github.com/bernerdschaefer/dotfiles/blob/68f5210fc4aeb51aed3e4d1cb054082c25504427/profile.nix

## References and credits

  * [NixOS Manual](https://nixos.org/nixos/manual/)
  * [ajhager/airnix][airnix]
  * [Installing NixOS on a ThinkPad W540 with encrypted root][nixos-with-encrypted-root]
  * Lots of helpful people on Linux forums and StackOverflow.

  [nixos-with-encrypted-root]: http://bluishcoder.co.nz/2014/05/14/installing-nixos-with-encrypted-root-on-thinkpad-w540.html
  [airnix]: https://github.com/ajhager/airnix
