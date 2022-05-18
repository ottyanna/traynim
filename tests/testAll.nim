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


import 
    math,
    options, 
    streams,
    sugar,
    unittest

import
    cameras, 
    colors, 
    common, 
    geometry,
    hdrimages, 
    hitRecord,
    imageTracer,
    materials,
    pcg,  
    ray, 
    render,
    shapesDef,
    shapes,
    transformations,
    world

suite "test cameras.nim":

    test "test on OrthogonalCamera":
        let cam = newOrthogonalCamera(aspectRatio = 2.0)
        let ray1 = cam.fireRay(0.0, 0.0)
        let ray2 = cam.fireRay(1.0, 0.0)
        let ray3 = cam.fireRay(0.0, 1.0)
        let ray4 = cam.fireRay(1.0, 1.0)

        # Verify that the rays are parallel by verifying that cross-products vanish
        assert areClose(0.0, ray1.dir.cross(ray2.dir).sqrNorm())
        assert areClose(0.0, ray1.dir.cross(ray3.dir).sqrNorm())
        assert areClose(0.0, ray1.dir.cross(ray4.dir).sqrNorm())

        # Verify that the ray hitting the corners have the right coordinates

        assert ray1.at(1.0).areClose(newPoint(0.0, 2.0, -1.0))
        assert ray2.at(1.0).areClose(newPoint(0.0, -2.0, -1.0))
        assert ray3.at(1.0).areClose(newPoint(0.0, 2.0, 1.0))
        assert ray4.at(1.0).areClose(newPoint(0.0, -2.0, 1.0))

    test "test on OrthogonalCamera transform":
        let cam = newOrthogonalCamera(transformation = translation(2.0 * -vecY) *
                rotationY(theta = 90))
        let ray = cam.fireRay(0.5, 0.5)

        assert ray.at(1.0).areClose(newPoint(0.0, -2.0, 0.0))

    test "test on PerspectiveCamera":
        
        let cam = newPerspectiveCamera(screenDistance = 1.0, aspectRatio = 2.0)

        let ray1 = cam.fireRay(0.0, 0.0)
        let ray2 = cam.fireRay(1.0, 0.0)
        let ray3 = cam.fireRay(0.0, 1.0)
        let ray4 = cam.fireRay(1.0, 1.0)

        # Verify that all the rays depart from the same point
        assert ray1.origin.areClose(ray2.origin)
        assert ray1.origin.areClose(ray3.origin)
        assert ray1.origin.areClose(ray4.origin)

        # Verify that the ray hitting the corners have the right coordinates
        assert ray1.at(1.0).areClose(newPoint(0.0, 2.0, -1.0))
        assert ray2.at(1.0).areClose(newPoint(0.0, -2.0, -1.0))
        assert ray3.at(1.0).areClose(newPoint(0.0, 2.0, 1.0))
        assert ray4.at(1.0).areClose(newPoint(0.0, -2.0, 1.0))



    test "test on PerspectiveCamera transform":
        let cam = newPerspectiveCamera(transformation = translation(-vecY * 2.0) * rotationZ(PI / 2.0))
        let ray = cam.fireRay(0.5, 0.5)
        assert ray.at(1.0).areClose(newPoint(0.0, -2.0, 0.0))


suite "test colors.nim":

    setup:
        let col1 = newColor(1.0, 2.0, 3.0)
        let col2 = newColor(5.0, 7.0, 9.0)

    test "test Color Operations":
        assert (col1 + col2).areClose(Color(r: 6.0, g: 9.0, b: 12.0))
        assert (col1 - col2).areClose(Color(r: -4.0, g: -5.0, b: -6.0))
        assert (col1 * col2).areClose(Color(r: 5.0, g: 14.0, b: 27.0))
        assert not (col1 + col2).areClose(Color(r: 3.0, g: 9.0, b: 12.0))
        assert ($col1) == "<r: 1.0 , g: 2.0, b: 3.0>" #test on Color print

    test "test on Color Luminosity":
        assert areClose(luminosity(col1), 2.0)
        assert areClose(luminosity(col2), 7.0)


