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


## This module implements transformations on geometry types,
## such as `Point`, `Vec`, `Normal`.

import common 
from geometry import Point, Vec, Normal, newPoint
from math import sin, cos, degToRad


type
    Matrix4x4* = array[4, array[4, float64]] ## 4x4 invertible real values matrix


const IdentityMatrix4x4* : Matrix4x4 =
    [[1.0, 0.0, 0.0, 0.0],
     [0.0, 1.0, 0.0, 0.0],
     [0.0, 0.0, 1.0, 0.0],
     [0.0, 0.0, 0.0, 1.0]]


proc matrixProd*(m1, m2: Matrix4x4): Matrix4x4 =

    ## Row by column matrix multiplication

    for i in 0..high(m1):
        for j in 0..high(m1):
            for k in 0..high(m1):
                result[i][j] += m1[i][k] * m2[k][j]

proc areMatrClose*(m1, m2: Matrix4x4): bool=
    
    for i in 0..high(m1):
        for j in 0..high(m1):
            if not are_close(m1[i][j], m2[i][j]):
                return false

    return true


type
    Transformation* = object ##An affine transformation.
        m*, invm*: Matrix4x4


proc newTransformation*(m = IdentityMatrix4x4, invm = IdentityMatrix4x4): Transformation =

    ## Creates a new tranformation with parameters tranformation 
    ## matrix and inverse tranformation.

    result.m = m
    result.invm = invm

proc isConsistent*(t : Transformation): bool =
        
        ## Checks the internal consistency of the transformation.
        ## This method is useful when writing tests.
        
        let prod = matrixProd(t.m, t.invm)
        return areMatrClose(prod, IdentityMatrix4x4)

proc areTranClose*(t1, t2 :Transformation):bool=
        
        #Checks if two tranformations represent the same transformation.
        
        return areMatrClose(t1.m, t2.m) and areMatrClose(t1.invm, t2.invm)

proc inverse*(t :Transformation): Transformation=
        
        ## Return a `Transformation` object representing the inverse affine transformation.
        
        return Transformation(m : t.invm, invm : t.m)


proc scaling*(v: Vec): Transformation =

    ## The parameter `v` specifies the amount of scaling to be applied along the three axes 
        
    result.m = [[v.x, 0.0, 0.0, 0.0],
     [0.0, v.y, 0.0, 0.0],
     [0.0, 0.0, v.z, 0.0],
     [0.0, 0.0, 0.0, 1.0]]

    result.invm = [[1/v.x, 0.0, 0.0, 0.0],
     [0.0, 1/v.y, 0.0, 0.0],
     [0.0, 0.0, 1/v.z, 0.0],
     [0.0, 0.0, 0.0, 1.0]]


proc traslation*(v: Vec): Transformation =

    ## The parameter `v` specifies the amount of shift to be applied along the three axes 
        
    result.m = [[1.0, 0.0, 0.0, v.x],
     [0.0, 1.0, 0.0, v.y],
     [0.0, 0.0, 1.0, v.z],
     [0.0, 0.0, 0.0, 1.0]]

    result.invm = [[1.0, 0.0, 0.0, -v.x],
     [0.0, 1.0, 0.0, -v.y],
     [0.0, 0.0, 1.0, -v.z],
     [0.0, 0.0, 0.0, 1.0]]

proc rotationX*(theta: float64): Transformation =

    ## Input angle in deg

    let (sinang, cosang) = (sin(degToRad(theta)), cos(degToRad(theta)))
    
    result.m = [[1.0, 0.0, 0.0, 0.0],
     [0.0, cosang, -sinang, 0.0],
     [0.0, sinang, cosang, 0.0],
     [0.0, 0.0, 0.0, 1.0]]

    result.m = [[1.0, 0.0, 0.0, 0.0],
     [0.0, cosang, sinang, 0.0],
     [0.0, -sinang, cosang, 0.0],
     [0.0, 0.0, 0.0, 1.0]]

proc rotationY*(theta: float64): Transformation =

    ## Input angle in deg

    let (sinang, cosang) = (sin(degToRad(theta)), cos(degToRad(theta)))
    
    result.m = [[cosang, 0.0, sinang, 0.0],
     [0.0, 1.0, 0.0, 0.0],
     [-sinang, 0.0, cosang, 0.0],
     [0.0, 0.0, 0.0, 1.0]]

    result.m = [[cosang, 0.0, -sinang, 0.0],
     [0.0, 1.0, 0.0, 0.0],
     [sinang, 0.0, cosang, 0.0],
     [0.0, 0.0, 0.0, 1.0]]

proc rotationZ*(theta: float64): Transformation =

    ## Input angle in deg

    let (sinang, cosang) = (sin(degToRad(theta)), cos(degToRad(theta)))
    
    result.m = [[cosang, -sinang, 0.0, 0.0],
     [sinang, cosang, 0.0, 0.0],
     [0.0, 0.0, 1.0, 0.0],
     [0.0, 0.0, 0.0, 1.0]]

    result.m = [[cosang, sinang, 0.0, 0.0],
     [-sinang, cosang, 0.0, 0.0],
     [0.0, 0.0, 1.0, 0.0],
     [0.0, 0.0, 0.0, 1.0]]

proc `*`*(t: Transformation, v: Vec): Vec =
    
    let (row0, row1, row2) = (t.m[0],t.m[1],t.m[2]) 

    result.x = v.x * row0[0] + v.y * row0[1] + v.z * row0[2]
    result.y = v.x * row1[0] + v.y * row1[1] + v.z * row1[2]
    result.z = v.x * row2[0] + v.y * row2[1] + v.z * row2[2]



proc `*`*(t: Transformation, n: Normal): Normal =
    let (row0, row1, row2) = (t.invm[0],t.invm[1],t.invm[2])
    
    result.x = n.x * row0[0] + n.y * row0[1] + n.z * row0[2]
    result.y = n.x * row1[0] + n.y * row1[1] + n.z * row1[2]
    result.z = n.x * row2[0] + n.y * row2[1] + n.z * row2[2]



proc `*`*(t: Transformation, p: Point): Point =
    
    
    let (row0, row1, row2, row3) = (t.m[0],t.m[1],t.m[2],t.m[3]) 
    result.x = p.x * row0[0] + p.y * row0[1] + p.z * row0[2]
    result.y = p.x * row1[0] + p.y * row1[1] + p.z * row1[2]
    result.z = p.x * row2[0] + p.y * row2[1] + p.z * row2[2]
    let w = p.x * row3[0] + p.y * row3[1] + p.z * row3[2]
    if areClose(w, 1.0):
        return result
    else:
        result = newPoint(p.x/w, p.y/w, p.z/w)


            

    
    
