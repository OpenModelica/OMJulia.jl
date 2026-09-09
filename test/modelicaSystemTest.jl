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

@testset "ModelicaSystem" begin
    workdir = abspath(joinpath(@__DIR__, "test-modelicasystem"))
    rm(workdir, recursive=true, force=true)
    mkpath(workdir)

    resultfile = joinpath(workdir, "ModSeborgCSTRorg_res.mat")

    mod = OMJulia.OMCSession()
    OMJulia.ModelicaSystem(mod,
                           joinpath(@__DIR__, "..", "docs", "testmodels", "ModSeborgCSTRorg.mo"),
                           "ModSeborgCSTRorg")
    OMJulia.simulate(mod,
                     resultfile = resultfile)
    @test isfile(resultfile)
    fmu = OMJulia.convertMo2FMU(mod)
    @test isfile(fmu)
    OMJulia.quit(mod)
end

# `simulate` and `linearize` cd into the session tempdir to run the generated
# executable. They must put the caller's working directory back on every exit
# path -- including the successful one, which used to `return` straight out and
# strand the process in a temporary directory that is later removed.
# See https://github.com/OpenModelica/OMJulia.jl/issues/132
@testset "Working directory is restored" begin
    workdir = abspath(joinpath(@__DIR__, "test-workingdir"))
    rm(workdir, recursive=true, force=true)
    mkpath(workdir)

    before = pwd()
    mod = OMJulia.OMCSession()
    try
        OMJulia.ModelicaSystem(mod,
                               joinpath(@__DIR__, "..", "docs", "testmodels", "ModSeborgCSTRorg.mo"),
                               "ModSeborgCSTRorg")
        @test pwd() == before

        OMJulia.simulate(mod, resultfile = joinpath(workdir, "res.mat"))
        @test pwd() == before

        OMJulia.linearize(mod)
        @test pwd() == before

        # A failing run must not stranded us either.
        @test_throws Exception OMJulia.simulate(mod, simflags = "-noSuchFlag")
        @test pwd() == before
    finally
        cd(before)
        OMJulia.quit(mod)
    end
end

# `simflags` is one string that may carry several flags. Each has to reach the
# executable as its own argument -- passing the whole string as a single argv
# entry makes the runtime reject it as one unrecognized option.
# See https://github.com/OpenModelica/OMJulia.jl/issues/133
@testset "Multiple simulation flags" begin
    workdir = abspath(joinpath(@__DIR__, "test-simflags"))
    rm(workdir, recursive=true, force=true)
    mkpath(workdir)

    mod = OMJulia.OMCSession()
    try
        OMJulia.ModelicaSystem(mod,
                               joinpath(@__DIR__, "..", "docs", "testmodels", "ModSeborgCSTRorg.mo"),
                               "ModSeborgCSTRorg")

        # One flag worked before; several did not.
        OMJulia.simulate(mod, resultfile = joinpath(workdir, "one.mat"),
                         simflags = "-s=euler")
        @test isfile(joinpath(workdir, "one.mat"))

        OMJulia.simulate(mod, resultfile = joinpath(workdir, "two.mat"),
                         simflags = "-s=euler -emit_protected")
        @test isfile(joinpath(workdir, "two.mat"))

        # An empty or absent value must still mean "no flags".
        OMJulia.simulate(mod, resultfile = joinpath(workdir, "none.mat"))
        @test isfile(joinpath(workdir, "none.mat"))

        @test OMJulia.linearize(mod, simflags = "-s=euler -emit_protected") isa Vector
    finally
        OMJulia.quit(mod)
    end
end

