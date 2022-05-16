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


## This module implements shapes and their interaction with the `rays`


import transformations, ray, options, hitRecord, geometry, materials
from math import sqrt, arctan2, arccos, PI, floor

type
    Shape* = ref object of RootObj

        ## A generic 3D shape 
        ## It's an abstract object
        ## Make sure to derive *real* object from it
        
        transformation*: Transformation
        material*: Material

type
    Sphere* = ref object of Shape
    ## A 3D unit sphere centered at origin

method rayIntersection*(s: Shape, ray: Ray): Option[HitRecord] {.base.} =

    ## Computes the intersection between a ray and a shape

    quit "Shape.rayIntersection is an abstract method and cannot be called directly"


proc newSphere*(transformation = newTransformation(), material: Material = newMaterial()): Sphere =

    ## Creates a unit sphere, potentially associating a transformation to it

    new(result)
    result.transformation = transformation
    result.material = material

proc spherePointToUV*(p: Point): Vec2d =

    ## Converts a 3D point of the unit sphere into a  `(u,v)` 2D point on its surface 
    
    let u = arctan2(p.y, p.x) / (2.0 * PI)

    if u >= 0.0:
        result.u = u
    else:
        result.u = u + 1.0

    result.v = arccos(p.z) / PI

proc sphereNormal*(p: Point, rayDir: Vec): Normal =

    ## Computes the normal of the unit sphere 
    ## The normal is computed for `point` (a point of the sphere) and
    ## it is always chosen is in the opposite direction with respect 
    ## to `rayDir` 
    
    if (p.parsePointToVec().dot(rayDir) < 0.0):
        result = newNormal(p.x, p.y, p.z)
    else:
        result = - newNormal(p.x, p.y, p.z)


method rayIntersection*(sphere: Sphere, ray: Ray): Option[HitRecord] =

    ## Checks if a ray intersects the sphere.
    ## 
    ## It returns `none(HitRecord)` if no intersection was found.  

    let invRay = ray.transform(sphere.transformation.inverse())
    let originVec = invRay.origin.parsePointToVec()
    let a = invRay.dir.sqrNorm()
    let b = 2.0 * originVec.dot(invRay.dir)
    let c = originVec.sqrNorm() - 1.0

    let delta = b*b - 4.0 * a * c
    if delta <= 0.0:
        return none(HitRecord)

    let sqrtDelta = sqrt(delta)
    let tmin = (-b - sqrtDelta) / (2.0 * a)
    let tmax = (-b + sqrtDelta) / (2.0 * a)
    var firstHitT: float64

    if (tmin > invRay.tmin) and (tmin < invRay.tmax):
        firstHitT = tmin
    elif (tmax > inv_ray.tmin) and (tmax < inv_ray.tmax):
        firstHitT = tmax
    else:
        return none(HitRecord)

    let hitPoint = invRay.at(firstHitT)

    let hitRecord = newHitRecord(
                    worldpoint = sphere.transformation * hitPoint,
                    normal = sphere.transformation * sphereNormal(hitPoint,
                            invRay.dir),
                    surfacePoint = spherePointToUV(hitPoint),
                    t = firstHitT,
                    ray = ray,
                    material = sphere.material)

    return some(hitRecord)

type
    Plane* = ref object of Shape
        ## A 3D infinite plane parallel to the x and y axis and passing through the origin.

proc newPlane*(transformation = newTransformation(), material: Material = newMaterial()): Plane =

    ## Creates a xy plane, potentially associating a transformation to it

    new(result)
    result.transformation = transformation
    result.material = material

method rayIntersection*(plane: Plane, ray: Ray): Option[HitRecord] =

    ## Checks if a ray intersects the plane.
    ## 
    ## Returns a `none(HitRecord)` if no intersection was found.

    let invRay = ray.transform(plane.transformation.inverse())
    if abs(invRay.dir.z) < 1e-5:
        return none(HitRecord)

    let t = -invRay.origin.z / invRay.dir.z

    if (t <= inv_ray.tmin) or (t >= inv_ray.tmax):
        return none(HitRecord)

    let hitPoint = invRay.at(t)

    let hitRecord = newHitRecord(
        worldPoint = plane.transformation * hitPoint,
        normal = plane.transformation * newNormal(0.0, 0.0, if invRay.dir.z <
                0.0: 1.0 else: -1.0),
        surfacePoint = newVec2d(hitPoint.x - floor(hitPoint.x), hitPoint.y -
                floor(hitPoint.y)),
        t = t,
        ray = ray,
        material = plane.material
    )

    return some(hitRecord)