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
import OMJulia

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
