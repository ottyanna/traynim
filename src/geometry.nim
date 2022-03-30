type
    Point* = object
        x*,y*,z* :float64
    
    Transformation* = object
        m*, invm* : array[4, array[4, float64]]
    
    Vec* = object 
        x*, y*, z* : float64

    Normal* = object
        x*, y*, z* : float64


template defineNew3dOp(rettype: typedesc) =
    proc new3dOp*(a, b, c: float64): rettype =
        
        result.x = a
        result.y = b
        result.z = c

defineNew3dOp(Vec)
defineNew3dOp(Point)
defineNew3dOp(Normal)


template print3Dop(type1: typedesc) =
    proc `$`*(a: type1): string =
        ## Parse a 3D obj as a string
        result = "<" & "x: " & $(a.x) & " , " & "y: " & $(a.y) & ", " &
            "z: " & $(a.z) & ">"

print3Dop(Vec)
print3Dop(Point)
print3Dop(Normal)
    