# The Dict/keyword set methods and the DataFrame getSolutions, against a real
# omc. See issues #98, #100 and #101.
@testset "Set methods and solutions" begin
    workdir = abspath(joinpath(@__DIR__, "test-setmethods"))
    rm(workdir, recursive=true, force=true)
    mkpath(workdir)

    resultfile = joinpath(workdir, "res.mat")

    mod = OMJulia.OMCSession()
    try
        OMJulia.ModelicaSystem(mod,
                               joinpath(@__DIR__, "..", "docs", "testmodels", "ModSeborgCSTRorg.mo"),
                               "ModSeborgCSTRorg")

        @testset "Simulation options as keyword arguments" begin
            OMJulia.setSimulationOptions(mod, stopTime = 2.0, tolerance = 1e-8)
            options = OMJulia.getSimulationOptions(mod)
            @test options["stopTime"] == "2.0"
            @test options["tolerance"] == "1.0e-8"

            # Options left out keep their value.
            OMJulia.setSimulationOptions(mod, stopTime = 1.0)
            @test OMJulia.getSimulationOptions(mod, "tolerance") == "1.0e-8"
            @test OMJulia.getSimulationOptions(mod, "stopTime") == "1.0"

            @test_throws ErrorException OMJulia.setSimulationOptions(mod, Dict("nope" => 1))
        end

        @testset "Parameters and inputs as a Dict" begin
            OMJulia.setParameters(mod, Dict("a" => 3, "V" => 200))
            @test OMJulia.getParameters(mod, ["a", "V"]) == ["3", "200"]

            # A typo used to be logged and ignored, which simulated the model
            # with its default value and said nothing.
            @test_throws ErrorException OMJulia.setParameters(mod, Dict("nosuchparam" => 1))

            OMJulia.setInputs(mod, Dict("cAi" => 100, "Ti" => 350,
                                        "Vdi" => 100, "Tc" => 300))
            @test OMJulia.getInputs(mod, "cAi") == "100"

            # A time table, which is what createcsvdata has to write out.
            OMJulia.setInputs(mod, Dict("Tc" => [(0, 300), (1, 320)]))
            @test OMJulia.getInputs(mod, "Tc") == [[0, 300], [1, 320]]

            @test_throws ErrorException OMJulia.setInputs(mod, Dict("Tc" => [1, 2, 3]))
        end

        OMJulia.simulate(mod, resultfile = resultfile)
        @test isfile(resultfile)

        @testset "getSolutionNames" begin
            names = OMJulia.getSolutionNames(mod)
            @test names isa Vector{String}
            @test "T" in names
            # time is the index, not something to ask for, and omc's internal
            # names cannot be read back.
            @test !("time" in names)
            @test !any(name -> startswith(name, '$'), names)
        end

        @testset "getSolutions returns a DataFrame" begin
            solutions = OMJulia.getSolutions(mod, ["T"])
            @test solutions isa DataFrames.DataFrame
            @test DataFrames.names(solutions) == ["time", "T"]
            @test eltype(solutions[!, "T"]) == Float64
            @test length(solutions[!, "time"]) > 1

            # time leads, once, however it was asked for.
            @test DataFrames.names(OMJulia.getSolutions(mod, "T")) == ["time", "T"]
            @test DataFrames.names(OMJulia.getSolutions(mod, ["T", "time"])) == ["time", "T"]
            @test DataFrames.names(OMJulia.getSolutions(mod, ["time", "T"])) == ["time", "T"]
            @test DataFrames.names(OMJulia.getSolutions(mod, ["T", "T"])) == ["time", "T"]

            # The caller's order is the column order they get.
            @test DataFrames.names(OMJulia.getSolutions(mod, ["cA", "T"])) == ["time", "cA", "T"]

            # No name in particular means everything in the file, and every
            # one of those names must be readable.
            everything = OMJulia.getSolutions(mod)
            @test DataFrames.names(everything)[1] == "time"
            @test issetequal(DataFrames.names(everything),
                             vcat("time", OMJulia.getSolutionNames(mod)))

            @test_throws ErrorException OMJulia.getSolutions(mod, "nosuchvariable")
        end

        @testset "Reading a result file by path" begin
            @test DataFrames.names(OMJulia.getSolutions(mod, ["T"], resultfile = resultfile)) ==
                  ["time", "T"]
            @test "T" in OMJulia.getSolutionNames(mod, resultfile = resultfile)
        end

        @testset "Get methods that read solutions by name" begin
            # These indexed the result by position, which stopped being right
            # once time was prepended.
            @test OMJulia.getContinuous(mod, "T") isa Real
            @test OMJulia.getOutputs(mod, "y_T") isa Real
            @test OMJulia.getContinuous(mod, ["T", "cA"]) isa Vector
        end

        @testset "The deprecated string form still works" begin
            OMJulia.setParameters(mod, "a=4")
            @test OMJulia.getParameters(mod, "a") == "4"
            OMJulia.setParameters(mod, ["a=5", "V=300"])
            @test OMJulia.getParameters(mod, ["a", "V"]) == ["5", "300"]
            OMJulia.setSimulationOptions(mod, "stopTime=3.0")
            @test OMJulia.getSimulationOptions(mod, "stopTime") == "3.0"
        end
    finally
        OMJulia.quit(mod)
    end
end

# sensitivity does array arithmetic on solutions, which a DataFrame does not
# support, so it reads them back as plain columns.
@testset "Sensitivity" begin
    workdir = abspath(joinpath(@__DIR__, "test-sensitivity"))
    rm(workdir, recursive=true, force=true)
    mkpath(workdir)

    mod = OMJulia.OMCSession()
    try
        OMJulia.ModelicaSystem(mod,
                               joinpath(@__DIR__, "..", "docs", "testmodels", "ModSeborgCSTRorg.mo"),
                               "ModSeborgCSTRorg")
        OMJulia.setSimulationOptions(mod, stopTime = 1.0)
        OMJulia.setInputs(mod, Dict("cAi" => 100, "Ti" => 350,
                                    "Vdi" => 100, "Tc" => 300))

        sensitivityNames, sensitivities = OMJulia.sensitivity(mod, ["V", "UA"], ["T", "cA"], [1e-2])

        # One entry per parameter, each naming one sensitivity per variable of
        # interest. Vp and Vv need not be the same length.
        @test length(sensitivityNames) == 2
        @test length(sensitivities) == 2
        @test sensitivityNames[1] == ["Sensitivity.V.T", "Sensitivity.V.cA"]
        @test sensitivityNames[2] == ["Sensitivity.UA.T", "Sensitivity.UA.cA"]
        @test sensitivities isa Vector{Vector{Vector{Float64}}}
        @test length(sensitivities[1]) == 2
    finally
        OMJulia.quit(mod)
    end
end
