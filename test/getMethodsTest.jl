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

using Test
import OMJulia
import DataFrames

# The get methods take a name, a vector of names, or nothing, and every one of
# those branches was uncovered. So were the errors they raise. None of this is
# new behaviour; it just had no tests.
@testset "Get methods" begin
    workdir = abspath(joinpath(@__DIR__, "test-getmethods"))
    rm(workdir, recursive=true, force=true)
    mkpath(workdir)

    modelfile = joinpath(@__DIR__, "..", "docs", "testmodels", "ModSeborgCSTRorg.mo")

    mod = OMJulia.OMCSession()
    try
        OMJulia.ModelicaSystem(mod, modelfile, "ModSeborgCSTRorg",
                               customBuildDirectory = workdir)
        @test OMJulia.getWorkDirectory(mod) == replace(workdir, r"[/\\]+" => "/")

        @testset "Quantities" begin
            quantities = OMJulia.getQuantities(mod)
            @test quantities isa Vector
            @test any(q -> q["name"] == "T", quantities)

            @test length(OMJulia.getQuantities(mod, "T")) == 1
            @test length(OMJulia.getQuantities(mod, ["T", "cA"])) == 2

            @test OMJulia.showQuantities(mod) isa DataFrames.DataFrame
            @test OMJulia.showQuantities(mod, "T") isa DataFrames.DataFrame
            @test OMJulia.showQuantities(mod, ["T", "cA"]) isa DataFrames.DataFrame
        end

        @testset "Parameters and options before simulating" begin
            @test OMJulia.getParameters(mod) isa AbstractDict
            @test parse(Float64, OMJulia.getParameters(mod, "V")) == 100
            @test parse.(Float64, OMJulia.getParameters(mod, ["V", "a"])) == [100, 1]
            # An unknown name reads back as 0 rather than throwing.
            @test OMJulia.getParameters(mod, "nosuchparam") == 0

            @test OMJulia.getSimulationOptions(mod) isa AbstractDict
            @test OMJulia.getSimulationOptions(mod, ["startTime", "stopTime"]) isa Vector
            @test OMJulia.getSimulationOptions(mod, "nosuchoption") == 0

            @test OMJulia.getInputs(mod) isa AbstractDict
            @test OMJulia.getInputs(mod, "cAi") isa Union{AbstractString, Number}
            @test OMJulia.getInputs(mod, ["cAi", "Ti"]) isa Vector

            # Before a simulation these read the xml rather than a result file.
            @test OMJulia.getOutputs(mod) isa AbstractDict
            @test OMJulia.getOutputs(mod, "y_T") isa Union{AbstractString, Number}
            @test OMJulia.getOutputs(mod, ["y_T"]) isa Vector
            @test OMJulia.getContinuous(mod) isa AbstractDict
            @test OMJulia.getContinuous(mod, "T") isa Union{AbstractString, Number}
            @test OMJulia.getContinuous(mod, ["T", "cA"]) isa Vector
        end

        OMJulia.setSimulationOptions(mod, stopTime = 1.0)
        OMJulia.setInputs(mod, Dict("cAi" => 100, "Ti" => 350,
                                    "Vdi" => 100, "Tc" => 300))
        OMJulia.simulate(mod)

        @testset "Reading them back from the result file" begin
            # Every one of these now reads by column name; they used to index
            # the result by position.
            continuous = OMJulia.getContinuous(mod)
            @test continuous isa AbstractDict
            @test continuous["T"] isa Real

            outputs = OMJulia.getOutputs(mod)
            @test outputs isa AbstractDict
            @test outputs["y_T"] isa Real

            @test OMJulia.getOutputs(mod, ["y_T"])[1] isa Real
            @test OMJulia.getContinuous(mod, ["T", "cA"])[1] isa Real

            @test_throws ErrorException OMJulia.getContinuous(mod, "nosuchvariable")
            @test_throws ErrorException OMJulia.getContinuous(mod, ["nosuchvariable"])
            @test_throws ErrorException OMJulia.getOutputs(mod, "nosuchvariable")
            @test_throws ErrorException OMJulia.getOutputs(mod, ["nosuchvariable"])
        end

        @testset "Excitations are matched to the parameter count" begin
            # More excitations than parameters: the extras are dropped rather
            # than silently misaligning the results.
            names, values = OMJulia.sensitivity(mod, ["V"], ["T"], [1e-2, 1e-3, 1e-4])
            @test length(names) == 1
            @test length(values) == 1
        end
    finally
        OMJulia.quit(mod)
    end
end

# `library` takes a name, a name and a version, or an array of either, and none
# of those branches was covered.
@testset "Loading libraries" begin
    mod = OMJulia.OMCSession()
    try
        @test isnothing(OMJulia.loadLibrary(mod, nothing))
        OMJulia.loadLibrary(mod, "Modelica")
        OMJulia.loadLibrary(mod, ("Modelica", "4.0.0"))
        OMJulia.loadLibrary(mod, ["Modelica"])
        OMJulia.loadLibrary(mod, [("Modelica", "4.0.0")])
        @test "Modelica" in string.(OMJulia.sendExpression(mod, "getClassNames()"))

        @test_throws ErrorException OMJulia.loadLibrary(mod, "NoSuchLibrary")
    finally
        OMJulia.quit(mod)
    end
