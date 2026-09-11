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

## Tested application areas

OMJulia forwards to omc, which supports the full Modelica language, so
nothing here is a language limitation of OMJulia itself. What follows is
narrower and more useful: the application areas actually exercised end to
end (`ModelicaSystem`, `simulate`, `linearize`, FMU export), so that "it
works" means more than "it loaded".

On every pull request, the test suite covers:

  - hybrid, event-driven models — `BouncingBall`
  - nonlinear DAEs, including the set/get methods, sensitivity analysis and
    linearization on the same model — a chemical CSTR
    (`ModSeborgCSTRorg`)
  - electrical circuits — `Modelica.Electrical.Analog.Examples.CauerLowPassAnalog`
  - thermal-fluid systems — `Modelica.Fluid.Examples.DrumBoiler.DrumBoiler`
  - control blocks, and running two sessions at once —
    `Modelica.Blocks.Examples.PID_Controller`
  - FMU export through [`convertMo2Fmu`](modelicaSystem.md)

[`convertFmu2Mo`](modelicaSystem.md), the FMU-to-Modelica direction, is not
covered: a test for it failed against a real omc in CI (`importFMU` on a
non-trivial FMU, with no diagnostic in `getErrorString()`) in a way that
needs a maintainer with a working omc to debug rather than a guess from
here. Treat it as unverified until someone does.

Two broader, non-blocking sweeps run outside the pull-request gate:

  - `regression-tests/` simulates, exports an FMU, re-imports it and diffs
    the result against the direct simulation, for a curated list that adds
    digital electronics, clocked (sampled-data) systems, and rotational and
    multibody mechanics. It runs weekly against three omc versions on two
    operating systems.
  - Every third night, the `msl-coverage` job asks omc which MSL areas have
    an `Examples` package, then simulates every non-partial model under each
    one's `Examples` — no curated list, so it tracks whatever MSL version CI
    has installed. It only checks that the model simulates, not the FMU
    round trip, and a model failing does not fail the job. The
    `publish-msl-coverage` job folds the result into
    [MSL coverage](mslCoverage.md), committed back to the branch that ran
    it, so the page always reflects the latest sweep rather than whatever
    was true when this page was last edited by hand.

A model turning up ❌ there does not always mean it is broken. The sweep
cannot tell a runnable example from a base class meant to be extended, so
some entries under `Examples` are expected to fail this way; the summary is
a starting point for triage, not a verdict.

Other Modelica Standard Library areas that do not have an `Examples`
package — `Media`, `Magnetic`, and so on — have been used through OMJulia in
practice, but are not exercised by anything above, so they are not claimed
here.

## What is public

From version 1.0.0 OMJulia follows [semantic versioning](https://semver.org/),
so it is worth being explicit about what that covers.

Public, and only broken in a new major version:

  - the exported functions, and everything documented on the
    [ModelicaSystem](modelicaSystem.md) and
    [sendExpression](sendExpression.md) pages
  - the [`OMJulia.API`](api.md) module

Internal, and free to change in any release:

  - `OMJulia.Parser` and `OMJulia.lexer`
  - the fields of `OMJulia.OMCSession` and `OMJulia.ZMQSession`
  - the element type of the dictionaries the get methods return. They are
    returned by reference today; treat them as read-only and do not rely on
    them being `Dict{Any, Any}`
