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



import ../src/traynim/geometry
import ../src/traynim/common
import ../src/traynim/transformations

proc testCreation (a: Vec) =
    assert areClose(a.x, 1.0)
    assert not areClose(a.y, 5.0)
    assert areClose(a.z, 3.0)

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


proc testIsClose (m,invm: Matrix4x4) =

    let t1 = newTransformation(m,invm)

    assert (t1.m == m)
    assert (t1.invm == invm)
    assert t1.isConsistent

    let t2 = newTransformation(m,invm)
    assert t1.areTranClose(t2)

    var t3 = newTransformation(m,invm)
    t3.m[2][2] += 1.0
    assert not t3.isConsistent
    assert not t3.areTranClose(t2)

    var t4 = newTransformation(m,invm)
    t4.invm[2][3] += 1.0
    assert not t4.areTranClose(t1)

proc testInverse() =
    let m1 = newTransformation(m=[
                [1.0, 2.0, 3.0, 4.0],
                [5.0, 6.0, 7.0, 8.0],
                [9.0, 9.0, 8.0, 7.0],
                [6.0, 5.0, 4.0, 1.0],
            ],
            invm=[
                [-3.75, 2.75, -1, 0],
                [4.375, -3.875, 2.0, -0.5],
                [0.5, 0.5, -1.0, 1.0],
                [-1.375, 0.875, 0.0, -0.5],
            ])
    let m2 = m1.inverse()
    assert m2.isConsistent()

    let prod = m1 * m2
    assert prod.isConsistent()
    assert areTranClose(prod, newTransformation())
    


proc testMultiplication (m, invm : Matrix4x4) =

    let m1= [[3.0, 5.0, 2.0, 4.0],
             [4.0, 1.0, 0.0, 5.0],
             [6.0, 3.0, 2.0, 0.0],
             [1.0, 4.0, 2.0, 1.0]]

    let invm1= [
                [0.4, -0.2, 0.2, -0.6],
                [2.9, -1.7, 0.2, -3.1],
                [-5.55, 3.15, -0.4, 6.45],
                [-0.9, 0.7, -0.2, 1.1],]

    let t = newTransformation(m,invm)
    let t1 = newTransformation(m1,invm1)

    assert t1.isConsistent()

    let expected = newTransformation(
            [
                [33.0, 32.0, 16.0, 18.0],
                [89.0, 84.0, 40.0, 58.0],
                [118.0, 106.0, 48.0, 88.0],
                [63.0, 51.0, 22.0, 50.0],
            ],
            [
                [-1.45, 1.45, -1.0, 0.6],
                [-13.95, 11.95, -6.5, 2.6],
                [25.525, -22.025, 12.25, -5.2],
                [4.825, -4.325, 2.5, -1.1],
            ],)

    assert expected.isConsistent()

    assert expected.areTranClose(t*t1)

proc testRotations() = 
    assert rotationX(0.1).isConsistent()
    assert rotationY(0.1).isConsistent()
    assert rotationZ(0.1).isConsistent()

    let vX = newVec(1.0, 0.0, 0.0)
    let vY = newVec(0.0, 1.0, 0.0)
    let vZ = newVec(0.0, 0.0, 1.0)

    assert (rotationX(theta = 90) * vY).areClose(vZ)
    assert (rotationY(theta = 90) * vZ).areClose(vX)
    assert (rotationZ(theta = 90) * vX).areClose(vY)



proc testVecPointMultiplication()=
    let mPoint = newTransformation(
            m=[
                [1.0, 2.0, 3.0, 4.0],
                [5.0, 6.0, 7.0, 8.0],
                [9.0, 9.0, 8.0, 7.0],
                [0.0, 0.0, 0.0, 1.0],
            ],invm=[
                [-3.75, 2.75, -1, 0],
                [5.75, -4.75, 2.0, 1.0],
                [-2.25, 2.25, -1.0, -2.0],
                [0.0, 0.0, 0.0, 1.0],
            ])
    assert mPoint.isConsistent()

    let vExpected = newVec(14.0, 38.0, 51.0)
    assert areClose(vExpected, mPoint * newVec(1.0, 2.0, 3.0))

    let pExpected = newPoint(18.0, 46.0, 58.0)
    assert areClose(pExpected, mPoint * newPoint(1.0, 2.0, 3.0))

    let nExpected = newNormal(-8.75, 7.75, -3.0)
    assert areClose(nExpected, mPoint * newNormal(3.0, 2.0, 4.0))


proc testTranslations() =

    let tr1 = translation(newVec(1.0, 2.0, 3.0))
    assert tr1.isConsistent()
    let tr2 = translation(newVec(4.0, 6.0, 8.0))
    assert tr1.is_consistent()
    let prod = tr1 * tr2
    assert prod.is_consistent()
    let expected = translation(newVec(5.0, 8.0, 11.0))
    assert prod.areTranClose(expected)

proc testScalings()=
    
    let tr1 = scaling(newVec(2.0, 5.0, 10.0))
    assert tr1.isConsistent()

    let tr2 = scaling(newVec(3.0, 2.0, 4.0))
    assert tr2.isConsistent()

    let expected = scaling(newVec(6.0, 10.0, 40.0))
    assert expected.areTranClose(tr1 * tr2)


when isMainModule:

    var a = newVec(1.0, 2.0, 3.0)
    var b = newVec(4.0, 6.0, 8.0)

    testCreation(a)
    testVecOperations(a, b)
        
    let m = [
                [1.0, 2.0, 3.0, 4.0],
                [5.0, 6.0, 7.0, 8.0],
                [9.0, 9.0, 8.0, 7.0],
                [6.0, 5.0, 4.0, 1.0],
            ]

    let invm = [
                [-3.75, 2.75, -1, 0],
                [4.375, -3.875, 2.0, -0.5],
                [0.5, 0.5, -1.0, 1.0],
                [-1.375, 0.875, 0.0, -0.5],
               ]

    testIsClose(m,invm)
    testMultiplication(m,invm)
    testVecPointMultiplication()
    testInverse()
    testRotations()
    testTranslations()
    testScalings()

