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