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
    OMCSession(omc=nothing)

Create new OpenModelica session.

## Arguments

- `omc`: "Path to OpenModelica compiler"

See also [`ModelicaSystem`](@ref).
"""
mutable struct OMCSession
    simulationFlag
    inputFlag
    simulateOptions
    overridevariables
    simoptoverride
    tempdir
    currentdir
    resultfile
    filepath
    modelname
    xmlfile
    csvfile
    variableFilter
    quantitieslist
    parameterlist
    inputlist
    outputlist
    continuouslist
    linearOptions
    linearfile
    linearFlag
    linearmodelname
    linearinputs
    linearoutputs
    linearstates
    linearquantitylist
    context
    socket
    omcprocess
    function OMCSession(omc=nothing)
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
        this.variableFilter = ""
        this.tempdir = ""
        this.linearfile = ""
        this.linearFlag = false
        this.linearmodelname = ""
        this.linearOptions = Dict("startTime" => "0.0", "stopTime" => "1.0", "stepSize" => "0.002", "tolerance" => "1e-6")
        args1 = "--interactive=zmq"
        randPortSuffix = Random.randstring(10)
        args2 = "-z=julia.$(randPortSuffix)"

        stdoutfile = "stdout-$(randPortSuffix).log"
        stderrfile = "stderr-$(randPortSuffix).log"

        if (Sys.iswindows())
            if (omc !== nothing)
                ompath = replace(omc, r"[/\\]+" => "/")
                dirpath = dirname(dirname(omc))
                ## create a omc process with OPENMODELICAHOME set to custom directory
                @info("Setting environment variable OPENMODELICAHOME=\"$dirpath\" for this session.")
                withenv("OPENMODELICAHOME" => dirpath) do
                    this.omcprocess = open(pipeline(`$omc $args1 $args2`, stdout=stdoutfile, stderr=stderrfile))
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
                    this.omcprocess = open(pipeline(`$ompath $args1 $args2`))
                end
            end
            portfile = join(["openmodelica.port.julia.", randPortSuffix])
        else
            if (Sys.isapple())
                # add omc to path if not exist
                ENV["PATH"] = ENV["PATH"] * "/opt/openmodelica/bin"
                if (omc !== nothing)
                    this.omcprocess = open(pipeline(`$omc $args1 $args2`, stdout=stdoutfile, stderr=stderrfile))
                else
                    this.omcprocess = open(pipeline(`omc $args1 $args2`, stdout=stdoutfile, stderr=stderrfile))
                end
            else
                if (omc !== nothing)
                    this.omcprocess = open(pipeline(`$omc $args1 $args2`, stdout=stdoutfile, stderr=stderrfile))
                else
                    this.omcprocess = open(pipeline(`omc $args1 $args2`, stdout=stdoutfile, stderr=stderrfile))
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
        if process_exited(this.omcprocess) && this.omcprocess.exitcode != 0
            throw(OMCError(this.omcprocess.cmd, stdoutfile, stderrfile))
        end
        rm.([stdoutfile, stderrfile], force=true)
        if tries >= 100
            throw(TimeoutError("ZMQ server port file \"$fullpath\" not created yet."))
        end
        filedata = read(fullpath, String)
        this.context = ZMQ.Context()
        this.socket = ZMQ.Socket(this.context, REQ)
        ZMQ.connect(this.socket, filedata)
        return this
    end
end
