import ../src/basictypes

when isMainModule:

    #tests on colors operations
    let col1 = Color(r : 1.0, g: 2.0, b: 3.0)
    let col2 = Color(r : 5.0, g: 7.0, b: 9.0)

    assert (col1 + col2).areColorsClose(Color(r: 6.0, g: 9.0, b: 12.0))
    assert (col1 - col2).areColorsClose(Color(r: -4.0, g: -5.0, b: -6.0))
    assert (col1 * col2).areColorsClose(Color(r: 5.0, g: 14.0, b: 27.0))

    #test on HDRimage
    var img : HdrImage = newHDRImage(7, 4)
    assert img.width == 7
    assert img.height == 4