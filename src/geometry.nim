type
    Point* = object
        x*,y*,z* :float64
    
    Transformation* = object
        m*, invm* : array[4, array[4, float64]]
    
    Vec* = object 
        x*, y*, z* : float64

    Normal* = object
        x*, y*, z* : float64


template defineNew3dObj(fname: untyped, rettype: typedesc) =
    proc fname*(a, b, c: float64): rettype =
        
        ## Creates a new 3D object


        result.x = a
        result.y = b
        result.z = c

defineNew3dObj(newVec,Vec)
defineNew3dObj(newPoint,Point)
defineNew3dObj(newNormal,Normal)


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
template define3dOp(fname: untyped, type1: typedesc, type2: typedesc, rettype: typedesc) =
    proc fname*(a: type1, b: type2): rettype =
        result.x = fname(a.x, b.x)
        result.y = fname(a.y, b.y)
        result.z = fname(a.z, b.z)

define3dOp(`+`,Vec,Vec,Vec)
define3dOp(`-`,Vec,Vec,Vec)
define3dOp(`+`,Vec,Point,Point)
define3dOp(`+`,Point,Vec,Point)
define3dOp(`-`,Point,Vec,Point)
define3dOp(`+`,Normal,Normal,Normal)
define3dOp(`-`,Normal,Normal,Normal)

template defineDotProd(type1: typedesc, type2: typedesc) =
    proc dot*(a: type1, b: type2): float64 = 
        result = (a.x * b.x + a.y * b.y + a.z * b.z)

defineDotProd(Vec,Vec)    
defineDotProd(Vec,Normal)    

template defineScalarProd(fname: untyped, rettype: typedesc) =
    proc fname*(scalar: float64, a: rettype): rettype = 
        result.x = fname(scalar, a.x)
        result.y = fname(scalar, a.y)
        result.z = fname(scalar, a.z)

defineScalarProd(`*`, Vec)
defineScalarProd(`*`, Normal)
    

template defineMirrorOp(rettype: typedesc) =
    proc neg*(a: var rettype): rettype = 
        result.x = -a.x
        result.y = -a.y
        result.z = -a.z

defineMirrorOp(Vec)
defineMirrorOp(Normal)
    

template print3dObj(fname: untyped, type1: typedesc) =
    proc fname*(a: type1): string =
        ## Parse a 3D obj as a string
        result = "<" & "x: " & $(a.x) & " , " & "y: " & $(a.y) & ", " &
            "z: " & $(a.z) & ">"

print3dObj(`$`, Vec)
print3dObj(`$`, Point)
print3dObj(`$`, Normal)
    
