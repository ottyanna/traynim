type
    Color* = object
        r*, g*, b*: float32

    HdrImage* = object
        width*, height*: int
        pixels*: seq[Color]

# Implement operations on Color type
proc `+`*(color1, color2: Color): Color =
    result.r = color1.r + color2.r
    result.g = color1.g + color2.g
    result.b = color1.b + color2.b

proc `*`*(col: Color, scalar: float32): Color =
    result.r = scalar * col.r
    result.g = scalar * col.g
    result.b = scalar * col.b

proc `*`*(scalar: float32, col: Color): Color =
    result.r = scalar * col.r
    result.g = scalar * col.g
    result.b = scalar * col.b

proc `-`*(color1, color2: Color): Color =
    result.r = color1.r - color2.r
    result.g = color1.g - color2.g
    result.b = color1.b - color2.b

proc `*`*(color1, color2: Color): Color =
    result.r = color1.r * color2.r
    result.g = color1.g * color2.g
    result.b = color1.b * color2.b

# Implement "stringfy" operation for Color object
proc `$`*(color: Color): string =
    result = "<" & "r: " & $(color.r) & " , " & "g: " & $(color.g) & ", " & "b: " & $(color.b) & ">"

# Determine if two colors are equal (to use with floating points)
proc areClose*(a, b: float32, epsilon = 1e-5): bool =
    return abs(a - b) < epsilon

proc areColorsClose*(color1, color2: Color): bool =
    return areClose(color1.r, color2.r) and areClose(color1.g, color2.g) and
            areClose(color1.b, color2.b)


# Create an empty black image (the Color fields are set to 0 by default)
proc newHDRImage*(width, height: int): HdrImage =
    (result.width, result.height) = (width, height)
    result.pixels = newSeq[Color] (width*height)

# Test if the coordinates are in the right range
proc validCoordinates*(img: HdrImage, x, y: int): bool =
    result = ((x >= 0) and (x < img.width) and (y >= 0) and (y < img.height))

# Calculate indices in the array
proc pixelOffset*(img: HdrImage, x, y: int): int =
    result = y * img.width + x

# Return Color in pixel of coordinates (x,y)
proc getPixel*(img: HdrImage, x, y: int): Color =
    assert img.validCoordinates(x, y)
    result = img.pixels[img.pixelOffset(x, y)]

# Set Color in pixel of coordinates (x,y)
proc setPixel*(img: var HdrImage, x, y: int, newColor : Color) = 
    assert img.validCoordinates(x, y)
    img.pixels[img.pixelOffset(x, y)] = newColor