suite "test geometry.nim":

    setup:
        var a {.used.} = newVec(1.0, 2.0, 3.0) 

    test "test on areClose":
        assert areClose(a.x, 1.0)
        assert not areClose(a.y, 5.0)
        assert areClose(a.z, 3.0)

    test "test on Vec operations":
        var b = newVec(4.0, 6.0, 8.0)
        assert not (($b) == "<x: 1.0 , y: 2.0, z: 3.0>")
        assert ($a) == "<x: 1.0 , y: 2.0, z: 3.0>"
        assert (-a).areClose(newVec(-1.0, -2.0, -3.0))
        assert (a + b).areClose(newVec(5.0, 8.0, 11.0))
        assert (b - a).areClose(newVec(3.0, 4.0, 5.0))
        assert (2 * a).areClose(newVec(2.0, 4.0, 6.0))
        assert (a * 2).areClose(newVec(2.0, 4.0, 6.0))
        assert (a.dot(b)).areClose(40.0)
        assert a.cross(b).areClose(newVec(-2.0, 4.0, -2.0))
        assert b.cross(a).areClose(newVec(2.0, -4.0, 2.0))
        assert b.parseVecToNormal == newNormal(4.0, 6.0, 8.0)
        assert areClose(a.sqrNorm(), 14.0)
        assert areClose(a.norm()*a.norm(), 14.0)
    
    test "test ONB creation":
        
        var pcg = newPCG()
        for i in 0 ..< 10000:
            let normal = newVec(pcg.randomFloat(), pcg.randomFloat(), pcg.randomFloat()).normalize()
            let onb = createONBfromZ(normal)

            # Verify that the z axis is aligned with the normal
            assert areClose(onb.e3, normal)

            # Verify that the base is orthogonal
            assert areClose(0.0, onb.e1.dot(onb.e2))
            assert areClose(0.0, onb.e2.dot(onb.e3))
            assert areClose(0.0, onb.e3.dot(onb.e1))

            # Verify right-hand rule
            assert areClose(onb.e3, onb.e1.cross(onb.e2))

            # Verifiy that each component is normalized

            assert areClose(1.0, onb.e1.sqrNorm())
            assert areClose(1.0, onb.e2.sqrNorm())
            assert areClose(1.0, onb.e3.sqrNorm())
        

suite "test hdrImages.nim (HDRimage type)":

    setup:
        var img = newHDRImage(7, 4)

    test "test on Image Creation":
        assert img.width == 7
        assert img.height == 4
        assert not (img.width == 27)
    
    test "test on coordinates":
        assert img.validCoordinates(0, 0)
        assert img.validCoordinates(6, 3)
        assert not img.validCoordinates(-1, 0)
        assert not img.validCoordinates(0, -1)
        assert not img.validCoordinates(7, 0)
        assert not img.validCoordinates(0, 4)

    test "test on pixel offset":
        assert (img.pixelOffset(0, 0) == 0)
        assert (img.pixelOffset(3, 2) == 17)
        assert (img.pixelOffset(6, 3) == 7 * 4 - 1)

    test "test on set pixel":
        let col = newColor(1.0, 2.0, 3.0)
        img.setPixel(3, 2, col)
        assert areClose(col, img.getPixel(3, 2))
    

suite "test hdrImages.nim (read and write Pfm files)":
    
    setup:
        let strm = newFileStream("tests/HdrImageReferences/reference_be.pfm", fmRead)
        var leBuf = newStringStream("")
        var beBuf = newStringStream("")

    
    teardown:
        strm.close()
        leBuf.close()
        beBuf.close()

    test "test on parseImgSize":
        assert parseImgSize("3 2") == (3, 2)
        expect InvalidPfmFileFormat:
            discard parseImgSize("-1 3")
            discard parseImgSize("1 2 3")

    test "test on parseEndianness":
        assert parseEndianness("1.0") == bigEndian
        assert parseEndianness("-1.0") == littleEndian
        expect InvalidPfmFileFormat:
            discard parseEndianness("2.0")
            discard parseEndianness("abc")
    
    test "test on readPfm":
        let imgR = readPfmImage(strm)
        assert imgR.width == 3
        assert imgR.height == 2
        assert imgR.getPixel(0, 0).areClose(Color(r: 1.0e1, g: 2.0e1, b: 3.0e1))

    test "integration test on read and write Pfm image":
        var img = newHdrImage(3, 2)
        img.setPixel(0, 0, newColor(1.0e1, 2.0e1, 3.0e1))
        img.setPixel(1, 0, newColor(4.0e1, 5.0e1, 6.0e1))
        img.setPixel(2, 0, newColor(7.0e1, 8.0e1, 9.0e1))
        img.setPixel(0, 1, newColor(1.0e2, 2.0e2, 3.0e2))
        img.setPixel(1, 1, newColor(4.0e2, 5.0e2, 6.0e2))
        img.setPixel(2, 1, newColor(7.0e2, 8.0e2, 9.0e2))

        img.writePfmImage(leBuf, endianness = littleEndian)
        leBuf.setPosition(0)
        assert leBuf.readPfmImage == img

        img.writePfmImage(beBuf, endianness = bigEndian)
        beBuf.setPosition(0)
        assert beBuf.readPfmImage == img


