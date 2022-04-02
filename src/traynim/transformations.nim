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

#encoding: utf-8

## This module implements transformations on geometry types,
## such as `Point`, `Vec`, `Normal`.

import common 
from geometry import Point, Vec, Normal


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