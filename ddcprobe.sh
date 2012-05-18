#!/bin/sh
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

BLACKLISTMODES="2288x1430"

if [ -n "$1" ]; then
  DDCPROBE="$(cat $1)"
else
  DDCPROBE="$(ddcprobe 2>/dev/null)"
fi
if [ "$?" = "1" ]; then
  exit 1
fi
if (echo "$DDCPROBE" | egrep "(edidfail|ddcfail)" >/dev/null 2>&1); then
  exit 0
fi

if (echo "$DDCPROBE" | egrep "^input: .*digital"); then
  SCREENTYPE="lcd"
else
  SCREENTYPE="crt"
fi

TIMINGS="$(echo "$DDCPROBE" | egrep '^[cd]*timing:' | \
	 sed -e 's/^[cd]*timing: \([^x]*\)x\([^ @$]*\).*$/\1x\2/;' | \
	 sort -nr | egrep -v "$BLACKLISTMODES")"

# highest in this case means 'highest resolution', and we want to demote it
# to the least-preferred resolution; it will usually be completely unviewable

if [ -n "$XRESPROBE_DEBUG" ]; then
   echo "raw timings - $(echo "$TIMINGS" | xargs echo)" >&2
fi

NTIMINGS="$(echo "$TIMINGS" | wc -l)"
HIGHEST="$(echo "$TIMINGS" | head -n 1)"
OUTTIMINGS="$(echo "$TIMINGS" | tail -n "$(($NTIMINGS-1))")"
MONITORNAME="$(echo "$DDCPROBE" | egrep '^monitorname:' | sed -e 's/^monitorname: //;')"
MONITORRANGE="$(echo "$DDCPROBE" | egrep '^monitorrange:' | sed -e 's/^monitorrange: //;' -e 's/\,//;')"
TIMINGS="$(echo "$TIMINGS" | sort -rnu -tx -k1,1nr -k2,2nr)"
OUTTIMINGS="$(echo "$OUTTIMINGS" | sort -rnu -tx -k1,1nr -k2,2nr)"

if [ "$SCREENTYPE" = "lcd" ]; then
  echo "res: $(echo $TIMINGS | xargs echo)"
  echo "disptype: lcd"
else
  if [ "$NTIMINGS" -gt "1" ]; then
    echo "res: $(echo $OUTTIMINGS | xargs echo)"
  else
    echo "res: $(echo $HIGHEST | xargs echo)"
  fi
  echo "disptype: crt"
fi
echo "name: $MONITORNAME"
echo "freq: $MONITORRANGE"
