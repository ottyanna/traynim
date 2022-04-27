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

import geometry, ray, shapes

type 
    HitRecord* = object
    
        ## An object holding information about a ray-shape intersection.
        ## The parameters defined in this are the following:
        ## -   `worldPoint`: a `Point` object holding the world coordinates of the hit point
        ## -   `normal`: a `Normal` object holding the orientation of the normal to the surface where the hit happened
        ## -   `surfacePoint`: a `Vec2d` object holding the position of the hit point on the surface of the object
        ## -   `t`: a floating-point value specifying the distance from the origin of the ray where the hit happened
        ## -   `ray`: the ray that hit the surface
 
        worldPoint: Point
        normal: Normal
        surfacePoint: Vec2d
        t: float
        ray: Ray

proc areClose*(self, other : HitRecord, epsilon = 1e-5) : bool =

        ## Check whether two `HitRecord` represent the same hit event or not
        
        return (
                self.world_point.areClose(other.world_point) and
                self.normal.areClose(other.normal) and
                self.surfacePoint.areClose(other.surface_point) and
                (abs(self.t - other.t) < epsilon) and
                self.ray.areClose(other.ray)
        )