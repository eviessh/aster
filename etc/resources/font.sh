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
outFile="./bld/fonts/$1.bin"
if ! [ -e "$fontFile" ]; then
    printf 'Unable to find the font "%s". Please ensure it is in "rss/fonts".\n' "$fontFile"
    exit 1
fi
mkdir -p 'bld/fonts'

width=8
height=8
needCharacter=
buildingCharacter='no'
rowsConsumed=0

# From <https://stackoverflow.com/a/1521498/32803332>.
while IFS="" read -r line || [ -n "$line" ]; do
    needWidth=no
    needHeight=no

    for word in $line; do
        # From <https://stackoverflow.com/a/51052644/32803332>.
        rest="${word#?}"
        first="${word%"$rest"}"
        if [ "$first" = '/' ]; then
            rest2="${rest#?}"
            second="${rest%"$rest2"}"

            if [ "$second" = '/' ]; then
                break
            fi
        fi

        if [ "$needWidth" = 'yes' ]; then
            if ! [ "$word" -eq "$word" ]; then
                printf 'Expected a number after "width".\n'
                exit 1
            fi
            width="$word"
        
            if ! [ "$((word % 8))" -eq '0' ]; then
                printf 'Width must be a power of 8.\n'
                exit 1
            fi

            needWidth=no
            continue
        elif [ "$needHeight" = 'yes' ]; then
            if ! [ "$word" -eq "$word" ]; then
                printf 'Expected a number after "height".\n'
                exit 1
            fi

            if ! [ "$((word % 8))" -eq '0' ]; then
                printf 'Height must be a power of 8.\n'
                exit 1
            fi

            height="$word"
            needHeight=no
            continue
        elif ! [ -z "$needCharacter" ]; then
            if ! [ "$buildingCharacter" = 'yes' ]; then
                if ! [ "$word" = '{' ]; then
                    printf 'Expected a section opener when defining "%s".\n' "$needCharacter"
                    exit 1
                else
                    buildingCharacter='yes'
                    continue
                fi
            else
                if [ "$word" = '}' ]; then
                    if ! [ "$rowsConsumed" -eq "$height" ]; then
                        printf 'Character "%s" ended prematurely.\n' "$needCharacter"
                        exit 1
                    fi
                    printf 'Built character "%s".\n' "$needCharacter"
                    needCharacter=
                    buildingCharacter='no'
                    rowsConsumed=0
                    break
                fi

                if [ "$rowsConsumed" -eq "$height" ]; then
                    printf 'Character "%s" is too tall.\n' "$needCharacter"
                    exit 1
                fi

                if ! [ "${#word}" -eq "$width" ]; then
                    printf 'Character "%s" has a malformed row.\n' "$needCharacter"
                    exit 1
                fi
                eval "$needCharacter=\"\${$needCharacter} $word\""

                rowsConsumed=$((rowsConsumed + 1))
                continue
            fi
        fi

        case "$word" in
            width)
                needWidth=yes
                ;;
            height)
                needHeight=yes
                ;;
            space)
                needCharacter='space'
                ;;
            exclamation)
                needCharacter='exclamation'
                ;;
            doublequote)
                needCharacter='doublequote'
                ;;
            hashtag)
                needCharacter='hashtag'
                ;;
            dollar)
                needCharacter='dollar'
                ;;
            percent)
                needCharacter='percent'
                ;;
            ampersand)
                needCharacter='ampersand'
                ;;
            singlequote)
                needCharacter='singlequote'
                ;;
            openparenthesis)
                needCharacter='openparenthesis'
                ;;
            closeparenthesis)
                needCharacter='closeparenthesis'
                ;;
            asterisk)
                needCharacter='asterisk'
                ;;
            plus)
                needCharacter='plus'
                ;;
            comma)
                needCharacter='comma'
                ;;
            hyphen)
                needCharacter='hyphen'
                ;;
            period)
                needCharacter='period'
                ;;
            forwardslash)
                needCharacter='forwardslash'
                ;;
            zero)
                needCharacter='zero'
                ;;
            one)
                needCharacter='one'
                ;;
            two)
                needCharacter='two'
                ;;
            three)
                needCharacter='three'
                ;;
            four)
                needCharacter='four'
                ;;
            five)
                needCharacter='five'
                ;;
            six)
                needCharacter='six'
                ;;
            seven)
                needCharacter='seven'
                ;;
            eight)
                needCharacter='eight'
                ;;
            nine)
                needCharacter='nine'
                ;;
            colon)
                needCharacter='colon'
                ;;
            semicolon)
                needCharacter='semicolon'
                ;;
            lessthan)
                needCharacter='lessthan'
                ;;
            equals)
                needCharacter='equals'
                ;;
            greaterthan)
                needCharacter='greaterthan'
                ;;
            question)
                needCharacter='question'
                ;;
            at)
                needCharacter='at'
                ;;
            A)
                needCharacter='A'
                ;;
            B)
                needCharacter='B'
                ;;
            C)
                needCharacter='C'
                ;;
            D)
                needCharacter='D'
                ;;
            E)
                needCharacter='E'
                ;;
            F)
                needCharacter='F'
                ;;
            G)
                needCharacter='G'
                ;;
            H)
                needCharacter='H'
                ;;
            I)
                needCharacter='I'
                ;;
            J)
                needCharacter='J'
                ;;
            K)
                needCharacter='K'
                ;;
            L)
                needCharacter='L'
                ;;
            M)
                needCharacter='M'
                ;;
            N)
                needCharacter='N'
                ;;
            O)
                needCharacter='O'
                ;;
            P)
                needCharacter='P'
                ;;
            Q)
                needCharacter='Q'
                ;;
            R)
                needCharacter='R'
                ;;
            S)
                needCharacter='S'
                ;;
            T)
                needCharacter='T'
                ;;
            U)
                needCharacter='U'
                ;;
            V)
                needCharacter='V'
                ;;
            W)
                needCharacter='W'
                ;;
            X)
                needCharacter='X'
                ;;
            Y)
                needCharacter='Y'
                ;;
            Z)
                needCharacter='Z'
                ;;
            openbracket)
                needCharacter='openbracket'
                ;;
            backslash)
                needCharacter='backslash'
                ;;
            closebracket)
                needCharacter='closebracket'
                ;;
            caret)
                needCharacter='caret'
                ;;
            underscore)
                needCharacter='underscore'
                ;;
            grave)
                needCharacter='grave'
                ;;
            a)
                needCharacter='a'
                ;;
            b)
                needCharacter='b'
                ;;
            c)
                needCharacter='c'
                ;;
            d)
                needCharacter='d'
                ;;
            e)
                needCharacter='e'
                ;;
            f)
                needCharacter='f'
                ;;
            g)
                needCharacter='g'
                ;;
            h)
                needCharacter='h'
                ;;
            i)
                needCharacter='i'
                ;;
            j)
                needCharacter='j'
                ;;
            k)
                needCharacter='k'
                ;;
            l)
                needCharacter='l'
                ;;
            m)
                needCharacter='m'
                ;;
            n)
                needCharacter='n'
                ;;
            o)
                needCharacter='o'
                ;;
            p)
                needCharacter='p'
                ;;
            q)
                needCharacter='q'
                ;;
            r)
                needCharacter='r'
                ;;
            s)
                needCharacter='s'
                ;;
            t)
                needCharacter='t'
                ;;
            u)
                needCharacter='u'
                ;;
            v)
                needCharacter='v'
                ;;
            w)
                needCharacter='w'
                ;;
            x)
                needCharacter='x'
                ;;
            y)
                needCharacter='y'
                ;;
            z)
                needCharacter='z'
                ;;
            openbrace)
                needCharacter='openbrace'
                ;;
            verticalbar)
                needCharacter='verticalbar'
                ;;
            closebrace)
                needCharacter='closebrace'
                ;;
            tilde)
                needCharacter='tilde'
                ;;
            *)
                printf 'Unknown token "%s".\n' "$word"
                exit 1
                ;;
        esac
    done

    if [ "$needWidth" = 'yes' ] || [ "$needHeight" = 'yes' ]; then
        printf 'Expected a number after "height".\n'
        exit 1
    fi
