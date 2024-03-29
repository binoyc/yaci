#!/bin/bash

###############################################################################
# $URL$
# $Author$
# $Date$
# $Rev$
###############################################################################

# set of grub bootloader manipulation

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/tmp

umask 022

# single load system
if [ -z "$_GRUB_FUNCTIONS" ] ; then
_GRUB_FUNCTIONS="loaded"

# Source the variables
. /tftpboot/etc/variables


# Initialize some variables.
host_os=linux-gnu
device_map=${system_mount}/boot/grub/device.map


# Usage: grub_set_boot_drive grub_conf_file
# Set boot drive in grub.conf. convert() needs /boot/grub/device.map so
# grub must be already installed
grub_set_boot_drive()
{
    local grub_conf=$1

    # get boot drive
    local bootdir_device=`find_device ${system_mount}${kernel_loc}`
    local root_drive=`convert ${bootdir_device}`

    # apply it to grub configuration file
    sed -e "s|<BOOT_GRUB>|${root_drive}|" $grub_conf > ${grub_conf}.new
    mv ${grub_conf}.new $grub_conf
}


################################################################################
# The following functions were extracted from /sbin/grub-install
# Copyright (C) 1999,2000,2001,2002,2003,2004 Free Software Foundation, Inc.
################################################################################

# Usage: convert os_device
# Convert an OS device to the corresponding GRUB drive.
# This part is OS-specific.
convert () {
    # First, check if the device file exists.
    if test -e "$1"; then
	:
    else
	echo "$1: Not found or not a block device." 1>&2
	exit 1
    fi

    # Break the device name into the disk part and the partition part.
    case "$host_os" in
    linux*)
	tmp_disk=`echo "$1" | sed -e 's%\([sh]d[a-z]\)[0-9]*$%\1%' \
				  -e 's%\(d[0-9]*\)p[0-9]*$%\1%' \
				  -e 's%\(fd[0-9]*\)$%\1%' \
				  -e 's%/part[0-9]*$%/disc%' \
				  -e 's%\(c[0-7]d[0-9]*\).*$%\1%'`
	tmp_part=`echo "$1" | sed -e 's%.*/[sh]d[a-z]\([0-9]*\)$%\1%' \
				  -e 's%.*d[0-9]*p*%%' \
				  -e 's%.*/fd[0-9]*$%%' \
				  -e 's%.*/floppy/[0-9]*$%%' \
				  -e 's%.*/\(disc\|part\([0-9]*\)\)$%\2%' \
				  -e 's%.*c[0-7]d[0-9]*p*%%'`
	;;
    gnu*)
	tmp_disk=`echo "$1" | sed 's%\([sh]d[0-9]*\).*%\1%'`
	tmp_part=`echo "$1" | sed "s%$tmp_disk%%"` ;;
    freebsd*)
	tmp_disk=`echo "$1" | sed 's%r\{0,1\}\([saw]d[0-9]*\).*$%r\1%' \
			    | sed 's%r\{0,1\}\(da[0-9]*\).*$%r\1%'`
	tmp_part=`echo "$1" \
	    | sed "s%.*/r\{0,1\}[saw]d[0-9]\(s[0-9]*[a-h]\)%\1%" \
       	    | sed "s%.*/r\{0,1\}da[0-9]\(s[0-9]*[a-h]\)%\1%"`
	;;
    netbsd*)
	tmp_disk=`echo "$1" | sed 's%r\{0,1\}\([sw]d[0-9]*\).*$%r\1d%' \
	    | sed 's%r\{0,1\}\(fd[0-9]*\).*$%r\1a%'`
	tmp_part=`echo "$1" \
	    | sed "s%.*/r\{0,1\}[sw]d[0-9]\([abe-p]\)%\1%"`
	;;
    *)
	echo "grub-install does not support your OS yet." 1>&2
	exit 1 ;;
    esac

    # Get the drive name.
    tmp_drive=`grep -v '^#' $device_map | grep "$tmp_disk *$" \
	| sed 's%.*\(([hf]d[0-9][a-g0-9,]*)\).*%\1%'`

    # If not found, print an error message and exit.
    if test "x$tmp_drive" = x; then
	echo "$1 does not have any corresponding BIOS drive." 1>&2
	exit 1
    fi

    if test "x$tmp_part" != x; then
	# If a partition is specified, we need to translate it into the
	# GRUB's syntax.
	case "$host_os" in
	linux*)
	    echo "$tmp_drive" | sed "s%)$%,`expr $tmp_part - 1`)%" ;;
	gnu*)
	    if echo $tmp_part | grep "^s" >/dev/null; then
		tmp_pc_slice=`echo $tmp_part \
		    | sed "s%s\([0-9]*\)[a-g]*$%\1%"`
		tmp_drive=`echo "$tmp_drive" \
		    | sed "s%)%,\`expr "$tmp_pc_slice" - 1\`)%"`
	    fi
	    if echo $tmp_part | grep "[a-g]$" >/dev/null; then
		tmp_bsd_partition=`echo "$tmp_part" \
		    | sed "s%[^a-g]*\([a-g]\)$%\1%"`
		tmp_drive=`echo "$tmp_drive" \
		    | sed "s%)%,$tmp_bsd_partition)%"`
	    fi
	    echo "$tmp_drive" ;;
	freebsd*)
	    if echo $tmp_part | grep "^s" >/dev/null; then
		tmp_pc_slice=`echo $tmp_part \
		    | sed "s%s\([0-9]*\)[a-h]*$%\1%"`
		tmp_drive=`echo "$tmp_drive" \
		    | sed "s%)%,\`expr "$tmp_pc_slice" - 1\`)%"`
	    fi
	    if echo $tmp_part | grep "[a-h]$" >/dev/null; then
		tmp_bsd_partition=`echo "$tmp_part" \
		    | sed "s%s\{0,1\}[0-9]*\([a-h]\)$%\1%"`
		tmp_drive=`echo "$tmp_drive" \
		    | sed "s%)%,$tmp_bsd_partition)%"`
	    fi
	    echo "$tmp_drive" ;;
	netbsd*)
	    if echo $tmp_part | grep "^[abe-p]$" >/dev/null; then
		tmp_bsd_partition=`echo "$tmp_part" \
		    | sed "s%\([a-p]\)$%\1%"`
		tmp_drive=`echo "$tmp_drive" \
		    | sed "s%)%,$tmp_bsd_partition)%"`
	    fi
	    echo "$tmp_drive" ;;
	esac
    else
	# If no partition is specified, just print the drive name.
	echo "$tmp_drive"
    fi
}

# Usage: resolve_symlink file
# Find the real file/device that file points at
resolve_symlink () {
	tmp_fname=$1
	# Resolve symlinks
	while test -L $tmp_fname; do
		tmp_new_fname=`ls -al $tmp_fname | sed -n 's%.*-> \(.*\)%\1%p'`
		if test -z "$tmp_new_fname"; then
			echo "Unrecognized ls output" 2>&1
			exit 1
		fi

		# Convert relative symlinks
		case $tmp_new_fname in
			/*) tmp_fname="$tmp_new_fname"
			;;
			*) tmp_fname="`echo $tmp_fname | sed 's%/[^/]*$%%'`/$tmp_new_fname"
			;;
		esac
	done
	echo "$tmp_fname"
}

# Usage: find_device file
# Find block device on which the file resides.
find_device () {
    # For now, this uses the program `df' to get the device name, but is
    # this really portable?
    tmp_fname=`df $1/ | sed -n 's%.*\(/dev/[^ 	]*\).*%\1%p'`

    if test -z "$tmp_fname"; then
	echo "Could not find device for $1" 2>&1
	exit 1
    fi

	tmp_fname=`resolve_symlink $tmp_fname`

    echo "$tmp_fname"
}

fi
