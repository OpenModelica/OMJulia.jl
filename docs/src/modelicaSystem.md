# Advanced API

## ModelicaSystem

```@docs
ModelicaSystem
```

```@docs
OMJulia.OMCSession
```

Let us see the usage of ModelicaSystem with the help of Modelica model `ModSeborgCSTRorg`

```modelica
model ModSeborgCSTRorg
  // Model of original Seborg CSTR in ode form
  // author: Bernt Lie, University of Southeast Norway,November 7, 2017

  // Parameters
  parameter Real V = 100 "Reactor volume, L";
  parameter Real rho = 1e3 "Liquid density, g/L";
  parameter Real a = 1 "Stoichiometric constant, -";
  parameter Real EdR = 8750 "Activation temperature, K";
  parameter Real k0 = exp(EdR/350) "Pre-exponential factor, 1/min";
  parameter Real cph = 0.239 "Specific heat capacity of mixture, J.g-1.K-1";
  parameter Real DrHt = -5e4 "Molar enthalpy of reaction, J/mol";
  parameter Real UA = 5e4 "Heat transfer parameter, J/(min.K)";

  // Initial state parameters
  parameter Real cA0 = 0.5 "Initial concentration of A, mol/L";
  parameter Real T0 = 350 "Initial temperature, K";
  // Declaring variables
  // -- states
  Real cA(start = cA0, fixed = true) "Initializing concentration of A in reactor, mol/L";
  Real T(start = T0, fixed = true) "Initializing temperature in reactor, K";
  // -- auxiliary variables
  Real r "Rate of reaction, mol/(L.s)";
  Real k "Reaction 'constant', ...";
  Real Qd "Heat flow rate, J/min";
  // -- input variables
  input Real Vdi "Volumetric flow rate through reactor, L/min";
  input Real cAi "Influent molar concentration of A, mol/L";
  input Real Ti "Influent temperature, K";
  input Real Tc "Cooling temperature', K";
  // -- output variables
  output Real y_T "Reactor temperature, K";
  // Equations constituting the model
equation
  // Differential equations
  der(cA) = Vdi*(cAi-cA)/V- a*r;
  der(T) = Vdi*(Ti-T)/V + (-DrHt)*r/(rho*cph) + Qd/(rho*V*cph);
  // Algebraic equations
  r = k*cA^a;
  k = k0*exp(-EdR/T);
  Qd = UA*(Tc-T);
  // Outputs
  y_T = T;
end ModSeborgCSTRorg
```
### Example
```@repl ModSeborgCSTRorg-example
using OMJulia
mod = OMJulia.OMCSession()
omcWorkDir = mkpath(joinpath("docs", "omc-temp"))  # hide
mkpath(omcWorkDir)                                 # hide
sendExpression(mod, "cd(\"$(omcWorkDir)\")")       # hide
ModelicaSystem(mod,
               joinpath("docs", "testmodels", "ModSeborgCSTRorg.mo"),
               "ModSeborgCSTRorg")
```

## WorkDirectory

For each OMJulia session a temporary work directory is created and the results are
published in that working directory.
In order to get the work directory use [`getWorkDirectory`](@ref).

```@docs
getWorkDirectory
```
```@repl ModSeborgCSTRorg-example
getWorkDirectory(mod)
```


## Build Model

```@docs
buildModel
```
In case the Modelica model needs to be updated or additional simulation flags needs to be
set using [`sendExpression`](@ref) The [`buildModel`](@ref) API can be used after
[`ModelicaSystem`](@ref).

