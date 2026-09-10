#=
This file is part of OpenModelica.
Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
c/o Linköpings universitet, Department of Computer and Information Science,
SE-58183 Linköping, Sweden.

All rights reserved.

THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
ACCORDING TO RECIPIENTS CHOICE.

The OpenModelica software and the OSMC (Open Source Modelica Consortium)
Public License (OSMC-PL) are obtained from OSMC, either from the above
address, from the URLs: http://www.openmodelica.org or
http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
distribution. GNU version 3 is obtained from:
http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
http://www.opensource.org/licenses/BSD-3-Clause.

This program is distributed WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
CONDITIONS OF OSMC-PL.
=#

# One shard of the Nightly workflow's msl-coverage matrix: every simulatable
# model under `Modelica.<area>.Examples`, simulated (not exported/re-imported
# -- see runSimulateOnly.jl for why). Never throws on a model failing; that
# is the report, not an error in the sweep itself. A model hanging or omc
# crashing is bounded by the per-model subprocess timeout below, not by
# this script surviving forever.
#
#   julia areaCoverageReport.jl <area> [msl-version]

import Pkg; Pkg.activate(@__DIR__)
import OMJulia

include("enumerateExamples.jl")

area = ARGS[1]
version = length(ARGS) >= 2 ? ARGS[2] : "4.1.0"

omc = OMJulia.OMCSession()
local models
try
  OMJulia.sendExpression(omc, "loadModel(Modelica, {\"$(version)\"})")
  models = exampleModels(omc, area)
finally
  OMJulia.quit(omc)
end

@info "Modelica.$(area).Examples: $(length(models)) models to simulate"

"""
Simulate one model in its own Julia process, with a wall-clock deadline.
Never throws: a hang, a crash and a clean failure are all just `false`.
"""
function simulateOnlyProcess(library, version, model, testdir; timeout::Integer=5 * 60)
  mkpath(testdir)
  logFile = joinpath(testdir, "runSimulateOnly.log")
  rm(logFile, force=true)

  cmd = Cmd(`$(joinpath(Sys.BINDIR, "julia")) runSimulateOnly.jl $(library) $(version) $(model) $(testdir)`, dir=@__DIR__)
  process = run(pipeline(cmd, stdout=logFile, stderr=logFile), wait=false)

  timer = Timer(0; interval=1)
  for _ in 1:timeout
    wait(timer)
    process_running(process) || break
  end
  close(timer)

  if process_running(process)
    @warn "Timed out after $(timeout)s, killing" model
    kill(process)
    return false
  end

  passed = process.exitcode == 0
  passed || println(read(logFile, String))
  return passed
end

workdir = abspath(joinpath(@__DIR__, "temp", area))
rm(workdir, recursive=true, force=true)
mkpath(workdir)

results = NamedTuple{(:model, :passed),Tuple{String,Bool}}[]
for model in models
  modeldir = joinpath(workdir, model)
  passed = simulateOnlyProcess("Modelica", version, model, modeldir)
  push!(results, (model=model, passed=passed))
end

n_pass = count(r -> r.passed, results)
n_total = length(results)

lines = String[]
push!(lines, "## MSL coverage -- Modelica.$(area).Examples: $(n_pass)/$(n_total) simulate")
push!(lines, "")
if n_total == 0
  push!(lines, "_No simulatable classes found under `Modelica.$(area).Examples`._")
else
  push!(lines, "| Model | Status |")
  push!(lines, "|---|---|")
  for r in results
    push!(lines, "| $(r.model) | $(r.passed ? "✅" : "❌") |")
  end
end
report = join(lines, "\n")
println(report)

summaryPath = get(ENV, "GITHUB_STEP_SUMMARY", nothing)
if summaryPath !== nothing
  open(summaryPath, "a") do io
    println(io, report)
  end
end

# Same content, written where publish-msl-coverage's artifact download can
# find it and fold it into docs/src/mslCoverage.md. A plain file rather than
# JSON: the job summary text above is already the exact markdown wanted, so
# there is nothing to parse back out of it.
sectionPath = joinpath(@__DIR__, "temp", "section-$(area).md")
mkpath(dirname(sectionPath))
write(sectionPath, report)
