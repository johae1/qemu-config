#!/bin/bash

echo "1. Verzeichnisse erstellen"
mkdir -p userland/rootfs
cd userland || { echo "Fehler beim Verzeichniswechsel"; exit 1; }

echo "2. Busybox herunterladen"
wget https://busybox.net/downloads/busybox-1.37.0.tar.bz2
wget https://busybox.net/downloads/busybox-1.37.0.tar.bz2.sig
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys ACC9965B
gpg --verify busybox-1.37.0.tar.bz2.sig

echo "3. Busybox entpacken"
tar xf busybox-1.37.0.tar.bz2

echo "4. Minimalkonfiguration setzen"
cd busybox-1.37.0 || { echo "Fehler beim Verzeichniswechsel"; exit 1; }
make allnoconfig

echo "BusyBox erfolgreich heruntergeladen, entpackt und konfiguriert!"
