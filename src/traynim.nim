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
from math import sqrt, pow
import tables
when compileOption("profiler"):
  import nimprof

import
    cameras,
    colors,
    geometry,
    hdrimages,
    imageTracer,
    lights,
    materials,
    std/monotimes,
    pcg,
    render,
    shapes,
    transformations,
    world,
    sceneFiles,
    options

proc buildVariablesTable(declareFloat:string):Table[string,float] =

    for item in splitWhitespace(declareFloat):
        
        var stringVariable = item.split(':')
        
        if stringVariable.len != 2:
            quit("Error: The format for variable declaration NAME:VALUE is not respected")
        else:
            var floatVar: float
            try:
                floatVar = stringVariable[1].parseFloat()
            except ValueError:
                quit("Error: The second term is not a floating-point")

            result[stringVariable[0]]=floatVar

# --------------RENDER--------------

proc renderer( inSceneName : string = "examples/example.txt",
               declareFloat:string ="",
               width = 640, height = 480,
               algorithm = "pathtracing",
               fileName = "demo", format = "png", 
               luminosity: float = 0.0, 
               samplesPerPixel = 1.0, 
               raysNum = 10, maxDepth = 3, 
               initState = 42, initSeq = 54)=



    let samplesPerSide = sqrt(samplesPerPixel).int
    if pow(samplesPerSide.float, 2.0) != samplesPerPixel:
        quit("Error: the number of samples per pixel ({samplePerPixel}) must be a perfect square")

    var inScene: Stream
    var variables:Table[string,float]
    try:
        if declareFloat=="":
            inScene = openFileStream(inSceneName,fmRead)
        else:
            variables = buildVariablesTable(declareFloat)
            inScene = openFileStream(inSceneName,fmRead)
    except IOError:
        quit("ERROR: " & getCurrentExceptionMsg())

    var inputStream = newInputStream(stream=inScene, fileName=inSceneName)
 
    var scene : Scene

    try:
        scene = parseScene(inputStream, variables)
    except GrammarError:
        quit("ERROR: " & getCurrentExceptionMsg() & " [GrammarError]")

    inScene.close()

    var image = newHDRImage(width, height)
    echo("Generating the ", width, "x", height,
            " image...")

    if scene.camera.isNone:
        quit("ERROR: camera not defined in input scene [GrammarError]")

    var tracer = newImageTracer(image, scene.camera.get, samplesPerSide)

    var renderer: Renderer

    case algorithm:
        of "on/off":
            echo("Using on/off renderer")
            renderer = newOnOffRenderer(scene.world, black, white)
        of "flat":
            echo("Using flat renderer")
            renderer = newFlatRenderer(scene.world)
        of "pathtracing":
            echo("Using pathtracing")
            var pcg = newPCG(initState = initState.uint64,
                    initSeq = initSeq.uint64)
            renderer = newPathTracer(
                world = scene.world,
                pcg = pcg,
                raysNum = raysNum,
                maxDepth = maxDepth
            )
        of "pointlight":
            echo("Using point-light tracer")
            renderer = newPointLightRenderer(world = scene.world,
                    backgroundColor = black)
        else:
            quit("Unknown renderer")

    let time = getMonoTime()
    tracer.fireAllRays(ray => call(renderer, ray))
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

# --------------STACK--------------

proc stack(inPfmFileName: string, numOfFiles : int,
        outputFileName: string, factor=0.2, gamma=1.0) =

    var imgs : seq[HDRimage] = @[]

    for i in 0..<numOfFiles:
        var inPfm :Stream 
        try:
            inPfm = newFileStream(inPfmFileName & $i & ".pfm" , fmRead)
        except IOError:
            quit("ERROR: " & getCurrentExceptionMsg())
        imgs.add(readPfmImage(inPfm))
        inPfm.close()
    #I need to verify that images are of the same width and height maybe

    var oImg = newHDRImage(imgs[0].width, imgs[0].height)

    var cumColor: Color = black

    for x in 0..<oImg.width:
        for y in 0..<oImg.height:
            cumColor=black
            for i in 0..<imgs.len:
                cumColor = cumColor + imgs[i].getPixel(x,y)
            oImg.setPixel(x,y,(cumColor/imgs.len.float))

    # Save the HDR image
    let outPfm = newFileStream(outputFileName & ".pfm", fmWrite)
    oImg.writePfmImage(outPfm)
    echo "HDR image written to " & outputFileName & ".pfm"
    outPfm.close()

    oImg.normalizeImage(factor)
    oImg.clampImage()

    oImg.writeLdrImage(outputFileName & ".png", gamma)

    echo ("File " & outputFileName & " has been written to disk")

# --------------PFM2FORMAT--------------

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

# --------------DEMO (Deprecated)--------------

