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


## This module implements operations on geometry types,
## such as `Point`, `Vec`, `Normal`.

import common
from math import sqrt, copySign

type
    Point* = object ## A point in 3d space with three floating-point fields: `x`, `y`, and `z`
        x*, y*, z*: float64

    Vec* = object ## A 3d vector with three floating-point fields: `x`, `y`, and `z`
        x*, y*, z*: float64

    Normal* = object ## A 3d normal vector with three floating-point fields: `x`, `y`, and `z`
        x*, y*, z*: float64


template defineNew3dObj(fname: untyped, rettype: typedesc) =
    proc fname*(a, b, c: float64): rettype =

        ## Creates a new 3d object of type `Vec`, `Point` and `Normal`

        result.x = a
        result.y = b
        result.z = c

defineNew3dObj(newVec, Vec)
defineNew3dObj(newPoint, Point)
defineNew3dObj(newNormal, Normal)

const vecX* = Vec(x: 1.0, y: 0.0, z: 0.0)
const vecY* = Vec(x: 0.0, y: 1.0, z: 0.0)
const vecZ* = Vec(x: 0.0, y: 0.0, z: 1.0)

template define3dOp(fname: untyped, type1: typedesc, type2: typedesc,
        rettype: typedesc) =
    proc fname*(a: type1, b: type2): rettype =

        ## Implements operations such as sum(`+`) and diff(`-`) on 3d objects

        result.x = fname(a.x, b.x)
        result.y = fname(a.y, b.y)
        result.z = fname(a.z, b.z)

define3dOp(`+`, Vec, Vec, Vec)
define3dOp(`-`, Vec, Vec, Vec)
define3dOp(`+`, Vec, Point, Point)
define3dOp(`+`, Point, Vec, Point)
define3dOp(`-`, Point, Vec, Point)
define3dOp(`+`, Normal, Normal, Normal)
define3dOp(`-`, Normal, Normal, Normal)

template defineDotProd(type1: typedesc, type2: typedesc) =
    proc `dot`*(a: type1, b: type2): float64 =

        ## Implements scalar product operation on 3d objects such as `Vec` and `Normal`

        result = (a.x * b.x + a.y * b.y + a.z * b.z)


defineDotProd(Vec, Vec)
defineDotProd(Vec, Normal)

template defineOuterProd(type1: typedesc, type2: typedesc, rettype: typedesc) =
    proc cross*(a: type1, b: type2): rettype =

        ## Implements outer product operation on 3d objects such as `Vec` and `Normal`

        result.x = a.y * b.z - a.z * b.y
        result.y = a.z * b.x - a.x * b.z
        result.z = a.x * b.y - a.y * b.x


defineOuterProd(Vec, Vec, Vec)
defineOuterProd(Normal, Normal, Vec)
defineOuterProd(Normal, Vec, Vec)


template defineProdScalar3dObj(rettype: typedesc) =
    proc `*`*(scalar: float64, a: rettype): rettype =

        ## Implements scalar product with a 3d objects such as `Vec` and `Normal` operation

        result.x = scalar * a.x
        result.y = scalar * a.y
        result.z = scalar * a.z

defineProdScalar3dObj(Vec)
defineProdScalar3dObj(Normal)

template defineProd3dObjScalar(rettype: typedesc) =
    proc `*`*(a: rettype, scalar: float64): rettype =

        ## Implements scalar product with a 3d objects such as `Vec` and `Normal` operation

        result.x = scalar * a.x
        result.y = scalar * a.y
        result.z = scalar * a.z

defineProd3dObjScalar(Vec)
defineProd3dObjScalar(Normal)


template defineMirrorOp(rettype: typedesc) =
    proc `-`*(a: rettype): rettype =

        ## Returns the reversed vector

        result.x = -a.x
        result.y = -a.y
        result.z = -a.z

defineMirrorOp(Vec)
defineMirrorOp(Normal)


template definePrint3dObj(type1: typedesc) =
    proc `$`*(a: type1): string =

        ## Parse a 3D obj as a string

        result = "<" & "x: " & $(a.x) & " , " & "y: " & $(a.y) & ", " &
            "z: " & $(a.z) & ">"

definePrint3dObj(Vec)
definePrint3dObj(Point)
definePrint3dObj(Normal)

template defineAreClose3dObj(type1: typedesc) =
    proc areClose*(a, b: type1, epsilon = 1e-5): bool =

        ## Determines if two 3d objects are equal (to use with floating points)

        return areClose(a.x, b.x, epsilon) and areClose(a.y, b.y, epsilon) and
                areClose(a.z, b.z, epsilon)

defineAreClose3dObj(Vec)
defineAreClose3dObj(Point)
defineAreClose3dObj(Normal)

template define3dOpParsing(fname: untyped, type1: typedesc, rettype: typedesc) =
    proc fname*(a: type1): rettype =

        ## Convertion between 3d objects

        result.x = a.x
        result.y = a.y
        result.z = a.z

define3dOpParsing(parsePointToVec, Point, Vec)
define3dOpParsing(parseNormalToVec, Normal, Vec)
define3dOpParsing(parseVecToNormal, Vec, Normal)

template defineSqrNorm(type1: typedesc) =
    proc sqrNorm*(a: type1): float64 =

        ## Quick 3d Vector/Normal square norm

        result = a.x * a.x + a.y * a.y + a.z * a.z

defineSqrNorm(Vec)
defineSqrNorm(Normal)

template defineNorm(type1: typedesc) =
    proc norm*(a: type1): float64 =

        ## A 3d Vector/Normal norm calculator

        result = sqrt(a.sqrNorm())

defineNorm(Vec)
defineNorm(Normal)

template defineNormalize(type1) =
    proc normalize*(a: type1): type1 =

        ## A 3d Vector/Normal normalize procedure

        result.x = a.x / a.norm()
        result.y = a.y / a.norm()
        result.z = a.z / a.norm()

defineNormalize(Vec)
defineNormalize(Normal)


type
    Vec2d* = object

        ## A 2D vector used to represent a point on a surface
        ## The fields are named `u` and `v` to distinguish them
        ## from the usual 3D coordinates `x`, `y`, `z`.

        u*, v*: float64

proc newVec2d*(u, v: float64): Vec2d =

    ## Creates a new `Vec2d` with paramether u and v

    result.u = u
    result.v = v

proc areClose*(a, b: Vec2d, epsilon = 1e-5): bool =

    ## Determines whether 2D objects are equal or not (Floating point use only!!!)

    return (areClose(a.u, b.u, epsilon)) and (areClose(a.v, b.v, epsilon))


type 
    ONB* = object
        e1*, e2*, e3* : Vec


proc createONBfromZ*(normal: Vec or Normal): ONB =
    let sign = copySign(1.0, normal.z)
    let a = -1.0 / (sign + normal.z)
    let b = normal.x * normal.y * a

    let e1 = newVec(1.0 + sign * normal.x * normal.x * a, sign * b, -sign * normal.x)
    let e2 = newVec(b, sign + normal.y * normal.y * a, -normal.y)

    result.e1 = e1
    result.e2 = e2
    result.e3 = newVec(normal.x, normal.y, normal.z)
    
    
