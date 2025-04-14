#!/bin/bash


echo "1. Tools herunterladen"
sudo apt install -y libncurses-dev qemu-system-x86 uml-utilities libssl-dev libelf-dev vim flex bison
# mkdir -p embedded/qemu
# cd       embedded/qemu || { echo "Fehler beim Verzeichniswechsel"; exit 1; }

echo "2. Linux Kernel herunterladen"
gpg  --locate-keys torvalds@kernel.org gregkh@kernel.org
wget https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.14.tar.xz
wget https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.14.tar.sign

echo "3. Linux Kernel entpacken"
xz  -d linux-6.14.tar.xz
gpg --verify linux-6.14.tar.sign
tar xf linux-6.14.tar
cd  linux-6.14 || { echo "Fehler beim Verzeichniswechsel"; exit 1; }

echo "4. Kernel Minimalkonfiguration"
make ARCH=x86_64 allnoconfig

echo "5. Kernel features aktivieren"
# ─── Allgemeine Optionen ────────────────────────────────────────────────
scripts/config --enable CONFIG_PCI                     # PCI support
scripts/config --enable CONFIG_BINFMT_ELF              # ELF binary support
scripts/config --enable CONFIG_BINFMT_SCRIPT           # #!-Skripte
scripts/config --enable CONFIG_NET                     # Net
scripts/config --enable CONFIG_INET                    # TCP/IP
scripts/config --enable CONFIG_NETFILTER               # Netfilter
scripts/config --enable CONFIG_BRIDGE                  # Ethernet Bridging

# ─── Netzwerkgerätetreiber ──────────────────────────────────────────────
scripts/config --enable CONFIG_TUN                     # TUN/TAP
scripts/config --enable CONFIG_NE2K_PCI                # NE2000 PCI

# ─── SCSI-Unterstützung ─────────────────────────────────────────────────
scripts/config --enable CONFIG_SCSI                    # Allgemein
scripts/config --enable CONFIG_BLK_DEV_SD              # SCSI Disk
scripts/config --enable CONFIG_CHR_DEV_SG              # SCSI Generic

# ─── SATA/PATA-Treiber ──────────────────────────────────────────────────
scripts/config --enable CONFIG_ATA                     # libata
scripts/config --enable CONFIG_ATA_PIIX                # Intel PIIX/ICH

# ─── Eingabegeräte ──────────────────────────────────────────────────────
scripts/config --enable CONFIG_INPUT                   # Allgemeine Eingabe
scripts/config --enable CONFIG_INPUT_KEYBOARD          # Tastaturen

# ─── Dateisysteme ───────────────────────────────────────────────────────
scripts/config --enable CONFIG_EXT2_FS                 # ext2
scripts/config --enable CONFIG_EXT4_FS                 # ext4
scripts/config --enable CONFIG_TMPFS                   # tmpfs

echo "6. Kernel builden"
make olddefconfig
CORES=$(nproc)
make -j"$CORES" bzImage
cd ..

echo "7. Skripte verschieben"
# cp ../../getbusybox.sh ./ || { echo "Fehler beim Verschieben von getbusybox.sh"; exit 1; }
# cp ../../mkrootfs.sh   ./ || { echo "Fehler beim Verschieben von mkrootfs.sh";   exit 1; }

echo "Kernel erfolgreich gebaut und Skripte verschoben!"
