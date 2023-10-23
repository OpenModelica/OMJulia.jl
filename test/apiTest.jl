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

@testset "API" begin
    workdir = abspath(joinpath(@__DIR__, "test-API"))
    rm(workdir, recursive=true, force=true)
    mkpath(workdir)
    if Sys.iswindows()
        workdir = replace(workdir, "\\" => "/")
    end

    omc = OMJulia.OMCSession()
    @test OMJulia.API.loadFile(omc, "../docs/testmodels/BouncingBall.mo")

    # Enter non-existing directory
    @test_throws OMJulia.ScriptingError
 OMJulia.API.cd(omc, "this/is/not/a/valid/directory/I/hope/otherwise/our/test/does/some/wild/stuff")

    dir = OMJulia.API.cd(omc, workdir)
    result2 = OMJulia.API.buildModel(omc, "BouncingBall")
    @test result2[2] == "BouncingBall_init.xml"
    result2 = OMJulia.API.buildModel(omc, "BouncingBall")
    @test result2[2] == "BouncingBall_init.xml"
    resultfile = joinpath(workdir, "BouncingBall_res.mat")

    OMJulia.API.simulate(omc, "BouncingBall")
    @test isfile(resultfile)

    vars = OMJulia.API.readSimulationResultVars(omc, resultfile)
    @test var = "h" in vars

    simres = OMJulia.API.readSimulationResult(omc, resultfile, ["h"])
    @test simres[1][1] == 1.0

    fmu = joinpath(workdir, "BouncingBall.fmu")
    OMJulia.API.buildModelFMU(omc, "BouncingBall")
    @test isfile(fmu)

    result3 = OMJulia.API.setCommandLineOptions(omc, "--generateSymbolicLinearization")
    @test result3 == true

    classNames = OMJulia.API.getClassNames()
    @test classNames == [:BouncingBall]

    OMJulia.quit(omc)
end
