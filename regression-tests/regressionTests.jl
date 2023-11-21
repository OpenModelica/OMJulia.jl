#=
This file is part of OpenModelica.
Copyright (c) 1998-2023, Open Source Modelica Consortium (OSMC),
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

using Test

"""
Timeout error.
"""
struct TimeOutError <: Exception
  cmd::Cmd
end
function Base.showerror(io::IO, e::TimeOutError)
  println(io, "Timeout reached running command")
  println(io, e.cmd)
end

"""
Run single test process.

Start a new Julia process.
Kill process and throw TimeOutError when timeout is reached.
Catch InterruptException, kill process and rethorw InterruptException.

# Arguments
  - `library`:  Modelica library name.
  - `version`:  Library version.
  - `model`:    Modelica model from library to test.
  - `testdir`:  Test working directory.

# Keywords
  - `timeout=10*60::Integer`:   Timeout in seconds. Defaults to 10 minutes.
"""
function singleTest(library, version, model, testdir;
                    timeout=10*60::Integer)

  mkpath(testdir)
  logFile = joinpath(testdir, "runSingleTest.log")
  rm(logFile, force=true)

  @info "Testing $model"

  cmd = Cmd(`$(joinpath(Sys.BINDIR, "julia")) runSingleTest.jl $(library) $(version) $(model) $(testdir)`, dir=@__DIR__)
  @info cmd
  plp = pipeline(cmd, stdout=logFile, stderr=logFile)
  process = run(plp, wait=false)

  try
    timer = Timer(0; interval=1)
    for _ in 1:timeout
      wait(timer)
      if !process_running(process)
        close(timer)
        break
      end
    end
    if process_running(process)
      @error "Killing $(process)"
      kill(process)
    end
  catch e
    if isa(e, InterruptException) && process_running(p)
      @error "Killing process $(cmd)."
      kill(p)
    end
    rethrow(e)
  end

  println(read(logFile, String))

  status = (process.exitcode == 0) &&
           isfile(joinpath(testdir, "$(model).fmu")) &&
           isfile(joinpath(testdir, "FMI_results.csv"))

  return status
end

"""
Run all tests.

Start a new Julia process for each test.
Kill process and throw TimeOutError when timeout is reached.
Catch InterruptException, kill process and rethorw InterruptException.

# Arguments
  - `libraries::Vector{Tuple{S,S}}`:  Vector of tuples with library and version to test.
  - `models::Vector{Vector{S}}`:      Vector of vectors with models to test for each library.

# Keywords
  - `workdir`:                        Root working directory.
"""
function runTests(libraries::Vector{Tuple{S,S}},
                  models::Vector{Vector{S}};
                  workdir=abspath(joinpath(@__DIR__, "temp"))) where S<:AbstractString

  rm(workdir, recursive=true, force=true) # This can break on Windows when some program or file is still open
  mkpath(workdir)

  @testset "OpenModelica" begin
    for (i, (library, version)) in enumerate(libraries)
      @testset verbose=true "$library" begin
        libdir = joinpath(workdir, library)
        mkpath(libdir)

        for model in models[i]
          modeldir = joinpath(libdir, model)
          @testset "$model" begin
            @test singleTest(library, version, model, modeldir)
          end
        end
      end
    end
  end

  return
end

libraries = [
  ("Modelica", "4.0.0")
]

models = [
  [
    "Modelica.Blocks.Examples.Filter",
    "Modelica.Electrical.Analog.Examples.CauerLowPassAnalog"
    "Modelica.Blocks.Examples.RealNetwork1",
    "Modelica.Electrical.Digital.Examples.FlipFlop",
    "Modelica.Mechanics.Rotational.Examples.FirstGrounded",
    "Modelica.Mechanics.Rotational.Examples.CoupledClutches",
    "Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum",
    "Modelica.Mechanics.MultiBody.Examples.Elementary.FreeBody",
    "Modelica.Fluid.Examples.TraceSubstances.RoomCO2WithControls",
    "Modelica.Clocked.Examples.SimpleControlledDrive.ClockedWithDiscreteTextbookController",
    "Modelica.Fluid.Examples.PumpingSystem"
  ]
]
