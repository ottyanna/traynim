import transformations, materials

type
    Shape* = ref object of RootObj

        ## A generic 3D shape 
        ## It's an abstract object
        ## Make sure to derive *real* object from it
        
        transformation*: Transformation
        material*: Material