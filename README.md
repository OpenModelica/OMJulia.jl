# OMJulia.jl

*Julia scripting [OpenModelica](https://openmodelica.org/) interface.*

[![][docs-dev-img]][docs-dev-url] [![][GHA-test-img]][GHA-test-url]

## Requirements

  - [OpenModelica](https://www.openmodelica.org/)
  - [Julia](https://julialang.org/)

## Installing OMJulia

Make sure [OpenModelica](https://openmodelica.org/) is installed.

Install OMJulia.jl with:

```julia
julia> import Pkg; Pkg.add("OMJulia")
```

## Usage

```julia
julia> using OMJulia
julia> using OMJulia: sendExpression
julia> omc=OMJulia.OMCSession()
julia> sendExpression(omc, "getVersion()")
"OpenModelica v1.21.0-dev-185-g9d983b8e35 (64-bit)"
julia> sendExpression(omc, "model a end a;")
1-element Array{Symbol,1}:
 :a
julia> sendExpression(omc, "getClassNames()")
1-element Array{Symbol,1}:
 :a
julia> sendExpression(omc, "loadModel(Modelica)")
true
julia> sendExpression(omc, "simulate(Modelica.Electrical.Analog.Examples.CauerLowPassAnalog)")
Dict{String,Any} with 10 entries:
  "timeCompile"       => 9.97018
  "simulationOptions" => "startTime = 0.0, stopTime = 60.0, numberOfIntervals = 500, tolerance = 1e-006, method = 'dassl', fileNamePrefix = 'Modelica.Electrical.Analog.Examples.CauerLowPassAnalog', options = '', outputFormat = 'mat', variableFilter = '.*', cflags = '', simflags = ''"
  "messages"          => "LOG_SUCCESS       | info    | The initialization finished successfully without homotopy method.\nLOG_SUCCESS       | info    | The simulation finished successfully.\n"
  "timeFrontend"      => 0.45081
  "timeTotal"         => 11.04
  "timeTemplates"     => 0.104619
  "timeSimulation"    => 0.29745
  "resultFile"        => "PATH/TO/Modelica.Electrical.Analog.Examples.CauerLowPassAnalog_res.mat"
  "timeSimCode"       => 0.0409317
  "timeBackend"       => 0.140713
julia> OMJulia.sendExpression(omc, "quit()",parsed=false)
"quit requested, shutting server down\n"
```

## Bug Reports

  - Submit OMJulia.jl bugs in this repositories [Issues](../../issues) section.
  - Submit OpenModelica related bugs through the [OpenModelica GitHub issues](https://github.com/OpenModelica/OpenModelica/issues/new).
  - [Pull requests](../../pulls) are welcome ❤️

## License

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

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://OpenModelica.github.io/OMJulia.jl/dev/

[GHA-test-img]: https://github.com/OpenModelica/OMJulia.jl/actions/workflows/Test.yml/badge.svg?branch=master
[GHA-test-url]: https://github.com/OpenModelica/OMJulia.jl/actions/workflows/Test.yml
