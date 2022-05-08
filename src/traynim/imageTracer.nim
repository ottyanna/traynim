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

import sugar, hdrimages, cameras, ray
from colors import Color


type
    ImageTracer* = object

        ## Traces an image by shooting light rays through each of its pixels

        image*: HdrImage
        camera*: Camera

proc newImageTracer*(image: HdrImage, camera: Camera): ImageTracer =

    ## Creates an ImageTracer object.
    ## 
    ## The parameter `image` must be a `HdrImage` object that has already been initialized.
    ## 
    ## The parameter `camera` must be a descendeant of the `Camera` object.

    result.image = image
    result.camera = camera

proc fireRay*(imagetracer: ImageTracer, col, row: int, uPixel = 0.5,
        vPixel = 0.5): Ray =

    ## Shoots one light6 ray through image pixel (col,row), with origin in bottom left of image.
    
    let u = (col.toFloat + uPixel) / (imagetracer.image.width ).toFloat
    let v = 1.0 - (row.toFloat + vPixel) / (imagetracer.image.height ).toFloat

    return (imagetracer.camera.fireRay(u, v))

proc fireAllRays*(imagetracer: var ImageTracer, fun: (Ray) -> Color) =

    ## Shoots several light rays crossing each of the pixels in the image
    ##
    ## For each pixel in the HdrImage object fire one ray, and pass it to the function `fun`, which
    ## must accept a `Ray` as its only parameter and must return a `Color` instance telling the
    ## color to assign to that pixel in the image.

    for row in 0..<imagetracer.image.height:
        for col in 0..<imagetracer.image.width:
            let ray = imagetracer.fireRay(col, row)
            let color = fun(ray)
            imagetracer.image.setPixel(col, row, color)
