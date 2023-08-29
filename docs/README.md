# Documentation

We use Documenter.jl to build the OMJulia documentation that is linked from the
OpenModelica User's Guide.

## Build and host locally

Make sure you developed OMJulia.jl, so that Documenter.jl is using the correct version to
build.
To run Documenter.jl along with LiveServer to render the docs and track any modifications
run:

```julia
using Pkg; Pkg.activate("docs/"); Pkg.resolve()
using OMJulia, LiveServer
servedocs()
```
