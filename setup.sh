#!/bin/sh
clear
echo "############################################################################"
echo "#                 09/03/2019 | Custom Firmware Manager v4.0                #"
echo "#                   Please Select Mode ( setup / reset )                   #"
echo "############################################################################"
echo
echo

if [ -f "/tmp/build.lock" ] && [ -d "/proc/$(cat /tmp/build.lock)" ]; then
	logger -st Skynet "[INFO] Lock File Detected (pid=$(cat /tmp/build.lock)) - Exiting"
	exit 1
else
	echo "$$" > /tmp/build.lock
fi

case "$1" in

	install)
		sudo apt-get update
		sudo apt-get -y dist-upgrade
		sudo apt-get update
		sudo apt-get -y install "git build-essential linux-headers-$(uname -r)"
		sudo dpkg --add-architecture i386
		sudo apt-get update
		sudo apt-get -y install lib32ncurses5-dev dos2unix libtool-bin cmake libproxy-dev uuid-dev liblzo2-dev autoconf automake bash bison bzip2 diffutils file flex m4 g++ gawk groff-base libncurses5-dev libtool libslang2 make patch perl pkg-config shtool subversion tar texinfo zlib1g zlib1g-dev git gettext libexpat1-dev libssl-dev cvs gperf unzip python libxml-parser-perl gcc-multilib gconf-editor libxml2-dev g++-multilib gitk libncurses5 mtd-utils libncurses5-dev libvorbis-dev git autopoint autogen sed build-essential intltool libelf1 libglib2.0-dev xutils-dev lib32z1-dev lib32stdc++6 xsltproc gtk-doc-tools libelf-dev:i386 libelf1:i386 libltdl-dev openssh-server
		curl -fsL --retry 3 "https://raw.githubusercontent.com/Adamm00/misc/master/build.sh?token=AbCq9jxn_1IZq8s2mxDA3yZG3nqFbM0wks5cg5tFwA%3D%3D" -o ~/Desktop/build.sh
		sudo ln -sf ~/Desktop/setup.sh /bin/setup
		sudo ln -sf ~/Desktop/build.sh /bin/build
		chmod 755 /bin/build /bin/setup
		mkdir -p ~/images
		echo
		if [ ! -f ~/.ssh/id_rsa ]; then
			ssh-keygen -b 4096
		fi
		echo "Your Pubkey For Remote Access"
		cat ~/.ssh/id_rsa.pub
		read -r
		echo "Setting Up OpenSSH-Server - Input authorized_keys"
		read -r
		sudo nano -w ~/.ssh/authorized_keys
		echo "Hardening OpenSSH Config"
		sed -i 's~#Port 22~Port 4216~g' /etc/ssh/sshd_config
		sed -i 's~#ChallengeResponseAuthentication yes~ChallengeResponseAuthentication no~g' /etc/ssh/sshd_config
		sed -i 's~#PasswordAuthentication yes~PasswordAuthentication no~g' /etc/ssh/sshd_config
		echo "Rebooting To Apply Updates"
		read -r
		sudo rm -f /bin/sh && sudo ln -sf bash /bin/sh && sudo reboot
	;;

	repo)
		sudo rm -rf ~/am-toolchains ~/asuswrt-merlin /opt
		sudo mkdir -p /opt
		cd ~ || exit 1
		if [ ! -d ~/am-toolchains ]; then
			echo "Preparing Toolchain Repo"
			git clone https://github.com/RMerl/am-toolchains.git
			sudo ln -s ~/am-toolchains/brcm-arm-hnd /opt/toolchains
			{ echo "export LD_LIBRARY_PATH=$LD_LIBRARY:/opt/toolchains/crosstools-arm-gcc-5.5-linux-4.1-glibc-2.26-binutils-2.28.1/usr/lib"
			echo "PATH=\$PATH:/opt/toolchains/crosstools-arm-gcc-5.5-linux-4.1-glibc-2.26-binutils-2.28.1/usr/bin"
			echo "PATH=\$PATH:/opt/toolchains/crosstools-aarch64-gcc-5.5-linux-4.1-glibc-2.26-binutils-2.28.1/usr/bin"; } >> ~/.profile
		fi
		if [ ! -d ~/asuswrt-merlin.ng ]; then
			git clone https://github.com/RMerl/asuswrt-merlin.ng
		fi
	;;

	*)
		echo "u dun goofd"
		exit 2
	;;

esac


rm -rf /tmp/build.lock