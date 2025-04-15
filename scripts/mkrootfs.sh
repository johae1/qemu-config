#!/bin/bash
set -e

BUSYBOX_DIR="busybox-1.37.0"
MOUNT_DIR=""

cleanup() {
    if mountpoint -q "$MOUNT_DIR"; then
        sudo umount "$MOUNT_DIR"
    fi
}
trap cleanup EXIT

# ─── Dateisystem anlegen ─────────────────────────────────────────────────────────
echo "[1/10] Dateisystem anlegen"
cd userland || { echo "Fehler beim Verzeichniswechsel"; exit 1; }
dd if=/dev/zero of=rootfs.img bs=1k count=16384

# ─── Dateisystem formatieren ─────────────────────────────────────────────────────────
echo "[2/10] Dateisystem formatieren"
mkfs.ext4 -L rootfs -F rootfs.img

# ─── Dateisystem einghaengen (mounten) ─────────────────────────────────────────────────────────
echo "[3/10] Dateisystem mounten"
MOUNT_DIR="$(pwd)/rootfs"
sudo mount rootfs.img rootfs
sudo chown -R jonas:jonas rootfs

# ─── Verzeichnissruktur im eingehaengten Dateisystem (Image) anlegen ─────────────────────────────────────────────────────────
echo "[4/10] Verzeichnisstruktur in Image anlegen"
mkdir -p rootfs/dev
mkdir -p rootfs/etc
mkdir -p rootfs/proc
mkdir -p rootfs/sys
mkdir -p rootfs/var/www/

# ─── Busybox generieren und vorab installieren ─────────────────────────────────────────────────────────
echo "[5/10] Busybox generieren"
cd "$BUSYBOX_DIR/" || { echo "Fehler beim Verzeichniswechsel"; exit 1; }
make
make install
cd .. || { echo "Fehler beim Verzeichniswechsel"; exit 1; }

# ─── Busyboxdateien ins Image installieren (kopieren) ─────────────────────────────────────────────────────────
echo "[6/10] Busyboxdateien kopieren"
rsync -a "$BUSYBOX_DIR"/_install/ rootfs/

# ─── Geraetedateien im Image anlegen ─────────────────────────────────────────────────────────
echo "[7/10] Geraetedateien anlegen"
sudo mknod rootfs/dev/null c 1 3
sudo mknod rootfs/dev/tty1 c 4 1
sudo mknod rootfs/dev/console c 5 1

# ─── Applikationsdateien kopieren ─────────────────────────────────────────────────────────
echo "[8/10] Applikationsdateien kopieren"
install -m 0755 target/rc.local       rootfs/bin/
install -m 0755 target/profile        rootfs/etc/
install -m 0644 target/httpd.conf     rootfs/etc/
install -m 0644 target/index.html     rootfs/var/www/
install -m 0755 target/ps.cgi         rootfs/var/www/
install -m 0644 target/de-latin1.bmap rootfs/etc/

# ─── Zugriffsrechte anpassen ─────────────────────────────────────────────────────────
echo "[9/10] Zugriffsrechte anpassen"
sudo chown -R root:root rootfs

# ─── Dateisystem (Image) wieder aushaengen ─────────────────────────────────────────────────────────
echo "[10/10] Image unmounten"
sync
sudo umount rootfs

echo "Rootfilesystem wurde erfolgreich erstellt!"
