# Package

version       = "1.0.1"
author        = "Jacopo Fera, Anna Spanò"
description   = "The Nim ray tracer"
license       = "GPLv3"
srcDir        = "src"
bin           = @["traynim"]


# Dependencies

requires "nim >= 1.6.4", "pixie", "cligen"
