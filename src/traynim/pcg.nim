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

from bitops import bitnot

type 
    PCG* = object
        ##
        state*, incr* : uint64

proc random*(pcg : var PCG): uint32 =
    ##
    let oldState = pcg.state

    pcg.state = oldState * 6364136223846793005.uint64 + pcg.incr

    let xorShifted = (((oldState shr 18) xor oldState) shr 27).uint32

    # 32-bit variable 
    let rot = oldState.uint32 shr 59

    result = ((xorShifted shr rot) or (xorShifted shl ((bitnot(rot)) and 31)))




proc newPCG*(initState:uint64 = 42, initSeq:uint64 = 54): PCG =
    ##
    
    result.state = 0
    result.incr = (initSeq shl 1) or 1
    discard result.random()
    result.state += initState
    discard result.random()

    