suite "test hdrImages.nim (operations for LDR image writing)":

    setup:
        var img = newHDRImage(2, 1)
        img.setPixel(0, 0, newColor(5.0, 10.0, 15.0)) # Luminosity: 10.0
        img.setPixel(1, 0, newColor(500.0, 1000.0, 1500.0)) # Luminosity: 1000.0
        var strm = newFileStream("tests/HdrImageReferences/memorial.pfm", fmRead)

    
    teardown:
        strm.close()

    test "test on average lunimosity":
        assert areClose(img.averageLuminosity(delta = 0.0), 100.0)
        assert img.averageLuminosity(delta = 0.0) == 100.0

    test "test on normalize image with arguments":
        normalizeImage(img, 1000.0, 100.0)
        assert areClose(img.getPixel(0, 0), newColor(0.5e2, 1.0e2, 1.5e2))
        assert areClose(img.getPixel(1, 0), newColor(0.5e4, 1.0e4, 1.5e4))

    test "test on normalize image without arguments":
        normalizeImage(img, 1000.0)
        assert areClose(img.getPixel(0, 0), newColor(0.5e2, 1.0e2, 1.5e2))
        assert areClose(img.getPixel(1, 0), newColor(0.5e4, 1.0e4, 1.5e4))

    test "test on clamp image":
        img.clampImage()
        # Just test that the R/G/B values are w/i the expected boundaries
        for curPixel in img.pixels:
            assert (curPixel.r >= 0) and (curPixel.r <= 1)
            assert (curPixel.g >= 0) and (curPixel.g <= 1)
            assert (curPixel.b >= 0) and (curPixel.b <= 1)

    test "test on write LDR image":
        var imgem = readPfmImage(strm)
        imgem.normalizeImage(0.2)
        imgem.clampImage()
        writeLdrImage(imgem, "tests/HdrImageReferences/output.png")


suite "test imageTracer.nim":

        setup:
            let image = newHdrImage(width = 4, height = 2)
            let camera = newPerspectiveCamera(aspectRatio = 2)
            var tracer = newImageTracer(image = image, camera = camera)

        test "test orientation":
            # Fire a ray against top-left corner of the screen
            let topLeftRay = tracer.fireRay(0, 0, uPixel=0.0, vPixel=0.0)
            assert newPoint(0.0, 2.0, 1.0).areClose(topLeftRay.at(1.0))

            # Fire a ray against bottom-right corner of the screen
            let bottomRightRay = tracer.fireRay(3, 1, uPixel=1.0, vPixel=1.0)
            assert newPoint(0.0, -2.0, -1.0).areClose(bottomRightRay.at(1.0))

        test "test uv submapping":
            let ray1 = tracer.fireRay(0, 0, uPixel=2.5, vPixel=1.5)
            let ray2 = tracer.fireRay(2, 1, uPixel=0.5, vPixel=0.5)
            assert ray1.areClose(ray2)

        test "test image coverage":
            tracer.fireAllRays(ray => newColor(1.0, 2.0, 3.0))
            for row in 0..<tracer.image.height:
                for col in 0..<tracer.image.width:
                    assert tracer.image.getPixel(col, row) == newColor(1.0, 2.0, 3.0)


