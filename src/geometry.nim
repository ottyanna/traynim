type
    Point* = object
        x*,y*,z* :float64
    
    Transformation* = object
        m*, invm* : array[4, array[4, float64]]
    
    Vec* = object 
        x*, y*, z* : float64

    Normal* = object
        x*, y*, z* : 
            

template new3dOp(rettype: typedesc) =
    proc new3dOp*(a, b, c: float64): rettype =
        result.x = a
        result.y = b
        result.z = c
