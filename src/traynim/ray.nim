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

    ## A ray of light propagating in space.

    origin*: Point
    dir*: Vec
    tmin*: float64
    tmax*: float64
    depth*: int

proc newRay*(origin: Point, dir: Vec, tmin = 1e-5, tmax = Inf, depth = 0): Ray =

    ## Creates a new Ray object with paramethers:
    ## -   `origin` (``Point``): the 3D point where the ray originated
    ## -   `dir` (``Vec``): the 3D direction along which this ray propagates
    ## -   `tmin` (float): the minimum distance travelled by the ray is this number times `dir`
    ## -   `tmax` (float): the maximum distance travelled by the ray is this number times `dir`
    ## -   `depth` (int): number of times this ray was reflected/refracted

    result.origin = origin
    result.dir = dir
    result.tmin = tmin
    result.tmax = tmax
    result.depth = depth

proc areClose*(a, b: Ray, epsilon = 1e-5): bool =

    ## Determines if two rays are equal (to use with floating points)

    result = (a.origin.areClose(b.origin, epsilon)) and (
            a.dir.areClose(b.dir, epsilon))

proc at*(ray: Ray, t: float64): Point =

    ## Computes the point along the ray's path at some distance from the origin.
    ## Returns a ``Point`` object representing the point in 3D space whose distance from the
    ## ray's origin is equal to `t`, measured in units of the length of `dir` field.

    result = ray.origin + ray.dir * t

proc transform*(ray: Ray, transformation: Transformation): Ray =

    ## Transforms a ray.
    ## This procedure returns a new ray whose origin and direction are
    ## the transformation of the original ray.

    result.origin = transformation * ray.origin
    result.dir = transformation * ray.dir
    result.tmin = ray.tmin
    result.tmax = ray.tmax
    result.depth = ray.depth