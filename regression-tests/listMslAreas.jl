#=
This file is part of OpenModelica.
Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
c/o Linköpings universitet, Department of Computer and Information Science,
SE-58183 Linköping, Sweden.

All rights reserved.

THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
ACCORDING TO RECIPIENTS CHOICE.

The OpenModelica software and the OSMC (Open Source Modelica Consortium)
Public License (OSMC-PL) are obtained from OSMC, either from the above
address, from the URLs: http://www.openmodelica.org or
http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
distribution. GNU version 3 is obtained from:
http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
http://www.opensource.org/licenses/BSD-3-Clause.

This program is distributed WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
CONDITIONS OF OSMC-PL.
=#

# Prints, and (under CI) writes to $GITHUB_OUTPUT, the JSON array of MSL
# areas the Nightly workflow's msl-coverage matrix should shard over.
#
#   julia listMslAreas.jl [msl-version]

import Pkg; Pkg.activate(@__DIR__)
import OMJulia

include("enumerateExamples.jl")

version = length(ARGS) >= 1 ? ARGS[1] : "4.1.0"

omc = OMJulia.OMCSession()
areas = try
  OMJulia.sendExpression(omc, "loadModel(Modelica, {\"$(version)\"})")
  mslAreasWithExamples(omc)
finally
  OMJulia.quit(omc)
end

json = "[" * join(("\"" * a * "\"" for a in areas), ",") * "]"
println("areas=", json)

out = get(ENV, "GITHUB_OUTPUT", nothing)
if out !== nothing
  open(out, "a") do io
    println(io, "areas=", json)
  end
end
