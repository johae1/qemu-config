#!/bin/bash

export ARCH=x86_64
#export EXTRA_CFLAGS=-m32 EXTRA_LDFLAGS=-m32
KERNELPARAMS="root=/dev/sda rw init=/bin/busybox -ash"
QEMU_COMMAND=qemu-system-$ARCH

function create_tap {
	echo "creating tap device"
	sudo modprobe tun
	
	USERID=$(whoami)
	iface=$(sudo tunctl -b -u $USERID)
	sudo tunctl -u $USERID -t $iface
	sudo ip a a 10.69.0.1/24 dev $iface
	sudo ifconfig $iface up
}

function internet_tap_on {
	sudo bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
	sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
}

function internet_tap_off {
#	sudo bash -c "echo 0 > /proc/sys/net/ipv4/ip_forward"
	sudo iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
}

function delete_tap {
	sudo tunctl -d $1
}

function start_qemu {
	create_tap
	$QEMU_COMMAND -m 128 -hda userland/rootfs.img \
		-kernel linux-*/arch/x86/boot/bzImage -append "$KERNELPARAMS" \
		-net nic,model=ne2k_pci \
		-net tap,script=no,downscript=no,ifname=tap0
	delete_tap tap0
}

if [ $0 != "bash" ]
then
	internet_tap_on
	start_qemu
	internet_tap_off
fi
