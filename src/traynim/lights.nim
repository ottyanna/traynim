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


## This module implements a `PointLight` type used for point light rendering

from colors import Color
from geometry import Point

type
    PointLight* = object

        ## A point light (used by the point-light renderer).
        ## This object holds information about a point light
        ## (a Dirac's delta in the rendering equation).


        position*: Point ## a `Point` object holding the position of
                             ## the point light in 3D space
        color*: Color ## the color of the point light
        linearRadius*: float ## a floating-point number. If non-zero, this «linear radius» `r`
                                 ## is used to compute the solid angle subtended by the light at a
                                 ## given distance `d` through the formula `(r / d)²`.

proc newPointLight*(position: Point, color: Color,
        linearRadius: float = 0.0): PointLight =

    ## Creates a new `PointLight` object

    result.position = position
    result.color = color
    result.linearRadius = linearRadius
