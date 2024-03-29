#!/bin/bash
 
###############################################################################
# $URL$
# $Author$
# $Date$
# $Rev$
###############################################################################

# Try to figure out what module you need

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/tmp

umask 022

if [ -z "$_MODULE_CHECK" ] ; then
_MODULE_CHECK="loaded"

# Source the variables
. /tftpboot/etc/variables

# Usage: what_module class type
# look at pcibus for class and print module required for it
what_module()
{
  class="$1"
  type="$2"
  COUNT=0

  if [ "${class}" = "0100" ] ; then
    if ( /sbin/lspci -n |grep -q "Class 0101: 10de" ) ; then
      echo "alias ${type}${COUNT} sata_nv"
      COUNT=`expr "$COUNT" + 1`
    fi
  fi

  # Find cards in class
  lspci -n | egrep "$class" | awk '{print $4}' | \
    sed "s/\(.*\):\(.*\)/0x\1    0x\2/" | sort |
  while read BASE DEVICE
  do 
    mod=""
    while [ -z "$mod" -a -n "$DEVICE" ] 
    do 
      mod=$(grep "^${BASE}[[:space:]]*${DEVICE}" /usr/share/hwdata/pcitable | \
      awk '{print $3}' | grep -v Card | sed "s/\"//g" | head -1)
      [ -z "$mod" ] && DEVICE=${DEVICE:0:${#DEVICE}-1}
    done
    if [ ! -z "${mod}" ] ; then
        echo "alias ${type}${COUNT} $mod"
        COUNT=`expr "$COUNT" + 1`
    fi
  done
}

# Usage: scsi_module
# find the modules required for scsi controller
scsi_module()
{
  what_module 0100 scsi_hostadapter
}

# Usage: network_module
# find the modules required for ethernet cards
network_module()
{
  # 0680 is hack for nforce4 for now
  what_module "0200|0680" eth
}

fi
