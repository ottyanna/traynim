type
    Point* = object
        x*,y*,z* :float64
    
    Transformation* = object
        m*, invm* : array[4, array[4, float64]]
    
    Vec* = object 
        x*, y*, z* : float64

    Normal* = object
        x*, y*, z* : float64


template defineNew3dOp(fname: untyped, rettype: typedesc) =
    proc fname*(a, b, c: float64): rettype =
        
        ## Creates a new 3D object


        result.x = a
        result.y = b
        result.z = c

defineNew3dOp(newVec,Vec)
defineNew3dOp(newPoint,Point)
defineNew3dOp(newNormal,Normal)


template defineNew3dOp(rettype: typedesc) =
    proc new3dOp*(res: var rettype, a, b, c: float64) =
        
        ##
        ## Creates new 3d object. 
        ## 
        ## It needs also the 3d object (`Vec`, `Point`, `Normal`)
        ## as `var` parameters.
        ## 
        
        res.x = a
        res.y = b
        res.z = c

defineNew3dOp(Vec)
defineNew3dOp(Point)
defineNew3dOp(Normal)


#[ template defineNew3dOp(rettype: untyped) =
    proc new3dOp*(a, b, c: float64): rettype =
        
        result.x = a
        result.y = b
        result.z = c

defineNew3dOp(Vec)
defineNew3dOp(Point)
defineNew3dOp(Normal)

Wrong it's like this.. it's ambiguous
proc newVec*(a: float64, b: float64, c: float64): Vec =
        
        result.x = a
        result.y = b
        result.z = c


proc newVec*(a: float64, b: float64, c: float64): Point =
        
        result.x = a
        result.y = b
        result.z = c

 ]#

template print3Dop(type1: typedesc) =
    proc `$`*(a: type1): string =
        ## Parse a 3D obj as a string
        result = "<" & "x: " & $(a.x) & " , " & "y: " & $(a.y) & ", " &
            "z: " & $(a.z) & ">"

print3Dop(Vec)
print3Dop(Point)
print3Dop(Normal)
    
