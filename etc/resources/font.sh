#!/usr/bin/env sh
#-------------------------------------------------------------------------------
# This file contains the build script for the font source files consumed by
# AsterOS. It will produce a bitlayout for the font's desired dimensions and
# glyphs that can be easily rendered later.
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

if [ -z "$1" ]; then
    printf 'Please provide the font file to build.\n'
    exit 1
fi

fontFile="./rss/fonts/$1"
if ! [ -e "$fontFile" ]; then
    printf 'Unable to find the font "%s". Please ensure it is in "rss/fonts".\n' "$fontFile"
    exit 1
fi

# From <https://stackoverflow.com/a/1521498/32803332>.
cat "$fontFile" | while IFS="" read -r line || [ -n "$line" ]; do
    printf '%s\n' "$line"
done

exit 1

