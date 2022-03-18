#encoding: utf-8

import ../src/basictypes
import unittest

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