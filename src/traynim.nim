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


import strutils, streams, traynim/hdrimages, cligen

type
    Parameters = object
        inPfmFileName: string
        factor: float32
        gamma: float32
        outputFileName: string

type RuntimeError = object of CatchableError

proc pfm2format(inPfmFileName: string, factor: float32 = 0.2, gamma: float32 = 1.0, outFileName: string)=

    let parameters = Parameters(inPfmFileName: inPfmFileName, factor : 1.0, gamma : 1.0, outputFileName : outFileName)

    let inPfm = newFileStream(parameters.inPfmFileName, fmRead)
    var img = readPfmImage(inPfm)
    inPfm.close()

    echo ("File " & parameters.inPfmFileName & " has been read from disk")

    img.normalizeImage(parameters.factor)
    img.clampImage()

    img.writeLdrImage(parameters.outputFileName, parameters.gamma)

    echo ("File " & parameters.outputFileName & " has been written to disk")


when isMainModule:

    dispatch(pfm2format)