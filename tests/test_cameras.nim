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


import ../src/traynim/cameras
import ../src/traynim/common
import ../src/traynim/geometry
import ../src/traynim/ray
import ../src/traynim/transformations

proc testOrthogonalCamera() =

    let cam = newOrthogonalCamera(aspectRatio = 2.0)
    let ray1 = cam.fireRay(0.0, 0.0)
    let ray2 = cam.fireRay(1.0, 0.0)
    let ray3 = cam.fireRay(0.0, 1.0)
    let ray4 = cam.fireRay(1.0, 1.0)

    # Verify that the rays are parallel by verifying that cross-products vanish
    assert areClose(0.0, ray1.dir.cross(ray2.dir).sqrNorm())
    assert areClose(0.0, ray1.dir.cross(ray3.dir).sqrNorm())
    assert areClose(0.0, ray1.dir.cross(ray4.dir).sqrNorm())

    # Verify that the ray hitting the corners have the right coordinates

    assert ray1.at(1.0).areClose(newPoint(0.0, 2.0, -1.0))
    assert ray2.at(1.0).areClose(newPoint(0.0, -2.0, -1.0))
    assert ray3.at(1.0).areClose(newPoint(0.0, 2.0, 1.0))
    assert ray4.at(1.0).areClose(newPoint(0.0, -2.0, 1.0))

proc testIsClose() =
    let ray1 = newRay(origin = newPoint(1.0, 2.0, 3.0), dir = newVec(5.0, 4.0, -1.0))
    let ray2 = newRay(origin = newPoint(1.0, 2.0, 3.0), dir = newVec(5.0, 4.0, -1.0))
    let ray3 = newRay(origin = newPoint(5.0, 2.0, 4.0), dir = newVec(3.0, 9.0, 4.0))

    assert ray1.isClose(ray2)
    assert not ray1.isClose(ray3)

proc testAt() =
    let ray = newRay(origin = newPoint(1.0, 2.0, 4.0), dir = newVec(4.0, 2.0, 1.0))
    assert ray.at(0.0).areClose(ray.origin)
    assert ray.at(1.0).areClose(newPoint(5.0, 4.0, 5.0))
    assert ray.at(2.0).areClose(newPoint(9.0, 6.0, 6.0))

proc testTranform() =
    let ray = newRay(newPoint(1.0, 2.0, 3.0), newVec(6.0, 5.0, 4.0))
    let transformation = translation(newVec(10.0, 11.0, 12.0)) * rotationX(90.0)
    let transformed = ray.transform(transformation)

    assert transformed.origin.areclose(newPoint(11.0, 8.0, 14.0))
    assert transformed.dir.areclose(newVec(6.0, -4.0, 5.0))

proc testOrthogonalCameraTransform() =

    let cam = newOrthogonalCamera(transformation = translation(-2.0 * newVec(
            0.0, 1.0, 0.0)) * rotationY(theta = 90))
    let ray = cam.fireRay(0.5, 0.5)

    assert ray.at(1.0).areClose(newPoint(0.0, -2.0, 0.0))






when isMainModule:
    testIsClose()
    testAt()
    testTranform()
    testOrthogonalCamera()
    testOrthogonalCameraTransform()
