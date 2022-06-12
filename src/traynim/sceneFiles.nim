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

import std/tables, streams, strutils, options, std/sets, hashes
import materials, world, cameras, geometry, colors, transformations, shapes,
        hdrimages, lights

const WHITESPACE* = [' ', '\t', '\n', '\r']
const SYMBOLS* = ['(', ')', '<', '>', '[', ']', '*', ',']

type
    SourceLocation* = object
        ## A specific position in a source file

        fileName*: string ## the name of the file, or the empty string if there is no file associated with this location
                      ##  (e.g., because the source code was provided as a memory stream, or through a network connection)
        lineNum*: int ## number of the line (starting from 1)
        colNum*: int  ## number of the column (starting from 1)


proc `$`*(loc: SourceLocation): string =
    ## Stringify procedure for `SourceLocation` type 
    result = "file " & loc.fileName & " at line " & $loc.lineNum &
            " and column " & $loc.colNum & ":"

type
    KeywordEnum* = enum
        ## Enumeration for all the possible keywords recognized by the lexer
        NEW = "new"
        MATERIAL = "material"
        PLANE = "plane"
        SPHERE = "sphere"
        DIFFUSE = "diffuse"
        SPECULAR = "specular"
        UNIFORM = "uniform"
        CHECKERED = "checkered"
        IMAGE = "image"
        IDENTITY = "identity"
        TRANSLATION = "translation"
        ROTATIONX = "rotationX"
        ROTATIONY = "rotationY"
        ROTATIONZ = "rotationZ"
        SCALING = "scaling"
        CAMERA = "camera"
        ORTHOGONAL = "orthogonal"
        PERSPECTIVE = "perspective"
        FLOAT = "float"
        LIGHT = "light"

type
    TokenType* = enum
        keyword,
        identifier,
        literalNumber,
        literalString,
        symbol,
        stopToken

    TokenValue* = object
        case kind*: TokenType
            of keyword: keywords*: KeywordEnum ## A token containing a keyword
            of identifier: idWord*: string ## A token containing an identifier
            of literalNumber: litNum*: float ## A token containing a literal number
            of literalString: litString * : string ## A token containing a literal string
            of symbol: sym*: char ## A token containing a symbol
            of stopToken: stop*: char ## A token signalling the end of a file

type
    Token* = object
        token*: TokenValue ## A lexical token, used when parsing a scene file
        location*: SourceLocation ## The location of the token

type GrammarError* = object of CatchableError
    ## An error found by the lexer/parser while reading a scene file


type
    InputStream* = object

        ## A high-level wrapper around a stream, used to parse scene files.
        ## This type implements a wrapper around a stream, 
        ## with the following additional capabilities:
        ## 
        ## - It tracks the line number and column number;
        ## 
        ## - It permits to "un-read" characters and tokens.
        
        stream*: Stream
        location*: SourceLocation
        savedChar*: char
        savedLoc*: SourceLocation
        tabulations: int
        savedToken: Option[Token]

proc newInputStream*(stream: Stream, fileName = "",
        tabulations = 8): InputStream =

    result.stream = stream
    result.location = SourceLocation(fileName: fileName, lineNum: 1, colNum: 1)
    result.savedChar = '\0'
    result.savedLoc = result.location
    result.tabulations = tabulations
    result.savedToken = none(Token)


# --------------LEXER--------------

proc updatePos*(inputS: var InputStream, ch: char) =

    ## Updates `location` after having read `ch` from the stream

    if ch == '\0':
        return
    elif ch == '\n':
        inputS.location.lineNum += 1
        inputS.location.colNum = 1
    elif ch == '\t':
        inputS.location.colNum += inputS.tabulations
    else:
        inputS.location.colNum += 1


proc readChar*(inputS: var InputStream): char =

    ## Reads a new character from the stream

    if inputS.savedChar != '\0':
        result = inputS.savedChar
        inputS.savedChar = '\0'
    else:
        result = inputS.stream.readChar()

    inputS.savedLoc = inputS.location

    inputS.updatePos(result)

proc unreadChar*(inputS: var InputStream, ch: char) =

    ## Pushes a character back to the stream

    assert inputS.savedChar == '\0'
    inputS.savedChar = ch
    inputS.location = inputS.savedLoc

