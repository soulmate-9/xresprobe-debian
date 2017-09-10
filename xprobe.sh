#!/bin/sh
# usage: xprobe.sh driver
# Copyright (C) 2004 Canonical Ltd.
# Author: Daniel Stone <daniel.stone@ubuntu.com>
# 
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2 of the License.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License with
#  the Debian GNU/Linux distribution in file /usr/share/common-licenses/GPL-2;
#  if not, write to the Free Software Foundation, Inc., 59 Temple Place,
#  Suite 330, Boston, MA  02111-1307  USA
#
# On Debian systems, the complete text of the GNU General Public
# License, version 2, can be found in /usr/share/common-licenses/GPL-2.

DATAPATH="/usr/share/xresprobe"

DRIVER="$1"
if [ -z "$DRIVER" ]; then
  echo "Driver name must be specified on the command line."
  exit 1
fi

set -e
if [ -z "$TMPDIR" ]; then
	TMPDIR="/tmp"
fi
XDIR="$TMPDIR/xprobe.$$"
TMPCONF="$XDIR/xorg.conf"
TMPLOG="$XDIR/xorg.log"
TMPOUT="$XDIR/xorg-stdout.log"

mkdir -m700 "$XDIR"
sed -e "s/::DRIVER::/$DRIVER/;" < "$DATAPATH/xorg.conf" > "$TMPCONF"
set +e

/usr/bin/Xorg :67 -ac -probeonly -logfile "$TMPLOG" -config "$TMPCONF" > "$TMPOUT" 2>&1

echo "$XDIR"
exit 0
