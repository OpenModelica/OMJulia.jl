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

import Pkg; Pkg.activate(@__DIR__)
import OMJulia
import FMI

using Test
using DataFrames
using CSV

"""
Simulate single model to generate a result file.
"""
function testSimulation(omc::OMJulia.OMCSession, className::String)
  @info "\tSimulation"
  @testset "Simulation" begin
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
  fmuImportSuccess = false
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
      solution = FMI.fmiSimulate(fmu; recordValues = recordValues, showProgress=false)

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
      fmuImportSuccess = true
    end
    @test fmuImportSuccess
  end

  @info "\tCheck Results"
  @testset "Verification" begin
    if fmuImportSuccess
      @test (true, String[]) == OMJulia.API.diffSimulationResults(omc, "FMI_results.csv", referenceResult, "diff")
    else
      @test false
    end
  end
end

"""
Run Simulation and FMU export/import test for all models.
"""
function runSingleTest(library, version, model, modeldir)
  local resultFile

  @info "Testing library: $library, model $model"
  mkpath(modeldir)
  omc = OMJulia.OMCSession()

  try
    @testset "$model" verbose=true begin
      @testset "Simulation" begin
        OMJulia.API.cd(omc, modeldir)

        @test OMJulia.API.loadModel(omc, library; priorityVersion = [version], requireExactVersion = true)
        resultFile = testSimulation(omc, model)
      end

      @testset "FMI" begin
        if isfile(resultFile)
          recordValues = names(CSV.read(resultFile, DataFrame))[2:end]
          filter!(val -> !startswith(val, "\$"), recordValues) # Filter internal variables
          testFmuExport(omc, model, resultFile, recordValues; workdir=modeldir)
        else
          @test false
        end
      end
    end
  finally
    OMJulia.quit(omc)
  end
end

# Comand-line interface
if !isempty(PROGRAM_FILE)
  if length(ARGS) == 4
    library  = ARGS[1]
    version  = ARGS[2]
    model    = ARGS[3]
    modeldir = ARGS[4]
    runSingleTest(library, version, model, modeldir)
  else
    @error "Wrong number of arguments"
    for a in ARGS; println(a); end
    return -1
  end
end
