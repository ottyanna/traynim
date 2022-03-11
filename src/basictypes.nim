type
    Color* = object
        r*, g*, b*: float32

    HdrImage* = object
        width*, height*: int
        pixels*: seq[Color]

#color Functions
proc `+`* ( color1, color2 : Color ) : Color =
    result.r = color1.r + color2.r
    result.g = color1.g + color2.g
    result.b = color1.b + color2.b

proc `*`* ( col : Color, scalar: float32 ) : Color =
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