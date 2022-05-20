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


## This module implements different algorithms for rendering

import colors, ray, world, materials, shapesDef, pcg
from geometry import normalizedDot, `-`, `*`, norm
import options

type Renderer* = ref object of RootObj
    ## generic renderer
    world*: World
    backgroundColor*: Color

method newBaseRenderer*(renderer: Renderer, world: World,
        backgroundColor = black) {.base.} =
    renderer.backgroundColor = backgroundColor
    renderer.world = world

method call*(renderer: Renderer, ray: Ray): Color {.base.} =
    quit "to override!"

type OnOffRenderer* = ref object of Renderer
    ## A on/off renderer: everything is of two colors (`backgroundColor` and `color`).
    color*: Color

proc newOnOffRenderer*(world: World, backgroundColor = black,
        color = white): OnOffRenderer =
    new(result)
    result.newBaseRenderer(world, backgroundColor)
    result.color = color

method call*(renderer: OnOffRenderer, ray: Ray): Color =
    ## Calls the image rendering where the shapes are in solid color `color`.
    if renderer.world.rayIntersection(ray).isSome:
        return renderer.color
    else: return renderer.backgroundColor


type FlatRenderer* = ref object of Renderer
    ## A «flat» renderer
    ## This renderer estimates the solution of the rendering equation by neglecting any contribution of the light.
    ## It just uses the pigment of each surface to determine how to compute the final radiance.

proc newFlatRenderer*(world: World, backgroundColor = black): FlatRenderer =
    new(result)
    result.newBaseRenderer(world, backgroundColor)



method call*(renderer: FlatRenderer, ray: Ray) : Color=
        let hit = renderer.world.rayIntersection(ray)
        if hit.isNone:
            return renderer.backgroundColor

        let material = (hit.get).shape.material

        result= (material.brdf.pigment.getColor((hit.get).surfacePoint) +
                material.emittedRadiance.getColor((hit.get).surfacePoint))


type
    PathTracer* = ref object of Renderer
        pcg* : PCG
        raysNum* : int
        maxDepth* : int
        rouletteMax* : int

proc newPathTracer*(world: World, backgroundColor = black, pcg: PCG, raysNum=10, maxDepth=2, rouletteMax=3): PathTracer =
    new(result)
    result.newBaseRenderer(world, backgroundColor)
    result.pcg = pcg
    result.raysNum = raysNum
    result.maxDepth = maxDepth
    result.rouletteMax = rouletteMax
    
method call*(renderer: PathTracer, ray: Ray) : Color = 
    {.warning[LockLevel]:off.} # essential to avoid a useless warning
    if ray.depth > renderer.maxDepth:
        return black 
    
    let hitRecord = renderer.world.rayIntersection(ray)
    if hitRecord.isNone :
        return renderer.backgroundColor

    let hitMaterial = hitRecord.get.shape.material

    var hitColor = hitMaterial.brdf.pigment.getColor(hitRecord.get.surfacePoint)

    let emittedRadiance = hitMaterial.emittedRadiance.getColor(hitRecord.get.surfacePoint)

    let hitColorLum = max(hitColor.r,max(hitColor.g,hitColor.b))

    if ray.depth >= renderer.rouletteMax:
        let q = max(0.05,1-hitColorLum)
        if renderer.pcg.randomFloat > q:
            hitColor = hitColor * (1.0/(1.0-q))
        else:
            return emittedRadiance
    
    var cumRadiance = black

    if hitColorLum > 0.0:
        for rayIndex in 0..<renderer.raysNum:
            let newRay = hitMaterial.brdf.scatterRay(
                pcg = renderer.pcg,
                incomingDir = hitRecord.get.ray.dir,
                interactionPoint = hitRecord.get.worldPoint,
                normal = hitRecord.get.normal,
                depth = ray.depth + 1
                )
            let newRadiance = renderer.call(newRay)
            cumRadiance = cumRadiance + hitColor*newRadiance


    return emittedRadiance + cumRadiance*(1.0/renderer.raysNum.float)

type 
    PointLightRenderer* = ref object of Renderer

        ## A simple point-light renderer
        ## This renderer is similar to what POV-Ray provides by default
        
        ambientColor*: Color

proc newPointLightRenderer*(world: World, backgroundColor: Color = black, 
            ambientColor: Color = newColor(0.1, 0.1, 0.1)): PointLightRenderer = 
            
            new(result)

            result.newBaseRenderer(world, backgroundColor)
            result.ambientColor = ambientColor

method call*(renderer: PointLightRenderer, ray: Ray) : Color = 

    let hitRecord = renderer.world.rayIntersection(ray)

    if hitRecord.isNone:
        return renderer.backgroundColor

    let hitMaterial = hitRecord.get.shape.material

    var resultColor = renderer.ambientColor
    for curLights in renderer.world.pointLights:
        if renderer.world.isPointVisible(point = curLights.position, observerPos = hitRecord.get.worldPoint):
            let distanceVec = hitRecord.get.worldPoint - curLights.position
            let distance = distanceVec.norm()
            let inDir = distanceVec * (1.0 / distance)
            let cosTheta = max(0.0, normalizedDot(-ray.dir, hitRecord.get.normal))

            let distanceFactor =  (if curLights.linearRadius > 0: ((curLights.linearRadius / distance)*(curLights.linearRadius / distance)) else: 1.0)

            
            let emittedColor = hitMaterial.emittedRadiance.getColor(hitRecord.get.surfacePoint)
            let brdfColor = hitMaterial.brdf.eval(
                normal = hitRecord.get.normal,
                inDir = inDir,
                outDir = -ray.dir,
                uv = hitRecord.get.surfacePoint
            )

            resultColor = resultColor + (emittedColor + brdfColor) * curLights.color * cosTheta * distanceFactor

    result = resultColor




     
