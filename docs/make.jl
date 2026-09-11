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

using Documenter, OMJulia

ENV["JULIA_DEBUG"]="Documenter"

# Every @repl block in the manual runs against a live omc. Without one they
# render their own error text into the published page instead of failing, which
# is how https://github.com/OpenModelica/OMJulia.jl/issues/119 happened: the
# quickstart shipped with "could not spawn omc" where its output should be.
# Fail here, where it is obvious, rather than publishing that.
@info "Check that omc is available"
let omc = OMJulia.OMCSession()
    try
        @info "Building the documentation against omc $(OMJulia.sendExpression(omc, "getVersion()"))"
    finally
        OMJulia.quit(omc)
    end
end

@info "Make the docs"
makedocs(
  sitename = "OMJulia.jl",
  format = Documenter.HTML(edit_link = "master"),
  workdir = joinpath(@__DIR__,".."),
  pages = [
    "Home" => "index.md",
    "Quickstart" => "quickstart.md",
    "ModelicaSystem" => "modelicaSystem.md",
    "OMJulia.API" => "api.md",
    "sendExpression" => "sendExpression.md",
    "MSL coverage" => "mslCoverage.md"
  ],
  modules = [OMJulia],
  # A failing @example block used to render its own error text into the
  # published page and pass. That is how
  # https://github.com/OpenModelica/OMJulia.jl/issues/119 stayed unnoticed --
  # the quickstart shipped an ERROR where the bouncing ball plot belonged.
  strict = [:example_block],
)

@info "Deploy the docs"
deploydocs(
  repo = "github.com/OpenModelica/OMJulia.jl.git",
  devbranch = "master"
)
