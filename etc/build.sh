#!/usr/bin/env sh
#-------------------------------------------------------------------------------
# This file contains the build script for the Aster operating system. This
# script should be completely cross-platform POSIX shell language, but if it
# does not work on your platform, open a ticket upstream.
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

bootloader=
run=off
use_gdb=off

while getopts "hbuQGB" opt; do
    case "$opt" in
        h)
            printf \
"Usage: %s [OPTIONS]\n\
Options:\n\
    -h: Display the help menu and exit.\n\
\n\
    -Q: Run the produced image in QEMU.\n\
    -G: Wait for a GDB connection.\n\
    -B: Run the produced image in Bochs.\n\
\n\
    -b: Build the BIOS bootloader.\n\
    -u: Build the UEFI bootloader.\n" $0
            exit 0
            ;;
        b)
            if ! [ "x$bootloader" = "x" ]; then
                echo "You may only compile one bootloader."
                exit 1
            fi
            bootloader=bios
            ;;
        u)
            if ! [ "x$bootloader" = "x" ]; then
                echo "You may only compile one bootloader."
                exit 1
            fi
            bootloader=uefi
            ;;
        Q)
            if ! [ "x$run" = "xoff" ]; then
                echo "You may only run with one virtualizer."
                exit 1
            fi
            run=qemu
            ;;
        G)
            if ! [ "x$run" = "xqemu" ]; then
                echo "You may only run GDB with QEMU."
                exit 1
            fi
            use_gdb=on
            ;;
        B)
            if ! [ "x$run" = "xoff" ]; then
                echo "You may only run with one virtualizer."
                exit 1
            fi
            run=bochs
            ;;
        *)
            printf "Unknown option '%s'.\n" $opt
            exit 1
            ;;
    esac
done

nasm_sources=

case "$bootloader" in
    bios)
        echo "Building the BIOS bootloader."
        nasm_sources="$nasm_sources boot/bios/stage1 boot/bios/stage2"
        ;;
    uefi)
        echo "Building the UEFI bootloader."
        echo "Unimplemented."
        exit 1
        ;;
    *)
        echo "Unable to make sense of bootloader selection."
        exit 1
        ;;
esac

if ! command -v nasm 1>/dev/null 2>&1; then
    echo "You do not have NASM installed on your system."
    exit 1
fi

mkdir -p 'bld' || exit 1
echo "mkdir -p bld"

#-------------------------------------------------------------------------------
# Compile the bootstrap Aster compiler. This will emit the Linux-only code that
# will compile the second-stage Aster compiler (also Linux only), which will
# provide an interface to compile the kernel with.
#-------------------------------------------------------------------------------

mkdir -p 'bld/boot' || exit 1
echo 'mkdir -p bld/boot'
nasm -f 'elf64' 'src/boot/compiler.nasm' -o 'bld/boot/compiler.o' || exit 1
echo 'nasm -f elf64 src/boot/compiler.nasm -o bld/boot/compiler.o'
ld 'bld/boot/compiler.o' -o 'bld/boot/compiler' || exit 1
echo 'ld bld/boot/compiler.o -o bld/boot/compiler'

rm 'bld/aster.img'
for file in $nasm_sources; do
    # TODO: Really bad way to do this. Fix that.
    mkdir -p "bld/$file" || exit 1

    nasm -f 'bin' "src/$file.nasm" -o "bld/$file.bin" || exit 1
    echo "nasm -f bin src/$file.nasm -o bld/$file.bin"
    cat "bld/$file.bin" >> 'bld/aster.img'
done

fonts='boot'
for font in $fonts; do
    ./etc/resources/font.sh $font || exit 1
    echo "./etc/resources/font.sh $font"
    cat "bld/fonts/$font.bin" >> 'bld/aster.img'
done

if [ "$run" = "off" ]; then
    exit 0
fi

if [ "$run" = "qemu" ]; then
    if ! command -v qemu-system-x86_64 1>/dev/null 2>&1; then
        echo "You do not have QEMU installed on your system."
        exit 1
    fi

    if [ "$use_gdb" = "off" ]; then
        qemu-system-x86_64 -drive file=bld/aster.img,format=raw -full-screen -serial mon:stdio || exit 1
        echo 'qemu-system-x86_64 -drive file=bld/aster.img,format=raw -full-screen -serial mon:stdio'
        exit 0
    fi

    if ! command -v gdb 1>/dev/null 2>&1; then
        echo "You do not have GDB installed on your system."
        exit 1
    fi

    (trap 'kill 0' SIGINT; qemu-system-x86_64 -drive file=bld/aster.img,format=raw -s -S -full-screen || exit 255 & )
    gdb -x 'etc/debugging/gdbsetup.gdb'
    wait
elif [ "$run" = "bochs" ]; then
    if ! command -v bochs 1>/dev/null 2>&1; then
        echo "You do not have Bochs installed on your system."
        exit 1
    fi

    mkdir -p 'bld/bochs' || exit 1

    if ! [ -e 'bld/bochs/monitor.bin' ]; then
        printf 'Missing monitor EDID file, automatically retrieve? (y/N) ' >&2
        read -r exportEDID

        case "$exportEDID" in
            y)
                printf 'Exporting EDID from your platform...'
                case "$(uname -s)" in
                    Linux)
                        printf 'linux.\n'
                        ./etc/edid/linux.sh
                        ;;
                    *)
                        printf 'unknown.\n'
                        printf 'There is currently no automatic EDID script for your system.\n'
                        exit 1
                        ;;
                esac
                ;;
            *)
                printf 'Okay. Please import your EDID as "bld/bochs/monitor.bin".\n'
                exit 0
                ;;
        esac
    fi

    cp 'etc/debugging/bochsrc' 'bld/.bochsrc' || exit 1
    cd 'bld' || exit 1

    bochs -debugger -q || exit 1
else
    echo "Unknown virtualizer."
    exit 1
fi

