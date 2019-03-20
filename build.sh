#!/bin/bash

sudo true

#######
### Asuswrt-Merlin.ng build script
### Created By RMerlin, Modified By Adamm 9/03/2018
### Expects you to have a copy of the sources at $SRC_LOC
### and model-specific copies as ~/amng.ac86, ~/amng.ac88, etc...
###
### Script will rsync between $SRC_LOC and the various ~/amng.XXX folders
######

### Start config

### Manual/hardcoded
# Append git revision
export BUILDREV=1

# Enable update server support (don't use if you build a fork!)
# export MERLINUPDATE=y

# rsync tree from central source tree before build
RSYNC_TREE=y

# Run make clean before build
#CLEANUP_TREE=y

# Set DEFAULTBUILD to "none", then
# uncomment desired models
#
# You can also set DEFAULTBUILD to one of the BUILDMODELS flags (see below)

DEFAULTBUILD="none"

#BAC56=y
#BAC68=y
#BAC87=y

#BAC3200=y

#BAC88=y
#BAC3100=y
#BAC5300=y

#BAC86=y

BAX88=y

### Specify at run time through env vars
#
# a) By group
#    Example:
# 	BUILDMODELS="sdk6|sdk7114" ./build-all
#
# Supported flags: all sdk6 sdk7x sdk7114 hnd mips arm none
#
# b) Or individual models (must disable group build):
#
#	BN66=y BUILDMODELS="none" ./build-all
#

### Paths
# Store built images there
STAGE_LOC=~/images

# Copy built images there
# Copy is done using scp, so it can be an ssh location
#FINAL_LOC=""
FINAL_LOC=admin@192.168.1.69:/share/Storage/Firmware

# Location of the original source code
SRC_LOC=~/asuswrt-merlin.ng

### End config



if [ -z "$BUILDMODELS" ]; then
	BUILDMODELS=$DEFAULTBUILD
fi

if [[ "$BUILDMODELS" =~ "arm" || "$BUILDMODELS" =~ "all" || "$BUILDMODELS" =~ "sdk6" ]] ; then
	BAC56=y
	BAC68=y
	BAC87=y
fi

if [[ "$BUILDMODELS" =~ "arm" || "$BUILDMODELS" =~ "all" || "$BUILDMODELS" =~ "sdk7x" ]] ; then
	BAC3200=y
fi

if [[ "$BUILDMODELS" =~ "arm" || "$BUILDMODELS" =~ "all" || "$BUILDMODELS" =~ "sdk7114" ]] ; then
	BAC88=y
	BAC3100=y
	BAC5300=y
fi

if [[ "$BUILDMODELS" =~ "hnd" || "$BUILDMODELS" =~ "all" ]] ; then
	BAC86=y
fi


build_fw()
{
	FWMODEL=$2
	FWPATH=$1

	if [ "$FWMODEL" == "rt-ax88u" ]; then
		echo "*** $(date +%R) - Updating $FWMODEL branch..."
		echo
		cd ~/amng.ax88/ || exit 1
		git checkout rtax88
		git pull origin rtax88
		echo
	fi
	echo "*** $(date +%R) - Starting building $FWMODEL..."
	cd ~/"$FWPATH" || exit 1
	make "$FWMODEL" &> output.txt

	if [ $? -eq 0 ]; then
		cd image || exit 1
		if [ "$FWMODEL" = "rt-ac86u" ] || [ "$FWMODEL" = "rt-ax88u" ]; then
			FWNAME=$(ls -t *_cferom_ubi.w | head -n 1)
			ZIPNAME="${FWNAME//_cferom_ubi.w/}".zip
		else
			FWNAME=$(ls -t *.trx | head -n 1)
			ZIPNAME="${FWNAME%.*}".zip
		fi
		cp $FWNAME $STAGE_LOC/

		sha256sum $FWNAME > sha256sum.sha256
		zip -j $STAGE_LOC/$ZIPNAME $FWNAME $STAGE_LOC/README-merlin.txt $STAGE_LOC/Changelog*.txt sha256sum.sha256 2>/dev/null
		echo "*** $(date +%R) - Done building $FWMODEL!"
	else
		echo "!!! $(date +%R) - $FWMODEL build failed!"
	fi
}

