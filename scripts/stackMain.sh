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
    echo "Usage: $(basename $0) NUM_OF_CORES PATH_TO_INPUT_SCENE"
    exit 1
fi

if [ "$2" == "" ]; then
    echo "Usage: $(basename $0) NUM_OF_CORES PATH_TO_INPUT_SCENE"
    exit 1
fi

mkdir stack

cd ..

nimble run

cd scripts

# the first one is the angle, the second the imput scene, the third the initSeq
parallel -j "$1" ./provaStack.sh '{}' "$2" '{}' ::: $(seq 0 10) 

./../traynim stack -i="stack/img" -o="stack/Def" -n=11 

rm stackProva/img*