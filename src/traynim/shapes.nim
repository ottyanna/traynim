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


import transformations, ray, options, hitRecord, geometry
from math import sqrt, arctan2, arccos, PI

type
    Shape* = ref object of RootObj

        transformation* : Transformation

    
    

type
    Sphere* = ref object of Shape

method rayIntersection*(s: Shape, ray: Ray): Option[HitRecord] {.base.} =
    quit "Shape.rayIntersection is an abstract method and cannot be called directly"


proc newSphere*(transformation = newTransformation()): Sphere =
    
    new(result)
    result.transformation = transformation

proc spherePointToUV*(p: Point): Vec2d =
    
    let u = arctan2(p.y, p.x) / (2.0 * PI)

    if u >= 0.0:
        result.u = u
    else:
        result.u = u * 1.0
    
    result.v = arccos(p.z) / PI

proc sphereNormal*(p: Point, rayDir: Vec): Normal = 

    if (p.parsePointToVec().dot(rayDir) < 0.0):
        result = newNormal(p.x, p.y, p.z)
    else:
        result = - newNormal(p.x, p.y, p.z)    


method rayIntersection*(sphere: Sphere, ray: Ray): HitRecord or Option[HitRecord] =
    
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
    var firstHitT : float64

    if (tmin > invRay.tmin) and (tmin < invRay.tmax):
        firstHitT = tmin
    elif (tmax > inv_ray.tmin) and (tmax < inv_ray.tmax):
        firstHitT = tmax
    else:
        return none(HitRecord)

    let hitPoint = invRay.at(firstHitT)

    return HitRecord(
                    worldpoint: sphere.transformation * hitPoint, 
                    normal: sphere.transformation * sphereNormal(hitPoint, invRay.dir), 
                    surfacePoint: spherePointToUV(hitPoint), 
                    t: firstHitT, 
                    ray: ray)




