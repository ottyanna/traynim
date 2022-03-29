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

#encoding: utf-8

import ./hdrimages
import os 
from strutils import parseFloat
import streams


when isMainModule:
  type RuntimeError = object of CatchableError

  if paramCount() != 5:
    raise newException(RuntimeError, "Usage: traynim.nim INPUT_PFM_FILE FACTOR GAMMA OUTPUT_PNG_FILE")
  var inPfmFileName = paramStr(1)

  try:
    let nFactor = parseFloat(paramStr(2))
     
  except ValueError:
    var msg = "Invalid factor (" & paramStr(2) & "), it must be a floating-point number."
    raise newException(ValueError, msg)

  try:
    let nGamma = parseFloat(paramStr(3))
    
  except ValueError:
    var msg = "Invalid factor (" & paramStr(3) & "), it must be a floating-point number."
    raise newException(ValueError, msg)
  
  let outputPngFileName = paramStr(4)

  let inPfm = newFileStream(inPfmFileName,fmRead)
  var img = readPfmImage(inPfm)
  img.normalizeImage(parseFloat(paramStr(2)))
  img.clampImage()

  let outFile = newFileStream(outputPngFileName, fmWrite)
  img.writeLdrImage("png", gamma = parseFloat(paramStr(3)))

  echo ("File " & outputPngFileName & "has been written to disk")


  