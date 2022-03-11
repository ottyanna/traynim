type
    Color* = object
        r*, g*, b*: float32

    HdrImage* = object
        width*, height*: int
        pixels*: seq[Color]

proc newHdrImage(width : int, height : int) : HdrImage = 
    var img : HdrImage
    img.height = height
    img.width = width       