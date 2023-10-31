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

using SafeTestsets
using Test
using DataFrames
using CSV

import OMJulia
import FMI

"""
Simulate single model to generate a result file.
"""
function testSimulation(omc::OMJulia.OMCSession, className::String)
  @info "\tSimulation"
  @testset verbose=false failfast=false "Simulation" begin
    res = OMJulia.API.simulate(omc, className; outputFormat="csv")
    resultFile = res["resultFile"]

    @test isfile(resultFile)
    return resultFile
  end
end

"""
Build a FMU for a single model, import the generated FMU, simulate it and compare to given reference results.
"""
function testFmuExport(omc::OMJulia.OMCSession, className::String, referenceResult, recordValues; workdir::String)
  local fmuPath
  @info "\tFMU Export"
  @testset "Export" begin
    fmuPath = OMJulia.API.buildModelFMU(omc, className)
    @test isfile(fmuPath)
    @test splitext(splitpath(fmuPath)[end]) == (className, ".fmu")
  end

  @info "\tFMU Import"
  @testset "Import" begin
    if isfile(fmuPath)
      fmu = FMI.fmiLoad(fmuPath)
      solution = FMI.fmiSimulate(fmu; recordValues = recordValues)

      # Own implementation of CSV export, workaround for https://github.com/ThummeTo/FMI.jl/issues/198
      df = DataFrames.DataFrame(time = solution.values.t)
      for i in 1:length(solution.values.saveval[1])
        for var in FMI.fmi2ValueReferenceToString(fmu, solution.valueReferences[i])
          if in(var, recordValues)
            df[!, Symbol(var)] = [val[i] for val in solution.values.saveval]
          end
        end
      end
      fmiResult = joinpath(workdir, "FMI_results.csv")
      CSV.write(fmiResult, df)

      #FMI.fmiSaveSolution(solution, "FMI_results.csv")
      @test true
    else
      @test false
    end
  end

  @info "\tCheck Results"
  @testset "Verification" begin
    @test (true, String[]) == OMJulia.API.diffSimulationResults(omc, "FMI_results.csv", referenceResult, "diff")
  end
end

"""
Run Simulation and FMU export/import test for all models.
"""
function testModels(omc::OMJulia.OMCSession, models::Vector{S}; libdir) where S<:AbstractString
  local resultFile

  for model in models
    @testset verbose=false failfast=false "$model" begin
      modeldir = joinpath(libdir, model)
      mkpath(modeldir)
      @info "Testing $model"
      OMJulia.API.cd(omc, modeldir)
      resultFile = testSimulation(omc, model)
      @testset verbose=false failfast=false "FMI" begin
        if isfile(resultFile)
          recordValues = names(CSV.read(resultFile, DataFrame))[2:end]
          testFmuExport(omc, model, resultFile, recordValues; workdir=modeldir)
        else
          @test false
        end
      end
    end
  end
end

"""
Run test for all libraries.
"""
function runTests(libraries::Vector{Tuple{S,S}},
                  models::Vector{Vector{S}};
                  workdir) where S<:AbstractString

  rm(workdir, recursive=true, force=true)
  mkpath(workdir)

  @testset verbose=true failfast=false "OpenModelica" begin
    for (i, (library, version)) in enumerate(libraries)
      @testset verbose = true failfast=false "$library" begin
        libdir = joinpath(workdir, library)
        mkpath(libdir)

        omc = OMJulia.OMCSession()
        v = OMJulia.API.getVersion(omc)

        @test OMJulia.API.loadModel(omc, library; priorityVersion = [version], requireExactVersion = true)
        testModels(omc, models[i]; libdir=libdir)

        OMJulia.quit(omc)
      end
    end
  end

  return
end

libraries = [
  ("Modelica", "4.0.0")
  ("Buildings", "10.0.0")
]

models = [
  [
    "Modelica.Electrical.Analog.Examples.CauerLowPassAnalog",
    "Modelica.Fluid.Examples.DrumBoiler.DrumBoiler"
  ],
  [
    "Buildings.Applications.DataCenters.ChillerCooled.Examples.IntegratedPrimaryLoadSideEconomizer"
  ]
]

workdir = abspath(joinpath(@__DIR__, "test-regressionTests"))
