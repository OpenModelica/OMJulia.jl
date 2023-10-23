# OMJulia.API

Module `OMJulia.API` aims to provide a Julia interface to the OpenModelica scripting API.
In contrast to sending the scripting api calls directly via [`sendExpression`](@ref)
this API has a Julia-like interface and some level of error handling implemented.
This means errors will throw Julia Exception [`OMJulia.API.ScriptingError`](@ref) instead
of only printing to stdout.

!!! warn
    Not all `OMJulia.API` functions are tested and some functions could have slightly
    different default values compared to the OpenModelica scripting API.


Instead of escaping strings yourself the API interface handles this for you:

```julia
sendExpression(omc, "loadFile(\"$(bouncingBallFile)\")")
```

becomes

```julia
API.loadFile(omc, bouncingBallFile)
```

## Functions

```@autodocs
Modules = [OMJulia.API]
Order   = [:function, :type]
Filter = t -> t != OMJulia.API.modelicaString
```
