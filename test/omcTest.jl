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

@testset "OpenModelica" begin
    @testset "OMCSession" begin
        workdir = abspath(joinpath(@__DIR__, "test-session"))
        rm(workdir, recursive=true, force=true)
        mkpath(workdir)

        if Sys.iswindows()
            workdir = replace(workdir, "\\" => "\\\\")
        end

        oldwd = pwd()
        try
            omc = OMJulia.OMCSession()
            OMJulia.sendExpression(omc, "cd(\"$workdir\")")
            version = OMJulia.sendExpression(omc, "getVersion()")
            @test (startswith(version, "v1.") || startswith(version, "OpenModelica v1.") || startswith(version, "OpenModelica 1."))
            a = OMJulia.sendExpression(omc, "model a end a;")
            @test a == [:a]

            classNames = OMJulia.sendExpression(omc, "getClassNames()")
            @test classNames == [:a]
            @test true == OMJulia.sendExpression(omc, "loadModel(Modelica)")
            res = OMJulia.sendExpression(omc, "simulate(Modelica.Electrical.Analog.Examples.CauerLowPassAnalog)")
            @test isfile(res["resultFile"])
            @test occursin("The simulation finished successfully.", res["messages"])

            @test 3 == OMJulia.sendExpression(omc, "1+2")
            # TODO: sendExpression(quit()) and kill(omc.omcprocess) get stuck on Ubuntu
        finally
            cd(oldwd)
        end
    end

    @testset "Multiple sessions" begin
        workdir1 = abspath(joinpath(@__DIR__, "test-omc1"))
        workdir2 = abspath(joinpath(@__DIR__, "test-omc2"))
        rm(workdir1, recursive=true, force=true)
        rm(workdir2, recursive=true, force=true)
        mkpath(workdir1)
        mkpath(workdir2)

        if Sys.iswindows()
            workdir1 = replace(workdir1, "\\" => "\\\\")
            workdir2 = replace(workdir2, "\\" => "\\\\")
        end

        oldwd = pwd()
        try
            omc1 = OMJulia.OMCSession()
            omc2 = OMJulia.OMCSession()

            OMJulia.sendExpression(omc1, "cd(\"$workdir1\")")
            @test true == OMJulia.sendExpression(omc1, "loadModel(Modelica)")
            res = OMJulia.sendExpression(omc1, "simulate(Modelica.Blocks.Examples.PID_Controller)")
            @test isfile(joinpath(@__DIR__, "test-omc1", "Modelica.Blocks.Examples.PID_Controller_res.mat"))

            OMJulia.sendExpression(omc2, "cd(\"$workdir2\")")
            @test true == OMJulia.sendExpression(omc2, "loadModel(Modelica)")
            res = OMJulia.sendExpression(omc2, "simulate(Modelica.Blocks.Examples.PID_Controller)")
            @test isfile(joinpath(@__DIR__, "test-omc2", "Modelica.Blocks.Examples.PID_Controller_res.mat"))

            # TODO: sendExpression(quit()) and kill(omc.omcprocess) get stuck on Ubuntu
        finally
            cd(oldwd)
        end
    end
end
