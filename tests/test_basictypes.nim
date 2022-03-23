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

import ../src/basictypes
import unittest, streams

when isMainModule:

    #tests on colors operations
    let col1 = Color(r: 1.0, g: 2.0, b: 3.0)
    let col2 = Color(r: 5.0, g: 7.0, b: 9.0)

    assert (col1 + col2).areColorsClose(Color(r: 6.0, g: 9.0, b: 12.0))
    assert (col1 - col2).areColorsClose(Color(r: -4.0, g: -5.0, b: -6.0))
    assert (col1 * col2).areColorsClose(Color(r: 5.0, g: 14.0, b: 27.0))
    assert not (col1 + col2).areColorsClose(Color(r: 3.0, g: 9.0, b: 12.0))

    var img = newHDRImage(7, 4)

    #test on HDRimage
    assert img.width == 7
    assert img.height == 4
    #assert not img.width == 27

    #test for coordinates
    assert img.validCoordinates(0, 0)
    assert img.validCoordinates(6, 3)
    assert not img.validCoordinates(-1, 0)
    assert not img.validCoordinates(0, -1)
    assert not img.validCoordinates(7, 0)
    assert not img.validCoordinates(0, 4)

    #test on pixel offset
    assert (img.pixelOffset(0, 0) == 0)
    assert (img.pixelOffset(3, 2) == 17)
    assert (img.pixelOffset(6, 3) == 7 * 4 - 1)

    #test on set pixel
    let referenceColor = Color(r: 1.0, g: 2.0, b: 3.0)
    img.setPixel(3, 2, referenceColor)
    assert areColorsClose(referenceColor, img.getPixel(3, 2))
    #test on color print
    assert ($referenceColor) == "<r: 1.0 , g: 2.0, b: 3.0>"

    #test on ParseImgSize
    assert parseImgSize("3 2") == (3, 2)
    #expect IOError: #I expect this to fail because it's the wrong type of error
    expect InvalidPfmFileFormat:
        discard parseImgSize("-1 3")
        discard parseImgSize("1 2 3")

    #test on ParseEndianness
    assert parseEndianness("1.0") == bigEndian
    assert parseEndianness("-1.0") == littleEndian
    expect InvalidPfmFileFormat:
        discard parseEndianness("2.0")
        discard parseEndianness("abc")

    let strm = newFileStream("tests/HdrImageReferences/reference_be.pfm", fmRead)
    let imge = readPfmImage(strm)

    assert imge.width == 3
    assert imge.height == 2

    assert imge.getPixel(0, 0).areColorsClose(Color(r: 1.0e1, g: 2.0e1, b: 3.0e1))


    img = newHdrImage(3, 2)
    img.setPixel(0, 0, newColor(1.0e1, 2.0e1, 3.0e1))
    img.setPixel(1, 0, newColor(4.0e1, 5.0e1, 6.0e1))
    img.setPixel(2, 0, newColor(7.0e1, 8.0e1, 9.0e1))
    img.setPixel(0, 1, newColor(1.0e2, 2.0e2, 3.0e2))
    img.setPixel(1, 1, newColor(4.0e2, 5.0e2, 6.0e2))
    img.setPixel(2, 1, newColor(7.0e2, 8.0e2, 9.0e2))

    var leBuf = newStringStream("")

    img.writePfmImage(leBuf, endianness = littleEndian)
    leBuf.setPosition(0)
    assert leBuf.readPfmImage == img

    var beBuf = newStringStream("")

    img.writePfmImage(beBuf, endianness = bigEndian)
    beBuf.setPosition(0)
    assert beBuf.readPfmImage == img