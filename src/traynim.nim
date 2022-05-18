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


import strutils, streams, cligen, sugar
from math import sqrt

import
    cameras,
    colors,
    geometry,
    hdrimages,
    imageTracer,
    materials,
    std/monotimes,
    pcg,
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
        fileName = "demo", format = "png", algorithm = "pathtracing",
        raysNum = 10, maxDepth = 3, initState = 42, initSeq = 54, samplePerPixel = 1,  
        luminosity : float = 0.0 ) =

    var image = newHDRImage(width, height)
    echo("Generating a ", width, "x", height, " image, with the camera tilted by ", angleDeg, "°")

    var world = newWorld()

    let skyMaterial = newMaterial(
        brdf = newDiffuseBRDF(pigment = newUniformPigment(newColor(0, 0, 0))),
        emittedRadiance = newUniformPigment(newColor(1.0, 0.9, 0.5))
    )

    let groundMaterial = newMaterial(
        brdf = newDiffuseBRDF(
            pigment = newCheckeredPigment(
                color1 = newColor(0.3, 0.5, 0.1),
                color2 = newColor(0.1, 0.2, 0.5)
            )
        )
    )

    let sphereMaterial = newMaterial(
        brdf = newDiffuseBRDF(
            pigment = newUniformPigment(newColor(0.3, 0.4, 0.8))
        )
    )

    let mirrorMaterial = newMaterial(
        brdf = newSpecularBRDF(
            pigment = newUniformPigment(newColor(0.6, 0.2, 0.3))
        )
    )

    world.addShape(
        newSphere(material = skyMaterial,
        transformation = scaling(newVec(200, 200, 200)) * translation(newVec(0, 0, 0.4)))
    )

    world.addShape(newPlane(material = groundMaterial))

    world.addShape(
        newSphere(
            material = sphereMaterial,
            transformation = translation(newVec(0, 0, 1))
        )
    )

    world.addShape(
        newSphere(
            material = mirrorMaterial,
            transformation = translation(newVec(1, 2.5, 0))
        )
    )

    # Define transformation on camera
    let cameraTr = rotationZ(angleDeg) * translation(newVec(-1.0, 0.0, 0.0))

    var camera: Camera

    if orthogonal:
        camera = newOrthogonalCamera(aspectRatio = width / height,
                transformation = cameraTr)
    else:
        camera = newPerspectiveCamera(aspectRatio = width / height,
                transformation = cameraTr)

    # Run the tracer

    var tracer = newImageTracer(image, camera)

    var renderer: Renderer

    case algorithm:
        of "on/off":
            echo("Using on/off renderer")
            renderer = newOnOffRenderer(world,white,black)
        of "flat":
            echo("Using flat renderer")
            renderer = newFlatRenderer(world)
        of "pathtracing":
            echo("Using pathtracing")
            var pcg = newPCG(initState = initState.uint64, initSeq = initSeq.uint64)
            renderer = newPathTracer(
                world = world,
                pcg = pcg,
                raysNum = raysNum,
                maxDepth = maxDepth
            )
        else:
            quit("Unknown renderer")
    
    let time = getMonoTime()
    tracer.fireAllRays(ray => call(renderer,ray))
    echo "Time taken: ", getMonoTime() - time

    # Save the HDR image
    let outPfm = newFileStream(fileName & ".pfm", fmWrite)
    tracer.image.writePfmImage(outPfm)
    echo "HDR demo image written to " & fileName & ".pfm"
    outPfm.close()

    # Apply tone-mapping to the image
    if luminosity == 0.0:    
        tracer.image.normalizeImage(factor = 1.0) #use average luminosity
    else:
        tracer.image.normalizeImage(factor = 1.0, luminosity)
    
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
                    "format": "PNG, PPM, BMP or QOI formats",
                    "algorithm": "options are on/off or flat renderer",
                    "luminosity": "luminosity for LDR image conversion, lower number is lighter, default is averageLuminosity",
                    "samplePerPixel":"Number of samples per pixel (must be a perfect square, e.g., 16)",
                    "algorithm": "options on/off, flat, pathtracing renderer",
                    "luminosity": "luminosity for LDR image conversion, lower number is lighter, default is averageLuminosity"}
        ])
