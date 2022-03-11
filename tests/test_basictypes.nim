import ../src/basictypes

when isMainModule:
    let col1 = Color(r : 1.0, g: 2.0, b: 3.0)
    let col2 = Color(r : 5.0, g: 7.0, b: 9.0)
    assert col1 + col2 == Color(r: 4.0, g: 6.0, b: 8.0)