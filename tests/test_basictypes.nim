#encoding: utf-8

import ../src/basictypes
import unittest,streams,typetraits

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
    

    # This is the content of "reference_le.pfm" (little-endian file)
    var leReferenceBytes = @[
        0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x2d, 0x31, 0x2e, 0x30, 0x0a,
        0x00, 0x00, 0xc8, 0x42, 0x00, 0x00, 0x48, 0x43, 0x00, 0x00, 0x96, 0x43,
        0x00, 0x00, 0xc8, 0x43, 0x00, 0x00, 0xfa, 0x43, 0x00, 0x00, 0x16, 0x44,
        0x00, 0x00, 0x2f, 0x44, 0x00, 0x00, 0x48, 0x44, 0x00, 0x00, 0x61, 0x44,
        0x00, 0x00, 0x20, 0x41, 0x00, 0x00, 0xa0, 0x41, 0x00, 0x00, 0xf0, 0x41,
        0x00, 0x00, 0x20, 0x42, 0x00, 0x00, 0x48, 0x42, 0x00, 0x00, 0x70, 0x42,
        0x00, 0x00, 0x8c, 0x42, 0x00, 0x00, 0xa0, 0x42, 0x00, 0x00, 0xb4, 0x42]

    # This is the content of "reference_be.pfm" (big-endian file)
    var beReferenceBytes = @[
        0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x31, 0x2e, 0x30, 0x0a, 0x42,
        0xc8, 0x00, 0x00, 0x43, 0x48, 0x00, 0x00, 0x43, 0x96, 0x00, 0x00, 0x43,
        0xc8, 0x00, 0x00, 0x43, 0xfa, 0x00, 0x00, 0x44, 0x16, 0x00, 0x00, 0x44,
        0x2f, 0x00, 0x00, 0x44, 0x48, 0x00, 0x00, 0x44, 0x61, 0x00, 0x00, 0x41,
        0x20, 0x00, 0x00, 0x41, 0xa0, 0x00, 0x00, 0x41, 0xf0, 0x00, 0x00, 0x42,
        0x20, 0x00, 0x00, 0x42, 0x48, 0x00, 0x00, 0x42, 0x70, 0x00, 0x00, 0x42,
        0x8c, 0x00, 0x00, 0x42, 0xa0, 0x00, 0x00, 0x42, 0xb4, 0x00, 0x00, 0x0a]    

    let strm = newFileStream("tests/HdrImageReferences/reference_be.pfm", fmRead)
    let imge = readPfmImage(strm)
    
    assert imge.width == 3
    assert imge.height == 2

    assert imge.getPixel(0, 0).areColorsClose(Color(r: 1.0e1,g: 2.0e1, b: 3.0e1))
    #[assert imge.get_pixel(1, 0).areColorsClose(Color(4.0e1, 5.0e1, 6.0e1))
    assert imge.get_pixel(2, 0).is_close(Color(7.0e1, 8.0e1, 9.0e1))
    assert imge.get_pixel(0, 1).is_close(Color(1.0e2, 2.0e2, 3.0e2))
    assert imge.get_pixel(0, 0).is_close(Color(1.0e1, 2.0e1, 3.0e1))
    assert imge.get_pixel(1, 1).is_close(Color(4.0e2, 5.0e2, 6.0e2))
    assert imge.get_pixel(2, 1).is_close(Color(7.0e2, 8.0e2, 9.0e2))
]#

    