proc skipWhiteSpAndComments*(inputS: var InputStream) =

    ## Keeps reading characters until a non-whitespace/non-comment character is found

    var ch = inputS.readChar()

    while (ch in WHITESPACE) or (ch == '#'):
        if ch == '#':
            while not (inputS.readChar() in ['\r', '\n', '\0']):
                discard
        ch = inputS.readChar()
        if ch == '\0':
            return

    inputS.unreadChar(ch)


proc parseStringToken*(inputS: var InputStream,
        location: SourceLocation): Token =

    var token = ""
    while true:
        var ch = inputS.readChar()


        if ch == '"':
            break

        if ch == '\0':
            raise newException(GrammarError, $location & " unterminated string")


        token = token & ch

    return Token(location: location, token: TokenValue(kind: literalString,
            litString: token))

proc parseFloatToken(inputS: var InputStream, firstChar: char,
        tokenLoc: SourceLocation): Token =

    var token: string = $firstChar
    var value: float

    while true:
        var ch = readChar(inputS)

        if not (ch.isDigit() or ch == '.' or ch in ['e', 'E']):
            inputS.unreadChar(ch)
            break

        token = token & ch

    try:
        value = token.parseFloat
    except ValueError:
        raise newException(GrammarError, $tokenLoc & " " & token & " is an invalid floating-point number.")

    return Token(token: TokenValue(kind: literalNumber, litNum: value),
            location: tokenLoc)

proc parseKeywordOrIdentifierToken (inputS: var InputStream, firstChar: char,
        tokenLoc: SourceLocation): Token =

    var token: string = $firstChar

    while true:
        var ch = inputS.readChar()

        if not (ch.isAlphaNumeric() or ch == '_'):
            inputS.unreadChar(ch)
            break

        token = token & ch

    try:
        # If it is a keyword, it must be listed in the KEYWORDS dictionary
        return Token(token: TokenValue(kind: keyword, 
                keywords: parseEnum[KeywordEnum](token)), location: tokenLoc)

    except ValueError:
        # If we got ValueError from parseEnum, it is not a keyword and 
        # thus it must be an identifier
        return Token(token: TokenValue(kind: identifier, idWord: token),
                location: tokenLoc)



proc readToken*(inputS: var InputStream): Token =

    ## Reads a token from the stream.
    ## Raises `GrammarError` if a lexical error is found

    if inputS.savedToken.isSome:
        result = inputS.savedToken.get
        inputS.savedToken = none(Token)
        return result

    inputS.skipWhiteSpAndComments()

    var ch = inputS.readChar()

    if ch == '\0':
        return Token(token: TokenValue(kind: stopToken),
                location: inputS.location)

    result.location = inputS.location

    if ch in SYMBOLS:
        return Token(token: TokenValue(kind: symbol, sym: ch),
                location: inputS.location)

    elif ch == '"':
        return inputS.parseStringToken(result.location)

    elif (ch.isDigit()) or (ch in ['+', '-', '.']):
        return inputS.parseFloatToken(ch, result.location)

    elif (ch.isAlphaAscii()) or (ch == '_'):
        return inputS.parseKeywordOrIdentifierToken(ch, result.location)

    else:
        raise newException(GrammarError, $inputS.location &
                " Invalid character " & ch)

proc unreadToken*(inputS: var InputStream, token: Token) =

    ## Make as if `token` was never read from the stream

    assert inputS.savedToken.isNone
    inputS.savedToken = some(token)



# --------------PARSER--------------

type
    Scene* = object
        ## A scene read from a scene file
        materials*: Table[string, materials.Material]
        world*: World
        camera*: Option[cameras.Camera]
        floatVariables*: Table[string, float]
        overriddenVariables*: HashSet[string]

proc newScene*(): Scene =

    result.materials = initTable[string, materials.Material]()
    result.world = newWorld()
    result.camera = none(cameras.Camera)
    result.floatVariables = initTable[string, float]()
    result.overriddenVariables = initHashSet[string]()

# --------------Expect procs--------------

