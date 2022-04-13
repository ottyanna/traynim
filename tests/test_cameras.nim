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
import ../src/traynim/ray

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
    

    


when isMainModule:
    testIsClose()
    testAt()