suite "test materials.nim":

    test "test Uniform Pigment":
        let color = newColor(1.0, 2.0, 3.0)
        let pigment = newUniformPigment(color)

        assert pigment.getColor(newVec2d(0.0, 0.0)).areClose(color)
        assert pigment.getColor(newVec2d(1.0, 0.0)).areClose(color)
        assert pigment.getColor(newVec2d(0.0, 1.0)).areClose(color)
        assert pigment.getColor(newVec2d(1.0, 1.0)).areClose(color)
    
    test "test Image Pigment":
        var image = newHDRImage(2, 2)
        image.setPixel(0, 0, newColor(1.0, 2.0, 3.0))
        image.setPixel(1, 0, newColor(2.0, 3.0, 1.0))
        image.setPixel(0, 1, newColor(2.0, 1.0, 3.0))
        image.setPixel(1, 1, newColor(3.0, 2.0, 1.0))

        let pigment = newImagePigment(image)
        assert pigment.getColor(newVec2d(0.0, 0.0)).areClose(newColor(1.0, 2.0, 3.0))
        assert pigment.getColor(newVec2d(1.0, 0.0)).areClose(newColor(2.0, 3.0, 1.0))
        assert pigment.getColor(newVec2d(0.0, 1.0)).areClose(newColor(2.0, 1.0, 3.0))
        assert pigment.getColor(newVec2d(1.0, 1.0)).areClose(newColor(3.0, 2.0, 1.0))
    
    test "test Checkered Pigment":
        let color1 = newColor(1.0, 2.0, 3.0)
        let color2 = newColor(10.0, 20.0, 30.0)

        let pigment = newCheckeredPigment(color1, color2, 2)

        # With num_of_steps == 2, the pattern should be the following:
        #
        #              (0.5, 0)
        #   (0, 0) +------+------+ (1, 0)
        #          |      |      |
        #          | col1 | col2 |
        #          |      |      |
        # (0, 0.5) +------+------+ (1, 0.5)
        #          |      |      |
        #          | col2 | col1 |
        #          |      |      |
        #   (0, 1) +------+------+ (1, 1)
        #              (0.5, 1)

        assert pigment.getColor(newVec2d(0.25, 0.25)).areClose(color1)
        assert pigment.getColor(newVec2d(0.75, 0.25)).areClose(color2)
        assert pigment.getColor(newVec2d(0.25, 0.75)).areClose(color2)
        assert pigment.getColor(newVec2d(0.75, 0.75)).areClose(color1)


suite "test pcg.nim":
    test "test on random":
        var pcg = newPCG()

        ##

        assert pcg.state == 1753877967969059832.uint64
        assert pcg.incr == 109

        for expected in [2707161783.uint32, 2068313097.uint32, 
                        3122475824.uint32, 2211639955.uint32,
                        3215226955.uint32, 3421331566.uint32]:
                            assert expected == pcg.random()


suite "test rays.nim":

    test "test on ray.areClose":
        let ray1 = newRay(origin = newPoint(1.0, 2.0, 3.0), dir = newVec(5.0, 4.0, -1.0))
        let ray2 = newRay(origin = newPoint(1.0, 2.0, 3.0), dir = newVec(5.0, 4.0, -1.0))
        let ray3 = newRay(origin = newPoint(5.0, 2.0, 4.0), dir = newVec(3.0, 9.0, 4.0))

        assert ray1.tmax == Inf
        assert ray1.areClose(ray2)
        assert not ray1.areClose(ray3)
        
    test "test on ray.at":
        let ray = newRay(origin = newPoint(1.0, 2.0, 4.0), dir = newVec(4.0, 2.0, 1.0))

        assert ray.at(0.0).areClose(ray.origin)
        assert ray.at(1.0).areClose(newPoint(5.0, 4.0, 5.0))
        assert ray.at(2.0).areClose(newPoint(9.0, 6.0, 6.0))

    test "test on ray.transform":
        let ray = newRay(newPoint(1.0, 2.0, 3.0), newVec(6.0, 5.0, 4.0))
        let transformation = translation(newVec(10.0, 11.0, 12.0)) * rotationX(90.0)
        let transformed = ray.transform(transformation)

        assert transformed.origin.areclose(newPoint(11.0, 8.0, 14.0))
        assert transformed.dir.areclose(newVec(6.0, -4.0, 5.0))


