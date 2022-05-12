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

import colors, ray, world
import options

type Renderer = ref object of RootObj
        world: World
        backgroundColor : Color

method call(renderer : Renderer, ray :Ray): Color {.base.}=
    quit "to override!"

type OnOffRenderer = ref object of Renderer
    ## A on/off renderer.
    color: Color

proc newOnOffRenderer*(world: World, backgroundColor = black, color = white): OnOffRenderer=
    new(result)
    result.backgroundColor=backgroundColor
    result.world = world
    result.color = color

method call*(renderer: OnOffRenderer, ray: Ray) : Color=

    if renderer.world.rayIntersection(ray).isSome:
        return renderer.color 
    else: return renderer.backgroundColor

#[ 
class FlatRenderer(Renderer):
    """A «flat» renderer
    This renderer estimates the solution of the rendering equation by neglecting any contribution of the light.
    It just uses the pigment of each surface to determine how to compute the final radiance."""

    def __init__(self, world: World, background_color: Color = BLACK):
        super().__init__(world, background_color)

    def __call__(self, ray: Ray) -> Color:
        hit = self.world.ray_intersection(ray)
        if not hit:
            return self.background_color

        material = hit.shape.material

        return (material.brdf.pigment.get_color(hit.surface_point) +
                material.emitted_radiance.get_color(hit.surface_point)) ]#