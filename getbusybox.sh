#!/bin/bash

# ─── Versionsparameter prüfen ───────────────────────────────────────────
BUSYBOX_VERSION="$1"
if [ -z "$BUSYBOX_VERSION" ]; then
    echo "Bitte gib die BusyBox-Version an, z. B.:" 
    echo "   $0 1.37.0"
    exit 1
fi

BUSYBOX_DIR="busybox-$BUSYBOX_VERSION"
BUSYBOX_URL="https://busybox.net/downloads/$BUSYBOX_DIR.tar.bz2"

export BUSYBOX_DIR


echo "1. Verzeichnisse erstellen"
mkdir -p userland/rootfs
cd userland || { echo "Fehler beim Verzeichniswechsel"; exit 1; }

echo "2. Busybox herunterladen"
if [ ! -f "$BUSYBOX_DIR.tar.bz2" ] || [ ! -f "$BUSYBOX_DIR.tar.bz2.sig" ]; then
    wget "$BUSYBOX_URL" || { echo "Fehler beim Download der BusyBox"; exit 1; }
    wget "$BUSYBOX_URL.sig" || { echo "Fehler beim Download der BusyBox-Signatur"; exit 1; }
else
    echo "BusyBox und Signatur bereits vorhanden – Überspringe Download."
fi

gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys ACC9965B
gpg --verify "$BUSYBOX_DIR.tar.bz2.sig" || { echo "Fehler bei der Verifizierung der BusyBox-Signatur"; exit 1; }

echo "3. Busybox entpacken"
tar xf "$BUSYBOX_DIR.tar.bz2" || { echo "Fehler beim Entpacken der BusyBox"; exit 1; }

echo "4. Minimalkonfiguration setzen"
cd "$BUSYBOX_DIR" || { echo "Fehler beim Verzeichniswechsel"; exit 1; }
make allnoconfig || { echo "Fehler bei der Minimalkonfiguration von BusyBox"; exit 1; }

cp ../../qemu-config/busybox.config .config
cp -r ../../qemu-config/target/ ../

echo "BusyBox $BUSYBOX_VERSION erfolgreich heruntergeladen, entpackt und konfiguriert!"