proc expectKeywords*(inputS: var InputStream, inputKeywords: seq[
        KeywordEnum]): KeywordEnum =

    ## Reads a token from `inputS` and check that is one of the kewywords in `KeywordEnum`.
    ## Returns the keyword as a `KeywordEnum` object.
    
    let inputToken = inputS.readToken()

    if not (inputToken.token.kind == keyword):
        raise newException(GrammarError,
            $inputS.location & " expected a keyword instead of " &
                $inputToken.token.kind)

    if not (inputToken.token.keywords in inputKeywords):
        raise newException(GrammarError,
            $inputS.location & " expected one of the the keywords " & join(
                inputKeywords, " , ") & " instead of " &
                        $inputToken.token.keywords)

    result = inputToken.token.keywords

proc expectString*(inputS: var InputStream): string =

    ## Reads a token from `inputS` and check that is a `literalString`

    let inputToken = inputS.readToken()

    if not (inputToken.token.kind == literalString):
        raise newException(GrammarError,
            "got " & $inputToken.token.kind & " instead of a string")

    result = inputToken.token.litString


proc expectSymbol*(inputS: var InputStream, sym: char) =

    ## Reads a token from `inputS` and check that it matches `symbol`

    let token = inputS.readToken()

    if token.token.kind != symbol:
        raise newException(GrammarError, $inputS.location & " Got " &
                $token.token.kind & " instead of the symbol " & sym)


    elif token.token.sym != sym:
        raise newException(GrammarError, $inputS.location & " Got " &
                token.token.sym & " instead of " & sym)


proc expectNumber*(inputS: var InputStream, scene: Scene): float =

    ## Reads a token from `inputS` and check that it is either a 
    ## literal number or a variable in `scene`.
    ## Returns the number as a ``float``.

    let token = inputS.readToken()

    if token.token.kind == literalNumber:
        return token.token.litNum
    elif token.token.kind == identifier:
        let variableName = token.token.idWord
        if not (scene.floatVariables).contains(variableName):
            raise newException(GrammarError, $inputS.location &
                    " Unknown variable " & variableName)

        return scene.floatVariables[variableName]

    raise newException(GrammarError, $inputS.location & " Got " &
            $token.token.kind & " instead of a number")


proc expectIdentifier*(inputS: var InputStream): string =

    ## Reads a token from `inputS` and check that it is an identifier.
    ## Returns the name of the identifier.

    let token = inputS.readToken()

    if token.token.kind != identifier:
        raise newException(GrammarError, $inputS.location & " Got " &
                $token.token.kind & " instead of an identifier")


    return token.token.idWord


# --------------Parse procs--------------

proc parseColor*(InputS: var InputStream, scene: Scene): Color =

    expectSymbol(InputS, '<')
    let red = expectNumber(InputS, scene)
    expectSymbol(InputS, ',')

    let green = expectNumber(InputS, scene)
    expectSymbol(InputS, ',')

    let blue = expectNumber(InputS, scene)
    expectSymbol(InputS, '>')

    result = newColor(red, green, blue)

proc parsePigment*(inputS: var InputStream, scene: Scene): Pigment =

    let list = @[KeywordEnum.UNIFORM, KeywordEnum.CHECKERED, KeywordEnum.IMAGE]

    let keyword = expectKeywords(inputS, list)

    expectSymbol(inputS, '(')
    if keyword == KeywordEnum.UNIFORM:
        let color = parseColor(inputS, scene)
        result = newUniformPigment(color = color)
    elif keyword == KeywordEnum.CHECKERED:
        let color1 = parseColor(inputS, scene)
        expectSymbol(inputS, ',')
        let color2 = parseColor(inputS, scene)
        expectSymbol(inputS, ',')
        let numOfSteps = int(expectNumber(inputS, scene))
        result = newCheckeredPigment(color1 = color1, color2 = color2,
                stepsNum = numOfSteps)
    elif keyword == KeywordEnum.IMAGE:
        let fileName = expectString(inputS)
        var stream: Stream
        try:
            stream = openFileStream(fileName, fmRead)
        except IOError:
            raise newException(GrammarError, $inputS.location & " " &
                    getCurrentExceptionMsg())
        let image = readPfmImage(stream)
        stream.close()
        result = newImagePigment(image = image)
    else:
        assert false, "This line should be unreachable"

    expectSymbol(inputS, ')')

