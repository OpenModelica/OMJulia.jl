using Documenter, OMJulia

ENV["JULIA_DEBUG"]="Documenter"

@info "Make the docs"
makedocs(
  sitename = "OMJulia.jl",
  format = Documenter.HTML(edit_link = "master"),
  workdir = joinpath(@__DIR__,".."),
  pages = [
    "Home" => "index.md",
    "Quickstart" => "quickstart.md",
    "ModelicaSystem" => "modelicaSystem.md",
    "OMJulia.API" => "api.md",
    "sendExpression" => "sendExpression.md"
  ],
  modules = [OMJulia],
)

@info "Deploy the docs"
deploydocs(
  repo = "github.com/OpenModelica/OMJulia.jl.git",
  devbranch = "master"
)
