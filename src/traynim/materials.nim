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

import geometry
from colors import Color

type 
    BRDF = ref object of RootObj
        ## A generic BRDF
     
type
    Pigment* = ref object of RootObj

method eval*(brdf: BRDF, normal: Normal, inDir: Vec, outDir: Vec, uv: Vec2d): Color {.base.}=
    ## Abstract method to override
    quit "to override"


method getColor*(pigment: Pigment, vec2d: Vec2d) : Color {.base}=
    quit "to override!"

type
    UniformPigment* = ref object of Pigment

type
    CheckeredPigment* = ref object of Pigment

type
    ImagePigment* = ref object of Pigment
