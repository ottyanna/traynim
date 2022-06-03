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
import materials, world, cameras, geometry, colors, transformations, shapes, hdrimages

const WHITESPACE* = [' ', '\t', '\n', '\r']
const SYMBOLS* = ['(', ')', '<', '>', '[', ']', '*', ',']

type
    SourceLocation* = object
        ## A specific position in a source file
        ## This class has the following fields:
        ## - fileName: the name of the file, or the empty string if there is no file associated with this location
        ##  (e.g., because the source code was provided as a memory stream, or through a network connection)
        ## - lineNum: number of the line (starting from 1)
        ## colNum: number of the column (starting from 1)

        fileName*: string
        lineNum*: int
        colNum*: int


proc `$`*(loc: SourceLocation): string =
    result = "file " & loc.fileName & " at line " & $loc.lineNum &
            " and column " & $loc.colNum & ":"

type
    KeywordEnum* = enum
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
        TRANSLATION = "traslation"
        ROTATIONX = "rotationX"
        ROTATIONY = "rotationY"
        ROTATIONZ = "rotationZ"
        SCALING = "scaling"
        CAMERA = "camera"
        ORTHOGONAL = "orthogonal"
        PERSPECTIVE = "perspective"
        FLOAT = "float"

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
            of keyword: keywords*: KeywordEnum
            of identifier: idWord*: string
            of literalNumber: litNum*: float
            of literalString: litString * : string
            of symbol: sym*: char
            of stopToken: stop*: char

type
    Token* = object
        token*: TokenValue
        location*: SourceLocation

type
    GrammarError* = object
        ## An error found by the lexer/parser while reading a scene file
        ## The fields of this type are the following:
        ## - `fileName`: the name of the file, or the empty string if there is no real file
        ## - `lineNum`: the line number where the error was discovered (starting from 1)
        ## - `colNum`: the column number where the error was discovered (starting from 1)
        error: CatchableError
        location: SourceLocation

type
    InputStream* = object
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


proc updatePos*(inputS: var InputStream, ch: char) =
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

    if inputS.savedChar != '\0':
        result = inputS.savedChar
        inputS.savedChar = '\0'
    else:
        result = inputS.stream.readChar()

    inputS.savedLoc = inputS.location

    inputS.updatePos(result)

proc unreadChar*(inputS: var InputStream, ch: char) =
    assert inputS.savedChar == '\0'
    inputS.savedChar = ch
    inputS.location = inputS.savedLoc

proc skipWhiteSpAndComments*(inputS: var InputStream) =
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
            raise newException(GrammarError.error, $location & " unterminated string")


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
            raise newException(GrammarError.error, $tokenLoc & " " & token & " is an invalid floating-point number.")

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
        return Token(token: TokenValue(kind: keyword, keywords: parseEnum[
                KeywordEnum](token)), location: tokenLoc)

    except ValueError:
        return Token(token: TokenValue(kind: identifier, idWord: token),
                location: tokenLoc)



proc readToken*(inputS: var InputStream): Token =

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
        raise newException(GrammarError.error, $inputS.location &
                " Invalid character " & ch)

proc unreadToken*(inputS: var InputStream, token: Token) = 
    
    assert not inputS.savedToken.isNone
    inputS.savedToken = some(token)
    

type
    Scene* = object
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

proc expectKeywords*(inputS: var InputStream, inputKeywords: seq[
        KeywordEnum]): KeywordEnum =

    ## Read a token from `inputS` and check that is one of the kewywords in `KeywordEnum`

    let inputToken = inputS.readToken()

    if not (inputToken.token.kind == keyword):
        raise newException(GrammarError.error,
    $inputS.location & " expected a keyword instead of " & $inputToken.token.kind)

    if not (inputToken.token.keywords in inputKeywords):
        raise newException(GrammarError.error,
         $inputS & " expected one of the the keywords" & join(inputKeywords,
                 " , ") & "instead of " & $inputToken.token.keywords)

    result = inputToken.token.keywords

proc expectString*(inputS: var InputStream): string =

    ## Read a token from `inputS` and check that is a `literalString`

    let inputToken = inputS.readToken()

    if not (inputToken.token.kind == literalString):
        raise newException(GrammarError.error,
    "got " & $inputToken.token.kind & " instead of a string")

    result = inputToken.token.litString


