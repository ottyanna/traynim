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

import streams, strutils

const WHITESPACE* = [' ','\t','\n','\r']
const SYMBOLS* = ['(',')','<','>','[',']','*',',']

type
    SourceLocation* = object
    #[A specific position in a source file
    This class has the following fields:
    - file_name: the name of the file, or the empty string if there is no file associated with this location
      (e.g., because the source code was provided as a memory stream, or through a network connection)
    - line_num: number of the line (starting from 1)
    - col_num: number of the column (starting from 1)
    ]#
        fileName*: string
        lineNum*: int
        colNum*: int 


proc `$`*(loc:SourceLocation):string=
    result="file " & loc.fileName & "at line " & $loc.lineNum & " and column " & $loc.colNum & ":"

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
        case kind* : TokenType
            of keyword: keywords*: KeywordEnum
            of identifier: idWord*: string 
            of literalNumber: litNum* : float
            of literalString: litString* : string
            of symbol: sym* : char
            of stopToken : stop* : char

type 
    Token* = object
        token* : TokenValue
        location* : SourceLocation

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
        location* : SourceLocation
        savedChar*: char
        savedLoc*: SourceLocation
        tabulations : int
        savedToken : Token

proc newInputStream*(stream:Stream, fileName="", tabulations=8): InputStream=
        
        result.stream = stream

        result.location = SourceLocation(fileName:fileName, lineNum:1, colNum:1)

        result.savedChar = '\0'
        result.savedLoc = result.location
        result.tabulations = tabulations

        #result.savedToken: Option[Token, None] = None

proc updatePos*(inputS:var InputStream, ch:char)=
    if ch == '\0':
        return
    elif ch == '\n':
        inputS.location.lineNum += 1
        inputS.location.colNum = 1
    elif ch == '\t':
        inputS.location.colNum += inputS.tabulations
    else:
        inputS.location.colNum += 1

proc readChar*(inputS: var InputStream):char=

    if inputS.savedChar != '\0':
        result=inputS.savedChar
        inputS.savedChar='\0'
    else:
        result=inputS.stream.readChar()

    inputS.savedLoc = inputS.location

    inputS.updatePos(result)

proc unreadChar*(inputS:var InputStream, ch:char)=
    assert inputS.savedChar == '\0'
    inputS.savedChar=ch
    inputS.location=inputS.savedLoc

proc skipWhiteSpAndComments*(inputS: var InputStream)=
    var ch = inputS.readChar()

    while (ch in WHITESPACE) or (ch == '#'):
        if ch == '#':
            while not (inputS.readChar() in ['\r','\n','\0']):
                discard  
        ch=inputS.readChar()
        if ch == '\0':
            return

    inputS.unreadChar(ch)


proc parseStringToken*(inputS: var InputStream, location: SourceLocation) : Token =
    
    var token = ""
    while true:
        var ch = inputS.readChar()
        

        if ch == '"':
            break

        if ch == '\0': #not sure about this
            raise newException(GrammarError.error, $location & " unterminated string")


        token = token & ch

    return Token(location : location, token : TokenValue( kind: literalString, litString: token))

proc parseFloatToken(inputS: var InputStream, firstChar: char, tokenLoc: SourceLocation) : Token =
    
    var token : string = $firstChar
    var value : float
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

        return Token(token : TokenValue(kind : literalNumber, litNum: value), location : tokenLoc)

proc parseKeywordOrIdentifierToken (inputS: var InputStream, firstChar: char, tokenLoc: SourceLocation) : Token = 

    var token : string = $firstChar
    
    while true:
        var ch = inputS.readChar()
        
        if not (ch.isAlphaNumeric() or ch == '_'):
            inputS.unreadChar(ch)
            break

        token = token & ch

    try:
        return Token(token : TokenValue(kind : keyword, keywords: parseEnum[KeywordEnum](token)), location: tokenLoc)
    
    except ValueError:
        return Token(token : TokenValue(kind : identifier, idWord : token), location : tokenLoc)
    
    

proc readToken*(inputS:var InputStream): Token =

    inputS.skipWhiteSpAndComments()

    var ch = inputS.readChar()

    if ch == '\0':
        return Token(token : TokenValue(kind: stopToken), location: inputS.location)

    result.location=inputS.location

    if ch in SYMBOLS:
        return Token(token : TokenValue(kind: symbol, sym: ch),location: inputS.location)

    elif ch == '"':
        return inputS.parseStringToken(result.location)
    
    elif (ch.isDigit()) or (ch in ['+','-','.']):
        return inputS.parseFloatToken(ch,result.location)

    elif (ch.isAlphaAscii()) or (ch == '_'):
        return inputS.parseKeywordOrIdentifierToken(ch,result.location)

    else:
        raise newException(GrammarError.error, $inputS.location & " Invalid character " & ch)