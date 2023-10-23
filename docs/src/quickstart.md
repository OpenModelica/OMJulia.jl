# Quickstart

There are three ways to interact with OpenModelica:

  - [`ModelicaSystem`](@ref modelicasystem): A Julia style scripting API that handles low level
    API calls.
  - [`OMJulia.API`](@ref omjulia-api): A Julia style scripting API that handles low level
    [`sendExpression`](@ref) calls and has some degree of error handling.
  - [Scripting API with sendExpression](@ref scripting-api-with-sendExpression):
    Send expressions to the low level OpenModelica scripting API.

The following examples demonstrate how to simulate Modelica model `BouncingBall` in both
ways.

```modelica
model BouncingBall
  parameter Real e=0.7 "coefficient of restitution";
  parameter Real g=9.81 "gravity acceleration";
  Real h(fixed=true, start=1) "height of ball";
  Real v(fixed=true) "velocity of ball";
  Boolean flying(fixed=true, start=true) "true, if ball is flying";
  Boolean impact;
  Real v_new(fixed=true);
  Integer foo;
equation
  impact = h <= 0.0;
  foo = if impact then 1 else 2;
  der(v) = if flying then -g else 0;
  der(h) = v;

  when {h <= 0.0 and v <= 0.0,impact} then
    v_new = if edge(impact) then -e*pre(v) else 0;
    flying = v_new > 0;
    reinit(v, v_new);
  end when;
end BouncingBall;
```

!!! info
    The BouncingBall.mo file can be found in your OpenModelica installation directory in
    `<OpenModelcia>/share/doc/omc/testmodels/BouncingBall.mo`.

## [ModelicaSystem](@id modelicasystem)

Start a new [`OMJulia.OMCSession`](@ref) and create a new [`ModelicaSystem`](@ref) to
build and simulate the `BouncingBall` model.
Afterwards the result can be plotted in Julia.

```@repl ModelicaSystem-example
using OMJulia
using CSV, DataFrames, PlotlyJS
using PlotlyDocumenter # hide

mod = OMJulia.OMCSession();

installDir = sendExpression(mod, "getInstallationDirectoryPath()")
bouncingBallFile = joinpath(installDir, "share", "doc", "omc", "testmodels", "BouncingBall.mo")

ModelicaSystem(mod,
               bouncingBallFile,
               "BouncingBall")
simulate(mod,
         resultfile = "BouncingBall_ref.csv",
         simflags   = "-override=outputFormat=csv,stopTime=3")

resultfile = joinpath(getWorkDirectory(mod), "BouncingBall_ref.csv")
df = DataFrame(CSV.File(resultfile));

plt = plot(df,
           x=:time, y=:h,
           mode="lines",
           Layout(title="Bouncing Ball", height = 700))

OMJulia.quit(mod)
```

```@example ModelicaSystem-example
PlotlyDocumenter.to_documenter(plt) # hide
```

## [OMJulia.API](@id omjulia-api)

## Example

Start a new [`OMJulia.OMCSession`](@ref) and call
[scripting API](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html)
directly using the [`OMJulia.API`](@ref) module.

```@repl API-example
using OMJulia
using OMJulia.API: API

using CSV, DataFrames, PlotlyJS
using PlotlyDocumenter # hide

omc = OMJulia.OMCSession();
omcWorkDir = mkpath(joinpath("docs", "omc-temp"))  # hide
mkpath(omcWorkDir)                                 # hide
API.cd(omcWorkDir)                                 # hide
installDir = API.getInstallationDirectoryPath(omc)
bouncingBallFile = joinpath(installDir, "share", "doc", "omc", "testmodels", "BouncingBall.mo")
bouncingBallFile = abspath(bouncingBallFile)        # hide
API.loadFile(omc, bouncingBallFile)
res = API.simulate(omc, "BouncingBall"; stopTime=3.0, outputFormat = "csv")
resultfile = res["resultFile"]
df = DataFrame(CSV.File(resultfile));

plt = plot(df,
           x=:time, y=:h,
           mode="lines",
           Layout(title="Bouncing Ball", height = 700))

OMJulia.quit(omc)
```

```@example API-example
PlotlyDocumenter.to_documenter(plt) # hide
```

## [Scripting API with sendExpression](@id scripting-api-with-sendExpression)

Start a new [`OMJulia.OMCSession`](@ref) and send
[scripting API](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html)
expressions to the omc session with [`sendExpression()`](@ref).

!!! warn
    All special characters inside a string argument for an API function need to be escaped
    when passing to `sendExpression`.

    E.g. MOS command
    ```modelica
    loadFile("/some/path/to/BouncingBall.mo");
    ```
    becomes Julia code
    ```julia
    sendExpression(omc, "loadFile(\"/some/path/to/BouncingBall.mo\")")
    ```

!!! info
    On Windows path separation symbol `\` needs to be escaped `\\`
    or replaced to Unix style path  `/` to prevent warnings.


```@repl ModelicaSystem-example
using OMJulia

omc = OMJulia.OMCSession();
omcWorkDir = mkpath(joinpath("docs", "omc-temp"))  # hide
mkpath(omcWorkDir)                                 # hide
sendExpression(omc, "cd(\"$(omcWorkDir)\")")       # hide
installDir = sendExpression(omc, "getInstallationDirectoryPath()")
bouncingBallFile = joinpath(installDir, "share", "doc", "omc", "testmodels", "BouncingBall.mo")
bouncingBallFile = abspath(bouncingBallFile)        # hide
if Sys.iswindows()
    bouncingBallFile = replace(bouncingBallFile, "\\" => "/")
end
sendExpression(omc, "loadFile(\"$(bouncingBallFile)\")")
sendExpression(omc, "simulate(BouncingBall)")
OMJulia.quit(omc)
```