proc expectSymbol*(s: var InputStream, sym: char) =
    ## Reads a token from `inputS` and check that it matches `symbol`

    let token = s.readToken()

    if ((token.token.kind != symbol) or (token.token.sym != sym)):
        raise newException(GrammarError.error, $s.location & " Got " &
                token.token.sym & " instead of " & sym)

proc expectNumber*(s: var InputStream, scene: Scene): float =
    #"""Read a token from `inputS` and check that it is either a literal number or a variable in `scene`.
    #Return the number as a ``float``."""

    let token = s.readToken()

    if token.token.kind == literalNumber:
        return token.token.litNum
    elif token.token.kind == identifier:
        let variableName = token.token.idWord
        if not (scene.floatVariables).contains(variableName):
            raise newException(GrammarError.error, $s.location &
                    " Unknown variable " & variableName)

        return scene.floatVariables[variableName]

    raise newException(GrammarError.error, $s.location & " Got " &
            $token.token.kind & " instead of a number")


proc expectIdentifier*(s: var InputStream): string =
    ## """Read a token from `inputS` and check that it is an identifier.
    ## Return the name of the identifier."""

    let token = s.readToken()

    if token.token.kind != identifier:
        raise newException(GrammarError.error, $s.location & " Got " &
                $token.token.kind & " instead of an identifier")


    return token.token.idWord

proc parseColor*(InputS: var InputStream, scene: Scene): Color =
    
    expectSymbol(InputS, '<')
    let red = expectNumber(InputS, scene)
    expectSymbol(InputS, ',')
    
    expectSymbol(InputS, '<')
    let green = expectNumber(InputS, scene)
    expectSymbol(InputS, ',')

    expectSymbol(InputS, '<')
    let blue = expectNumber(InputS, scene)
    expectSymbol(InputS, ',')

    result = newColor(red, green, blue)

proc parsePigment*(s: var InputStream, scene: Scene) : Pigment =

    let list = @[KeywordEnum.UNIFORM, KeywordEnum.CHECKERED, KeywordEnum.IMAGE]

    let keyword = expectKeywords(s, list)

    expectSymbol(s, '(')
    if keyword == KeywordEnum.UNIFORM:
        let color = parseColor(s, scene)
        result = newUniformPigment(color=color)
    elif keyword == KeywordEnum.CHECKERED:
        let color1 = parseColor(s, scene)
        expectSymbol(s, ',')
        let color2 = parseColor(s, scene)
        expectSymbol(s, ',')
        let numOfSteps = int(expectNumber(s, scene))
        result = newCheckeredPigment(color1=color1, color2=color2, stepsNum=numOfSteps)
    elif keyword == KeywordEnum.IMAGE:
        let fileName = expectString(s)
        let stream = newFileStream(fileName,fmRead)
        let image = readPfmImage(stream)
        stream.close()
        result = newImagePigment(image=image)
    else:
        assert false, "This line should be unreachable"

    expectSymbol(s, ')') 

proc parseBRDF*(inputS: var InputStream, scene: Scene): BRDF =
    
    let brdfKeyword = expectKeywords(inputS, @[KeywordEnum.DIFFUSE, KeywordEnum.SPECULAR])
    expectSymbol(inputS, '(')

    let pigment = parsePigment(inputS, scene)
    expectSymbol(inputS, ')')

    if brdfKeyword == KeywordEnum.DIFFUSE:
        result = newDiffuseBRDF(pigment=pigment)
    elif brdfKeyword == KeywordEnum.SPECULAR:
        result = newSpecularBRDF(pigment=pigment)
    
    assert false, "This line should be unreacheble"

proc parseVector*(s: var InputStream, scene: Scene) : Vec =

    expectSymbol(s, '[')
    let x = expectNumber(s, scene)
    expectSymbol(s, ',')
    let y = expectNumber(s, scene)
    expectSymbol(s, ',')
    let z = expectNumber(s, scene)
    expectSymbol(s, ']')

    return newVec(x, y, z)

proc parseTransformation*(inputS: var InputStream, scene: Scene): Transformation =
    
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
        
        let nextKeyword = inputS.readToken()
        if nextKeyword.token.kind != symbol or nextKeyword.token.sym != '*':
            inputS.unreadToken(nextKeyword)
            break
    
type 
    coupleMat = object
        name : string
        mat : Material


