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

import unittest, streams
import 
    traynim/colors,
    traynim/hdrimages,
    traynim/common


# Tests on Colors.nim procedures

proc testColorOperations(col1, col2: Color) =
    assert (col1 + col2).areColorsClose(Color(r: 6.0, g: 9.0, b: 12.0))
    assert (col1 - col2).areColorsClose(Color(r: -4.0, g: -5.0, b: -6.0))
    assert (col1 * col2).areColorsClose(Color(r: 5.0, g: 14.0, b: 27.0))
    assert not (col1 + col2).areColorsClose(Color(r: 3.0, g: 9.0, b: 12.0))
    assert ($col1) == "<r: 1.0 , g: 2.0, b: 3.0>" #test on Color print

proc testLuminosity(color1, color2: Color) =
    assert areClose(luminosity(color1), 2.0)
    assert areClose(luminosity(color2), 7.0)


# Tests on HdrImages.nim procedures

proc testImageCreation(img: HdrImage) =
    assert img.width == 7
    assert img.height == 4
    assert not (img.width == 27)

proc testPixelOffset(img: HdrImage) =
    assert (img.pixelOffset(0, 0) == 0)
    assert (img.pixelOffset(3, 2) == 17)
    assert (img.pixelOffset(6, 3) == 7 * 4 - 1)

proc testSetPixel(img: var HdrImage, referenceColor: Color) =
    img.setPixel(3, 2, referenceColor)
    assert areColorsClose(referenceColor, img.getPixel(3, 2))

proc testCoordinates(img: HdrImage) =
    assert img.validCoordinates(0, 0)
    assert img.validCoordinates(6, 3)
    assert not img.validCoordinates(-1, 0)
    assert not img.validCoordinates(0, -1)
    assert not img.validCoordinates(7, 0)
    assert not img.validCoordinates(0, 4)


proc testParseImgSize() =
    assert parseImgSize("3 2") == (3, 2)
    expect InvalidPfmFileFormat:
        discard parseImgSize("-1 3")
        discard parseImgSize("1 2 3")

proc testParseEndianness() =
    assert parseEndianness("1.0") == bigEndian
    assert parseEndianness("-1.0") == littleEndian
    expect InvalidPfmFileFormat:
        discard parseEndianness("2.0")
        discard parseEndianness("abc")

proc testReadPfm() =
    var strm = newFileStream("tests/HdrImageReferences/reference_be.pfm", fmRead)
    let img = readPfmImage(strm)
    strm.close()

    assert img.width == 3
    assert img.height == 2

    assert img.getPixel(0, 0).areColorsClose(Color(r: 1.0e1, g: 2.0e1, b: 3.0e1))

proc integrationTestReadWritePfmImage() =
    var img = newHdrImage(3, 2)
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


proc testAverageLuminosity(img: HdrImage) =
    assert areClose(img.averageLuminosity(delta = 0.0), 100.0)
    assert img.averageLuminosity(delta = 0.0) == 100.0

proc testNormalizeImageWithArgs(img: var HdrImage) =
    normalizeImage(img, 1000.0, 100.0)
    assert areColorsClose(img.getPixel(0, 0), newColor(0.5e2, 1.0e2, 1.5e2))
    assert areColorsClose(img.getPixel(1, 0), newColor(0.5e4, 1.0e4, 1.5e4))

proc testNormalizeImageWithoutArgs(img: var HdrImage) =
    normalizeImage(img, 1000.0)
    assert areColorsClose(img.getPixel(0, 0), newColor(0.5e2, 1.0e2, 1.5e2))
    assert areColorsClose(img.getPixel(1, 0), newColor(0.5e4, 1.0e4, 1.5e4))

proc testClampImage(img: var HdrImage) =
    img.clampImage()

    # Just test that the R/G/B values are w/i the expected boundaries
    for curPixel in img.pixels:
        assert (curPixel.r >= 0) and (curPixel.r <= 1)
        assert (curPixel.g >= 0) and (curPixel.g <= 1)
        assert (curPixel.b >= 0) and (curPixel.b <= 1)

proc testwriteLdrImage() =
    var strm = newFileStream("tests/HdrImageReferences/memorial.pfm", fmRead)
    var imgem = readPfmImage(strm)
    strm.close()
    imgem.normalizeImage(0.2)
    imgem.clampImage()
    writeLdrImage(imgem, "tests/HdrImageReferences/output.png")

when isMainModule:

    var col1 = newColor(1.0, 2.0, 3.0)
    var col2 = newColor(5.0, 7.0, 9.0)

    testColorOperations(col1, col2)

    var img = newHDRImage(7, 4)

    testImageCreation(img)
    testCoordinates(img)
    testPixelOffset(img)
    testSetPixel(img, col1)

    testparseImgSize()
    testParseEndianness()
    testReadPfm()
    integrationTestReadWritePfmImage()

    col2 = newColor(9.0, 5.0, 7.0)

    img = newHDRImage(2, 1)
    img.set_pixel(0, 0, newColor(5.0, 10.0, 15.0)) # Luminosity: 10.0
    img.set_pixel(1, 0, newColor(500.0, 1000.0, 1500.0)) # Luminosity: 1000.0

    testLuminosity(col1, col2)
    testAverageLuminosity(img)
    testNormalizeImageWithoutArgs(img)

    img.set_pixel(0, 0, newColor(5.0, 10.0, 15.0)) # Luminosity: 10.0
    img.set_pixel(1, 0, newColor(500.0, 1000.0, 1500.0)) # Luminosity: 1000.0

    testNormalizeImageWithArgs(img)
    testClampImage(img)

    testwriteLdrImage()
    