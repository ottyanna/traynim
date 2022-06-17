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
    echo "Usage: $(basename $0) NUM_OF_CORES"
    exit 1
fi

mkdir animation

cd ..

nimble run

cd scripts

parallel -j "$1" ./generateImage.sh '{}' ::: $(seq 0 359)

# -r 25: Number of frames per second
ffmpeg -r 25 -f image2 -s 640x480 -i "animation/img%03d.png" -vcodec libx264 -pix_fmt yuv420p \
    "animation/animation.mp4"

rm animation/img*