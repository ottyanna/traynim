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


import strutils, streams, cligen, sugar, options

import
    cameras,
    colors,
    geometry,
    hdrimages,
    imageTracer,
    render,
    shapes,
    transformations,
    world

proc pfm2format(inPfmFileName: string, factor = 0.2, gamma = 1.0,
        outputFileName: string) =

    let inPfm = newFileStream(inPfmFileName, fmRead)
    var img = readPfmImage(inPfm)
    inPfm.close()

    echo ("File " & inPfmFileName & " has been read from disk")

    img.normalizeImage(factor)
    img.clampImage()

    img.writeLdrImage(outputFileName, gamma)

    echo ("File " & outputFileName & " has been written to disk")


proc demo(angleDeg = 0.0, orthogonal = false, width = 640, height = 480,
        fileName = "demo", format = "png") =

    var image = newHDRImage(width, height)

    var world = newWorld()

    # Add spheres as vertices of a 0.5 side cube
    for x in [-0.5, 0.5]:
        for y in [-0.5, 0.5]:
            for z in [-0.5, 0.5]:
                world.addShape(
                    newSphere(
                        transformation = translation(newVec(x, y, z))*scaling(
                                newVec(0.1, 0.1, 0.1))
                    )
                )

    # Place two other spheres in the cube, in order to check whether
    # there are issues with the orientation of the image

    # First sphere at bottom
    world.addShape(
        newSphere(
            transformation = translation(newVec(0.0, 0.0, -0.5)) *
                scaling(newVec(0.1, 0.1, 0.1))
        )
    )

    # Second sphere on the left face
    world.addShape(
        newSphere(
            transformation = translation(newVec(0.0, 0.5, 0.0)) *
                scaling(newVec(0.1, 0.1, 0.1))
        )
    )

    # DEfine transformation on camera
    let cameraTr = rotationZ(angleDeg) * translation(newVec(-1.0, 0.0, 0.0))

    var camera: Camera

    if orthogonal:
        camera = newOrthogonalCamera(aspectRatio = width / height,
                transformation = cameraTr)
    else:
        camera = newPerspectiveCamera(aspectRatio = width / height,
                transformation = cameraTr)

    var tracer = newImageTracer(image, camera)

    # Run ray tracer with "on/off" renderer
    tracer.fireAllRays(ray => (if world.rayIntersection(
            ray).isSome: white else: black))

    # Save the HDR image
    let outPfm = newFileStream(fileName & ".pfm", fmWrite)
    tracer.image.writePfmImage(outPfm)
    echo "HDR demo image written to " & fileName & ".pfm"
    outPfm.close()

    # Apply tone-mapping to the image
    tracer.image.normalizeImage(factor = 1.0)
    tracer.image.clampImage()

    # Save the LDR image
    tracer.image.writeLdrImage(fileName & "." & format)
    echo "PNG demo image written to " & fileName & ".png"


when isMainModule:

    const traynim = """
 
                     _______*             _   _ _           
                    |__   __ *           | \ | (_)          
                       | |_ *_ __ _ _   _|  \| |_ _ __ ___  
                       | | '__/ _` | | | | . ` | | '_ ` _ \ 
                       | | | | (_| | |_| | |\  | | | | | | |
                       |_|_|  \__,_|\__, |_| \_|_|_| |_| |_|
                                     __/ |                  
                                    |___/                   
                    """

    echo traynim

    dispatchMulti(
        [pfm2format, 
            help = {"outputFileName":" Path to output file (PNG, PPM, BMP or QOI formats)", 
                    "factor":"Multiplicative factor",
                    "gamma":"Exponent for gamma-correction",
                    "inPfmFileName":"Path to input file (PFM)" }
        ],
        [demo,
            help = {"angleDeg": "Angle rotation of the camera (Degrees)",
                    "orthogonal" : "Perspective or orthogonal camera (DefaultPerspective)",
                    "width" : "Width of the image",
                    "height" : "Height of the image",
                    "fileName" : "Path to output file without format",
                    "format": "PNG, PPM, BMP or QOI formats"}
        ])
