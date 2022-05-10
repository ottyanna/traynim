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


mkdir demo

nimble run

for angle in $(seq 0 359); do 
    # Angle with three digits, e.g  angle"1" -> angleNNN="001"
    angleNNN=$(printf "%03d" $angle)
    ./traynim demo --width=640 --height=480 -a=$angle --fileName="demo/img$angleNNN"
done

# -r 25: Number of frames per second
ffmpeg -r 25 -f image2 -s 640x480 -i "demo/img%03d.png" -vcodec libx264 -pix_fmt yuv420p \
    "demo/spheres-perspective.mp4"

rm demo/img*