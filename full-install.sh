#!/bin/bash
set -e  # Bricht bei Fehler ab

./install.sh
cd ..

KERNEL_VERSION="6.14.1"
BUSYBOX_VERSION="1.37.0"

# 1. Kernel bauen
./getkernel.sh "$KERNEL_VERSION"

# 2. BusyBox bauen
./getbusybox.sh "$BUSYBOX_VERSION"

# 3. Rootfs erstellen
./mkrootfs.sh

# 4. Qemu starten
./start_el.sh
