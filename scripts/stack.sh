#!/bin/bash
#encoding: utf-8

#traynim is a ray tracer program written in Nim
#Copyright (C) 2022 Jacopo Fera, Anna Spanò

#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <https://www.gnu.org/licenses/>.

if [ "$1" == "" ]; then
    echo "Usage: $(basename $0) ANGLE PATH_TO_INPUT_SCENE INIT_SEQ"
    exit 1
fi

if [ "$2" == "" ]; then
    echo "Usage: $(basename $0) ANGLE PATH_TO_INPUT_SCENE INIT_SEQ"
    exit 1
fi

if [ "$3" == "" ]; then
    echo "Usage: $(basename $0) ANGLE PATH_TO_INPUT_SCENE INIT_SEQ"
    exit 1
fi

readonly angle="$1"
readonly inScene="$2"
readonly initSeq="$3"

#to just use this to reduce noise you have to omit the -d option
time ./../traynim renderer -i="$inScene" -a=pathtracing -r=2 -s=4 -o="stack/img$angle" -l=0.5 -q="$initSeq" -d=ang:"$angle"