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


## This module implements a `pcg` random number generator

type
    PCG* = object
        ## PCG Uniform Pseudo-random Number Generator
        state*, incr*: uint64

proc `-`(rot: uint32): uint32 =
    result = not(rot)+1

proc random*(pcg: var PCG): uint32 =

    ## Returns a new random number and advance PCG's internal state
    
    let oldState = pcg.state

    pcg.state = oldState * 6364136223846793005.uint64 + pcg.incr

    let xorShifted = (((oldState shr 18) xor oldState) shr 27).uint32

    let rot = (oldState shr 59).uint32

    result = (xorShifted shr rot) or (xorShifted shl (-rot and 31))


proc newPCG*(initState: uint64 = 42, initSeq: uint64 = 54): PCG =
    
    ## Generates a new `PCG` object

    result.state = 0
    result.incr = (initSeq shl 1) or 1
    discard result.random()
    result.state += initState
    discard result.random()


proc randomFloat*(pcg: var PCG): float =

    ## Returns a new random number uniformly distributed over [0, 1]

    result = random(pcg).float / 0xffffffff.float
