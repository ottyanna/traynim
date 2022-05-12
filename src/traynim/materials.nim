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

from geometry import Normal, Vec, Vec2d
from colors import Color
from math import floor
from hdrimages import HDRimage, getPixel

type 
    BRDF = ref object of RootObj
        ## A generic BRDF
     
method eval*(brdf: BRDF, normal: Normal, inDir: Vec, outDir: Vec, uv: Vec2d): Color {.base.}=
    ## Abstract method to override
    quit "to override"

type
    Pigment* = ref object of RootObj
        ## A "pigment".
        ## This abstract class represents a pigment, 
        ## i.e., a function that associates a color with
        ## each point on a parametric surface (u,v). 
        ## Call the method Pigment.getColor` to
        ## obtain the color of the surface given a `Vec2d` object.

method getColor*(pigment: Pigment, vec2d: Vec2d) : Color {.base}=
    ## Returns the color of the pigment at the specified coordinates
    quit "to override!" # vec2d is a genric point on the abstract surface of the pigment

type
    UniformPigment* = ref object of Pigment
        ## A "pigment" of one chosen color.
        ## Initialise with `Pigment.newUniformPigment`.
        color: Color

proc newUniformPigment*(color: Color) : UniformPigment =
    result.color = color

method getColor*(pigment: UniformPigment, vec2d: Vec2d) : Color =
    ## Returns the color of the pigment at the specified coordinates
    return pigment.color

type
    CheckeredPigment* = ref object of Pigment
        ## A checkered pigment.
        ## The number of rows/columns in the checkered pattern is tunable, 
        ## but you cannot have a different number of repetitions along the u/v directions.
        color1, color2: Color
        stepsNum : int #how many squares of color you have in the "checkered image",
                       #so you can have bigger squares by setting a low stepNum,
                       #or fewer squares by setting a high stepNum value.

proc newCheckeredPigment*(color1, color2: Color, stepsNum = 10) : CheckeredPigment =
    
    result.color1 = color1
    result.color2 = color2
    result.stepsNum = stepsNum

method getColor*(pigment: CheckeredPigment, vec2d: Vec2d) : Color =
    ## Returns the color of the pigment at the specified coordinates
    let intU = int(floor(vec2d.u * pigment.stepsNum.float))
    let intV = int(floor(vec2d.v * pigment.stepsNum.float))

    if (intU mod 2) == (intV mod 2): 
        return pigment.color1 
    else: 
        return pigment.color2

type
    ImagePigment* = ref object of Pigment
        ## A textured pigment.
        ## The texture is given through a PFM image.
        image : HDRimage

proc newImagePigment*(image : HdrImage) : ImagePigment =
    
    result.image = image

method getColor*(pigment: ImagePigment, vec2d: Vec2d) : Color =
        ## Returns the color of the pigment at the specified coordinates
        var col = int(vec2d.u * pigment.image.width.float)
        var row = int(vec2d.v * pigment.image.height.float)

        if col >= pigment.image.width:
            col = pigment.image.width - 1

        if row >= pigment.image.height:
            row = pigment.image.height - 1

        # A nicer solution would implement bilinear interpolation to reduce pixelization artifacts
        # See https://en.wikipedia.org/wiki/Bilinear_interpolation
        return pigment.image.getPixel(col, row)