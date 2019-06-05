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
"C:/OpenModelica1.13.0-dev-64bit/bin"
```
## For GNU/Linux and macOS
Follow the instructions @ https://github.com/JuliaLang/julia

# Getting OMJUlia
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
```

To see the list of available commands in the OpenModelicaScripting API see (https://www.openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html
