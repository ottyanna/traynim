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


## This module contains all elements (`Shape`) in a scene (`World`)
## and their relative procedures

from ray import Ray, newRay
from hitRecord import HitRecord
from lights import PointLight
from geometry import Point, `-`, norm
import options, shapes, shapesDef

type
    World* = object

        ## An object holding a list of shapes, which makes a «world».
        ##
        ## Shapes can be added to a world using `addShape` procedure. Typically, you call
        ## `rayIntersection` to check whether a light ray intersects any
        ## of the shapes in the world.

        shapes*: seq[Shape]
        pointLights*: seq[PointLight]

proc newWorld*(): World =

    ## Inizialises World object

    result.shapes = @[]
    result.pointLights = @[]

proc addShape*(world: var World, shape: Shape) =

    ## Adds `Shape` object to inizialised `World`.
    ## Remember to inizialise `World` object with `newWorld`.

    world.shapes.add(shape)

proc addLight*(world: var World, light: PointLight) =

    ## Append a new point light to this world
    
    world.pointLights.add(light)
    

proc rayIntersection*(world: World, ray: Ray): Option[HitRecord] =

    ## Determines whether a ray intersects any of the objects in this world

    var closest = none(HitRecord) # "closest" should be a nullable type!

    for shape in world.shapes:

        var intersection: Option[HitRecord] = rayIntersection(shape, ray)

        if intersection.isNone:
            continue
        if (closest.isNone) or (intersection.get.t < closest.get.t):
            closest = intersection

    return closest

proc isPointVisible*(world: World, point: Point, observerPos: Point): bool =

    let direction = point - observerPos
    let directionNorm = direction.norm()

    let ray = newRay(origin=observerPos, dir=direction, tmin=1e-2 / directionNorm, tmax=1.0)
    for shape in world.shapes:
        if shape.quickRayIntersection(ray):
            return false
    
    return true


    

     
    
