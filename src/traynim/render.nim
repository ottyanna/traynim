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


## This module implements different algorithms for rendering

import colors, ray, world
import options

type Renderer* = ref object of RootObj
    ## generic renderer
    world*: World
    backgroundColor*: Color

method newBaseRenderer*(renderer: Renderer, world: World,
        backgroundColor = black) {.base.} =
    renderer.backgroundColor = backgroundColor
    renderer.world = world

method call*(renderer: Renderer, ray: Ray): Color {.base.} =
    quit "to override!"

type OnOffRenderer* = ref object of Renderer
    ## A on/off renderer: everything is of two colors (`backgroundColor` and `color`).
    color*: Color

proc newOnOffRenderer*(world: World, backgroundColor = black,
        color = white): OnOffRenderer =
    new(result)
    result.newBaseRenderer(world, backgroundColor)
    result.color = color

method call*(renderer: OnOffRenderer, ray: Ray): Color =
    ## Calls the image rendering where the shapes are in solid color `color`.
    if renderer.world.rayIntersection(ray).isSome:
        return renderer.color
    else: return renderer.backgroundColor


type FlatRenderer* = ref object of Renderer
    ## A «flat» renderer
    ## This renderer estimates the solution of the rendering equation by neglecting any contribution of the light.
    ## It just uses the pigment of each surface to determine how to compute the final radiance.

proc newFlatRenderer*(world: World, backgroundColor = black): FlatRenderer =
    new(result)
    result.newBaseRenderer(world, backgroundColor)


#[
method call*(renderer: FlatRenderer, ray: Ray) : Color=
        let hit = renderer.world.rayIntersection(ray)
        if hit.isNone:
            return renderer.backgroundColor

        let material = (hit.get).shape.material

        return (material.brdf.pigment.getColor((hit.get).surfacePoint) +
                material.emittedRadiance.getColor((hit.get).surfacePoint))]#