proc demo(angleDeg = 0.0, orthogonal = false, width = 640, height = 480,
        fileName = "demo", format = "png", algorithm = "pathtracing",
        raysNum = 10, maxDepth = 3, initState = 42, initSeq = 54,
                samplePerPixel = 1.0,
        luminosity: float = 0.0) =

    let samplesPerSide = sqrt(samplePerPixel).int
    if pow(samplesPerSide.float, 2.float) != samplePerPixel:
        quit("Error, the number of samples per pixel ({samplePerPixel}) must be a perfect square")

    var image = newHDRImage(width, height)
    echo("Generating a ", width, "x", height,
            " image, with the camera tilted by ", angleDeg, "°")

    var world = newWorld()
    var cameraTr : Transformation

    if (algorithm != "on/off"):
        let skyMaterial = newMaterial(
            brdf = newDiffuseBRDF(pigment = newUniformPigment(newColor(0.7, 0.7, 0.7))),
            emittedRadiance = newUniformPigment(newColor(0.7, 0.7, 0.7))
            )

        let groundMaterial = newMaterial(
            brdf = newDiffuseBRDF(
                pigment = newCheckeredPigment(
                    color1 = newColor(0.3, 0.5, 0.1),
                    color2 = newColor(0.1, 0.2, 0.5)))
            )
        

        let bigSphereMaterial = newMaterial(
            brdf = newDiffuseBRDF(
                pigment = newUniformPigment(newColor(0.3, 0.4, 0.8))
            )
        )

        let littleSphereMaterial = newMaterial(brdf = newDiffuseBRDF(
                pigment = newUniformPigment(newColor(0.7, 0.1, 0.3)))
        )

        let mirrorMaterial = newMaterial(
            brdf = newSpecularBRDF(
                pigment = newUniformPigment(newColor(0.6, 0.2, 0.3))
            )
        )

        world.addShape(
            newSphere(material = skyMaterial,
            transformation = scaling(newVec(200, 200, 200)) * translation(newVec(0,
                    0, 0.4)))
        )

        world.addShape(newPlane(material = groundMaterial))

        world.addShape(
            newSphere(
                material = bigSphereMaterial,
                transformation = translation(newVec(0, 0, 1))
            )
        )

        world.addShape(
            newSphere(
                material = littleSphereMaterial,
                transformation = translation(newVec(0,0, 2.5))*scaling(newVec(0.3,0.3,0.3))
                # Pay attention to the order of the transformations! 
                # In order to do it right the scaling must be second to the translation
            )
        )


        world.addShape(
            newSphere(
                material = mirrorMaterial,
                transformation = translation(newVec(1, 2.5, 0))
            )
        )

        world.addLight(newPointLight(position = newPoint(-30, 30, 30),
                color = white))
        

        # Define transformation on camera
        cameraTr = rotationZ(angleDeg) * translation(newVec(-2.0, 0.0, 1.0))

    else:
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

        cameraTr = rotationZ(angleDeg) * translation(newVec(-1.0, 0.0, 0.0))

    var camera: Camera

    if orthogonal:
        camera = newOrthogonalCamera(aspectRatio = width / height,
                transformation = cameraTr)
    else:
        camera = newPerspectiveCamera(aspectRatio = width / height,
                transformation = cameraTr)

    # Run the tracer

    var tracer = newImageTracer(image, camera, samplesPerSide = samplesPerSide)

    var renderer: Renderer

    case algorithm:
        of "on/off":
            echo("Using on/off renderer")
            renderer = newOnOffRenderer(world, black, white)
        of "flat":
            echo("Using flat renderer")
            renderer = newFlatRenderer(world)
        of "pathtracing":
            echo("Using pathtracing")
            var pcg = newPCG(initState = initState.uint64,
                    initSeq = initSeq.uint64)
            renderer = newPathTracer(
                world = world,
                pcg = pcg,
                raysNum = raysNum,
                maxDepth = maxDepth
            )
        of "pointlight":
            echo("Using point-light tracer")
            renderer = newPointLightRenderer(world = world,
                    backgroundColor = black)
        else:
            quit("Unknown renderer")

    let time = getMonoTime()
    tracer.fireAllRays(ray => call(renderer, ray))
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

# --------------MAIN--------------

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

    const rHelp = { "inSceneName" : "name of the file containing the image",
                    "declareFloat": "Declare a variable. The syntax is «--d=VAR:VALUE». Example: --d=\"clock:150 ang:90\"",
                    "width": "Width of the image",
                    "height": "Height of the image",
                    "fileName": "Path to output file without format",
                    "format": "PNG, PPM, BMP or QOI formats",
                    "algorithm": "pathtracing, pointlight, flat or on/off renderer",
                    "luminosity": "luminosity for LDR image conversion, lower number is lighter, default is averageLuminosity",
                    "samplesPerPixel": "Number of samples per pixel (this must be a perfect square, e.g., 16)",
                    "raysNum" : "Number of rays departing from each surface point (only applicable with --algorithm=pathtracing)",
                    "maxDepth": "Maximum allowed ray depth (only applicable with --algorithm=pathtracing)",
                    "initState" : "Initial seed for the random number generator (positive number)",
                    "initSeq" : "Identifier of the sequence produced by the random number generator (positive number)"}.toTable

    const rShort = { "inSceneName" : 'i',
                    "height": 'e',
                    "fileName" : 'o',
                    "format": 'f',
                    "initState" : 't',
                    "initSeq" : 'q'}.toTable

    dispatchMulti(
        [renderer, help = rHelp, short=rShort],
        [stack],
        [pfm2format,
            help = {"outputFileName": " Path to output file (PNG, PPM, BMP or QOI formats)",
                    "factor": "Multiplicative factor",
                    "gamma": "Exponent for gamma-correction",
                    "inPfmFileName": "Path to input file (PFM)"}
        ],
        [demo,
            help = {"angleDeg": "Angle rotation of the camera (Degrees)",
                    "orthogonal": "Perspective or orthogonal camera (fefault is perspective)",
                    "width": "Width of the image",
                    "height": "Height of the image",
                    "fileName": "Path to output file without format",
                    "format": "PNG, PPM, BMP or QOI formats",
                    "samplePerPixel": "Number of samples per pixel (must be a perfect square, e.g., 16)",
                    "algorithm": "options on/off, flat, pathtracing renderer",
                    "luminosity": "luminosity for LDR image conversion, lower number is lighter, default is averageLuminosity"}
        ])