clean_tree()
{
	FWPATH=$1
	SDKPATH=$2
	FWMODEL=$3
	if [ "$RSYNC_TREE" == "y" ]; then
		echo "*** $(date +%R) - Cloning $FWMODEL tree..."
		sudo rsync -a --del $SRC_LOC/ ~/$FWPATH
	fi

	if [ "$CLEANUP_TREE" == "y" ]; then
		echo "*** $(date +%R) - Cleaning up $FWMODEL..."
		cd ~/$FWPATH/$SDKPATH || exit 1
		make cleankernel clean 2>/dev/null 2>&1
		rm .config image/*.trx image/*.w 2>/dev/null
	fi

	echo -e "*** $(date +%R) - $FWMODEL code ready.\n"
}

localver="$(cat ~/Desktop/git.txt)"
remotever="$(git ls-remote https://github.com/RMerl/asuswrt-merlin.ng.git refs/heads/rtax88 | awk '{print $1}')"

if [ "$localver" = "$remotever" ] && [ "$1" != "force" ]; then
	echo "RT-AX88U Build Up-To-Date - Exiting"
else
	# Initial cleanup

	echo "--- $(date +%R) - Global cleanup..."
	mkdir -p $STAGE_LOC/backup
	mv $STAGE_LOC/* $STAGE_LOC/backup/ 2>/dev/null
	cp $SRC_LOC/README-merlin.txt $STAGE_LOC/
	cp $SRC_LOC/Changelog*.txt $STAGE_LOC/


	# Update all model trees

	echo "*** $(date +%R) - Updating Master branch..."
	echo
	cd $SRC_LOC || exit 1
	git pull origin master
	echo

	echo "--- $(date +%R) - Preparing trees"
	if [ "$BAC56" == "y" ]; then
		clean_tree amng.ac56 release/src-rt-6.x.4708 rt-ac56u
	fi
	if [ "$BAC68" == "y" ]; then
		clean_tree amng.ac68 release/src-rt-6.x.4708 rt-ac68u
	fi
	if [ "$BAC87" == "y" ]; then
		clean_tree amng.ac87 release/src-rt-6.x.4708 rt-ac87u
	fi
	if [ "$BAC3200" == "y" ]; then
		clean_tree amng.ac3200 release/src-rt-7.x.main/src rt-ac3200
	fi
	if [ "$BAC3100" == "y" ]; then
		clean_tree amng.ac3100 release/src-rt-7.14.114.x/src rt-ac3100
	fi
	if [ "$BAC88" == "y" ]; then
		clean_tree amng.ac88 release/src-rt-7.14.114.x/src rt-ac88u
	fi
	if [ "$BAC5300" == "y" ]; then
		clean_tree amng.ac5300 release/src-rt-7.14.114.x/src rt-ac5300
	fi
	if [ "$BAC86" == "y" ]; then
		clean_tree amng.ac86 release/src-rt-5.02hnd rt-ac86u
	fi
	if [ "$BAX88" == "y" ]; then
		clean_tree amng.ax88 release/src-rt-5.02axhnd rt-ax88u
	fi

	echo -e "--- $(date +%R) - All trees ready!\n"

	# Launch parallel builds

	echo "--- $(date +%R) - Launching all builds"
	if [ "$BAC56" == "y" ]; then
		build_fw amng.ac56/release/src-rt-6.x.4708 rt-ac56u &
		sleep 20
	fi
	if [ "$BAC68" == "y" ]; then
		build_fw amng.ac68/release/src-rt-6.x.4708 rt-ac68u &
		sleep 20
	fi
	if [ "$BAC87" == "y" ]; then
		build_fw amng.ac87/release/src-rt-6.x.4708 rt-ac87u &
		sleep 20
	fi
	if [ "$BAC3200" == "y" ]; then
		build_fw amng.ac3200/release/src-rt-7.x.main/src rt-ac3200 &
		sleep 20
	fi
	if [ "$BAC3100" == "y" ]; then
		build_fw amng.ac3100/release/src-rt-7.14.114.x/src rt-ac3100 &
		sleep 20
	fi
	if [ "$BAC88" == "y" ]; then
		build_fw amng.ac88/release/src-rt-7.14.114.x/src rt-ac88u &
		sleep 20
	fi
	if [ "$BAC5300" == "y" ]; then
		build_fw amng.ac5300/release/src-rt-7.14.114.x/src rt-ac5300 &
		sleep 10
	fi
	if [ "$BAC86" == "y" ]; then
		build_fw amng.ac86/release/src-rt-5.02hnd rt-ac86u &
		sleep 10
	fi
	if [ "$BAX88" == "y" ]; then
		build_fw amng.ax88/release/src-rt-5.02axhnd rt-ax88u &
		sleep 10
	fi

	echo "--- $(date +%R) - All builds launched, please wait..."

	wait

	echo ""
	cd "$STAGE_LOC" || exit 1
	sudo sha256sum *.w | unix2dos > sha256sums-ng.txt

	# Copy everything to the host

	if [ -n "$FINAL_LOC" ]; then
		scp -P 4216 *.w $FINAL_LOC/
	fi

	git -C ~/amng.ax88 rev-parse HEAD > ~/Desktop/git.txt

fi

echo "=== $(date +%R) - All done!"