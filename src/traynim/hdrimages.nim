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


## This module implements operations on HDRimages and PFM files

import colors, streams, endians, strutils
from pixie import newImage, color, writeFile, setColor
from math import pow, log10


# --------------HDR Images--------------

type
    HdrImage* = object ## A High-Dynamic-Range 2D image type
        width*, height*: int ## `width` (int) and `height` (int) number of columns and rows of the matrix of colors
        pixels*: seq[colors.Color] ## `pixels` (seq of Color type): the matrix of colors represented by a 1D array


proc newHDRImage*(width, height: int): HdrImage =

    ## Creates an empty black image (the Color fields are set to 0 by default)

    (result.width, result.height) = (width, height)
    result.pixels = newSeq[colors.Color] (width*height)


proc validCoordinates*(img: HdrImage, x, y: int): bool =

    ## Tests if image coordinates are in right range

    result = ((x >= 0) and (x < img.width) and (y >= 0) and (y < img.height))


proc pixelOffset*(img: HdrImage, x, y: int): int =

    ## Calculates indices in the image array

    result = y * img.width + x


proc getPixel*(img: HdrImage, x, y: int): colors.Color =

    ## Returns Color in pixel of coordinates (x,y)

    assert img.validCoordinates(x, y)
    result = img.pixels[img.pixelOffset(x, y)]


proc setPixel*(img: var HdrImage, x, y: int, newColor: colors.Color) =

    ## Sets Color in pixel of coordinates (x,y)

    assert img.validCoordinates(x, y)
    img.pixels[img.pixelOffset(x, y)] = newColor


# --------------PFM files--------------

type InvalidPfmFileFormat* = object of CatchableError

proc parseImgSize*(line: string): tuple =

    ## Outputs the HDRimage size (width and height) from PFM file format.
    ##
    ## Raises InvalidPfmFileFormat Error if the size specifications are not valid

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

    ## Outputs the HDRimage byte endiannes from PFM file format.
    ##
    ## Raises `InvalidPfmFileFormat` error if the endianess specification is not valid

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

proc readFloat(stream: Stream, endianness = littleEndian): float32 =

    ## Reads a float32 from PFM file format from binary using given byte endiannes.
    ##
    ## Raises `InvalidPfmFileFormat` error if data is not valid

    try:

        var appo: float32
        appo = readFloat32(stream)
        if endianness == littleEndian:
            littleEndian32(addr result, addr appo)
        elif endianness == bigEndian:
            bigEndian32(addr result, addr appo)

    except: #(e.g. if data is not enough)
        raise newException(InvalidPfmFileFormat, "Impossible to read binary data from the file")

proc readPfmImage*(stream: Stream): HdrImage =

    ## Reads data from PFM file format.
    ##
    ## The `stream` parameter must be a I/O stream.
    ## Raises `InvalidPfmFileFormat` error if magic is not valid
    ## or other data is not readable/enough.

    # The ﬁrst bytes in a binary ﬁle are usually called «magic bytes»
    let magic = readLine(stream)
    if magic != "PF":
        raise newException(InvalidPfmFileFormat, "Invalid magic in PFM file")

    let imgSize = readLine(stream)
    let (width, height) = parseImgSize(imgSize)

    let endianessLine = readLine(stream)
    let endianness = parseEndianness(endianessLine)

    result = newHdrImage(width, height)

    # Data order in PFM files: left to right, bottom to top order
    for y in countdown(height-1, 0):
        for x in countup(0, width-1):
            var color = newSeq[float32](3)
            for i in 0..<3: color[i] = readFloat(stream, endianness)
            result.setPixel(x, y, colors.Color(r: color[0], g: color[1],
                    b: color[2]))


proc writeFloat(stream: Stream, val: var float32, endianness = littleEndian) =

    ## Writes float32 data in binary form following given byte endianness

    var appo: float32
    if endianness == littleEndian:
        littleEndian32(addr appo, addr val)
        write(stream, appo)
    elif endianness == bigEndian:
        bigEndian32(addr appo, addr val)
        write(stream, appo)

proc writePfmImage*(img: HdrImage, stream: Stream, endianness = littleEndian) =

    ## Writes the image in PFM file format.
    ##
    ## The `stream` parameter must be a I/O stream.
    ## The parameter `endianness` specifies the byte endianness to be used in the file,
    ## default is set to little endian.

    var endiannessStr: string
    if endianness == littleEndian:
        endiannessStr = "-1.0"
    else:
        endiannessStr = "1.0"

    # The PFM header, as a string
    stream.writeLine("PF")
    stream.writeLine(img.width, " ", img.height)
    stream.writeLine(endiannessStr)

    # Write the image in left to right, bottom to top order
    for y in countdown(img.height-1, 0):
        for x in countup(0, img.width-1):
            var color = img.getPixel(x, y)
            writeFloat(stream, color.r, endianness)
            writeFloat(stream, color.g, endianness)
            writeFloat(stream, color.b, endianness)


proc averageLuminosity*(img: HdrImage, delta = 1e-10): float32 =

    ## Computes average luminosity of an image.
    ##
    ## The `delta` parameter is to take account of
    ## numerical problems for underilluminated pixels, default is set to 10e-10.

    var cumsum = 0.0

    for pix in img.pixels:
        cumsum += log10(delta + pix.luminosity())

    result = pow(10, cumsum / len(img.pixels).float)

proc normalizeImage*(img: var HdrImage, factor: float32,
        luminosity = averageLuminosity(img)) =

    ## Normalizes image for a given luminosity.
    ##
    ## `Luminosity` parameter can be set by user, if the field is empty,
    ## default is set to `averageLuminosity()` value.

    for i in 0..<img.pixels.len:
        img.pixels[i] = img.pixels[i]*(factor/luminosity)

proc clamp(x: float32): float32 =

    result = x / (1 + x)

proc clampImage*(img: var HdrImage) =

    ## Adjusts the color levels of the brightest pixels in the image

    for i in 0..<img.pixels.len:
        img.pixels[i].r = clamp(img.pixels[i].r)
        img.pixels[i].g = clamp(img.pixels[i].g)
        img.pixels[i].b = clamp(img.pixels[i].b)

proc writeLdrImage*(img: HdrImage, outputPath: string, gamma = 1.0) =

    ## Saves the image in a LDR format.
    ##
    ## Before calling this function, you should apply a tone-mapping algorithm to the
    ## image and be sure that the R, G, and B values of the colors in the image are all
    ## in the range [0, 1].
    ## Use `normalizeImage`and `clampImage` to do this.


    var imgF = newImage(img.width, img.height)
    for y in 0..<img.height:
        for x in 0..<img.width:
            var curColor = img.getPixel(x, y)

            var curColorF = color((pow(curColor.r, 1 / gamma)), (pow(curColor.g,
                    1 / gamma)), (pow(curColor.b, 1 / gamma)))

            setColor(imgF, x, y, curColorF)

    writeFile(imgF, outputPath)
