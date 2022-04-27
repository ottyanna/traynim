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


import os, strutils, streams, traynim/hdrimages

type
    Parameters = object
        inPfmFileName: string
        factor: float32
        gamma: float32
        outputFileName: string

type RuntimeError = object of CatchableError

proc parseCommandLine(parameters: var Parameters, argv: seq[string]) =

    if argv.len != 4:
        raise newException(RuntimeError, "Usage: traynim.nim INPUT_PFM_FILE FACTOR GAMMA OUTPUT_FILE.FORMAT")
        #available formats from pixie are ppm, png, bmp, qoi

    parameters.inPfmFileName = argv[0]

    try:
        parameters.factor = argv[1].parseFloat

    except ValueError:
        let msg = "Invalid factor (" & argv[1] & "), it must be a floating-point number."
        raise newException(ValueError, msg)

    try:
        parameters.gamma = argv[2].parseFloat

    except ValueError:
        let msg = "Invalid gamma (" & argv[2] & "), it must be a floating-point number."
        raise newException(ValueError, msg)

    parameters.outputFileName = argv[3]


when isMainModule:

    var parameters = Parameters()

    try:
        parseCommandLine(parameters, commandLineParams()) #CommandLineParams returns just the parameters
    except RuntimeError:
        echo ("Error: " & getCurrentExceptionMsg())

    let inPfm = newFileStream(parameters.inPfmFileName, fmRead)
    var img = readPfmImage(inPfm)
    inPfm.close()

    echo ("File " & parameters.inPfmFileName & " has been read from disk")

    img.normalizeImage(parameters.factor)
    img.clampImage()

    img.writeLdrImage(parameters.outputFileName, parameters.gamma)

    echo ("File " & parameters.outputFileName & " has been written to disk")

