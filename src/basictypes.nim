type
    Color* = object
        r*, g*, b*: float32

    HdrImage* = object
        width*, height*: int
        pixels*: seq[Color]

proc `+`* ( col1, col2 : Color ) : Color =
    
    result.r = col1.r + col2.r
    result.g = col1.g + col2.g
    result.b = col1.b + col2.b

proc `*`* ( col : Color, scalar: float32 ) : Color =
    
    result.r = scalar * col.r
    result.g = scalar + col.g
    result.b = scalar + col.b
      
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
