import ../src/basictypes

when isMainModule:

    #tests on colors operations
    let col1 = Color(r : 1.0, g: 2.0, b: 3.0)
    let col2 = Color(r : 5.0, g: 7.0, b: 9.0)

    assert (col1 + col2).areColorsClose(Color(r: 6.0, g: 9.0, b: 12.0))
    assert (col1 - col2).areColorsClose(Color(r: -4.0, g: -5.0, b: -6.0))
    assert (col1 * col2).areColorsClose(Color(r: 5.0, g: 14.0, b: 27.0))
    assert not (col1 + col2).areColorsClose(Color(r: 3.0, g: 9.0, b: 12.0))

    let img = newHDRImage(7,4)

    #test on HDRimage
    assert img.width == 7
    assert img.height == 4
    #assert not img.width == 27

    #test for coordinates
    assert validCoordinates(img, 0, 0)
    assert validCoordinates(img, 6, 3)
    assert not validCoordinates(img, -1, 0)
    assert not validCoordinates(img, 0, -1)
    assert not validCoordinates(img, 7, 0)
    assert not validCoordinates(img, 0, 4)

    #test on pixel offset
    assert pixelOffset(img, 0, 0) == 0
    assert pixelOffset(img, 3, 2) == 17
    assert pixelOffset(img, 6, 3) == 7 * 4 - 1
