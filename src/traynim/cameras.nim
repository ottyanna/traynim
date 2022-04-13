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

import transformations
import ray
import geometry

type 
    Camera* = ref object of RootObj
        aspectRatio* : float64
        transformation* : Transformation

type 
    OrthogonalCamera* = ref object of Camera

type 
    PerspectiveCamera* = ref object of Camera
        distance* : float64

method fireRay*(c: var Camera) {.base.} =
    quit "to override!"

method newCamera*(c: var Camera) {.base.} =
    quit "to override!"

method newCamera*(c : var PerspectiveCamera, distance = 1.0, aspectRatio = 1.0, transformation = Transformation()) =
        c.distance = distance
        c.aspectRatio = aspectRatio
        c.transformation = transformation

method newCamera*(c : var OrthogonalCamera, aspectRatio = 1.0, transformation = Transformation()) =
        c.aspectRatio = aspectRatio
        c.transformation = transformation


method fireRay*(c: PerspectiveCamera, u: float64, v: float64) : Ray =
    result.origin = newPoint(-c.distance,0.0,0.0)
    result.dir = newVec(c.distance, (1.0 - 2 * u) * c.aspect_ratio, 2*v - 1)
    result.tmin=1.0
    return result.transform(c.transformation)

method fireRay*(c: OrthogonalCamera, u: float64, v: float64) : Ray =
    result.origin = newPoint(-1.0,(1.0 - 2 * u) * c.aspectRatio, 2 * v - 1)
    result.dir = vecX
    result.tmin=1.0
    return result.transform(c.transformation)