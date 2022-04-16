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


## This module implements operation on Ray type

import geometry, transformations

type Ray* = object
    origin*: Point
    dir*: Vec
    tmin*: float64
    tmax*: float64
    depth*: int

proc newRay*(origin: Point, dir: Vec, tmin = 1e5, tmax = Inf, depth = 0): Ray =
    result.origin = origin
    result.dir = dir
    result.tmin = tmin
    result.depth = depth

proc areClose*(a, b: Ray, epsilon = 1e-5): bool =
    result = (a.origin.areClose(b.origin, epsilon)) and (
            a.dir.areClose(b.dir, epsilon))

proc at*(ray: Ray, t: float64): Point =
    result = ray.origin + ray.dir * t

proc transform*(ray: Ray, transformation: Transformation): Ray=
        result.origin=transformation * ray.origin
        result.dir=transformation * ray.dir
        result.tmin=ray.tmin
        result.tmax=ray.tmax
        result.depth=ray.depth