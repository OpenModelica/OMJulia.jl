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

# Where OMCSession looks for OpenModelica: omc, version, OPENMODELICAHOME,
# OPENMODELICAHOME_<version>, PATH. Apart from the last testset no omc is
# started, the installations are directories with an empty bin/omc.exe.

using Test
import OMJulia

const RELEASE = "OPENMODELICAHOME_1_27_0"
const MAINTENANCE = "OPENMODELICAHOME_1_27_0_5_g0123456789"
const NIGHTLY_OLD = "OPENMODELICAHOME_1_28_0_dev_900_gaaaaaaaaaa"
const NIGHTLY = "OPENMODELICAHOME_1_28_0_dev_1962_g6e348e217c"

function install(dir, name)
    omhome = joinpath(dir, name)
    mkpath(joinpath(omhome, "bin"))
    touch(joinpath(omhome, "bin", "omc.exe"))
    return omhome
end

omcOf(omhome) = joinpath(omhome, "bin", "omc.exe")

locate(env; omc=nothing, version=nothing) = OMJulia.locateOMC(omc; version=version, env=env)

# what is started on Windows if neither an omc nor a version is asked for
windowsDefault(env) = OMJulia.windowsDefaultOMC(env)

@testset "Environment variable of a version" begin
    @test OMJulia.versionEnvName("1.27.0") == RELEASE
    @test OMJulia.versionEnvName("v1.27.0") == RELEASE
    @test OMJulia.versionEnvName("1.28.0-dev-1962-g6e348e217c") == NIGHTLY
    @test OMJulia.versionEnvName("1.27") == "OPENMODELICAHOME_1_27"
end

mktempdir() do dir
    env = Dict(name => install(dir, name) for name in (NIGHTLY_OLD, RELEASE, NIGHTLY, MAINTENANCE))

    @testset "Installed versions, newest first" begin
        withOthers = merge(env, Dict("OPENMODELICAHOME" => env[RELEASE],
                                     "OPENMODELICAHOME_1_30_0" => joinpath(dir, "uninstalled"),
                                     "PATH" => "/usr/bin"))
        @test first.(OMJulia.installedVersions(withOthers)) == [NIGHTLY, NIGHTLY_OLD, MAINTENANCE, RELEASE]

        # numbers, not strings
        names = ["OPENMODELICAHOME_1_9_0", "OPENMODELICAHOME_1_27_1", "OPENMODELICAHOME_1_100_0"]
        numbers = Dict(name => install(dir, name) for name in names)
        @test first.(OMJulia.installedVersions(numbers)) == reverse(names)
    end

    @testset "omc wins" begin
        @test locate(env; omc="/some/where/bin/omc", version="1.27.0") == "/some/where/bin/omc"
    end

    @testset "version" begin
        @test locate(env; version="1.27.0") == omcOf(env[RELEASE])
        @test locate(env; version="v1.27.0") == omcOf(env[RELEASE])
        @test locate(env; version="1.28.0-dev-900-gaaaaaaaaaa") == omcOf(env[NIGHTLY_OLD])
    end

    @testset "start of a version" begin
        # the newest one that starts with the given version
        @test locate(env; version="1.28") == omcOf(env[NIGHTLY])
        @test locate(env; version="1.28.0-dev") == omcOf(env[NIGHTLY])
        @test locate(env; version="1") == omcOf(env[NIGHTLY])
        @test locate(env; version="1.27") == omcOf(env[MAINTENANCE])
        # the given version is used if it is installed, 1.27.0-5-g0123456789 is not picked
        @test locate(env; version="1.27.0") == omcOf(env[RELEASE])
        # 1.2 is not 1.27
        @test_throws ErrorException locate(env; version="1.2")
    end

    @testset "version that is not installed" begin
        err = try
            locate(env; version="1.26.0")
        catch e
            e
        end
        @test err isa ErrorException
        @test occursin("OPENMODELICAHOME_1_26_0", err.msg)
        # the installed versions are listed
        @test occursin(RELEASE, err.msg) && occursin(NIGHTLY, err.msg)

        @test_throws "Installed versions: none" locate(Dict{String, String}(); version="1.26.0")
    end

    @testset "OPENMODELICAHOME" begin
        @test windowsDefault(merge(env, Dict("OPENMODELICAHOME" => env[RELEASE]))) == omcOf(env[RELEASE])
        # no versioned installations: the path is used as it is, as before
        @test windowsDefault(Dict("OPENMODELICAHOME" => joinpath(dir, "not", "checked"))) ==
              joinpath(dir, "not", "checked", "bin", "omc.exe")
        # left behind by an uninstalled version
        @test windowsDefault(merge(env, Dict("OPENMODELICAHOME" => joinpath(dir, "uninstalled")))) ==
              omcOf(env[NIGHTLY])
    end

    @testset "Newest version" begin
        @test windowsDefault(env) == omcOf(env[NIGHTLY])
    end

    @testset "omc from PATH" begin
        @test isnothing(windowsDefault(Dict("PATH" => "/usr/bin")))
        @test isnothing(locate(Dict("PATH" => "/usr/bin")))
    end

    @testset "Platform" begin
        withHome = merge(env, Dict("OPENMODELICAHOME" => env[RELEASE]))
        if Sys.iswindows()
            @test locate(withHome) == omcOf(env[RELEASE])
            @test locate(env) == omcOf(env[NIGHTLY])
        else
            # Linux and macOS: the environment variables are only used for a version
            @test isnothing(locate(withHome))
            @test isnothing(locate(env))
        end
    end

    @testset "Names are case-insensitive" begin
        # Windows keeps the case the variable was created with
        @test locate(Dict("OpenModelicaHome_1_27_0" => env[RELEASE]); version="1.27.0") == omcOf(env[RELEASE])
    end