proc parseBRDF*(inputS: var InputStream, scene: Scene): BRDF =

    let brdfKeyword = expectKeywords(inputS, @[KeywordEnum.DIFFUSE,
            KeywordEnum.SPECULAR])

    expectSymbol(inputS, '(')
    let pigment = parsePigment(inputS, scene)
    expectSymbol(inputS, ')')

    if brdfKeyword == KeywordEnum.DIFFUSE:
        return newDiffuseBRDF(pigment = pigment)
    elif brdfKeyword == KeywordEnum.SPECULAR:
        return newSpecularBRDF(pigment = pigment)

    assert false, "This line should be unreacheble"

proc parseVector*(inputS: var InputStream, scene: Scene): Vec =


    expectSymbol(inputS, '[')
    let x = expectNumber(inputS, scene)
    expectSymbol(inputS, ',')
    let y = expectNumber(inputS, scene)
    expectSymbol(inputS, ',')
    let z = expectNumber(inputS, scene)
    expectSymbol(inputS, ']')

    return newVec(x, y, z)

proc parseTransformation*(inputS: var InputStream,
        scene: Scene): Transformation =

    result = newTransformation()

    while true:
        let transfKeywords = expectKeywords(inputS,
            @[KeywordEnum.IDENTITY,
            KeywordEnum.TRANSLATION,
            KeywordEnum.ROTATIONX,
            KeywordEnum.ROTATIONY,
            KeywordEnum.ROTATIONZ,
            KeywordEnum.SCALING])

        if transfKeywords == KeywordEnum.IDENTITY:
            discard
        elif transfKeywords == KeywordEnum.TRANSLATION:
            expectSymbol(inputS, '(')
            result = result * translation(parseVector(inputS, scene))
            expectSymbol(inputS, ')')

        elif transfKeywords == KeywordEnum.ROTATIONX:
            expectSymbol(inputS, '(')
            result = result * rotationX(expectNumber(inputS, scene))
            expectSymbol(inputS, ')')
        
        elif transfKeywords == KeywordEnum.ROTATIONY:
            expectSymbol(inputS, '(')
            result = result * rotationY(expectNumber(inputS, scene))
            expectSymbol(inputS, ')')
        
        elif transfKeywords == KeywordEnum.ROTATIONZ:
            expectSymbol(inputS, '(')
            result = result * rotationZ(expectNumber(inputS, scene))
            expectSymbol(inputS, ')')
        
        elif transfKeywords == KeywordEnum.SCALING:
            expectSymbol(inputS, '(')
            result = result * scaling(parseVector(inputS, scene))
            expectSymbol(inputS, ')')

        
        # We must peek the next token to check if there 
        # is another transformation that is being
        # chained or if the sequence ends. Thus, this is a LL(1) parser.

        let nextKeyword = inputS.readToken()
        if nextKeyword.token.kind != symbol or nextKeyword.token.sym != '*':
            inputS.unreadToken(nextKeyword)
            break

type
    coupleMat = object
        name: string
        mat: Material


proc parseMaterial*(inputS: var InputStream, scene: Scene): coupleMat =
    let name = expectIdentifier(inputS)

    expectSymbol(inputS, '(')
    let brdf = parseBrdf(inputS, scene)
    expectSymbol(inputS, ',')
    let emittedRadiance = parsePigment(inputS, scene)
    expectSymbol(inputS, ')')

    result.name = name
    result.mat = newMaterial(brdf = brdf, emittedRadiance = emittedRadiance)

proc parseSphere*(inputS: var InputStream, scene: Scene): Sphere =

    expectSymbol(inputS, '(')

    let materialName = expectIdentifier(inputS)
    if not scene.materials.contains(materialName):
        raise newException(GrammarError, $inputS.location &
                "Unknown material " & $materialName)

    expectSymbol(inputS, ',')
    let transformation = parseTransformation(inputS, scene)
    expectSymbol(inputS, ')')

    result = newSphere(transformation = transformation,
            material = scene.materials[materialName])

