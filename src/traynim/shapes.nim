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

import transformations, ray, geometry, options, hitRecord

type
    Vec2d* = object
        u*,v* : float64

type 
    Shape* = ref object of RootObj

        transformation*: Transformation

method rayIntersection(s: Shape, ray: Ray): Option[HitRecord] {.base.} =
    quit "Shape.ray_intersection is an abstract method and cannot be called directly"



    