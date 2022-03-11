type
    Color* = object
        r*, g*, b*: float32

    HdrImage* = object
        width*, height*: int
        pixels*: seq[Color]

#color functions
proc `+`* ( color1, color2 : Color ) : Color =
    result.r = color1.r + color2.r
    result.g = color1.g + color2.g
    result.b = color1.b + color2.b

proc `*`* ( col : Color, scalar: float32 ) : Color =
    result.r = scalar * col.r
    result.g = scalar * col.g
    result.b = scalar * col.b

proc `*`* ( scalar: float32, col : Color ) : Color =
    result.r = scalar * col.r
    result.g = scalar * col.g
    result.b = scalar * col.b

proc `-`* (color1, color2 : Color) : Color =
    result.r = color1.r - color2.r 
    result.g = color1.g - color2.g
    result.b = color1.b - color2.b 

proc `*`* (color1, color2 : Color) : Color = 
    result.r = color1.r * color2.r
    result.g = color1.g * color2.g
    result.b = color1.b * color2.b
      
#this function creates a new black image (the Color fields are created 0 by default)
proc newHDRImage* ( width, height : int ) : HdrImage =
    result.width = width
    result.height = height
    result.pixels = newSeq[Color] (width*height)

#test hdr
proc validCoordinates* (img : HdrImage, x,y : int ) : bool = 
    result = ((x >= 0) and (x < img.width) and (y >= 0) and (y < img.height))

proc pixelOffset* (img : HdrImage, x,y : int) : int = 
    result = y * img.width + x

proc getPixel* (img : HdrImage, x,y : int ) : Color =
    assert validCoordinates(img, x, y)
    result = img.pixels[img.pixelOffset(x,y)]

proc setPixel* (img : HdrImage, x, y : int) : Color = 
    assert validCoordinates(img, x, y)
    result = img.pixels[pixelOffset(img, x, y)]      