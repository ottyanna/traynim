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


## This module implements operations on  `Color` type

import common

type
    Color* = object
        r*, g*, b*: float32


proc newColor*(r, g, b: float32): Color =

    ## Creates a new color from scratch

    result.r = r
    result.g = g
    result.b = b

const white* = Color(r: 1.0, g: 1.0, b: 1.0)
const black* = Color(r: 0.0, g: 0.0, b: 0.0)

# Implementation of simple operations on Color type

proc `+`*(color1, color2: Color): Color =
    result.r = color1.r + color2.r
    result.g = color1.g + color2.g
    result.b = color1.b + color2.b

proc `*`*(col: Color, scalar: float32): Color =
    result.r = scalar * col.r
    result.g = scalar * col.g
    result.b = scalar * col.b

proc `*`*(scalar: float32, col: Color): Color =
    result.r = scalar * col.r
    result.g = scalar * col.g
    result.b = scalar * col.b

proc `-`*(color1, color2: Color): Color =
    result.r = color1.r - color2.r
    result.g = color1.g - color2.g
    result.b = color1.b - color2.b

proc `*`*(color1, color2: Color): Color =
    result.r = color1.r * color2.r
    result.g = color1.g * color2.g
    result.b = color1.b * color2.b

proc `/`*(col: Color, scalar: float): Color =
    result.r = col.r / scalar
    result.g = col.g / scalar
    result.b = col.b / scalar


# Implementation of "stringfy" operation for Color object
proc `$`*(color: Color): string =
    result = "<" & "r: " & $(color.r) & " , " & "g: " & $(color.g) & ", " &
            "b: " & $(color.b) & ">"

proc areClose*(color1, color2: Color, epsilon = 1e-5): bool =

    ## Determines if two colors are equal (to use with floating points)

    return areClose(color1.r, color2.r, epsilon) and areClose(color1.g,
            color2.g, epsilon) and areClose(color1.b, color2.b, epsilon)


proc luminosity*(color: Color): float32 =

    ## Determines the luminosity of a given color

    result = (max(color.r, max(color.g, color.b)) + min(color.r, min(color.g, color.b)))/2
