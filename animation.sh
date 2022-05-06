#!/bin/bash

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