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

"""
    Linearization <: Any

Collection of linearization settings and variables.

See also [``]
"""
mutable struct Linearization
    "Name of linear model in Julia function `linearfile`"
    linearmodelname::AbstractString
    "Julia file linearized_model.jl containing linearization matrices A, B, C and D."
    linearfile::AbstractString
    "Experiment settings for linearization"
    linearOptions::Dict{AbstractString, AbstractString}
    linearFlag::Bool

    "Input variables"
    linearinputs::Union{Missing, Any}
    "Output variables"
    linearoutputs::Union{Missing, Any}
    "State variables"
    linearstates::Union{Missing, Any}

    function Linearization()
        linearmodelname = ""
        linearfile = ""
        linearOptions = Dict("startTime" => "0.0", "stopTime" => "1.0", "stepSize" => "0.002", "tolerance" => "1e-6")
        linearFlag = false

        new(linearmodelname, linearfile, linearOptions, linearFlag, missing, missing, missing)
    end
end

"""
How long to wait for omc to write its ZMQ port file, in seconds.

A healthy omc writes the file in well under a second and the wait ends the
moment it appears, so this only bounds the pathological case. It is generous
on purpose: the first omc start on a cold machine pays for paging the omc
libraries off disk past the virus scanner, which has taken several seconds on
a Windows CI runner.
"""
const PORT_FILE_TIMEOUT_S = 30

"""
    waitForPortFile(fullpath, omcprocess; timeout=PORT_FILE_TIMEOUT_S)

Wait for `omcprocess` to write its ZMQ port file at `fullpath`.

Return `true` as soon as the file exists, `false` if `timeout` seconds pass
without it or if omc exits without ever writing it.

Wait against the clock rather than counting `sleep`s. `sleep` rounds up to the
OS timer granularity -- of the order of 15 ms on Windows against 1 ms on Linux
-- so a fixed iteration count buys a different amount of time on every
platform, and the amount it buys on Windows was not enough.
"""
function waitForPortFile(fullpath::AbstractString, omcprocess::Base.Process;
                         timeout::Real=PORT_FILE_TIMEOUT_S)
    deadline = time() + timeout
    while true
        isfile(fullpath) && return true
        # omc is gone and is never going to write the file. Look once more, in
        # case it wrote the file and exited between the two checks, then give
        # up rather than sit out the rest of the deadline.
        process_exited(omcprocess) && return isfile(fullpath)
        time() >= deadline && return false
        sleep(0.01)
    end
end

"""
    omcStartupLog(stdoutfile, stderrfile)

omc's redirected output, formatted for an error message. Empty when omc said
nothing or the logs cannot be read -- a missing log must not turn the error
being reported into an unrelated IO error.
"""
function omcStartupLog(stdoutfile::AbstractString, stderrfile::AbstractString)
    buffer = IOBuffer()
    for (name, file) in (("stdout", stdoutfile), ("stderr", stderrfile))
        contents = try
            isfile(file) ? read(file, String) : ""
        catch
            ""
        end
        isempty(strip(contents)) && continue
        print(buffer, "\nomc $(name):\n", contents)
    end
    return String(take!(buffer))
end

