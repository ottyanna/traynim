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
        
        ## Creates a new 3d object of type `Vec`, `Point` and `Normal`


        result.x = a
        result.y = b
        result.z = c

defineNew3dObj(newVec,Vec)
defineNew3dObj(newPoint,Point)
defineNew3dObj(newNormal,Normal)


template define3dOp(fname: untyped, type1: typedesc, type2: typedesc, rettype: typedesc) =
    proc fname*(a: type1, b: type2): rettype =

        ## Implements operations such as sum(`+`) and diff(`-`) on 3d objects

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
    proc `*`*(a: type1, b: type2): float64 =

        ## Implements scalar product operation on 3d objects such as `Vec` and `Normal`

        result = (a.x * b.x + a.y * b.y + a.z * b.z)

    
defineDotProd(Vec,Vec)    
defineDotProd(Vec,Normal)

template defineProdWithScalar(rettype: typedesc) =
    proc `*`*(scalar: float64, a: rettype): rettype = 

        ## Implements scalar product with a 3d objects such as `Vec` and `Normal` operation
         
        result.x = scalar * a.x
        result.y = scalar * a.y
        result.z = scalar * a.z

defineProdWithScalar(Vec)
defineProdWithScalar(Normal)    

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
    
