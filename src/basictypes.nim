type
    Color* = object
        r*, g*, b*: float32

    HdrImage* = object
        width*, height*: int
        pixels*: seq[Color]

      
#this function creates a new black image (the Color fields are created 0 by default)
proc newHDRImage* ( width, height : int ) : HdrImage =

    result.width = width
    result.height = height
    result.pixels = newSeq[Color] (width*height)

func `-`* (color_1, color_2 : Color) : Color =
    result.r = color_1.r - color_2.r 
    result.g = color_1.g - color_2.g
    result.b = color_1.b - color_2.b 

func `*`* (color_1, color_2 : Color) : Color = 
    result.r = color_1.r * color_2.r
    result.g = color_1.g * color_2.g
    result.b = color_1.b * color_2.b
