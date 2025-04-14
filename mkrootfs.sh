#!/bin/bash

echo "1. Busybox Binary erstellen"
cd userland/busybox-1.37.0/ || { echo "Fehler beim Verzeichniswechsel"; exit 1; }
make
make install

echo "2. Rootfs image erstellen, mounten und Busybox installieren"
cd .. || { echo "Fehler beim Verzeichniswechsel"; exit 1; }
dd if=/dev/zero of=rootfs.img bs=1k count=16384
mkfs.ext4 -L rootfs -F rootfs.img
sudo mount rootfs.img rootfs
sudo rsync -a busybox-1.37.0/_install/ rootfs/

echo "3. Filesystem vorbereiten"
cd rootfs
mkdir dev etc proc sys

echo "4. Geräte erstellen"
sudo mknod dev/null c 1 3
sudo mknod dev/tty1 c 4 1
sudo mknod dev/console c 5 1

echo "5. Initskript einbauen"
# install -m 0755 ~/embedded/qemu/userland/target/prepuserland.sh ~/embedded/qemu/userland/rootfs/bin/
cd .. || { echo "Fehler beim Verzeichniswechsel"; exit 1; }
sudo chown -R root:root rootfs

echo "6. Rootfs image unmounten"
sync
sudo umount rootfs

echo "Rootfs erfolgreich erstellt!"
