#!/bin/bash
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


./../../traynim pfm2format -i=sample.pfm -o=sampleDefault.png


listGamma=(1.0 2.2)
listFactor=(0.15 0.30 0.50)


for i in "${listGamma[@]}"; do
	for j in "${listFactor[@]}"; do
		./../../traynim pfm2format -i=sample.pfm -g=$i -f=$j -o=sample$i$j.png
	done
done
