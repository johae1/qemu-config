#!/bin/bash

# Pfad des Skripts ermitteln
script_dir=$(dirname "$(realpath "$0")")

# Symlinks für skripte erstellen
ln -s "$script_dir/scripts/getkernel.sh"  "$script_dir/../getkernel.sh"
ln -s "$script_dir/scripts/getbusybox.sh" "$script_dir/../getbusybox.sh"
ln -s "$script_dir/scripts/mkrootfs.sh"   "$script_dir/../mkrootfs.sh"
ln -s "$script_dir/scripts/start_el.sh"   "$script_dir/../start_el.sh"

# Target Skripte kopieren
mkdir "$script_dir/../userland/"
cp -r "$script_dir/target" "$script_dir/../userland/"