end

@testset "Session of a version" begin
    # the installation the tests run with, registered as version 1.99.0
    omcOnPath = Sys.which("omc")
    omhome = isnothing(omcOnPath) ? get(ENV, "OPENMODELICAHOME", "") : dirname(dirname(omcOnPath))
    if OMJulia.hasOMC(omhome)
        withenv("OPENMODELICAHOME_1_99_0" => omhome) do
            omc = OMJulia.OMCSession(version="1.99")
            try
                @test OMJulia.sendExpression(omc, "getVersion()") isa String
            finally
                OMJulia.quit(omc)
            end
            @test_throws ErrorException OMJulia.OMCSession(version="1.0")
        end
    else
        @test_skip "no omc on PATH or in OPENMODELICAHOME"
    end
end

# Start a session, ask omc for its version and stop it again.
function sessionAnswers(omc=nothing)
    session = OMJulia.OMCSession(omc)
    try
        return OMJulia.sendExpression(session, "getVersion()") isa String
    finally
        OMJulia.quit(session)
    end
end

# The environment without OPENMODELICAHOME and without any OPENMODELICAHOME_<version>.
function withoutOMHome(f)
    names = [name for name in keys(ENV) if startswith(uppercase(name), "OPENMODELICAHOME")]
    withenv(f, [name => nothing for name in names]...)
end

@testset "Session of a given omc" begin
    omcOnPath = Sys.which("omc")
    omhome = isnothing(omcOnPath) ? get(ENV, "OPENMODELICAHOME", "") : dirname(dirname(omcOnPath))
    if OMJulia.hasOMC(omhome)
        omc = joinpath(omhome, "bin", Sys.iswindows() ? "omc.exe" : "omc")
        @test sessionAnswers(omc)
        # the given omc does not need the environment variables
        withoutOMHome() do
            @test sessionAnswers(omc)
        end
    else
        @test_skip "no omc on PATH or in OPENMODELICAHOME"
    end
end

@testset "Session of omc from PATH" begin
    if !isnothing(Sys.which("omc"))
        withoutOMHome() do
            @test sessionAnswers()
        end
    else
        @test_skip "no omc on PATH"
    end
end