end

# Two inputs changing at different times: createcsvdata has to carry the last
# value of one across a row belonging to the other.
@testset "Inputs on different time grids" begin
    workdir = abspath(joinpath(@__DIR__, "test-inputgrid"))
    rm(workdir, recursive=true, force=true)
    mkpath(workdir)

    mod = OMJulia.OMCSession()
    try
        OMJulia.ModelicaSystem(mod,
                               joinpath(@__DIR__, "..", "docs", "testmodels", "ModSeborgCSTRorg.mo"),
                               "ModSeborgCSTRorg",
                               customBuildDirectory = workdir)
        OMJulia.setSimulationOptions(mod, stopTime = 1.0)
        OMJulia.setInputs(mod, Dict("cAi" => [(0, 100), (0.5, 120)],
                                    "Ti" => [(0, 350), (0.25, 360), (0.75, 340)],
                                    "Vdi" => 100,
                                    "Tc" => 300))
        OMJulia.simulate(mod)
        @test isfile(joinpath(OMJulia.getWorkDirectory(mod), "ModSeborgCSTRorg.csv"))
        @test OMJulia.getSolutions(mod, ["T"])[!, "T"][end] isa Real
    finally
        OMJulia.quit(mod)
    end
end

# linearize used to return [A, B, C, D] and throw away the dimensions and the
# operating point it had already read out of the generated model.
@testset "Linearization" begin
    workdir = abspath(joinpath(@__DIR__, "test-linearization"))
    rm(workdir, recursive=true, force=true)
    mkpath(workdir)

    mod = OMJulia.OMCSession()
    try
        OMJulia.ModelicaSystem(mod,
                               joinpath(@__DIR__, "..", "docs", "testmodels", "ModSeborgCSTRorg.mo"),
                               "ModSeborgCSTRorg",
                               customBuildDirectory = workdir)

        # Asking before linearizing fails the same way for all three.
        @test_throws ErrorException OMJulia.getLinearInputs(mod)
        @test_throws ErrorException OMJulia.getLinearOutputs(mod)
        @test_throws ErrorException OMJulia.getLinearStates(mod)

        OMJulia.setLinearizationOptions(mod, stopTime = 1.0)
        result = OMJulia.linearize(mod)

        @test result isa OMJulia.LinearizationResult
        @test result.n == length(result.x0)
        @test size(result.A) == (result.n, result.n)
        @test result.stateVars isa Vector{String}

        # The old spelling still works.
        A, B, C, D = result
        @test A == result.A
        @test D == result.D
        @test result[1] == result.A
        @test length(result) == 4
        @test_throws BoundsError result[5]

        @test OMJulia.getLinearStates(mod) == result.stateVars
        @test OMJulia.getLinearInputs(mod) isa Vector
        @test OMJulia.getLinearOutputs(mod) isa Vector
    finally
        OMJulia.quit(mod)
    end
end

@testset "Continuous start values and unchangeable parameters" begin
    mod = OMJulia.OMCSession()
    try
        OMJulia.ModelicaSystem(mod,
                               joinpath(@__DIR__, "..", "docs", "testmodels", "ModSeborgCSTRorg.mo"),
                               "ModSeborgCSTRorg")

        OMJulia.setContinuous(mod, Dict("T" => 355))
        @test OMJulia.getContinuous(mod, "T") == "355"
        @test_throws ErrorException OMJulia.setContinuous(mod, Dict("nosuchvariable" => 1))

        # k0 has a non-constant binding, so it cannot be overridden. That used
        # to warn and carry on, leaving the model to simulate with the old
        # value and say nothing about it.
        @test !OMJulia.isParameterChangeable(mod, "k0")
        @test OMJulia.isParameterChangeable(mod, "V")
        @test_throws ErrorException OMJulia.setParameters(mod, Dict("k0" => 1))
    finally
        OMJulia.quit(mod)
    end
end

@testset "ModelicaSystem rejects what it cannot build" begin
    mod = OMJulia.OMCSession()
    try
        @test_throws ErrorException OMJulia.ModelicaSystem(
            mod, joinpath(@__DIR__, "no-such-model.mo"), "NoSuchModel")

        # An unusable command line option is omc's error, reported as ours.
        @test_throws ErrorException OMJulia.ModelicaSystem(
            mod,
            joinpath(@__DIR__, "..", "docs", "testmodels", "ModSeborgCSTRorg.mo"),
            "ModSeborgCSTRorg",
            commandLineOptions = "--thisIsNotAnOption")
    finally
        OMJulia.quit(mod)
    end
end
