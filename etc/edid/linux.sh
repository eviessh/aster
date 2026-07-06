#!/usr/bin/env sh
#-------------------------------------------------------------------------------
# This file contains a script to get the current monitor's EDID information
# under the Linux operating system. More or less only needed for Bochs
# virtualization.
#-------------------------------------------------------------------------------
# Copyright (c) 2026 Evelyn (eviessh)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the “Software”), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#-------------------------------------------------------------------------------

connectedOutputs=
optionsAvailable=0

# Partial credit for this part goes to <https://askubuntu.com/a/1552762>.
for edidSource in /sys/class/drm/*/edid; do
    statusFile="${edidSource%/edid}/status"
    if [ -f "$statusFile" ] && grep -qx 'connected' "$statusFile"; then
        printf 'Found connected output: %s.\n' "$edidSource"

        if [ -z "$connectedOutputs" ]; then
            connectedOutputs="$edidSource"
        else
            connectedOutputs="$connectedOutputs $edidSource"
            # The user doesn't have to be annoyed by a prompt if there's only
            # one choice!
            optionsAvailable=1
        fi
    fi
done

usedOutput=
if [ "$optionsAvailable" -eq '1' ]; then
    printf 'Select the output index to use: ' >&2
    read -r edidSelection

    if ! [ "$edidSelection" -eq "$edidSelection" ]; then
        printf 'Selection provided is not a number.\n'
        exit 1
    fi

    atIndex=0
    for edidSource in $connectedOutputs; do
        if [ "$atIndex" -eq "$edidSelection" ]; then
            usedOutput="$edidSource"
            break
        fi
        atIndex=$((atIndex + 1))
    done

    if [ -z "$usedOutput" ]; then
        printf 'Index was too large.\n'
        exit 1
    fi
else
    usedOutput="$connectedOutputs"
fi

printf 'Selected %s.\n' "$usedOutput"

mkdir -p 'bld/bochs' || exit 1
cat "$usedOutput" > 'bld/bochs/monitor.bin' || exit 1
printf 'Exported to "bld/bochs/monitor.bin".\n'