proc parsePlane*(inputS: var InputStream, scene: Scene): Plane =

    expectSymbol(inputS, '(')

    let materialName = expectIdentifier(inputS)
    if not scene.materials.contains(materialName):
        # We raise the exception here because inputS is pointing to the end of the wrong identifier
        raise newException(GrammarError, $inputS.location &
                " Unknown material " & materialName)

    expectSymbol(inputS, ',')
    let transformation = parseTransformation(inputS, scene)
    expectSymbol(inputS, ')')

    return newPlane(transformation = transformation, material = scene.materials[materialName])

proc parseLight*(inputS: var InputStream, scene: Scene): PointLight =

    expectSymbol(inputS, '(')
    let position = parseVector(inputS, scene).parseVecToPoint()

    expectSymbol(inputS, ',')

    let color = parseColor(inputS, scene)

    # We must check if there is the value for the linearRadius. 

    let nextToken = inputS.readToken()
    
    if nextToken.token.kind == symbol and nextToken.token.sym == ')':
        return newPointLight(position, color)
    else:
        inputS.unreadToken(nextToken)
        expectSymbol(inputS, ',')
        let linearRadius = expectNumber(inputS, scene)
        expectSymbol(inputS,')')
        return newPointLight(position, color, linearRadius)


proc parseCamera*(inputS: var InputStream, scene: Scene): Camera =

    expectSymbol(inputS, '(')
    let typeKw = expectKeywords(inputS, @[KeywordEnum.PERSPECTIVE,
            KeywordEnum.ORTHOGONAL])
    expectSymbol(inputS, ',')
    let transformation = parseTransformation(inputS, scene)
    expectSymbol(inputS, ',')
    let aspectRatio = expectNumber(inputS, scene)
    expectSymbol(inputS, ',')
    let distance = expectNumber(inputS, scene)
    expectSymbol(inputS, ')')

    if typeKw == KeywordEnum.PERSPECTIVE:
        result = newPerspectiveCamera(screenDistance = distance,
                aspectRatio = aspectRatio, transformation = transformation)
    elif typeKw == KeywordEnum.ORTHOGONAL:
        result = newOrthogonalCamera(aspectRatio = aspectRatio,
                transformation = transformation)


# --------------PARSE SCENE--------------

proc parseScene*(inputS: var InputStream, variables: Table[string,
        float] = initTable[string, float]()): Scene =

    ## Reads a scene description from a stream and return a `Scene` object
    
    var scene = newScene()

    scene.floatVariables = variables

    for k in variables.keys:
        scene.overriddenVariables.incl(k)

    while true:
        var what = inputS.readToken()

        if what.token.kind == stopToken:
            break

        if not (what.token.kind == keyword):
            raise newException(GrammarError, $what.location &
            " expected a keyword instead of " &
            $what.token.kind)

        if what.token.keywords == KeywordEnum.FLOAT:

            let variableName = expectIdentifier(inputS)

            #Save this for the error message
            let variableLoc = inputS.location

            expectSymbol(inputS, '(')
            let variableValue = expectNumber(inputS, scene)
            expectSymbol(inputS, ')')

            if (scene.floatVariables.contains(variableName)) and not (
                    scene.overriddenVariables.contains(variableName)):
                raise newException(GrammarError, $variableLoc & "\n" &
                        $variableName & " cannot be redefined")

            if not (scene.overriddenVariables.contains(variableName)):

                # Only define the variable if it was not defined by the user *outside* the scene file
                # (e.g., from the command line)
                scene.floatVariables[variableName] = variableValue

        elif what.token.keywords == KeywordEnum.SPHERE:
            scene.world.addShape(parseSphere(inputS, scene))

        elif what.token.keywords == KeywordEnum.PLANE:
            scene.world.addShape(parsePlane(inputS, scene))

        elif what.token.keywords == KeywordEnum.LIGHT:
            scene.world.addLight(parseLight(inputS, scene))

        elif what.token.keywords == KeywordEnum.CAMERA:
            if scene.camera.isSome:
                raise newException(GrammarError,
                                    $what.location & " You cannot define more than one camera")

            scene.camera = some(parseCamera(inputS, scene))

        elif what.token.keywords == KeywordEnum.MATERIAL:
            let mat = parseMaterial(inputS, scene)
            scene.materials[mat.name] = mat.mat

    result = scene
