# OMJulia
Julia scripting OpenModelica interface 

# Requirement:
[Openmodelica](https://www.openmodelica.org/)<br>
[Julia](https://julialang.org/)<br>
[JuliaZMQ](https://github.com/JuliaInterop/ZMQ.jl)<br>

# Installation
Clone the repository and add the installation directory to julia LOAD_PATH. For Example <br>
```
>>> cd C:\\OPENMODELICAGIT\\OpenModelica\\OMJulia
>>> julia
>>> LOAD_PATH will specify the current path where the packages are loaded
>>> push!(LOAD_PATH, "C:\\OPENMODELICAGIT\\OpenModelica\\OMJulia")
```
Now the OMJulia module is loaded and can be started for use. But in this approach the LOAD_PATH with be active for only current session, and everytime a new julia session is opened we have to push the directory to LOAD_PATH <br>

The other alternate solution is to add the "push!(LOAD_PATH, "C:\\OPENMODELICAGIT\\OpenModelica\\OMJulia")" for the first time in the julia startup environment file called "juliarc.jl" located in the following path. For example in windows installation of julia, this is located at <br>
"C:\Program Files\Julia-0.6.2\etc\julia\juliarc.jl"
add this line to the file <br>
push!(LOAD_PATH, "C:\\OPENMODELICAGIT\\OpenModelica\\OMJulia") <br>

or the next solution is to create a ".julia.rc" in the julia home directory and add the above line to that file. For example

```
>>> julia
>>> homedir() gives the path of directory where julia searches
```
After doing this steps when you run LOAD_PATH from julia terminal it should show your local directory added to path. For example

```
julia> LOAD_PATH
3-element Array{Any,1}:
 "C:\\Program Files\\Julia-0.6.2\\local\\share\\julia\\site\\v0.6"
 "C:\\Program Files\\Julia-0.6.2\\share\\julia\\site\\v0.6"
 "C:\\OPENMODELICAGIT\\OpenModelica\\OMJulia"
```
# Usage
```
>>> using OMJulia
>>> omc=OMJulia.OMCSession()
>>> omc.sendExpression("getVersion()")
"\"v1.13.0-dev-531-gde26b558a (64-bit)\"\n"
>>> omc.sendExpression("model a end a;")
"{a}\n"
>>> omc.sendExpression("getClassNames()")
"{a}\n"
```

To see the list of available OpenModelicaScripting API see    (https://www.openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html
