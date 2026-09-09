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

# A stand-in for omc: a process that never writes a port file. Julia itself, so
# these tests need no OpenModelica installation.
function dummyProcess(expression::AbstractString)
    cmd = `$(Base.julia_cmd()) --startup-file=no -e $expression`
    return open(pipeline(cmd, stdout=devnull, stderr=devnull))
end

# The wait used to be 100 iterations of `sleep(0.02)`, which is a different
# amount of time on every platform and was too little for a cold omc start on
# Windows. See https://github.com/OpenModelica/OMJulia.jl/issues/137
@testset "Waiting for the omc port file" begin
    @testset "Returns at once when the file is already there" begin
        mktempdir() do dir
            portfile = joinpath(dir, "openmodelica.port.julia.here")
            touch(portfile)
            process = dummyProcess("sleep(60)")
            try
                started = time()
                found = OMJulia.waitForPortFile(portfile, process, timeout = 60)
                elapsed = time() - started
                @test found
                @test elapsed < 1
            finally
                kill(process)
            end
        end
    end

    @testset "Picks the file up while waiting" begin
        mktempdir() do dir
            portfile = joinpath(dir, "openmodelica.port.julia.late")
            process = dummyProcess("sleep(60)")
            try
                @async begin
                    sleep(0.3)
                    touch(portfile)
                end
                @test OMJulia.waitForPortFile(portfile, process, timeout = 60)
            finally
                kill(process)
            end
        end
    end

    @testset "Gives up at the deadline" begin
        mktempdir() do dir
            portfile = joinpath(dir, "openmodelica.port.julia.never")
            process = dummyProcess("sleep(60)")
            try
                started = time()
                found = OMJulia.waitForPortFile(portfile, process, timeout = 0.5)
                elapsed = time() - started
                @test !found
                # The deadline is honoured, and honoured in wall-clock seconds
                # rather than in whatever a fixed number of `sleep`s costs here.
                @test elapsed >= 0.5
                @test elapsed < 10
            finally
                kill(process)
            end
        end
    end

    @testset "Stops early when omc exits without writing it" begin
        mktempdir() do dir
            portfile = joinpath(dir, "openmodelica.port.julia.dead")
            process = dummyProcess("exit(0)")
            try
                started = time()
                found = OMJulia.waitForPortFile(portfile, process, timeout = 60)
                elapsed = time() - started
                @test !found
                # Nothing to wait for once omc is gone, so this must not sit out
                # the deadline.
                @test elapsed < 30
            finally
                kill(process)
            end
        end
    end
end

@testset "A timeout says why" begin
    @testset "omc's output is folded into the message" begin
        mktempdir() do dir
            stdoutfile = joinpath(dir, "stdout.log")
            stderrfile = joinpath(dir, "stderr.log")
            write(stdoutfile, "omc said something\n")
            write(stderrfile, "omc complained\n")

            details = OMJulia.omcStartupLog(stdoutfile, stderrfile)
            @test occursin("omc said something", details)
            @test occursin("omc complained", details)
        end
    end

    @testset "Missing logs do not mask the timeout" begin
        mktempdir() do dir
            @test OMJulia.omcStartupLog(joinpath(dir, "gone"),
                                        joinpath(dir, "also-gone")) == ""
        end
    end

    @testset "The message reaches the error output" begin
        # `showerror` printed the message to stdout instead of `io`, so the
        # reported error was a bare "TimeoutError" with the detail stranded
        # elsewhere in the log.
        buffer = IOBuffer()
        showerror(buffer, OMJulia.TimeoutError("the port file never showed up"))
        @test occursin("the port file never showed up", String(take!(buffer)))
    end
end