suite "test render.nim":

    test "test on OnOffRenderer":
        let sphere = newSphere(transformation=translation(newVec(2, 0, 0))*scaling(newVec(0.2, 0.2, 0.2)),
                        material=newMaterial(brdf=newDiffuseBRDF(pigment=newUniformPigment(white))))
        let image = newHdrImage(width=3, height=3)
        let camera = newOrthogonalCamera()
        var tracer = newImageTracer(image, camera)
        var world = newWorld()
        world.addShape(sphere)
        let renderer = newOnOffRenderer(world)
        tracer.fireAllRays(ray => call(renderer,ray))

        assert tracer.image.getPixel(0, 0).areClose(black)
        assert tracer.image.getPixel(1, 0).areClose(black)
        assert tracer.image.getPixel(2, 0).areClose(black)

        assert tracer.image.getPixel(0, 1).areClose(black)
        assert tracer.image.getPixel(1, 1).areClose(white)
        assert tracer.image.getPixel(2, 1).areClose(black)

        assert tracer.image.getPixel(0, 2).areClose(black)
        assert tracer.image.getPixel(1, 2).areClose(black)
        assert tracer.image.getPixel(2, 2).areClose(black)

    test "test on FlatRenderer":
        let sphereColor = newColor(1.0, 2.0, 3.0)
        let sphere = newSphere(transformation=translation(newVec(2, 0, 0))*scaling(newVec(0.2, 0.2, 0.2)),
                        material=newMaterial(brdf=newDiffuseBRDF(pigment=newUniformPigment(sphereColor))))
        let image = newHdrImage(width=3, height=3)
        let camera = newOrthogonalCamera()
        var tracer = newImageTracer(image=image, camera=camera)
        var world = newWorld()
        world.addShape(sphere)
        var renderer = newFlatRenderer(world=world)
        tracer.fireAllRays(ray => call(renderer,ray))

        assert tracer.image.getPixel(0, 0).areClose(black)
        assert tracer.image.getPixel(1, 0).areClose(black)
        assert tracer.image.getPixel(2, 0).areClose(black)

        assert tracer.image.getPixel(0, 1).areClose(black)
        assert tracer.image.getPixel(1, 1).areClose(sphereColor)
        assert tracer.image.getPixel(2, 1).areClose(black)

        assert tracer.image.getPixel(0, 2).areClose(black)
        assert tracer.image.getPixel(1, 2).areClose(black)
        assert tracer.image.getPixel(2, 2).areClose(black)
    
    test "test Pathtracer":

        var pcg = newPCG()

        for i in 0 ..< 10:
            var world = newWorld()
            
            let emittedRadiance = pcg.randomFloat()
            let reflectance = pcg.randomFloat() * 0.9
            let enclosureMaterial = newMaterial(
                brdf = newDiffuseBRDF(pigment=newUniformPigment(white*reflectance)),
                emittedRadiance = newUniformPigment(white*emittedRadiance) 
            )
            
            world.addShape(newSphere(material=enclosureMaterial))
            
            let pathTracer = newPathTracer(pcg = pcg, raysNum=1, world=world, maxDepth = 100, rouletteMax=101)

            let ray = newRay(origin = newPoint(0,0,0), dir = newVec(1,0,0))
            let color = pathTracer.call(ray)

            let expected = emittedRadiance / (1.0 - reflectance)
                        

            assert areClose(expected, color.r, epsilon=1e-3)
            assert areClose(expected, color.g, epsilon=1e-3
             )
            assert areClose(expected, color.b, epsilon=1e-3)
        


suite "test shapes.nim (Plane)":

    setup:
        var plane = newPlane()

    test "test Hit":
        let ray1 = newRay(origin = newPoint(0, 0, 1), dir = -vecZ)
        let intersection1 = plane.rayIntersection(ray1)
        assert intersection1.isSome
        assert newHitRecord(
            worldPoint=newPoint(0.0, 0.0, 0.0),
            normal=newNormal(0.0, 0.0, 1.0),
            surfacePoint=newVec2d(0.0, 0.0),
            t=1.0,
            ray=ray1,
        ).areClose(intersection1)

        let ray2 = newRay(origin=newPoint(0, 0, 1), dir=vecZ)
        let intersection2 = plane.rayIntersection(ray2)
        assert intersection2.isNone

        let ray3 = newRay(origin=newPoint(0, 0, 1), dir=vecX)
        let intersection3 = plane.rayIntersection(ray3)
        assert not intersection3.isSome

        let ray4 = newRay(origin=newPoint(0, 0, 1), dir=vecY)
        let intersection4 = plane.rayIntersection(ray4)
        assert intersection4.isNone

    test "test on tranformations":
        plane = newPlane(transformation=rotationY(90.0))

        let ray1 = newRay(origin=newPoint(1, 0, 0), dir = -vecX)
        let intersection1 = plane.rayIntersection(ray1)
        assert intersection1.isSome
        assert newHitRecord(
            worldPoint=newPoint(0.0, 0.0, 0.0),
            normal=newNormal(1.0, 0.0, 0.0),
            surfacePoint=newVec2d(0.0, 0.0),
            t=1.0,
            ray=ray1
        ).areClose(intersection1)

        let ray2 = newRay(origin=newPoint(0, 0, 1), dir=vecZ)
        let intersection2 = plane.rayIntersection(ray2)
        assert not intersection2.isSome

        let ray3 = newRay(origin=newPoint(0, 0, 1), dir=vecX)
        let intersection3 = plane.rayIntersection(ray3)
        assert intersection3.isNone

        let ray4 = newRay(origin=newPoint(0, 0, 1), dir=vecY)
        let intersection4 = plane.rayIntersection(ray4)
        assert not intersection4.isSome

    test "test UVCoordinates":
        
        let ray1 = newRay(origin=newPoint(0, 0, 1), dir= -vecZ)
        let intersection1 = plane.rayIntersection(ray1)
        assert intersection1.get.surfacePoint.areClose(newVec2d(0.0, 0.0))

        let ray2 = newRay(origin=newPoint(0.25, 0.75, 1), dir= -vecZ)
        let intersection2 = plane.rayIntersection(ray2)
        assert intersection2.get.surfacePoint.areClose(newVec2d(0.25, 0.75))

        let ray3 = newRay(origin=newPoint(4.25, 7.75, 1), dir = -vecZ)
        let intersection3 = plane.rayIntersection(ray3)
        assert intersection3.get.surfacePoint.areClose(newVec2d(0.25, 0.75))


