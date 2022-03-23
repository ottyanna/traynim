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

# Create a new color from scratch
proc newColor*(r,g,b : float32) : Color =
    result.r = r
    result.g = g
    result.b = b

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

proc readFloat(stream : Stream , endianness = littleEndian) : float32 =

    try:

        var appo : float32
        appo = readFloat32(stream)
        if endianness == littleEndian:
            littleEndian32(addr result, addr appo)
        elif endianness == bigEndian:
            bigEndian32(addr result, addr appo)
       
    except:
        raise newException(InvalidPfmFileFormat, "Impossible to read binary data from the file")

proc readPfmImage*(stream : Stream) : HdrImage =
    #The ﬁrst bytes in a binary ﬁle are usually called «magic bytes»
    let magic = readLine(stream)
    if magic != "PF":
        raise newException(InvalidPfmFileFormat, "Invalid magic in PFM file")

    let imgSize = readLine(stream)
    let (width, height) = parseImgSize(imgSize)

    let endianessLine = readLine(stream)
    let endianness = parseEndianness(endianessLine)

    result = newHdrImage(width, height)

    #left to right, bottom to top order

    for y in countdown(height-1,0):
        for x in countup(0, width-1):
            var color = newSeq[float32](3)
            for i in 0..<3: color[i] = readFloat(stream, endianness)
            result.setPixel(x, y, Color(r: color[0], g: color[1], b: color[2]))


proc writeFloat(stream : Stream, val : var float32, endianness = littleEndian) =
    
    var appo : float32
    if endianness == littleEndian:
        littleEndian32(addr appo, addr val)
        write(stream,appo)
    elif endianness == bigEndian:
        bigEndian32(addr appo, addr val)
        write(stream,appo)


proc writePfmImage*(img : HdrImage, stream : Stream, endianness = littleEndian) = 
    
    var endiannessStr : string
    if endianness == littleEndian:
        endiannessStr = "-1.0"
    else:
        endiannessStr = "1.0"
    # The PFM header, as a string
    stream.writeLine("PF")
    stream.writeLine(img.width, " ", img.height)
    stream.writeLine(endiannessStr)

    # Write the image (bottom-to-up, left-to-right)
    for y in countdown(img.height-1, 0):
        for x in countup(0, img.width-1):
           var color = img.getPixel(x, y)
           writeFloat(stream, color.r, endianness)
           writeFloat(stream, color.g, endianness)
           writeFloat(stream, color.b, endianness)
