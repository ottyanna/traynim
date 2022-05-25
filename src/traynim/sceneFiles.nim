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

import std/tables, streams, strutils

const WHITESPACE* = ['\0','\t','\n','\r']
const SYMBOLS* = ['(',')','<','>','[',']','*']

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
    result="file " & loc.fileName & "at line " & $loc.lineNum & " and column " & $loc.colNum 

type
    KeywordEnum* = enum
        NEW = 1
        MATERIAL = 2
        PLANE = 3
        SPHERE = 4
        DIFFUSE = 5
        SPECULAR = 6
        UNIFORM = 7
        CHECKERED = 8
        IMAGE = 9
        IDENTITY = 10
        TRANSLATION = 11
        ROTATIONX = 12
        ROTATIONY = 13
        ROTATIONZ = 14
        SCALING = 15
        CAMERA = 16
        ORTHOGONAL = 17
        PERSPECTIVE = 18
        FLOAT = 19


const KEYWORDS* = {
    "new": KeywordEnum.NEW,
    "material": KeywordEnum.MATERIAL,
    "plane": KeywordEnum.PLANE,
    "sphere": KeywordEnum.SPHERE,
    "diffuse": KeywordEnum.DIFFUSE,
    "specular": KeywordEnum.SPECULAR,
    "uniform": KeywordEnum.UNIFORM,
    "checkered": KeywordEnum.CHECKERED,
    "image": KeywordEnum.IMAGE,
    "identity": KeywordEnum.IDENTITY,
    "translation": KeywordEnum.TRANSLATION,
    "rotationX": KeywordEnum.ROTATIONX,
    "rotationY": KeywordEnum.ROTATIONY,
    "rotationZ": KeywordEnum.ROTATIONZ,
    "scaling": KeywordEnum.SCALING,
    "camera": KeywordEnum.CAMERA,
    "orthogonal": KeywordEnum.ORTHOGONAL,
    "perspective": KeywordEnum.PERSPECTIVE,
    "float": KeywordEnum.FLOAT,
}.toTable


type
    TokenType* = enum #Tag
        keyword,
        identifier,
        literalNumber,
        literalString,
        symbol,
        stopToken
    Token* = ref TokenValue
    TokenValue* = object #Union
        case kind* : TokenType
            of keyword: kWord*: string
            of identifier: idWord*: string 
            of literalNumber: litNum* : float
            of literalString: litString* : string
            of symbol: sym* : char
            of stopToken : stop* : char

type 
    TokenLoc* = object
        token* :Token
        location* :SourceLocation

#var num = Token(kind: literalNumber, litNum : 0.1)

proc assign*(token:Token)=
    
    case token.kind:
        of keyword: token.kWord="ok"
        of identifier: discard 
        of literalNumber: discard
        of literalString: discard
        of symbol: discard
        of stopToken : discard

type
    GrammarError* = object of CatchableError
    #[An error found by the lexer/parser while reading a scene file
    The fields of this type are the following:
    - `file_name`: the name of the file, or the empty string if there is no real file
    - `line_num`: the line number where the error was discovered (starting from 1)
    - `col_num`: the column number where the error was discovered (starting from 1)
    - `message`: a user-frendly error message
    """]#

type
    InputStream* = object
        stream*: Stream
        location* :SourceLocation
        savedChar*: char
        savedLoc*: SourceLocation
        tabulations : int
        savedToken : Token

proc newInputStream*(stream:Stream, fileName="", tabulations=8):InputStream=
        
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


proc readToken*(inputS:var InputStream): TokenLoc =

    inputS.skipWhiteSpAndComments()

    var ch = inputS.readChar()

    if ch == '\0':
        return TokenLoc(token : Token(kind: stopToken),location: inputS.location)

    result.location=inputS.location

    if ch in SYMBOLS:
        return TokenLoc(token : Token(kind: symbol, sym: ch),location: inputS.location)

    elif ch == '"':
        return parseStringToken(result.location)
    
    elif (ch.isDigit()) or (ch in ['+','-','.']):
        return parseFloatToken(ch,result.location)

    elif (ch.isAlphaAscii()) or (ch == '_'):
        return parseKeywordOrIdentifierToken(ch,result.location)

    else:
        raise newException(GrammarError, "Invalid character " & ch & " in " & $inputS.location)