suite "test shapes.nim (Spheres)":

    setup:
        var sphere = newSphere()
    
    test "test Hit":
        
        let ray1 = newRay(origin=newPoint(0,0,2), dir= -vecZ)
        let intersection1 = sphere.rayIntersection(ray1)
        assert intersection1.isSome
        assert newHitRecord(
            worldPoint=newPoint(0.0, 0.0, 1.0),
            normal=newNormal(0.0, 0.0, 1.0),
            surfacePoint=newVec2d(0.0, 0.0),
            t=1.0,
            ray=ray1 
        ).areClose(intersection1)

        let ray2 = newRay(origin=newPoint(3,0,0), dir= -vecX)
        let intersection2 = sphere.rayIntersection(ray2)
        assert intersection2.isSome
        assert newHitRecord( 
            worldPoint=newPoint(1.0,0.0,0.0),
            normal=newNormal(1.0,0.0,0.0),
            surfacePoint=newVec2d(0.0,0.5),
            t=2.0,
            ray=ray2
        ).areClose(intersection2)

        assert not sphere.rayIntersection(newRay(origin = newPoint(0, 10, 2), dir= -vecZ)).isSome

    test "test Inner Hit":

        let ray = newRay(origin=newPoint(0,0,0), dir=vecX)
        let intersection = sphere.rayIntersection(ray)
        assert intersection.isSome
        assert newHitRecord(
            worldPoint=newPoint(1.0,0.0,0.0),
            normal=newNormal(-1.0,0.0,0.0),
            surfacePoint=newVec2d(0.0,0.5),
            t=1.0,
            ray=ray
        ).areClose(intersection)
    
    test "test transformation":

        sphere = newSphere(transformation=translation(newVec(10.0,0.0,0.0)))

        let ray1 = newRay(origin=newPoint(10,0,2), dir= -vecZ)
        let intersection1 = sphere.rayIntersection(ray1)
        assert intersection1.isSome
        assert newHitRecord(
            worldPoint=newPoint(10.0,0.0,1.0),
            normal=newNormal(0.0,0.0,1.0),
            surfacePoint=newVec2d(0.0,0.0),
            t=1.0,
            ray=ray1
        ).areClose(intersection1)

        let ray2 = newRay(origin=newPoint(13, 0, 0), dir= -vecX)
        let intersection2 = sphere.rayIntersection(ray2)
        assert intersection2.isSome
        assert newHitRecord(
            worldPoint=newPoint(11.0, 0.0, 0.0),
            normal=newNormal(1.0, 0.0, 0.0),
            surfacePoint=newVec2d(0.0, 0.5),
            t=2.0,
            ray=ray2
        ).areClose(intersection2)

        # Check if the sphre failed to move by trying to hit the untranformed shape 
        assert not sphere.rayIntersection(newRay(origin=newPoint(0, 0, 2), dir= -vecZ)).isSome

        # Check if the *inverse* transformation was wrongly applied
        assert not sphere.rayIntersection(newRay(origin=newPoint(-10, 0, 0), dir= -vecZ)).isSome
    
    test "test on normals":

        sphere = newSphere(transformation=scaling(newVec(2.0, 1.0, 1.0)))

        let ray = newRay(origin=newPoint(1.0, 1.0, 0.0), dir=newVec(-1.0, -1.0, 0.0))
        let intersection = sphere.rayIntersection(ray)
        # We normalize "intersection.normal", as we are not interested in its lenght
        assert intersection.get.normal.normalize().areClose(newNormal(1.0, 4.0, 0.0).normalize())
    
    
    test "test normal direction":
        ## Scaling a sphere by -1 keeps the sphere the same but reverses its
        ## reference frame

        sphere = newSphere(transformation=scaling(newVec(-1.0, -1.0, -1.0)))

        let ray = newRay(origin=newPoint(0.0, 2.0, 0.0), dir = -vecY)
        let intersection = sphere.rayIntersection(ray)
        # We normaize "intersection.normal", as we are not interested in its lenght
        assert intersection.get.normal.normalize().areClose(newNormal(0.0, 1.0, 0.0).normalize())

    test "test UV coordinates":

        # The first four rays hit the unit sphere at the
        # points P1, P2, P3, and P4.
        #
        #                    ^ y
        #                    | P2
        #              , - ~ * ~ - ,
        #          , '       |       ' ,
        #        ,           |           ,
        #       ,            |            ,
        #      ,             |             , P1
        # -----*-------------+-------------*---------> x
        #   P3 ,             |             ,
        #       ,            |            ,
        #        ,           |           ,
        #          ,         |        , '
        #            ' - , _ * _ ,  '
        #                    | P4
        #
        # P5 and P6 are aligned along the x axis and are displaced
        # along z (ray5 in the positive direction, ray6 in the negative
        # direction).

        let ray1 = newRay(origin=newPoint(2.0, 0.0, 0.0), dir= -vecX)
        assert sphere.rayIntersection(ray1).get.surfacePoint.areClose(newVec2d(0.0, 0.5))

        let ray2 = newRay(origin=newPoint(0.0, 2.0, 0.0), dir= -vecY)
        assert sphere.rayIntersection(ray2).get.surfacePoint.areClose(newVec2d(0.25, 0.5))

        let ray3 = newRay(origin=newPoint(-2.0, 0.0, 0.0), dir= vecX)
        assert sphere.rayIntersection(ray3).get.surfacePoint.areClose(newVec2d(0.5, 0.5))

        let ray4 = newRay(origin=newPoint(0.0, -2.0, 0.0), dir= vecY)
        assert sphere.rayIntersection(ray4).get.surfacePoint.areClose(newVec2d(0.75, 0.5))

        let ray5 = newRay(origin=newPoint(2.0, 0.0, 0.5), dir= -vecX)
        assert sphere.rayIntersection(ray5).get.surfacePoint.areClose(newVec2d(0.0, 1/3))

        let ray6 = newRay(origin=newPoint(2.0, 0.0, -0.5), dir= -vecX)
        assert sphere.rayIntersection(ray6).get.surfacePoint.areClose(newVec2d(0.0, 2/3))


