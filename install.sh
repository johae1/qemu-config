#!/bin/bash

script_dir=$(dirname "$(realpath "$0")")

ln -s "$script_dir/mkkernel.sh" "$script_dir/../mkkernel.sh"
ln -s "$script_dir/getbusybox.sh" "$script_dir/../getbusybox.sh"
ln -s "$script_dir/mkrootfs.sh" "$script_dir/../mkrootfs.sh"
