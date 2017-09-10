#!/bin/sh
# Usage: rigprobe.sh driver screentype laptop
# Copyright (C) 2005 Canonical Ltd
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

DATADIR="/usr/share/xresprobe"

if [ -n "$XRESPROBE_DRIVER" ]; then
  DRIVER="$XRESPROBE_DRIVER"
else
  DRIVER="$1"
fi
if [ -n "$XRESPROBE_DEBUG" ]; then
  echo "rigprobe: assuming $DRIVER as driver" >&2
fi

SCREENTYPE="$2"
LAPTOP="$3"

rignoddc() {
  if [ -n "$XRESPROBE_DEBUG" ]; then
    echo "rigprobe: returning failed DDC" >&2
  fi
  if [ -n "$LAPTOP" ]; then
    DISPTYPE="lcd/lvds"
  fi
}

rigddc() {
  if [ -n "$XRESPROBE_DEBUG" ]; then
    echo "rigprobe: returning DDC from $XRESPROBE_RIG_DDC" >&2
  fi
  DDCOUT="$("$DATADIR/ddcprobe.sh" "$XRESPROBE_RIG_DDC")"
  RETCODE="$?"
  RES="$(echo "$DDCOUT" | grep "^res:" | sed -e 's/^res: *//;')"
  IDENTIFIER="$(echo "$DDCOUT" | grep "^name:" | sed -e 's/^name: *//;')"
  FREQ="$(echo "$DDCOUT" | grep "^freq:" | sed -e 's/^freq: *//;')"
  DISPTYPE="$(echo "$DDCOUT" | grep "^disptype:" | sed -e 's/^disptype: *//;')"

  # well, not necessarily, but it's a pretty good guess
  if [ -n "$DISPTYPE" ] && [ "$DISPTYPE" = "lcd" ]; then
    DISPTYPE="lcd/tmds"
  fi
}

rigprobe() {
  if [ -n "$XRESPROBE_DEBUG" ]; then
    echo "rigprobe: returning LCD size from $XRESPROBE_RIG_LOG" >&2
  fi
  RES="$("$DATADIR/lcdsize.sh" $DRIVER $XRESPROBE_RIG_LOG)"
}

rigdepth() {
  if [ -n "$XRESPROBE_DEBUG" ]; then
    echo "rigprobe: checking for broken i8xx BIOS with no 24bpp modes" >&2
    echo "          from $XRESPROBE_RIG_LOG" >&2
  fi
  FORCEDEPTH="$("$DATADIR/bitdepth.sh" $DRIVER $XRESPROBE_RIG_LOG)"
}

if [ "$XRESPROBE_RIG" = "noddc" ]; then
  rignoddc
elif [ "$XRESPROBE_RIG" = "ddc" ]; then
  rigddc
elif [ "$XRESPROBE_RIG" = "probe" ]; then
  rigprobe
fi

if [ "$DRIVER" = "i810" ] && [ -n "$XRESPROBE_RIG_LOG" ] && \
   [ -e "$XRESPROBE_RIG_LOG" ]; then
  rigdepth
fi

if [ -n "$XRESPROBE_DEBUG" ]; then
  echo "id: $IDENTIFIER" >&2
  echo "res: $RES" >&2
  echo "freq: $FREQ" >&2
  echo "disptype: $DISPTYPE" >&2
  if [ -n "$FORCEDEPTH" ]; then
    echo "depth: $FORCEDEPTH" >&2
  fi
fi

echo "id: $IDENTIFIER"
echo "res: $RES"
echo "freq: $FREQ"
echo "disptype: $DISPTYPE"
if [ -n "$FORCEDEPTH" ]; then
  echo "depth: $FORCEDEPTH"
fi

exit 0
