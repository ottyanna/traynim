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

from ray import Ray
from hitRecord import HitRecord
import options, shapes

type
    World* = object

        ## An object holding a list of shapes, which makes a «world».
        ##
        ## Shapes can be added to a world using `addShape` procedure. Typically, you call
        ## `rayIntersection` to check whether a light ray intersects any
        ## of the shapes in the world.

        shapes*: seq[Shape]

proc newWorld*(): World =

    ## Inizialises World object

    result.shapes = @[]

proc addShape*(shape: Shape, world: var World) =

    ## Adds `Shape` object to inizialised `World`.
    ## Remember to inizialise `World` object with `newWorld`.

    world.shapes.add(shape)

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
