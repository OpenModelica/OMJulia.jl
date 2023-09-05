# OMJulia.jl

**Julia scripting OpenModelica interface.**

## Overview

OMJulia - the OpenModelica Julia API is a free, open source, highly portable Julia based
interactive session handler for Julia scripting of OpenModelica API functionality.
It provides the modeler with components for creating a complete Julia-Modelica modeling,
compilation and simulation environment based on the latest OpenModelica implementation and
Modelica library standard available.

OMJulia is structured to combine both the solving strategy and model building.
Thus, domain experts (people writing the models) and computational engineers (people
writing the solver code) can work on one unified tool that is industrially viable for
optimization of Modelica models, while offering a flexible platform for algorithm
development and research.
OMJulia is not a standalone package, it depends upon the OpenModelica installation.

OMJulia is implemented in Julia and depends on ZeroMQ - high performance asynchronous
messaging library and it supports the Modelica Standard Library version 4.0 that is
included with OpenModelica.

## Installation

Make sure [OpenModelica](https://openmodelica.org/) is installed.

Install OMJulia.jl with:

```julia
julia> import Pkg; Pkg.add("OMJulia")
```

## Features of OMJulia

The OMJulia package contains the following features:

  - Interactive session handling, parsing, interpretation of commands and Modelica
    expressions for evaluation, simulation, plotting, etc.
  - Connect with the OpenModelica compiler through zmq sockets
  - Able to interact with the OpenModelica compiler through the available API
  - Easy access to the Modelica Standard library.
  - All the API calls are communicated with the help of the sendExpression method
    implemented in a Julia module
  - The results are returned as strings
