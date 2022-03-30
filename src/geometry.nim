type
    Point* = object
        x*,y*,z* :float64
    
    Transformation* = object
        m*, invm* : array[4, array[4, float64]]