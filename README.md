# OMJulia
Julia scripting OpenModelica interface 

# Requirement:
[Openmodelica](https://www.openmodelica.org/)<br>
[Julia](https://julialang.org/)<br>
[JuliaZMQ](https://github.com/JuliaInterop/ZMQ.jl)<br>

# Installation 
Clone the repository 
```
julia> Pkg.clone("https://github.com/OpenModelica/OMJulia.jl")
```
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
