#!/bin/bash

# ─── Standardwerte ──────────────────────────────────────────────────────────────
NO_BUILD=0

# ─── Optionen parsen ────────────────────────────────────────────────────────────
print_help() {
    echo "Usage: $0 [OPTIONS] <kernel-version>"
    echo ""
    echo "Beispiel:"
    echo "  $0 6.14             # Lädt und baut Kernel 6.14"
    echo "  $0 --no-build 6.14  # Lädt Kernel 6.14, aber ohne zu bauen"
    echo ""
    echo "Optionen:"
    echo "  -n, --no-build      Kein Build (make bzImage) durchführen"
    echo "  -h, --help          Hilfe anzeigen"
}

# Temporäres Array für Long Options
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--no-build)
            NO_BUILD=1
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        -*)
            echo "Unbekannte Option: $1"
            print_help
            exit 1
            ;;
        *)
            POSITIONAL+=("$1") # vermutlich Kernel-Version
            shift
            ;;
    esac
done

# Wiederherstellen der Positionsargumente (z. B. Kernel-Version)
set -- "${POSITIONAL[@]}"

# ─── Kernel-Version verarbeiten ─────────────────────────────────────────────────
KERNEL_VERSION="$1"
if [ -z "$KERNEL_VERSION" ]; then
    echo "Fehlende Kernel-Version!"
    print_help
    exit 1
fi

KERNEL_MAJOR="${KERNEL_VERSION%%.*}"
KERNEL_DIR="linux-$KERNEL_VERSION"
KERNEL_URL="https://www.kernel.org/pub/linux/kernel/v$KERNEL_MAJOR.x/$KERNEL_DIR"

export KERNEL_DIR


# ─── Tools mit APT herunterladen ────────────────────────────────────────────────
echo "[1/6] Tools herunterladen"
sudo apt install -y libncurses-dev qemu-system-x86 uml-utilities libssl-dev libelf-dev vim flex bison


# ─── Linux Kernel herunterladen ─────────────────────────────────────────────────
echo "[2/6] Linux Kernel herunterladen"
if [ ! -d "$KERNEL_DIR" ] && { [ ! -f "$KERNEL_DIR.tar" ] || [ ! -f "$KERNEL_DIR.tar.sign" ]; }; then
    gpg --locate-keys torvalds@kernel.org 
    gpg --locate-keys gregkh@kernel.org
    wget "$KERNEL_URL.tar.xz"   || { echo "Fehler beim Download des Kernel-Archivs";  exit 1; }
    wget "$KERNEL_URL.tar.sign" || { echo "Fehler beim Download der Kernel-Signatur"; exit 1; }
    xz -d "$KERNEL_DIR.tar.xz"  || { echo "Fehler beim Entpacken des Kernel-Archivs"; exit 1; }
else
    echo "[2/6] Kernelarchiv oder entpackter Kernel bereits vorhanden – Überspringe Download."
fi


# ─── Linux Kernel entpacken ─────────────────────────────────────────────────────
echo "[3/6] Linux Kernel entpacken"
if [ ! -d "$KERNEL_DIR" ]; then
    gpg --verify "$KERNEL_DIR.tar.sign" || { echo "Fehler bei der Verifizierung des Kernel-Archivs"; exit 1; }
    tar xf "$KERNEL_DIR.tar"            || { echo "Fehler beim Entpacken des Kernel-Tarballs";       exit 1; }
else
    echo "[3/6] Kernel bereits entpackt – Überspringe Entpacken."
fi


# ─── Kernel Minimalkonfiguration ────────────────────────────────────────────────
echo "[4/6] Kernel Minimalkonfiguration"
cd "$KERNEL_DIR"
make ARCH=x86_64 allnoconfig || { echo "Fehler bei der Minimalkonfiguration des Kernels"; exit 1; }


# ─── Kernel Features aktivieren ─────────────────────────────────────────────────
echo "[5/6] Kernel features aktivieren"
# ─── Allgemeine Optionen ────────────────────────────────
scripts/config --enable CONFIG_PCI                     # PCI support
scripts/config --enable CONFIG_BINFMT_ELF              # ELF binary support
scripts/config --enable CONFIG_BINFMT_SCRIPT           # #!-Skripte
scripts/config --enable CONFIG_NET                     # Net
scripts/config --enable CONFIG_INET                    # TCP/IP
scripts/config --enable CONFIG_NETFILTER               # Netfilter
scripts/config --enable CONFIG_BRIDGE                  # Ethernet Bridging

# ─── Netzwerkgerätetreiber ──────────────────────────────
scripts/config --enable CONFIG_NETDEVICES              # Network device support
scripts/config --enable CONFIG_ETHERNET                # Ethernet devices
scripts/config --enable CONFIG_TUN                     # TUN/TAP
scripts/config --enable CONFIG_NE2K_PCI                # NE2000 PCI

# ─── SCSI-Unterstützung ─────────────────────────────────
scripts/config --enable CONFIG_SCSI                    # Allgemein
scripts/config --enable CONFIG_BLK_DEV_SD              # SCSI Disk
scripts/config --enable CONFIG_CHR_DEV_SG              # SCSI Generic

# ─── SATA/PATA-Treiber ──────────────────────────────────
scripts/config --enable CONFIG_ATA                     # libata
scripts/config --enable CONFIG_ATA_PIIX                # Intel PIIX/ICH

# ─── Eingabegeräte ──────────────────────────────────────
scripts/config --enable CONFIG_INPUT                   # Allgemeine Eingabe
scripts/config --enable CONFIG_INPUT_KEYBOARD          # Tastaturen

# ─── Dateisysteme ───────────────────────────────────────
scripts/config --enable CONFIG_EXT2_FS                 # ext2
scripts/config --enable CONFIG_EXT4_FS                 # ext4
scripts/config --enable CONFIG_TMPFS                   # tmpfs


# ─── Linux Kernel bauen ─────────────────────────────────────────────────────────
echo "[6/6] Kernel builden"
make olddefconfig       || { echo "Fehler beim Erstellen der alten Konfiguration"; exit 1; }
if [ "$NO_BUILD" -eq 0 ]; then
    CORES=$(nproc)
    make -j"$CORES" bzImage || { echo "Fehler beim Bauen des Kernels"; exit 1; }
    echo "Linux Kernel ($KERNEL_VERSION) erfolgreich heruntergeladen und gebaut!"
else
    echo "Linux Kernel ($KERNEL_VERSION) erfolgreich heruntergeladen und konfiguriert!"
fi
