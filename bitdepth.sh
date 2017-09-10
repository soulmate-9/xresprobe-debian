#!/bin/sh
# usage: bitdepth.sh driver logfile [stdout]
# Copyright (C) 2005 Canonical Ltd.
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
#  the Debian GNU/Linux distribution in file /usr/share/common-licenses/GPL;
#  if not, write to the Free Software Foundation, Inc., 59 Temple Place,
#  Suite 330, Boston, MA  02111-1307  USA
#
# On Debian systems, the complete text of the GNU General Public
# License, version 2, can be found in /usr/share/common-licenses/GPL-2.

DRIVER="$1"
LOGFILE="$2"
# stdout is, for now, unused
STDOUT="$3"

if [ -z "$DRIVER" -o -z "$LOGFILE" ]; then
  echo "Driver name and logfile must be specified on the command line."
  exit 1
fi

if [ "$DRIVER" = "i810" ]; then
  if egrep -q "\(EE\) I810\(.*\): No Video BIOS modes for chosen depth." \
           "$LOGFILE"; then
    # broken bios!  word.  if we don't have any 24bpp modes, just hope like
    # hell that 16bpp will work; some vendors ship bioses without 24bpp modes
    # in their vesa mode table.  but sometimes this means we need to go to 32.
    FORCEDEPTH=16
  fi
else
  exit 1
fi

if [ -n "$FORCEDEPTH" ]; then
  echo $FORCEDEPTH
fi
