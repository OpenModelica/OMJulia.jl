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
using CSV
using DataFrames
import OMJulia

@testset "API" begin
    workdir = abspath(joinpath(@__DIR__, "test-API"))
    rm(workdir, recursive=true, force=true)
    mkpath(workdir)
    if Sys.iswindows()
        workdir = replace(workdir, "\\" => "/")
    end

    omc = OMJulia.OMCSession()
    # Install packages
    @test OMJulia.API.updatePackageIndex(omc)
    versions = OMJulia.API.getAvailablePackageVersions(omc, "Modelica", version="3.0.0+maint.om")
    @test "3.0.0+maint.om" in versions
    @test OMJulia.API.upgradeInstalledPackages(omc)
    @test OMJulia.API.installPackage(omc, "Modelica", version = "")

    # Load file
    @test OMJulia.API.loadFile(omc, joinpath(@__DIR__, "../docs/testmodels/BouncingBall.mo"))

    # Enter non-existing directory
    @test_throws OMJulia.API.ScriptingError throw(OMJulia.API.ScriptingError(msg = "Test error message."))
    @test_throws OMJulia.API.ScriptingError throw(OMJulia.API.ScriptingError(omc, msg = "Test error message."))
    @test_throws OMJulia.API.ScriptingError OMJulia.API.cd(omc, "this/is/not/a/valid/directory/I/hope/otherwise/our/test/does/some/wild/stuff")

    dir = OMJulia.API.cd(omc, workdir)
    result = OMJulia.API.buildModel(omc, "BouncingBall")
    @test result[2] == "BouncingBall_init.xml"
    resultfile = joinpath(workdir, "BouncingBall_res.mat")

    # Remove simulation artifacts from previous buildModel
    if VERSION > v"1.4"
        foreach(rm, readdir(workdir, join=true))
    else
        foreach(rm, joinpath.(workdir, readdir(workdir)))
    end
    OMJulia.API.simulate(omc, "BouncingBall")
    @test isfile(resultfile)

    vars = OMJulia.API.readSimulationResultVars(omc, resultfile)
    @test var = "h" in vars

    simres = OMJulia.API.readSimulationResult(omc, resultfile, ["time", "h", "v"])
    @test simres[2][1] == 1.0

    df = DataFrame(:time => simres[1], :h => simres[2], :v => simres[3])
    expectedFile = joinpath(workdir, "BouncingBall_ref.csv")
    wrongExpectedFile = joinpath(workdir, "BouncingBall_wrong.csv")
    CSV.write(expectedFile, df)
    df2 = copy(df)
    df2[:,2] .= df2[:,2] .* 0.01
    CSV.write(wrongExpectedFile, df2)

    @test (true, String[]) == OMJulia.API.diffSimulationResults(omc, resultfile, expectedFile, "diff"; vars=String[])
    @test (true, String[]) == OMJulia.API.diffSimulationResults(omc, resultfile, expectedFile, "diff"; vars=["h", "v"])
    @test (false, ["h"]) == OMJulia.API.diffSimulationResults(omc, resultfile, wrongExpectedFile, "diff"; vars=["h", "v"])

    fmu = joinpath(workdir, "BouncingBall.fmu")
    OMJulia.API.buildModelFMU(omc, "BouncingBall")
    @test isfile(fmu)

    @test OMJulia.API.setCommandLineOptions(omc, "--generateSymbolicLinearization")

    @test OMJulia.API.loadFile(omc, joinpath(@__DIR__, "../docs/testmodels/ModSeborgCSTRorg.mo"))

    @test [:BouncingBall, :ModSeborgCSTRorg] == sort(OMJulia.API.getClassNames(omc))

    flatModelicaCode = OMJulia.API.instantiateModel(omc, "BouncingBall")
    @test occursin("class BouncingBall", flatModelicaCode)

    OMJulia.quit(omc)
end
