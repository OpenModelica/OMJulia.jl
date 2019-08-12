# OMJulia
Julia scripting OpenModelica interface

# Requirements:
[Openmodelica](https://www.openmodelica.org/)<br>
[Julia](https://julialang.org/)<br>
[Dependencies](Project.toml)

# Installation
## For Windows
Set the OpenModelica to "Path" environment variable for windows:
```
"C:/OpenModelica1.14.0-dev-64bit/bin"
```
## For GNU/Linux and macOS
Follow the instructions @ https://github.com/JuliaLang/julia

# Getting OMJulia
Clone the repository according to your version of Julia:
```
julia> Pkg.clone("https://github.com/OpenModelica/OMJulia.jl")
```

# Advanced API Scripting and UserGuide

To see the list advanced API, the informations are provided in the UserGuide see
(https://www.openmodelica.org/doc/OpenModelicaUsersGuide/latest/omjulia.html)

# Usage
```
julia> using OMJulia: sendExpression
julia> omc=OMJulia.OMCSession()
julia> sendExpression(omc, "getVersion()")
"OMCompiler v1.14.0-dev.117+gddcc28391"
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
```

To see the list of available commands in the OpenModelicaScripting API see (https://www.openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html
