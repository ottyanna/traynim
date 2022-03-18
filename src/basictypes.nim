#encoding: utf-8

import streams, endians, strutils

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
    result = "<" & "r: " & $(color.r) & " , " & "g: " & $(color.g) & ", " &
            "b: " & $(color.b) & ">"

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
proc setPixel*(img: var HdrImage, x, y: int, newColor: Color) =
    assert img.validCoordinates(x, y)
    img.pixels[img.pixelOffset(x, y)] = newColor


#PFM files

#proc ReadFloat*(stream : string, endianness :  ) =

type InvalidPfmFileFormat* = object of CatchableError


#Output the HDRimage size (width and height)
proc parseImgSize*(line: string): tuple =
    let elements = line.split(" ")
    type Res = tuple[width, height: int]
    var res: Res
    if elements.len != 2:
        raise newException(InvalidPfmFileFormat, "Invalid image size specification")

    try:
        res = (elements[0].parseInt, elements[1].parseInt)
        if (res.width < 0) or (res.height < 0):
            raise newException(ValueError, "")
    except ValueError:
        raise newException(InvalidPfmFileFormat, "Invalid width/height")

    return res

proc parseEndianness*(line: string): Endianness =
    var value: float
    try:
        value = line.parseFloat
    except ValueError:
        raise newException(InvalidPfmFileFormat, "Missing endianness specification")

    if value == 1.0:
        return bigEndian
    elif value == -1.0:
        return littleEndian
    else:
        raise newException(InvalidPfmFileFormat, "Invalid endianness specification")

proc readFloat(stream : Stream , endianness = littleEndian) :  Color =

    if endianness == bigEndian:
        var appo : float32
        appo = stream.readFloat32.float32
        bigEndian32(addr result.r,addr appo)
        result.g= stream.readFloat32.float32
        result.b = stream.readFloat32.float32



proc readPfmImage(stream : Stream) : HdrImage =
    #The ﬁrst bytes in a binary ﬁle are usually called «magic bytes»
    let magic = readLine(stream)
    if magic != "PF":
        raise newException(InvalidPfmFileFormat, "Invalid magic in PFM file")

    let imgSize = readLine(stream)
    let (width, height) = parseImgSize(imgSize)

    let endianessLine = readLine(stream)
    let endianness = parseEndianness(endianessLine)

    result = HdrImage( width : width, height : height)
    #left to right, bottom to top order
    for y in countdown(height-1,0):
        for x in 0..<width:
            let color : Color = readFloat(stream, endianness)
            result.setPixel(x, y, color)