```
buildModel(omc)
buildModel(omc, variableFilter="a|T")
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

Three calling possibilities are accepted using getXXX() where "XXX" can be any of the above functions (eg:) getParameters().
1. getXXX() without input argument, returns a dictionary with names as keys and values as values.
2. getXXX(S), where S is a string of names.
3. getXXX(["S1","S2"]) where S1 and S1 are array of string elements

### Examples of using Get Methods

```@repl ModSeborgCSTRorg-example
getQuantities(mod)
getQuantities(mod, "T")
getQuantities(mod, ["T","cA"])
showQuantities(mod)
```

```@repl ModSeborgCSTRorg-example
getContinuous(mod)
getContinuous(mod, ["Qd","Tc"])
```

```@repl ModSeborgCSTRorg-example
getInputs(mod)
getOutputs(mod)
```

```@repl ModSeborgCSTRorg-example
getParameters(mod)
getParameters(mod, ["a","V"])
```

```@repl ModSeborgCSTRorg-example
getSimulationOptions(mod)
getSimulationOptions(mod, ["stepSize","tolerance"])
```
### Reading Simulation Results
To read the simulation results, we need to simulate the model first and use the getSolution() API to read the results

```@repl ModSeborgCSTRorg-example
simulate(mod)
```

The getSolution method can be used in two different ways.
1. using default result filename
2. use the result filenames provided by user

This provides a way to compare simulation results and perform regression testing

```@repl ModSeborgCSTRorg-example
getSolutions(mod)
getSolutions(mod, ["time","a"])
```
### Examples of using resultFile provided by user location

```
getSolutions(mod, resultfile="C:/BouncingBal/tmpbouncingBall.mat") //returns list of simulation variables for which results are available , the resulfile location is provided by user
getSolutions(mod, ["time","h"], resultfile="C:/BouncingBal/tmpbouncingBall.mat") // return list of array
```
## Set Methods

```@docs
setInputs
setParameters
setSimulationOptions
```

Two setting possibilities are accepted using setXXXs(),where "XXX" can be any of above functions.
1.setXXX("Name=value") string of keyword assignments
2.setXXX(["Name1=value1","Name2=value2","Name3=value3"]) array of string of keyword assignments

### Examples

```@repl ModSeborgCSTRorg-example
setInputs(mod, "cAi=100")
setInputs(mod, ["cAi=100","Ti=200","Vdi=300","Tc=250"])
```

```@repl ModSeborgCSTRorg-example
setParameters(mod, "a=3")
setParameters(mod, ["a=4","V=200"])
```

```@repl ModSeborgCSTRorg-example
setSimulationOptions(mod, ["stopTime=2.0", "tolerance=1e-08"])
```

## Advanced Simulation

```@docs
simulate
```

An example of how to do advanced simulation to set parameter values using set methods and finally simulate the "ModSeborgCSTRorg.mo" model is given below .

```@repl ModSeborgCSTRorg-example
getParameters(mod)
setParameters(mod, "a=3.0")
```

To check whether new values are updated to model , we can again query the getParameters().

```@repl ModSeborgCSTRorg-example
getParameters(mod)
```

Similary we can also use setInputs() to set a value for the inputs during various time interval can also be done using the following.

```@repl ModSeborgCSTRorg-example
setInputs(mod, "cAi=100")
```
And finally we simulate the model

```@repl ModSeborgCSTRorg-example
simulate(mod)
```

## Linearization

```@docs
linearize
getLinearizationOptions
setLinearizationOptions
getLinearInputs
getLinearOutputs
getLinearStates
```

### Examples

```@repl ModSeborgCSTRorg-example
getLinearizationOptions(mod)
getLinearizationOptions(mod, ["startTime","stopTime"])
```

```@repl ModSeborgCSTRorg-example
setLinearizationOptions(mod,["stopTime=2.0","tolerance=1e-06"])
```

```@repl ModSeborgCSTRorg-example
res = linearize(mod)
```

```@repl ModSeborgCSTRorg-example
getLinearInputs(mod)
getLinearOutputs(mod)
getLinearStates(mod)
```

## Sensitivity Analysis

```@docs
sensitivity
```

### Examples

```@repl ModSeborgCSTRorg-example
(Sn, Sa) = sensitivity(mod, ["UA","EdR"], ["T","cA"], [1e-2,1e-4])
```