proc parseMaterial*(s: var InputStream, scene: Scene) : coupleMat=
    let name = expectIdentifier(s)

    expectSymbol(s, '(')
    let brdf = parseBrdf(s, scene)
    expectSymbol(s, ',')
    let emittedRadiance = parsePigment(s, scene)
    expectSymbol(s, ')')

    result.name = name
    result.mat = newMaterial(brdf=brdf, emittedRadiance=emittedRadiance)

proc parseSphere*(inputS: var InputStream, scene: Scene): Sphere =

    expectSymbol(inputS, '(')

    let materialName = expectIdentifier(inputS)
    if not scene.materials.contains(materialName):
        raise newException(GrammarError.error, "Unknown material " & $materialName)
    
    expectSymbol(inputS, ',')
    let transformation = parseTransformation(inputS, scene)
    expectSymbol(inputS, ')')

    result = newSphere(transformation=transformation, material=scene.materials[materialName])

proc parsePlane*(inputS: var InputStream, scene: Scene) : Plane=
    
    expectSymbol(inputS, '(')

    let materialName = expectIdentifier(inputS)
    if not scene.materials.contains(materialName):
        # We raise the exception here because inputS is pointing to the end of the wrong identifier
        raise newException(GrammarError.error, " Unknown material " & materialName)

    expectSymbol(inputS, ',')
    let transformation = parseTransformation(inputS, scene)
    expectSymbol(inputS, ')')

    return newPlane(transformation=transformation, material=scene.materials[materialName])

proc parseCamera*(inputS: var InputStream, scene: Scene) : Camera=
    expectSymbol(inputS, '(')
    let typeKw = expectKeywords(inputS, @[KeywordEnum.PERSPECTIVE, KeywordEnum.ORTHOGONAL])
    expectSymbol(inputS, ',')
    let transformation = parseTransformation(inputS, scene)
    expectSymbol(inputS, ',')
    let aspectRatio = expectNumber(inputS, scene)
    expectSymbol(inputS, ',')
    let distance = expectNumber(inputS, scene)
    expectSymbol(inputS, ')')

    if typeKw == KeywordEnum.PERSPECTIVE:
        result = newPerspectiveCamera(screenDistance=distance, aspectRatio=aspectRatio, transformation=transformation)
    elif typeKw == KeywordEnum.ORTHOGONAL:
        result = newOrthogonalCamera(aspectRatio=aspectRatio, transformation=transformation)

proc parseScene*(inputS: var InputStream, variables: Table[string, float] = initTable[string,float]()): Scene =
    
    ## Read a scene description from a stream and return a `Scene` object
    var scene = newScene()
    
    scene.floatVariables = variables

    for k in variables.keys:
        scene.overriddenVariables.incl(k)
    
    while true:
        var what = inputS.readToken()
        
        if what.token.kind == stopToken:
            break

        if not (what.token.kind == keyword):
            raise newException(GrammarError.error, $what.location & " expected a keyword instead of " & 
            $what.token.kind)    
        
        if what.token.keywords == KeywordEnum.FLOAT:
            let variableName = expectIdentifier(inputS)

            #Save this for the error message
            let variableLoc = inputS.location

            expectSymbol(inputS,'(')
            let variableValue = expectNumber(inputS, scene)
            expectSymbol(inputS, ')')

            if (scene.floatVariables.contains(variableName)) and not (scene.overriddenVariables.contains(variableName)):
                raise newException(GrammarError.error, $variableLoc & "\n" & $variableName & " cannot be redefined")

            if not (scene.overriddenVariables.contains(variableName)):

                # Only define the variable if it was not defined by the user *outside* the scene file
                # (e.g., from the command line)
                scene.floatVariables[variableName] = variableValue

            elif what.token.keywords == KeywordEnum.SPHERE:
                scene.world.addShape(parseSphere(inputS, scene))
            
            elif what.token.keywords == KeywordEnum.PLANE:
                scene.world.addShape(parsePlane(inputS, scene))
            
            elif what.token.keywords == KeywordEnum.CAMERA:
                if scene.camera.isSome:
                    raise newException(GrammarError.error, 
                                        $what.location & " You cannot define more than one camera")
            
                scene.camera = some(parseCamera(inputS, scene))
            
            elif what.token.keywords == KeywordEnum.MATERIAL:

                let mat = parseMaterial(inputS, scene)
                scene.materials[mat.name] = mat.mat

    result = scene