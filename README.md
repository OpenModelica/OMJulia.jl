# OMJulia
Julia scripting OpenModelica interface 

# Requirement:
[Openmodelica](https://www.openmodelica.org/)<br>
[Julia](https://julialang.org/)<br>

# julia Dependencies:
> Pkg.add("ZMQ") <br>
> Pkg.add("Compat") <br>
> Pkg.add("DataStructures") <br>
> Pkg.add("LightXML") <br>
> Pkg.add("Random")<br>

# Installation 

Set OpenModelica to "Path" environment variable for windows, for example 
```
"C:/OpenModelica1.13.0-dev-64bit/bin"
```
Clone the repository 
```
julia> Pkg.clone("https://github.com/OpenModelica/OMJulia.jl")
```

# Advanced API Scripting and UserGuide

To see the list advanced API, the informations are provided in the UserGuide see
(https://www.openmodelica.org/doc/OpenModelicaUsersGuide/latest/omjulia.html)

# Usage
```
julia> using OMJulia
julia> omc=OMJulia.OMCSession()
julia> omc.sendExpression("getVersion()")
"\"v1.13.0-dev-531-gde26b558a (64-bit)\"\n"
julia> omc.sendExpression("model a end a;")
"{a}\n"
julia> omc.sendExpression("getClassNames()")
"{a}\n"
```

To see the list of available OpenModelicaScripting API see    (https://www.openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html
