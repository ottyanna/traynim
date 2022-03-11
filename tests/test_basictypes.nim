import ../src/basictypes

when isMainModule:
    let col1 = Color(r : 1.0, g: 2.0, b: 3.0)
    let col2 = Color(r : 5.0, g: 7.0, b: 9.0)

    #assert (col1 + col2).areColorClose(Color(6.0, 9.0, 12.0))
    #assert (col1 - col2).is_close(Color(-4.0, -5.0, -6.0))
    #assert (col1 * col2).is_close(Color(5.0, 14.0, 27.0))
    
    #Test for scalar * color
    let prodCol = Color(r: 1.0, g: 2.0, b: 3.0) * 2
    assert areColorsClose(prodCol, Color(r: 1.0, g: 2.0, b: 3.0))

    #test for coordinates
    let img = newHDRImage(7,4)
    assert validCoordinates(img, 0, 0)
    assert validCoordinates(img, 6, 3)
    assert not validCoordinates(img, -1, 0)
    assert not validCoordinates(img, 0, -1)
    assert not validCoordinates(img, 7, 0)
    assert not validCoordinates(img, 0, 4)