suite "test transformations.nim":

    setup:
        let m {.used.} = [
            [1.0, 2.0, 3.0, 4.0],
            [5.0, 6.0, 7.0, 8.0],
            [9.0, 9.0, 8.0, 7.0],
            [6.0, 5.0, 4.0, 1.0],
        ]

        let invm {.used.} = [
                    [-3.75, 2.75, -1, 0],
                    [4.375, -3.875, 2.0, -0.5],
                    [0.5, 0.5, -1.0, 1.0],
                    [-1.375, 0.875, 0.0, -0.5],
                   ]

    test "test on areClose":
        let t1 = newTransformation(m,invm)

        assert (t1.m == m)
        assert (t1.invm == invm)
        assert t1.isConsistent

        let t2 = newTransformation(m,invm)
        assert t1.areClose(t2)

        var t3 = newTransformation(m,invm)
        t3.m[2][2] += 1.0
        assert not t3.isConsistent
        assert not t3.areClose(t2)

        var t4 = newTransformation(m,invm)
        t4.invm[2][3] += 1.0
        assert not t4.areClose(t1)

    test "test on inverse transformation":
        let m1 = newTransformation(m=[
            [1.0, 2.0, 3.0, 4.0],
            [5.0, 6.0, 7.0, 8.0],
            [9.0, 9.0, 8.0, 7.0],
            [6.0, 5.0, 4.0, 1.0],
        ],
        invm=[
            [-3.75, 2.75, -1, 0],
            [4.375, -3.875, 2.0, -0.5],
            [0.5, 0.5, -1.0, 1.0],
            [-1.375, 0.875, 0.0, -0.5],
        ])
        let m2 = m1.inverse()
        assert m2.isConsistent()

        let prod = m1 * m2
        assert prod.isConsistent()
        assert areClose(prod, newTransformation())

    test "test on multiplication":
        let m1= [[3.0, 5.0, 2.0, 4.0],
         [4.0, 1.0, 0.0, 5.0],
         [6.0, 3.0, 2.0, 0.0],
         [1.0, 4.0, 2.0, 1.0]]

        let invm1= [
                    [0.4, -0.2, 0.2, -0.6],
                    [2.9, -1.7, 0.2, -3.1],
                    [-5.55, 3.15, -0.4, 6.45],
                    [-0.9, 0.7, -0.2, 1.1],]

        let t = newTransformation(m,invm)
        let t1 = newTransformation(m1,invm1)

        assert t1.isConsistent()

        let expected = newTransformation(
                [
                    [33.0, 32.0, 16.0, 18.0],
                    [89.0, 84.0, 40.0, 58.0],
                    [118.0, 106.0, 48.0, 88.0],
                    [63.0, 51.0, 22.0, 50.0],
                ],
                [
                    [-1.45, 1.45, -1.0, 0.6],
                    [-13.95, 11.95, -6.5, 2.6],
                    [25.525, -22.025, 12.25, -5.2],
                    [4.825, -4.325, 2.5, -1.1],
                ],)

        assert expected.isConsistent()

        assert expected.areClose(t*t1)

    test "test on rotations":
        assert rotationX(0.1).isConsistent()
        assert rotationY(0.1).isConsistent()
        assert rotationZ(0.1).isConsistent()

        assert (rotationX(theta = 90) * vecY).areClose(vecZ)
        assert (rotationY(theta = 90) * vecZ).areClose(vecX)
        assert (rotationZ(theta = 90) * vecX).areClose(vecY)

    test "test on Vec Transformation multiplication":
        let mPoint = newTransformation(
            m=[
                [1.0, 2.0, 3.0, 4.0],
                [5.0, 6.0, 7.0, 8.0],
                [9.0, 9.0, 8.0, 7.0],
                [0.0, 0.0, 0.0, 1.0],
            ],invm=[
                [-3.75, 2.75, -1, 0],
                [5.75, -4.75, 2.0, 1.0],
                [-2.25, 2.25, -1.0, -2.0],
                [0.0, 0.0, 0.0, 1.0],
            ])
        assert mPoint.isConsistent()

        let vExpected = newVec(14.0, 38.0, 51.0)
        assert areClose(vExpected, mPoint * newVec(1.0, 2.0, 3.0))

        let pExpected = newPoint(18.0, 46.0, 58.0)
        assert areClose(pExpected, mPoint * newPoint(1.0, 2.0, 3.0))

        let nExpected = newNormal(-8.75, 7.75, -3.0)
        assert areClose(nExpected, mPoint * newNormal(3.0, 2.0, 4.0))

    test "test on translations":
        let tr1 = translation(newVec(1.0, 2.0, 3.0))
        assert tr1.isConsistent()
        let tr2 = translation(newVec(4.0, 6.0, 8.0))
        assert tr1.isConsistent()
        let prod = tr1 * tr2
        assert prod.isConsistent()
        let expected = translation(newVec(5.0, 8.0, 11.0))
        assert prod.areClose(expected)

    test "test on scalings":
        let tr1 = scaling(newVec(2.0, 5.0, 10.0))
        assert tr1.isConsistent()
    
        let tr2 = scaling(newVec(3.0, 2.0, 4.0))
        assert tr2.isConsistent()
    
        let expected = scaling(newVec(6.0, 10.0, 40.0))
        assert expected.areClose(tr1 * tr2)


suite "test world.nim":

    setup:
        var world = newWorld()

        let sphere1 = newSphere(transformation = translation(vecX * 2))
        let sphere2 = newSphere(transformation = translation(vecX * 8))
        world.addShape(sphere1)
        world.addShape(sphere2)
    
    test "test on World creation":
        assert world.shapes.len == 2
        assert areClose(world.shapes[0].transformation, translation(vecX * 2))
        assert not areClose(world.shapes[1].transformation, translation(vecX * 6)) 

    test "test on ray intersection":
        let intersection1 = world.rayIntersection(newRay(origin=newPoint(0.0, 0.0, 0.0), dir = vecX))
        assert intersection1.isSome
        assert intersection1.get.worldPoint.areClose(newPoint(1.0, 0.0, 0.0))

        let intersection2 = world.rayIntersection(newRay(origin=newPoint(10.0, 0.0, 0.0), dir = -vecX))

        assert intersection2.isSome
        assert intersection2.get.worldPoint.areClose(newPoint(9.0, 0.0, 0.0))    

