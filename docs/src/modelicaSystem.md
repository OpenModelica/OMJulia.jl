# Advanced API

## ModelicaSystem

```@docs
ModelicaSystem
```

```@docs
OMJulia.OMCSession
```

### Example

```@repl BouncingBall-example
using OMJulia

mod = OMJulia.OMCSession()
omcWorkDoir = mkpath(joinpath("docs", "omc-temp"))  # hide
mkpath(omcWorkDoir)                                 # hide
sendExpression(mod, "cd(\"$(omcWorkDoir)\")")       # hide
ModelicaSystem(mod,
               joinpath("docs", "testmodels", "BouncingBall.mo"),
               "BouncingBall")
```

## WorkDirectory

For each OMJulia session a temporary work directory is created and the results are
published in that working directory.
In order to get the work directory use [`getWorkDirectory`](@ref).

```@docs
getWorkDirectory
```

## Build Model

In case the Modelica model needs to be updated or additional simulation flags needs to be
set using [`sendExpression`](@ref) The [`buildModel`](@ref) API can be used after
[`ModelicaSystem`](@ref).

```@docs
buildModel
```

## Get Methods

```@docs
getQuantities
showQuantities
getContinuous
getInputs
getOutputs
getParameters
getSimulationOptions
getSolutions
```

### Examples

```@repl BouncingBall-example
getQuantities(mod)
getQuantities(mod, "height")
getQuantities(mod, ["c","radius"])
showQuantities(mod)
```

```@repl BouncingBall-example
getContinuous(mod)
getContinuous(mod, ["velocity","height"])
```

```@repl BouncingBall-example
getInputs(mod)
getOutputs(mod)
```

```@repl BouncingBall-example
getParameters(mod)
getParameters(mod, ["c","radius"])
```

```@repl BouncingBall-example
getSimulationOptions(mod)
getSimulationOptions(mod, ["stepSize","tolerance"])
```

```@repl BouncingBall-example
getSolutions(mod)
getSolutions(mod, ["time","height"])
```

## Set Methods

```@docs
setInputs()
setParameters()
setSimulationOptions()
```

### Examples

```@repl BouncingBall-example
setInputs(mod, "cAi=1")
setInputs(mod, ["cAi=1","Ti=2"])
```

```@repl BouncingBall-example
setParameters(mod, "radius=14")
setParameters(mod, ["radius=14","c=0.5"])
```

```@repl BouncingBall-example
setSimulationOptions(mod, ["stopTime=2.0","tolerance=1e-08"])
```

## Simulation

```@docs
simulate
```

### Examples

```@repl BouncingBall-example
simulate(mod, simflags="-noEventEmit -noRestart -override=e=0.3,g=9.71")
```


## Linearization

```@docs
linearize()
getLinearizationOptions()
setLinearizationOptions()
getLinearInputs()
getLinearOutputs()
getLinearStates()
```

### Examples

```@repl BouncingBall-example
getLinearizationOptions(mod) 
getLinearizationOptions(mod, ["startTime","stopTime"])
```

```@repl BouncingBall-example
setLinearizationOptions(mod,["stopTime=2.0","tolerance=1e-06"])
```

```@repl BouncingBall-example
linearize(mod)
```

```@repl BouncingBall-example
getLinearInputs(mod)
getLinearOutputs(mod)
getLinearStates(mod)
```

## Sensitivity Analysis

```@docs
sensitivity
```

### Examples

```@repl BouncingBall-example
(Sn, Sa) = sensitivity(mod, ["UA","EdR"], ["T","cA"], [1e-2,1e-4])
```
