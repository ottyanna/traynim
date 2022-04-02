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


import ../src/traynim/geometry
import ../src/traynim/common
import ../src/traynim/transformations

template test3dObjCreation(type1: typedesc) =

    proc testCreation (a: type1) =
        assert areClose(a.x, 1.0)
        assert not areClose(a.y, 5.0)
        assert areClose(a.z, 3.0)

test3dObjCreation(Vec)
test3dObjCreation(Point)
test3dObjCreation(Normal)

proc testVecOperations (a, b: Vec) =
    assert not (($b) == "<x: 1.0 , y: 2.0, z: 3.0>")
    assert ($a) == "<x: 1.0 , y: 2.0, z: 3.0>"
    assert (-a).areClose(newVec(-1.0, -2.0, -3.0))
    assert (a + b).areClose(newVec(5.0, 8.0, 11.0))
    assert (b - a).areClose(newVec(3.0, 4.0, 5.0))
    assert (2 * a).areClose(newVec(2.0, 4.0, 6.0))
    assert (a * 2).areClose(newVec(2.0, 4.0, 6.0))
    assert (a.dot(b)).areClose(40.0)
    assert a.cross(b).areClose(newVec(-2.0, 4.0, -2.0))
    assert b.cross(a).areClose(newVec(2.0, -4.0, 2.0))
    assert b.parseVecToNormal == newNormal(4.0, 6.0, 8.0)
    assert areClose(a.sqrNorm(), 14.0)
    assert areClose(a.norm()*a.norm(), 14.0)


when isMainModule:

    var a = newVec(1.0, 2.0, 3.0)
    var b = newVec(4.0, 6.0, 8.0)

    testCreation(a)
    testVecOperations(a, b)

    var c = newPoint(1.0, 2.0, 3.0)
    var d = newPoint(4.0, 6.0, 8.0)

    testCreation(c)

    var e = newNormal(1.0, 2.0, 3.0)
    var f = newNormal(4.0, 6.0, 8.0)

    testCreation(e)

    var m : Matrix4x4 =[[1.0, 0.0, 0.0, 0.0],
                        [0.0, 1.0, 0.0, 0.0],
                        [0.0, 0.0, 1.0, 0.0],
                        [0.0, 0.0, 0.0, 1.0]]

    var n : Matrix4x4 =[[1.0, 0.0, 0.0, 0.0],
                        [0.0, 1.0, 0.0, 0.0],
                        [0.0, 0.0, 1.0, 0.0],
                        [0.0, 0.0, 0.0, 1.0]]

    #echo matrixProd(m,n)
    #echo areMatrClose(m,n)

