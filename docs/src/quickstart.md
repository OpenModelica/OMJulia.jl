# Quickstart

## ModelicaSystem

To simulate Modelica model `BouncingBall` start a new [`OMJulia.OMCSession`](@ref) and create a
new [`ModelicaSystem`](@ref) to build the BouncingBall model.

!!! info
    The BouncingBall.mo file can be found in your OpenModelica installation directory in
    `<OpenModelcia>/share/doc/omc/testmodels/BouncingBall.mo`

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

```@repl ModelicaSystem-example
using OMJulia
using CSV, DataFrames, PlotlyJS
using PlotlyDocumenter # hide

mod = OMJulia.OMCSession()
ModelicaSystem(mod,
               joinpath("docs", "testmodels", "BouncingBall.mo"),
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
```

```@example ModelicaSystem-example
PlotlyDocumenter.to_documenter(plt) # hide
OMJulia.quit(mod) # hide
```

## Scripting API with sendExpression

Start a new [`OMJulia.OMCSession`](@ref) and send
[scripting API](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html)
expressions to the omc session with [`sendExpression()`](@ref).

```@repl
using OMJulia

omc = OMJulia.OMCSession()
sendExpression(omc, "loadModel(Modelica)")
omcWorkDoir = mkpath(joinpath("docs", "omc-temp"))  # hide
mkpath(omcWorkDoir)                                 # hide
sendExpression(omc, "cd(\"$(omcWorkDoir)\")")       # hide
sendExpression(omc, "model a Real s; equation s=sin(10*time); end a;")
sendExpression(omc, "simulate(a)")
OMJulia.quit(omc)
```