"""
    ZMQSession <: Any

ZeroMQ session running interactive omc process.

-----------------------------------------

    ZMQSession(omc::Union{String, Nothing}=nothing)::ZMQSession

Start new interactive OpenModelica session using ZeroMQ.

  ## Arguments

- `omc::Union{String, Nothing}`: Path to OpenModelica compiler.
                                 Use omc from `PATH` if nothing is provided.
"""
mutable struct ZMQSession
    context::ZMQ.Context
    socket::ZMQ.Socket
    omcprocess::Base.Process

    function ZMQSession(omc::Union{String, Nothing}=nothing)::ZMQSession
        args1 = "--interactive=zmq"
        # Draw from the OS, not the global RNG. `@testset` reseeds the global
        # RNG identically for every testset, so `randstring(10)` returns the
        # same string in each one -- every session created first inside a
        # testset would then pick the same port file and collide.
        randPortSuffix = Random.randstring(Random.RandomDevice(), 10)
        args2 = "-z=julia.$(randPortSuffix)"

        stdoutfile = "stdout-$(randPortSuffix).log"
        stderrfile = "stderr-$(randPortSuffix).log"

        local omcprocess
        if Sys.iswindows()
            if !isnothing(omc )
                ompath = replace(omc, r"[/\\]+" => "/")
                dirpath = dirname(dirname(omc))
                ## create a omc process with OPENMODELICAHOME set to custom directory
                @info("Setting environment variable OPENMODELICAHOME=\"$dirpath\" for this session.")
                withenv("OPENMODELICAHOME" => dirpath) do
                    omcprocess = open(pipeline(`$omc $args1 $args2`, stdout=stdoutfile, stderr=stderrfile))
                end
            else
                omhome = ""
                try
                    omhome = ENV["OPENMODELICAHOME"]
                catch Exception
                    println(Exception, "is not set, Please set the environment Variable")
                    return
                end
                ompath = replace(joinpath(omhome, "bin", "omc.exe"), r"[/\\]+" => "/")
                # ompath=joinpath(omhome,"bin")
                ## create a omc process with default OPENMODELICAHOME set in environment variable
                withenv("OPENMODELICAHOME" => omhome) do
                    # Redirect to files like every other branch. Without a
                    # redirect omc's output goes to a pipe nobody reads, and a
                    # chatty run -- `-d=` debug flags, say -- fills the pipe
                    # buffer and blocks omc forever.
                    omcprocess = open(pipeline(`$ompath $args1 $args2`, stdout=stdoutfile, stderr=stderrfile))
                end
            end
            portfile = join(["openmodelica.port.julia.", randPortSuffix])
        else
            if Sys.isapple()
                # add omc to path if not exist
                ENV["PATH"] = ENV["PATH"] * "/opt/openmodelica/bin"
                if !isnothing(omc )
                    omcprocess = open(pipeline(`$omc $args1 $args2`, stdout=stdoutfile, stderr=stderrfile))
                else
                    omcprocess = open(pipeline(`omc $args1 $args2`, stdout=stdoutfile, stderr=stderrfile))
                end
            else
                if !isnothing(omc )
                    omcprocess = open(pipeline(`$omc $args1 $args2`, stdout=stdoutfile, stderr=stderrfile))
                else
                    omcprocess = open(pipeline(`omc $args1 $args2`, stdout=stdoutfile, stderr=stderrfile))
                end
            end
            portfile = join(["openmodelica.", ENV["USER"], ".port.julia.", randPortSuffix])
        end
        fullpath = joinpath(tempdir(), portfile)
        @info("Path to zmq file=\"$fullpath\"")
        started = waitForPortFile(fullpath, omcprocess)
        # Catch omc error
        if process_exited(omcprocess) && omcprocess.exitcode != 0
            throw(OMCError(omcprocess.cmd, stdoutfile, stderrfile))
        end
        if !started
            # Read the logs before deleting them. Without them the error says
            # only that a file is missing, which is no help in working out why.
            # Kill omc too: no ZMQSession exists yet to carry the finalizer that
            # would reap it, so it would be left running for the rest of the
            # session, competing for the CPU the next start needs.
            details = omcStartupLog(stdoutfile, stderrfile)
            kill(omcprocess)
            rm.([stdoutfile, stderrfile], force=true)
            throw(TimeoutError("omc did not create the ZMQ server port file " *
                               "\"$(fullpath)\" within $(PORT_FILE_TIMEOUT_S) s." *
                               details))
        end
        rm.([stdoutfile, stderrfile], force=true)
        filedata = read(fullpath, String)
        context = ZMQ.Context()
        socket = ZMQ.Socket(context, REQ)
        # ZMQ lingers indefinitely by default, so closing a socket whose peer is
        # gone blocks forever -- if omc dies with a request outstanding, Julia
        # then hangs on exit in the socket finalizer. Nothing is gained by
        # waiting to flush a request omc will never read.
        socket.linger = 0
        ZMQ.connect(socket, filedata)

        zmqSession = new(context, socket, omcprocess)

        # Register finalizer to stop omc process when this OMCsession is no longer reachable
        f(zmqSession) = kill(zmqSession.omcprocess)
        finalizer(f, zmqSession)

        return zmqSession
    end
end

"""
    OMCSession <: Any

OMC session struct.

--------------

    OMCSession(omc=nothing)

Create new OpenModelica session.

## Arguments

- `omc::Union{String, Nothing}`: Path to OpenModelica compiler.
                                 Use omc from `PATH` if nothing is provided.

See also [`ModelicaSystem`](@ref), [`OMJulia.quit`](@ref).
"""
mutable struct OMCSession
    simulationFlag::Bool
    inputFlag::Bool
    simulateOptions::Dict
    overridevariables::Dict
    simoptoverride::Dict
    tempdir::AbstractString
    "Current directory"
    currentdir::AbstractString
    resultfile::AbstractString
    filepath::AbstractString
    modelname::AbstractString
    xmlfile::AbstractString
    csvfile::AbstractString
    "Filter for simulation result passed to buildModel"
    variableFilter::Union{AbstractString, Nothing}
    quantitieslist::Array{Any, 1}
    parameterlist::Dict
    inputlist::Dict
    outputlist::Dict
    "List of continuous model variables"
    continuouslist::Dict

    zmqSession::ZMQSession
    linearization::Linearization

    function OMCSession(omc::Union{String, Nothing}=nothing)::OMCSession
        this = new()
        this.overridevariables = Dict()
        this.simoptoverride = Dict()
        this.quantitieslist = Any[]
        this.parameterlist = Dict()
        this.simulateOptions = Dict()
        this.inputlist = Dict()
        this.outputlist = Dict()
        this.continuouslist = Dict()
        this.currentdir = pwd()
        this.filepath = ""
        this.modelname = ""
        this.xmlfile = ""
        this.resultfile = ""
        this.simulationFlag = false
        this.inputFlag = false
        this.csvfile = ""
        this.variableFilter = nothing
        this.tempdir = ""
        this.linearization = Linearization()
        this.zmqSession = ZMQSession(omc)

        return this
    end
end

"""
    quit(omc::OMCSession; timeout=4::Integer)

Quit OMCSession.

# Arguments
    - `omc::OMCSession`:      OMC session.

# Keywords
    - `timeout=4::Integer`:   Timeout in seconds.

See also [`OMJulia.OMCSession`](@ref).
"""
function quit(omc::OMCSession; timeout=4::Integer)

    tsk = @task sendExpression(omc, "quit()", parsed=false)
    schedule(tsk)
    Timer(timeout) do timer
        istaskdone(tsk) || Base.throwto(tsk, InterruptException())
    end
    try
        fetch(tsk)
    catch _;
        if !process_exited(omc.zmqSession.omcprocess)
            @warn "omc process did not respond to send expression \"quit()\". Killing the process"
            kill(omc.zmqSession.omcprocess)
        end
    end

    # Wait one second for process to exit, kill otherwise
    if !process_exited(omc.zmqSession.omcprocess)
        Timer(1) do timer
            if !process_exited(omc.zmqSession.omcprocess)
                @warn "omc process didn't stop after evaluating expression \"quit()\". Killing the process"
                kill(omc.zmqSession.omcprocess)
            end
        end
    end

    return
end