done < "$fontFile"

rm "$outFile"
index=32
while [ "$index" -le 126 ]; do
    # This is a genuinely awful way to do this. I, however, don't know another
    # way to do this in POSIX sh. If I could use C without adding dependencies I
    # would...
    case "$index" in
        32)
            needCharacter='space'
            ;;
        33)
            needCharacter='exclamation'
            ;;
        34)
            needCharacter='doublequote'
            ;;
        35)
            needCharacter='hashtag'
            ;;
        36)
            needCharacter='dollar'
            ;;
        37)
            needCharacter='percent'
            ;;
        38)
            needCharacter='ampersand'
            ;;
        39)
            needCharacter='singlequote'
            ;;
        40)
            needCharacter='openparenthesis'
            ;;
        41)
            needCharacter='closeparenthesis'
            ;;
        42)
            needCharacter='asterisk'
            ;;
        43)
            needCharacter='plus'
            ;;
        44)
            needCharacter='comma'
            ;;
        45)
            needCharacter='hyphen'
            ;;
        46)
            needCharacter='period'
            ;;
        47)
            needCharacter='forwardslash'
            ;;
        48)
            needCharacter='zero'
            ;;
        49)
            needCharacter='one'
            ;;
        50)
            needCharacter='two'
            ;;
        51)
            needCharacter='three'
            ;;
        52)
            needCharacter='four'
            ;;
        53)
            needCharacter='five'
            ;;
        54)
            needCharacter='six'
            ;;
        55)
            needCharacter='seven'
            ;;
        56)
            needCharacter='eight'
            ;;
        57)
            needCharacter='nine'
            ;;
        58)
            needCharacter='colon'
            ;;
        59)
            needCharacter='semicolon'
            ;;
        60)
            needCharacter='lessthan'
            ;;
        61)
            needCharacter='equals'
            ;;
        62)
            needCharacter='greaterthan'
            ;;
        63)
            needCharacter='question'
            ;;
        64)
            needCharacter='at'
            ;;
        65)
            needCharacter='A'
            ;;
        66)
            needCharacter='B'
            ;;
        67)
            needCharacter='C'
            ;;
        68)
            needCharacter='D'
            ;;
        69)
            needCharacter='E'
            ;;
        70)
            needCharacter='F'
            ;;
        71)
            needCharacter='G'
            ;;
        72)
            needCharacter='H'
            ;;
        73)
            needCharacter='I'
            ;;
        74)
            needCharacter='J'
            ;;
        75)
            needCharacter='K'
            ;;
        76)
            needCharacter='L'
            ;;
        77)
            needCharacter='M'
            ;;
        78)
            needCharacter='N'
            ;;
        79)
            needCharacter='O'
            ;;
        80)
            needCharacter='P'
            ;;
        81)
            needCharacter='Q'
            ;;
        82)
            needCharacter='R'
            ;;
        83)
            needCharacter='S'
            ;;
        84)
            needCharacter='T'
            ;;
        85)
            needCharacter='U'
            ;;
        86)
            needCharacter='V'
            ;;
        87)
            needCharacter='W'
            ;;
        88)
            needCharacter='X'
            ;;
        89)
            needCharacter='Y'
            ;;
        90)
            needCharacter='Z'
            ;;
        91)
            needCharacter='openbracket'
            ;;
        92)
            needCharacter='backslash'
            ;;
        93)
            needCharacter='closebracket'
            ;;
        94)
            needCharacter='caret'
            ;;
        95)
            needCharacter='underscore'
            ;;
        96)
            needCharacter='grave'
            ;;
        97)
            needCharacter='a'
            ;;
        98)
            needCharacter='b'
            ;;
        99)
            needCharacter='c'
            ;;
        100)
            needCharacter='d'
            ;;
        101)
            needCharacter='e'
            ;;
        102)
            needCharacter='f'
            ;;
        103)
            needCharacter='g'
            ;;
        104)
            needCharacter='h'
            ;;
        105)
            needCharacter='i'
            ;;
        106)
            needCharacter='j'
            ;;
        107)
            needCharacter='k'
            ;;
        108)
            needCharacter='l'
            ;;
        109)
            needCharacter='m'
            ;;
        110)
            needCharacter='n'
            ;;
        111)
            needCharacter='o'
            ;;
        112)
            needCharacter='p'
            ;;
        113)
            needCharacter='q'
            ;;
        114)
            needCharacter='r'
            ;;
        115)
            needCharacter='s'
            ;;
        116)
            needCharacter='t'
            ;;
        117)
            needCharacter='u'
            ;;
        118)
            needCharacter='v'
            ;;
        119)
            needCharacter='w'
            ;;
        120)
            needCharacter='x'
            ;;
        121)
            needCharacter='y'
            ;;
        122)
            needCharacter='z'
            ;;
        123)
            needCharacter='openbrace'
            ;;
        124)
            needCharacter='verticalbar'
            ;;
        125)
            needCharacter='closebrace'
            ;;
        126)
            needCharacter='tilde'
            ;;
        *)
            printf 'Unable to figure out character index.\n'
            exit 1
    esac

    if [ "$width" -ge '9' ]; then
        printf 'Greater than 8-bit fonts are not implemented.\n'
        exit 1
    fi

    if [ -z "$(eval "echo \${$needCharacter}")" ]; then
        printf 'Missing glyph "%s" in font.\n' "$needCharacter"
        exit 1
    fi

    # From <https://stackoverflow.com/a/43214215/32803332>.
    eval "characterMap=\"\${$needCharacter}\""
    for row in $characterMap; do
        printf "\\$(printf '%o' "$((2#$row))")" >> "$outFile"
    done

    index=$((index + 1))
done
