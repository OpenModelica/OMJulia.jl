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
        randPortSuffix = Random.randstring(10)
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
                    omcprocess = open(pipeline(`$ompath $args1 $args2`))
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
        ## Try to find better approach if possible, as sleep does not work properly across different platform
        tries = 0
        while tries < 100 && !isfile(fullpath)
            sleep(0.02)
            tries += 1
        end
        # Catch omc error
        if process_exited(omcprocess) && omcprocess.exitcode != 0
            throw(OMCError(omcprocess.cmd, stdoutfile, stderrfile))
        end
        rm.([stdoutfile, stderrfile], force=true)
        if tries >= 100
            throw(TimeoutError("ZMQ server port file \"$fullpath\" not created yet."))
        end
        filedata = read(fullpath, String)
        context = ZMQ.Context()
        socket = ZMQ.Socket(context, REQ)
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
