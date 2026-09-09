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

"""
    ModelicaSystem(omc, fileName, modelName, library=nothing;
                   commandLineOptions=nothing, variableFilter=nothing, customBuildDirectory=nothing)

Set command line options for OMCSession and build model `modelName` to prepare for a simulation.

## Arguments

- `omc`:       OpenModelica compiler session, see `OMCSession()`.
- `fileName`:  Path to Modelica file.
- `modelName`: Name of Modelica model to build, including namespace if the
               model is wrappen within a Modelica package.
- `library`:   List of dependent libraries or Modelica files.
               This argument can be passed as string (e.g. `"Modelica"`)
               or tuple (e.g. `("Modelica", "4.0")`
               or array (e.g. ` ["Modelica", "SystemDynamics"]`
               or `[("Modelica", "4.0"), "SystemDynamics"]`).

## Keyword Arguments

- `commandLineOptions`: OpenModelica command line options, see
                        [OpenModelica Compiler Flags](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/omchelptext.html).
- `variableFilter`:     Regex to filter variables in result file.

## Usage

```
using OMJulia
mod = OMJulia.OMCSession()
ModelicaSystem(mod, "BouncingBall.mo", "BouncingBall", ["Modelica", "SystemDynamics"], commandLineOptions="-d=newInst")
```

Providing dependent libaries:

```
using OMJulia
mod = OMJulia.OMCSession()
ModelicaSystem(mod, "BouncingBall.mo", "BouncingBall", ["Modelica", "SystemDynamics", "dcmotor.mo"])
```

See also [`OMCSession()`](@ref).
"""
function ModelicaSystem(omc::OMCSession,
                        fileName::Union{AbstractString, Nothing},
                        modelName::AbstractString,
                        library::Union{<:AbstractString, Tuple{<:AbstractString, <:AbstractString}, Array{<:AbstractString}, Array{Tuple{<:AbstractString, <:AbstractString}}, Nothing} = nothing;
                        commandLineOptions::Union{<:AbstractString, Nothing} = nothing,
                        variableFilter::Union{<:AbstractString, Nothing} = nothing,
                        customBuildDirectory::Union{<:AbstractString, Nothing} = nothing)

    ## check for commandLineOptions
    setCommandLineOptions(omc, commandLineOptions)

    ## set default command Line Options for linearization as
    ## linearize() will use the simulation executable and runtime
    ## flag -l to perform linearization
    sendExpression(omc, "setCommandLineOptions(\"--linearizationDumpLanguage=julia\")")
    sendExpression(omc, "setCommandLineOptions(\"--generateSymbolicLinearization\")")

    omc.modelname = modelName
    omc.variableFilter = variableFilter

    #loadFile and set temporary directory
    if !isnothing(fileName)
        omc.filepath = fileName
        loadFile(omc, fileName)
    end

    #set temp directory for each modelica session
    setTempDirectory(omc, customBuildDirectory)

    #load Libraries provided by users
    loadLibrary(omc, library)

    # build the model
    buildModel(omc)
end


"""
    ModelicaSystem(omc; modelName, library=nothing,
                   commandLineOptions=nothing, variableFilter=nothing, customBuildDirectory=nothing)

Set command line options for OMCSession and build model `modelname` to prepare for a simulation.

## Arguments

- `omc`:       OpenModelica compiler session, see `OMCSession()`.

## Keyword Arguments

- `modelName`: Name of Modelica model to build, including namespace if the
               model is wrappen within a Modelica package.
- `library`:   List of dependent libraries or Modelica files.
               This argument can be passed as string (e.g. `"Modelica"`)
               or tuple (e.g. `("Modelica", "4.0")`
               or array (e.g. ` ["Modelica", "SystemDynamics"]`
               or `[("Modelica", "4.0"), "SystemDynamics"]`).

- `commandLineOptions`: OpenModelica command line options, see
                        [OpenModelica Compiler Flags](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/omchelptext.html).
- `variableFilter`:     Regex to filter variables in result file.

## Usage

```
using OMJulia
mod = OMJulia.OMCSession()
ModelicaSystem(mod, modelName="Modelica.Electrical.Analog.Examples.CauerLowPassAnalog", library="Modelica")
```
See also [`OMCSession()`](@ref).
"""
function ModelicaSystem(omc::OMCSession;
                        fileName::Union{AbstractString, Nothing} = nothing,
                        modelName::AbstractString,
                        library::Union{<:AbstractString,Tuple{<:AbstractString,<:AbstractString},Array{<:AbstractString},Array{Tuple{<:AbstractString,<:AbstractString}},Nothing} = nothing,
                        commandLineOptions::Union{<:AbstractString,Nothing} = nothing,
                        variableFilter::Union{<:AbstractString,Nothing} = nothing,
                        customBuildDirectory::Union{<:AbstractString,Nothing} = nothing)

    ModelicaSystem(omc, fileName, modelName, library; commandLineOptions=commandLineOptions, variableFilter=variableFilter, customBuildDirectory=customBuildDirectory)
end


function setCommandLineOptions(omc::OMCSession, commandLineOptions::Union{<:AbstractString,Nothing}=nothing)
    ## check for commandLineOptions
    if !isnothing(commandLineOptions)
        exp = join(["setCommandLineOptions(", "", "\"", commandLineOptions, "\"", ")"])
        cmdexp = sendExpression(omc, exp)
        if !cmdexp
            error(sendExpression(omc, "getErrorString()"))
        end
    end
end

function loadFile(omc::OMCSession, filename::AbstractString)
    filepath = replace(abspath(filename), r"[/\\]+" => "/")
    if isfile(filepath)
        loadmsg = sendExpression(omc, "loadFile(\"" * filepath * "\")")
        if !loadmsg
            error(sendExpression(omc, "getErrorString()"))
        end
    else
        error("\"$filename\" not found")
    end
end

function setTempDirectory(omc::OMCSession, customBuildDirectory::Union{<:AbstractString,Nothing}=nothing)
    if !isnothing(customBuildDirectory)
        if !isdir(customBuildDirectory)
            error("Directory does not exist  \"$(customBuildDirectory)\"")
        end
        omc.tempdir = replace(abspath(customBuildDirectory), r"[/\\]+" => "/")
    else
        omc.tempdir = replace(mktempdir(), r"[/\\]+" => "/")
        if !isdir(omc.tempdir)
            error("Failed to create temp directory \"$(omc.tempdir)\"")
        end
    end
    sendExpression(omc, "cd(\"" * omc.tempdir * "\")")
end

"""
    loadLibrary(omc, library)

Load libraries.
"""
function loadLibrary(omc::OMCSession, library::Union{<:AbstractString, Tuple{<:AbstractString, <:AbstractString}, Array{<:AbstractString}, Array{Tuple{<:AbstractString, <:AbstractString}}, Nothing})
    if isnothing(library)
        return
    end

    if isa(library, AbstractString)
        loadLibraryHelper(omc, library)
    # allow users to provide library version e.g. ("Modelica", "3.2.3")
    elseif isa(library, Tuple{AbstractString, AbstractString})
        if !isempty(library[2])
            loadLibraryHelper(omc, library[1], library[2])
        else
            loadLibraryHelper(omc, library[1])
        end
    elseif isa(library, Array)
        for i in library
            # allow users to provide library version e.g. ("Modelica", "3.2.3")
            if isa(i, Tuple{AbstractString, AbstractString})
                if !isempty(i[2])
                    loadLibraryHelper(omc, i[1], i[2])
                else
                    loadLibraryHelper(omc, i[1])
                end
            elseif isa(i, AbstractString)
                loadLibraryHelper(omc, i)
            else
                error("Unknown type detected in input argument library[$i]. Is of type $(typeof(i))")
            end
        end
    else
        error("Unknown type detected in input argument library[$i]. Is of type $(typeof(i))")
    end
end

"""
    loadLibraryHelper(omc, libname, version=nothing)

Load library `libname` by calling `loadFile` or `loadModel` via scripting API.
"""
function loadLibraryHelper(omc::OMCSession, libname, version=nothing)
    if isfile(libname)
        libfile = replace(abspath(libname), r"[/\\]+" => "/")
        libfilemsg = sendExpression(omc, "loadFile(\"" * libfile * "\")")
        if !libfilemsg
            error(sendExpression(omc, "getErrorString()"))
        end
    else
        if isnothing(version)
            libname = join(["loadModel(", libname, ")"])
        else
            libname = join(["loadModel(", libname, ", ", "{", "\"", version, "\"", "}", ")"])
        end
        result = sendExpression(omc, libname)
        if !result
            error(sendExpression(omc, "getErrorString()"))
        end
    end
end

"""
    buildModel(omc; variableFilter=nothing)

Build modelica model.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.

## Keyword Arguments

- `variableFilter`:     Regex to filter variables in result file.
"""
function buildModel(omc::OMCSession; variableFilter::Union{<:AbstractString, Nothing} = nothing)
    if !isnothing(variableFilter)
        omc.variableFilter = variableFilter
    end

    if !isnothing(omc.variableFilter)
        varFilter = join(["variableFilter=", "\"", omc.variableFilter, "\""])
    else
        varFilter = join(["variableFilter=\"", ".*" ,"\""])
    end

    buildmodelexpr = join(["buildModel(",omc.modelname,", ", varFilter,")"])
    @debug "buildmodelexpr: $buildmodelexpr"

    buildModelmsg = sendExpression(omc, buildmodelexpr)
    if !isempty(buildModelmsg[2])
        omc.xmlfile = replace(joinpath(omc.tempdir, buildModelmsg[2]), r"[/\\]+" => "/")
        xmlparse(omc)
    else
        error(sendExpression(omc, "getErrorString()"))
    end
end

"""
    xmlparse(omc)

This function parses the XML file generated from the buildModel()
and stores the model variable into different categories namely parameter
inputs, outputs, continuous etc..
"""
function xmlparse(omc::OMCSession)
    if isfile(omc.xmlfile)
        xdoc = parse_file(omc.xmlfile)
        # get the root element
        xroot = root(xdoc)  # an instance of XMLElement
        for c in child_nodes(xroot)  # c is an instance of XMLNode
            if is_elementnode(c)
                e = XMLElement(c)  # this makes an XMLElement instance
                if name(e) == "DefaultExperiment"
                    omc.simulateOptions["startTime"] = attribute(e, "startTime")
                    omc.simulateOptions["stopTime"] = attribute(e, "stopTime")
                    omc.simulateOptions["stepSize"] = attribute(e, "stepSize")
                    omc.simulateOptions["tolerance"] = attribute(e, "tolerance")
                    omc.simulateOptions["solver"] = attribute(e, "solver")
                end
                if name(e) == "ModelVariables"
                    for r in child_elements(e)
                        scalar = Dict()
                        scalar["name"] = attribute(r, "name")
                        scalar["changeable"] = attribute(r, "isValueChangeable")
                        scalar["description"] = attribute(r, "description")
                        scalar["variability"] = attribute(r, "variability")
                        scalar["causality"] = attribute(r, "causality")
                        scalar["alias"] = attribute(r, "alias")
                        scalar["aliasvariable"] = attribute(r, "aliasVariable")
                        subchild = child_elements(r)
                        for s in subchild
                            value = attribute(s, "start")
                            min = attribute(s, "min")
                            max = attribute(s, "max")
                            if !isnothing(value)
                                scalar["start"] = value
                            else
                                scalar["start"] = "None"
                            end
                            if !isnothing(min)
                                scalar["min"] = min
                            else
                                scalar["min"] = "None"
                            end
                            if !isnothing(max)
                                scalar["max"] = max
                            else
                                scalar["max"] = "None"
                            end
                        end
                        if !omc.linearization.linearFlag
                            if scalar["variability"] == "parameter"
                                if haskey(omc.overridevariables, scalar["name"])
                                    omc.parameterlist[scalar["name"]] = omc.overridevariables[scalar["name"]]
                                else
                                    omc.parameterlist[scalar["name"]] = scalar["start"]
                                end
                            end
                            if scalar["variability"] == "continuous"
                                omc.continuouslist[scalar["name"]] = scalar["start"]
                            end
                            if scalar["causality"] == "input"
                                omc.inputlist[scalar["name"]] = scalar["start"]
                            end
                            if scalar["causality"] == "output"
                                omc.outputlist[scalar["name"]] = scalar["start"]
                            end
                        end
                        push!(omc.quantitieslist, scalar)
                    end
                end
            end
        end
        # return quantities
    else
        println("file not generated")
        return
    end
end

"""
    getQuantities(omc, name=nothing)

Return list of all variables parsed from xml file.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing}`: Names of variables to read from xml file.
                                                                       If nothing is provided read all variables.

See also [`showQuantities`](@ref).
"""
function getQuantities(omc::OMCSession, name::Union{<:AbstractString, Array{<:AbstractString, 1}, Nothing} = nothing)
    if isnothing(name)
        return omc.quantitieslist
    elseif isa(name, AbstractString)
        return [x for x in omc.quantitieslist if x["name"] == name]
    elseif isa(name, Array)
        return [x for y in name for x in omc.quantitieslist if x["name"] == y]
    end
end

function getQuantitiesHelper(omc::OMCSession, name=nothing; verbose=true)
    for x in omc.quantitieslist
        if x["name"] == name
            return x
        end
    end
    if verbose
        @info "getQuantities() failed: \" $name \" does not exist."
    end
    return []
end

"""
    showQuantities(omc, name=nothing)

Return `DataFrame` of all variables parsed from xml file.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing}`:     Names of variables to read from xml file.
                                                                       If nothing is provided read all variables.

See also [`getQuantities`](@ref).
"""
function showQuantities(omc::OMCSession, name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing} = nothing)
    q = getQuantities(omc, name);
    # assuming that the keys of the first dictionary is representative for them all
    sym = map(Symbol, collect(keys(q[1])))
    arr = []
    for d in q
        push!(arr, Dict(zip(sym, values(d))))
    end
    return df_from_dicts(arr)
end


"""
helper function to return getQuantities as DataFrame
"""
function df_from_dicts(arr::AbstractArray; missing_value="missing")
    cols = Set{Symbol}()
    for di in arr union!(cols, keys(di)) end
    df = DataFrame()
    for col = cols
      # df[col] = [get(di, col, missing_value) for di=arr]
        df[!,col] = [get(di, col, missing_value) for di = arr]
    end
    return df
end

"""
    getParameters(omc, name=nothing)

Return parameter variables parsed from xml file.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing}`:     Names of parameters to read from xml file.
                                                                       If nothing is provided read all parameters.
"""
function getParameters(omc::OMCSession, name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing} = nothing)
    if isnothing(name)
        return omc.parameterlist
    elseif isa(name, String)
        return get(omc.parameterlist, name, 0)
    elseif isa(name, Array)
        return [get(omc.parameterlist, x, 0) for x in name]
    end
end

"""
    getSimulationOptions(omc, name=nothing)

Return SimulationOption variables parsed from xml file.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing}`:     Names of parameters to read from xml file.
                                                                       If nothing is provided read all parameters.
"""
function getSimulationOptions(omc::OMCSession, name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing} = nothing)
    if isnothing(name)
        return omc.simulateOptions
    elseif isa(name, String)
        return get(omc.simulateOptions, name, 0)
    elseif isa(name, Array)
        return [get(omc.simulateOptions, x, 0) for x in name]
    end
end

"""
    getContinuous(omc, name=nothing)

Return continuous variables parsed from xml file.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing}`:  Names of continuous variables to read from xml file.
                                                                        If nothing is provided read all continuous variables.
"""
function getContinuous(omc::OMCSession, name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing} = nothing)
    if !omc.simulationFlag
        if isnothing(name)
            return omc.continuouslist
        elseif isa(name, String)
            return get(omc.continuouslist, name, 0)
        elseif isa(name, Array)
            return [get(omc.continuouslist, x, 0) for x in name]
        end
    end
    if omc.simulationFlag
        if isnothing(name)
            for name in keys(omc.continuouslist)
                ## failing for variables with $ sign
                ## println(name)
                try
                    omc.continuouslist[name] = getSolutions(omc, name)[!, name][end]
                catch Exception
                    println(Exception)
                end
            end
            return omc.continuouslist
        elseif isa(name, String)
            if haskey(omc.continuouslist, name)
                omc.continuouslist[name] = getSolutions(omc, name)[!, name][end]
                return get(omc.continuouslist, name, 0)
            else
                error("\"$name\" is not continuous")
            end
        elseif isa(name, Array)
            continuousvaluelist = Any[]
            for x in name
                if haskey(omc.continuouslist, x)
                    omc.continuouslist[x] = getSolutions(omc, x)[!, x][end]
                    push!(continuousvaluelist, omc.continuouslist[x])
                else
                    error("\"$x\" is not continuous")
                end
            end
            return continuousvaluelist
        end
    end
end

"""
    getInputs(omc, name=nothing)

Return input variables parsed from xml file.
If input variables have no start value the returned value is `\"None\"`.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing}`:     Names of input variables to read from xml file.
                                                                       If nothing is provided read all input variables.
"""
function getInputs(omc::OMCSession, name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing} = nothing)
    if isnothing(name)
        return omc.inputlist
    elseif isa(name, String)
        return get(omc.inputlist, name, 0)
    elseif isa(name, Array)
        return [get(omc.inputlist, x, 0) for x in name]
    end
end

"""
    getInputs(omc, name=nothing)

Return output variables parsed from xml file.
If output variables have no start value the returned value is `\"None\"`.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing}`:  Names of output variables to read from xml file.
                                                                        If nothing is provided read all output variables.
"""
function getOutputs(omc::OMCSession, name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing}=nothing)
    if !omc.simulationFlag
        if isnothing(name)
            return omc.outputlist
        elseif isa(name, String)
            return get(omc.outputlist, name, 0)
        elseif isa(name, Array)
            return [get(omc.outputlist, x, 0) for x in name]
        end
    end
    if omc.simulationFlag
        if isnothing(name)
            for name in keys(omc.outputlist)
                omc.outputlist[name] = getSolutions(omc, name)[!, name][end]
            end
            return omc.outputlist
        elseif isa(name, String)
            if haskey(omc.outputlist, name)
                omc.outputlist[name] = getSolutions(omc, name)[!, name][end]
                return get(omc.outputlist, name, 0)
            else
                error("\"$name\" is not an output variable")
            end
        elseif isa(name, Array)
            valuelist = Any[]
            for x in name
                if haskey(omc.outputlist, x)
                    omc.outputlist[x] = getSolutions(omc, x)[!, x][end]
                    push!(valuelist, omc.outputlist[x])
                else
                    error("\"$x\" is not an output variable")
                end
            end
            return valuelist
        end
    end
end

"""
    simulate(omc; resultfile=nothing, simflags="", verbose=false)

Simulate modelica model.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session, see `OMCSession()`.

## Keyword Arguments

- `resultFile::Union{String, Nothing}`: Result file to write simulation results into.
- `simflags::String`:                   Simulation flags, see [Simulation Runtime Flags](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/simulationflags.html).
- `verbose::Bool`:                      [debug] Log cmd call to `log.txt` and `error.txt`.

## Examples

```julia
simulate(omc)
```

Specify result file:

```julia
simulate(omc, resultfile="tmpresult.mat")
```

Set simulation runtime flags:

```julia
simulate(omc, simflags="-noEmitEvent -override=e=0.3,g=9.3")
```
"""
function simulate(omc::OMCSession;
                  resultfile::Union{String, Nothing} = nothing,
                  simflags::String = "",
                  verbose::Bool = false)

    if isnothing(resultfile)
        r = ""
        omc.resultfile = replace(joinpath(omc.tempdir, join([omc.modelname,"_res.mat"])), r"[/\\]+" => "/")
    else
        r = join(["-r=",resultfile])
        omc.resultfile = replace(joinpath(omc.tempdir, resultfile), r"[/\\]+" => "/")
    end

    if isfile(omc.xmlfile)
        if Sys.iswindows()
            getexefile = replace(joinpath(omc.tempdir, join([omc.modelname,".exe"])), r"[/\\]+" => "/")
        else
            getexefile = replace(joinpath(omc.tempdir, omc.modelname), r"[/\\]+" => "/")
        end
        if isfile(getexefile)
            ## change to tempdir to run the simulation executable, restoring the
            ## caller's working directory even if the run throws
            cd(omc.tempdir)
            try
                if !isempty(omc.overridevariables) | !isempty(omc.simoptoverride)
                    tmpdict = merge(omc.overridevariables, omc.simoptoverride)
                    overridefile = replace(joinpath(omc.tempdir, join([omc.modelname,"_override.txt"])), r"[/\\]+" => "/")
                    file = open(overridefile, "w")
                    for k in keys(tmpdict)
                        val = join([k,"=",tmpdict[k],"\n"])
                        println(val)
                        write(file, val)
                    end
                    close(file)
                    overridevar = join(["-overrideFile=", overridefile])
                else
                    overridevar = ""
                end
                if omc.inputFlag
                    createcsvdata(omc, omc.simulateOptions["startTime"], omc.simulateOptions["stopTime"])
                    csvinput = join(["-csvInput=",omc.csvfile])
                    # run(pipeline(`$getexefile $overridevar $csvinput`,stdout="log.txt",stderr="error.txt"))
                else
                    csvinput = ""
                    # run(pipeline(`$getexefile $overridevar`,stdout="log.txt",stderr="error.txt"))
                end
                # remove empty args in cmd objects
                # `simflags` is a single string that may hold several flags; split it so
                # each reaches the executable as its own argument rather than one
                # quoted blob. See https://github.com/OpenModelica/OMJulia.jl/issues/133
                cmd = filter!(e -> e ≠ "", [getexefile, overridevar, csvinput, r])
                append!(cmd, String.(split(simflags)))
                # println(cmd)
                if Sys.iswindows()
                    installPath = sendExpression(omc, "getInstallationDirectoryPath()")
                    envPath = ENV["PATH"]
                    newPath = "$(installPath)/bin/;$(installPath)/lib/omc;$(installPath)/lib/omc/cpp;$(installPath)/lib/omc/omsicpp;$(envPath)"
                    # println("Path: $newPath")
                    withenv("PATH" => newPath) do
                        if verbose
                            run(pipeline(`$cmd`))
                        else
                            run(pipeline(`$cmd`, stdout="log.txt", stderr="error.txt"))
                        end
                    end
                else
                    if verbose
                        run(pipeline(`$cmd`))
                    else
                        run(pipeline(`$cmd`, stdout="log.txt", stderr="error.txt"))
                    end
                end
                # omc.resultfile=replace(joinpath(omc.tempdir,join([omc.modelname,"_res.mat"])),r"[/\\]+" => "/")
                omc.simulationFlag = true
            finally
                cd(omc.currentdir)
            end
        else
            error("Simulation Failed")
        end
    end
end

"""
function which converts modelica model to FMU

    convertMo2FMU(omc; version::String = "2.0", fmuType::String = "me_cs", fileNamePrefix::String = "<default>", includeResources::Bool = true)

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session, see `OMCSession()`.

## Keyword Arguments

- `version::String`: version 1.0 or 2.0
- `fmuType::String`: FMU type, me (model exchange), cs (co-simulation), me_cs (both model exchange and co-simulation)"
- `fileNamePrefix::String`: modelname will be used as default.

## Examples

```julia
convertMo2FMU(omc)
```
"""
function convertMo2FMU(omc; version::String = "2.0", fmuType::String = "me_cs", fileNamePrefix::String = "<default>", includeResources::Bool = true)

    if fileNamePrefix == "<default>"
        fileNamePrefix = omc.modelname
    end

    if length(fileNamePrefix) > 50
        ## this approach will work only for MSL or fileNamePrefix seperated with . (e.g) Modelica.Electrical.Analog.Examples.CauerLowPassAnalog
        fileNamePrefix = String(last(split(fileNamePrefix, ".")))
    end

    ## check again for the length if unable to reduce
    if length(fileNamePrefix) > 50
        error("fileNamePrefix \"$(fileNamePrefix)\" is $(length(fileNamePrefix)) characters; it must be shorter than 50.")
    end

    exp = join(["buildModelFMU(", omc.modelname, ", version=", API.modelicaString(version), ", fmuType=", API.modelicaString(fmuType), ", fileNamePrefix=", API.modelicaString(fileNamePrefix), ", includeResources=", includeResources, ")"])

    fmu = sendExpression(omc, exp)

    if !isfile(fmu)
        error("Failed to build FMU for $(omc.modelname):\n$(sendExpression(omc, "getErrorString()"))")
    end

    return fmu
end

"""
function which converts FMU to modelicamodel
"""
function convertFmu2Mo(omc::OMCSession, fmupath)
    if !isfile(fmupath)
        error("\"$(fmupath)\" does not exist")
    end

    fmupath = replace(fmupath, r"[/\\]+" => "/")

    filename = sendExpression(omc, "importFMU(\"" * fmupath * "\")")

    if !isfile(filename)
        error("Failed to import FMU \"$(fmupath)\":\n$(sendExpression(omc, "getErrorString()"))")
    end

    return filename
end

"""
Read `variables` from the current result file as plain column vectors, in the
order asked for. `sensitivity` does array arithmetic on these, which a
`DataFrame` does not support.
"""
function solutionColumns(omc::OMCSession, variables::AbstractVector{<:AbstractString})::Vector{Vector{Float64}}
    solutions = getSolutions(omc, variables)
    return [Float64.(solutions[!, variable]) for variable in variables]
end

"""
    sensitivity(omc::OMCSession, Vp, Vv, Ve=[1e-2])

Method for computing numeric sensitivity of OpenModelica object.

## Arguments

- `omc::OMCSession`:                OpenModelica compiler session.
- `Vp::Array{<:AbstractString, 1}`:   Modelica Parameter names.
- `Vv::Array{<:AbstractString, 1}`:   Modelica Variable names.
- `Ve::Array{Float64, 1}`:          Excitations of parameters; defaults to scalar 1e-2

## Return

- `VSname::Vector{Vector{String}}`:             Vector of sensitivity names
- `VSarray::Vector{Vector{Vector{Float64}}}`:   Vector of sensitivies: vector of elements per parameter
Each element containing time series per variable
"""
function sensitivity(omc::OMCSession,
                     Vp::Array{<:AbstractString, 1},
                     Vv::Array{<:AbstractString, 1},
                     Ve::Array{Float64, 1} = [1e-2])::Tuple{Vector{Vector{String}}, Vector{Vector{Vector{Float64}}}}
    ## Production quality code should check type and form of input arguments
    Ve = map(Float64, Ve) # converting eVements of excitation to floats
    nVp = length(Vp) # number of parameter names
    nVe = length(Ve) # number of excitations in parameters
    # Adjusting size of Ve to that of Vp
    if nVe < nVp
        push!(Ve, Ve[end] * ones(nVp - nVe)...) # extends Ve by adding last eVement of Ve
    elseif nVe > nVp
         Ve = Ve[1:nVp] # truncates Ve to same length as Vp
    end
    # Nominal parameters p0
    par0 = [parse(Float64, pp) for pp in getParameters(omc, Vp)]
    # eXcitation parameters parX
    parX = [par0[i] * (1 + Ve[i]) for i in 1:nVp]
    # Nominal parameter values, to restore after every excitation
    nominal = Dict(Vp[i] => par0[i] for i in 1:nVp)
    # Simulate nominal system
    simulate(omc)
    # Get nominal SOLutions of variabVes of interest (Vv), converted to 2D array
    sol0 = solutionColumns(omc, Vv)
    # Get vector of eXcited SOLutions (2D arrays), one for each parameter (Vp)
    solX = Vector{Vector{Vector{Float64}}}()
    for i in 1:nVp
         # change to excited parameter
        setParameters(omc, Dict(Vp[i] => parX[i]))
         # simulate perturbed system
        simulate(omc)
         # get eXcited SOLutions (Vv) as 2D array, and append to list
        push!(solX, solutionColumns(omc, Vv))
         # reset parameters to nominal values
        setParameters(omc, nominal)
    end
    ## Compute sensitivities and add to vector, one 2D array per parameter (Vp)
    VSname = Vector{Vector{String}}()
    VSarray = Vector{Vector{Vector{Float64}}}() # same shape as solX
    for (i, sol) in enumerate(solX)
        push!(VSarray, ((sol - sol0) / (par0[i] * Ve[i])))
        vsname = Vector{String}()
        # One name per variable of interest: Vv and Vp need not be the same
        # length, and it is Vv that indexes a row of the sensitivity array.
        for j in eachindex(Vv)
            push!(vsname, "Sensitivity." * Vp[i] * "." * Vv[j])
        end
        push!(VSname, vsname)
    end
    return VSname, VSarray
end

"""
    keyValuePairs(assignments)

Turn the `"name=value"` assignment form -- a single string or a vector of them
-- into a `Dict{String, String}`.

Only the first `=` separates name from value, so a value may contain one.
"""
function keyValuePairs(assignments::Union{<:AbstractString, AbstractVector{<:AbstractString}})::Dict{String, String}
    pairs = Dict{String, String}()
    for assignment in (assignments isa AbstractString ? (assignments,) : assignments)
        stripped = filter(!isspace, assignment)
        separator = findfirst(isequal('='), stripped)
        if isnothing(separator) || separator == firstindex(stripped)
            error("\"$assignment\" is not a \"name=value\" assignment")
        end
        pairs[stripped[1:prevind(stripped, separator)]] = stripped[nextind(stripped, separator):end]
    end
    return pairs
end

"""
Throw a helpful error if `resultfile` cannot be read.
"""
function checkResultFile(resultfile::AbstractString)
    if isempty(resultfile)
        error("Model not Simulated, Simulate the model to get the results")
    end
    if !isfile(resultfile)
        error("Result file $(abspath(resultfile)) does not exist !")
    end
    return nothing
end

"""
    getSolutionNames(omc::OMCSession; resultfile=nothing)

Return the names of the variables stored in the result file.

`time` is not part of the list: it is the independent variable, and
[`getSolutions`](@ref) always returns it. Neither are omc's internal
`\$`-prefixed names, which cannot be read back.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.

## Keyword Arguments

- `resultfile::Union{AbstractString, Nothing}`:     Path to result file. If nothing is provided use saved result file.
"""
function getSolutionNames(omc::OMCSession;
                          resultfile::Union{AbstractString, Nothing} = nothing)::Vector{String}

    resfile = isnothing(resultfile) ? omc.resultfile : resultfile
    checkResultFile(resfile)

    variables = sendExpression(omc, "readSimulationResultVars(\"" * resfile * "\")")
    sendExpression(omc, "closeSimulationResultFile()")

    # Names starting with `$` are omc bookkeeping rather than model variables,
    # and asking for one makes the read fail. `time` is the independent
    # variable, not something to ask for.
    return filter(variable -> !startswith(variable, '$') && variable != "time",
                  String.(variables))
end

"""
    solutionVariables(name, available)

Work out which columns [`getSolutions`](@ref) should read, given what the
caller asked for and what the result file holds.

`time` comes first and appears once, whatever the caller asked for; every
other name is checked against `available`. Passing `nothing` means every
variable in the file.
"""
function solutionVariables(name::Union{<:AbstractString, AbstractVector{<:AbstractString}, Nothing},
                           available::AbstractVector{<:AbstractString})::Vector{String}

    variables = if isnothing(name)
        # These came out of the result file, so there is nothing to check.
        String.(available)
    else
        requested = name isa AbstractString ? [String(name)] : String.(name)
        known = Set(available)
        for variable in requested
            if variable != "time" && !(variable in known)
                error("'$variable' not found in simulation results")
            end
        end
        requested
    end

    # Every other column is indexed by time, so time is never optional and
    # never duplicated, however the caller spelled the request.
    filter!(!isequal("time"), variables)
    unique!(variables)
    pushfirst!(variables, "time")

    return variables
end

"""
    getSolutions(omc::OMCSession, name=nothing; resultfile=nothing)

Read the result file and return the simulation results as a
`DataFrames.DataFrame`.

`time` is always the first column, whether or not it was asked for, so the
returned frame stands on its own.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.
- `name::Union{<:AbstractString, AbstractVector{<:AbstractString}, Nothing}`:  Names of variables to read from result file.
                                                                              If nothing is provided read all variables,
                                                                              parameters included, which for a large model
                                                                              is a large read.

## Keyword Arguments

- `resultfile::Union{AbstractString, Nothing}`:     Path to result file. If nothing is provided use saved result file.

See also [`getSolutionNames`](@ref) to list what a result file holds
without reading it.
"""
function getSolutions(omc::OMCSession,
                      name::Union{<:AbstractString, AbstractVector{<:AbstractString}, Nothing} = nothing;
                      resultfile::Union{AbstractString, Nothing} = nothing)::DataFrames.DataFrame

    resfile = isnothing(resultfile) ? omc.resultfile : resultfile
    variables = solutionVariables(name, getSolutionNames(omc; resultfile = resfile))

    resultvar = string("{", join(variables, ","), "}")
    simres = sendExpression(omc, "readSimulationResult(\"" * resfile * "\"," * resultvar * ")")
    sendExpression(omc, "closeSimulationResultFile()")

    if !(simres isa AbstractVector) || length(simres) != length(variables)
        error("Reading $(join(variables, ", ")) from $(abspath(resfile)) failed: $simres")
    end

    # The parser hands back Any-typed vectors; broadcasting narrows each
    # column to what it actually holds.
    return DataFrames.DataFrame([identity.(column) for column in simres], variables)
end

"""
    setParameters(omc, parameters; verbose=true)

Set parameter values for parameter variables defined by users.

## Arguments

- `omc::OMCSession`: OpenModelica compiler session.
- `parameters::AbstractDict`:  Parameter names mapped to their new values,
                               e.g. `Dict("a" => 3, "V" => 200)`.
                               Values are converted with `string`.

## Keyword Arguments

- `verbose::Bool`:     Explain why a parameter could not be changed.

An unknown parameter name is an error: a typo would otherwise simulate the
model with its default value and say nothing.
"""
function setParameters(omc::OMCSession, parameters::AbstractDict; verbose::Bool = true)
    for (name, value) in parameters
        parameter = string(name)
        newValue = string(value)
        if !haskey(omc.parameterlist, parameter)
            error("\"$parameter\" is not a parameter")
        end
        if isParameterChangeable(omc, parameter, newValue; verbose = verbose)
            omc.parameterlist[parameter] = newValue
            omc.overridevariables[parameter] = newValue
        end
    end
    return nothing
end

"""
    setParameters(omc, name; verbose=true)

Deprecated. Use the `AbstractDict` method of [`setParameters`](@ref) instead:

```julia
setParameters(omc, Dict("a" => 3, "V" => 200))
```
"""
function setParameters(omc::OMCSession,
                       name::Union{<:AbstractString, AbstractVector{<:AbstractString}};
                       verbose::Bool = true)
    Base.depwarn("`setParameters(omc, \"name=value\")` is deprecated, use `setParameters(omc, Dict(\"name\" => value))` instead.", :setParameters)
    return setParameters(omc, keyValuePairs(name); verbose = verbose)
end

"""
check for parameter modifiable or not
"""
function isParameterChangeable(omc::OMCSession, name, value; verbose=true)
    q = getQuantities(omc, String(name))
    if isempty(q)
        println(name, " does not exist in the model")
        return false
    elseif q[1]["changeable"] == "false"
        if verbose
            @warn "setParameters() failed: it is not possible to set \"$name\". It seems to be structural, final, protected or evaluated, or has a non-constant binding. Use sendExpression(setParameterValue($(omc.modelname), $name, $value), parsed=false) and rebuild the model with buildModel()."
        end
        return false
    end
    return true
end

"""
    setSimulationOptions(omc; startTime=nothing, stopTime=nothing, stepSize=nothing, tolerance=nothing, solver=nothing)

Set simulation option values. Options left at `nothing` keep their current
value.

## Arguments

- `omc::OMCSession`: OpenModelica compiler session.

## Keyword Arguments

- `startTime`:     Start time of the simulation.
- `stopTime`:      Stop time of the simulation.
- `stepSize`:      Step size of the output interval, `interval` in the
                   Modelica `experiment` annotation.
- `tolerance`:     Solver tolerance.
- `solver`:        Name of the integration method, e.g. `"dassl"`.
"""
function setSimulationOptions(omc::OMCSession;
                              startTime = nothing,
                              stopTime = nothing,
                              stepSize = nothing,
                              tolerance = nothing,
                              solver = nothing)
    options = Dict{String, Any}()
    for (option, value) in ("startTime" => startTime,
                            "stopTime" => stopTime,
                            "stepSize" => stepSize,
                            "tolerance" => tolerance,
                            "solver" => solver)
        isnothing(value) || (options[option] = value)
    end
    return setSimulationOptions(omc, options)
end

"""
    setSimulationOptions(omc, options)

Set simulation option values from a `Dict`, e.g.
`Dict("stopTime" => 2.0, "tolerance" => 1e-8)`.

## Arguments

- `omc::OMCSession`: OpenModelica compiler session.
- `options::AbstractDict`:  Option names mapped to their new values.
                            Values are converted with `string`.
"""
function setSimulationOptions(omc::OMCSession, options::AbstractDict)
    for (name, value) in options
        option = string(name)
        if !haskey(omc.simulateOptions, option)
            error("\"$option\" is not a simulation option")
        end
        omc.simulateOptions[option] = string(value)
        omc.simoptoverride[option] = string(value)
    end
    return nothing
end

"""
    setSimulationOptions(omc, name)

Deprecated. Use the keyword arguments of [`setSimulationOptions`](@ref)
instead:

```julia
setSimulationOptions(omc, stopTime = 2.0, tolerance = 1e-8)
```
"""
function setSimulationOptions(omc::OMCSession,
                              name::Union{<:AbstractString, AbstractVector{<:AbstractString}})
    Base.depwarn("`setSimulationOptions(omc, \"stopTime=2.0\")` is deprecated, use `setSimulationOptions(omc, stopTime = 2.0)` instead.", :setSimulationOptions)
    return setSimulationOptions(omc, keyValuePairs(name))
end

"""
Normalize a value handed to [`setInputs`](@ref) into what `createcsvdata`
expects: either a string holding a constant, or a vector of `[time, value]`
points.
"""
inputValue(value::Real) = string(value)

inputValue(value::AbstractVector) = [timeValuePoint(value, point) for point in value]

function inputValue(value)
    error("an input value must be a number or a vector of (time, value) points, not a $(typeof(value))")
end

"""
Turn one `(time, value)` element of a time table into `[time, value]`.

Accepts a tuple, a pair or a two-element vector; anything else is a caller
mistake worth naming, since a bare vector of numbers would otherwise be read
as a list of points that each repeat themselves.
"""
function timeValuePoint(value::AbstractVector, point)
    pair = point isa Pair ? (point.first, point.second) :
           (point isa Tuple || point isa AbstractVector) && length(point) == 2 ?
               (point[1], point[2]) : nothing
    if isnothing(pair) || !all(entry -> entry isa Real, pair)
        error("$value is not a vector of (time, value) points with numeric entries")
    end
    return Any[pair[1], pair[2]]
end

function inputValue(value::AbstractString)
    parsed = Meta.parse(value)
    parsed isa Expr || return String(value)
    if parsed.head !== :vect
        error("\"$value\" is not a constant or a vector of (time, value) points")
    end
    return [inputPoint(value, point) for point in parsed.args]
end

"""
Turn one parsed `(time, value)` element of a time table into `[time, value]`.

Only numeric literals are accepted. `createcsvdata` used to `eval` whatever
came out of `Meta.parse` here, which ran arbitrary Julia from an input string.
"""
function inputPoint(value::AbstractString, point)
    if !(point isa Expr && point.head === :tuple && length(point.args) == 2 &&
         all(arg -> arg isa Number, point.args))
        error("\"$value\" is not a vector of (time, value) points with numeric entries")
    end
    return Any[point.args[1], point.args[2]]
end

"""
    setInputs(omc, inputs)

Set new values for input variables.

## Arguments

- `omc::OMCSession`: OpenModelica compiler session.
- `inputs::AbstractDict`:  Input names mapped to their new values, e.g.
                           `Dict("cAi" => 100, "Ti" => 200)`.
                           A value may also be a vector of `(time, value)`
                           points, e.g. `Dict("cAi" => [(0, 100), (1, 50)])`,
                           to vary the input over the simulation.
"""
function setInputs(omc::OMCSession, inputs::AbstractDict)
    for (name, value) in inputs
        input = string(name)
        if !haskey(omc.inputlist, input)
            error("$input is not an input variable")
        end
        omc.inputlist[input] = inputValue(value)
        omc.inputFlag = true
    end
    return nothing
end

"""
    setInputs(omc, name)

Deprecated. Use the `AbstractDict` method of [`setInputs`](@ref) instead:

```julia
setInputs(omc, Dict("cAi" => 100))
```
"""
function setInputs(omc::OMCSession,
                   name::Union{<:AbstractString, AbstractVector{<:AbstractString}})
    Base.depwarn("`setInputs(omc, \"name=value\")` is deprecated, use `setInputs(omc, Dict(\"name\" => value))` instead.", :setInputs)
    return setInputs(omc, keyValuePairs(name))
end

"""
    getWorkDirectory(omc)

Return working directory of OMJulia.OMCsession `omc`.
"""
function getWorkDirectory(omc::OMCSession)
    return omc.tempdir
end

"""
function which creates the csvinput when user specify new values
for input variables, this function is used in context with setInputs()
"""
function createcsvdata(omc::OMCSession, startTime, stopTime)
    omc.csvfile = joinpath(omc.tempdir, join([omc.modelname,".csv"]))
    file = open(omc.csvfile, "w")
    write(file, join(["time",",",join(keys(omc.inputlist), ","),",","end","\n"]))
    csvdata = deepcopy(omc.inputlist)
    value = values(csvdata)

    time = Any[]
    for val in value
        if isa(val, Array)
            checkflag = "true"
            for v in val
                push!(time, v[1])
            end
        end
    end

    if length(time) == 0
        push!(time, startTime)
        push!(time, stopTime)
    end

    previousvalue = Dict()
    for i in sort(time)
        if isa(i, SubString{String}) || isa(i, String)
            write(file, i, ",")
        else
            write(file, join(i, ","), ",")
        end
        listcount = 1
        for val in value
            if isa(val, Array)
                newval = val
                count = 1
                found = "false"
                for v in newval
                    if i == v[1]
                        data = v[2]
                        write(file, join(data, ","), ",")
                        previousvalue[listcount] = data
                        deleteat!(newval, count)
                        found = "true"
                        break
                    end
                    count = count + 1
                end
                if found == "false"
                    write(file, join(previousvalue[listcount], ","), ",")
                end
            end

            if isa(val, String)
                if val == "None"
                    val = "0"
                else
                    val = val
                end
                write(file, val, ",")
                previousvalue[listcount] = val
            end

            if isa(val, SubString{String})
                if val == "None"
                    val = "0"
                else
                    val = val
                end
                write(file, val, ",")
                previousvalue[listcount] = val
            end
            listcount = listcount + 1
        end
        write(file, "0", "\n")
    end
    close(file)
end

"""
function which returns the linearize model of modelica model, The function returns four matrices A, B, C, D

    linearize(omc; lintime = nothing, simflags= nothing, verbose=true)

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.

## Keyword Arguments

- `lintime` : Value specifies a time where the linearization of the model should be performed
- `simflags`: Simulation flags, see [Simulation Runtime Flags](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/simulationflags.html).

## Examples of using linearize() API

```julia
linearize(omc)
```

Specify result file:

```julia
linearize(omc, lintime="0.5")
```

Set simulation runtime flags:

```julia
linearize(omc, simflags="-noEmitEvent")
```
"""
function linearize(omc::OMCSession; lintime = nothing, simflags= nothing, verbose=true)

    if isempty(omc.xmlfile)
        error("Linearization cannot be performed as the model is not build, use ModelicaSystem() to build the model first")
    end

    if isnothing(simflags)
        simflags="";
    end

    overridelinearfile = replace(joinpath(omc.tempdir, join([omc.modelname,"_override_linear.txt"])), r"[/\\]+" => "/")
    # println(overridelinearfile);

    file = open(overridelinearfile, "w")
    overridelist = false
    for k in keys(omc.overridevariables)
        val = join([k,"=",omc.overridevariables[k],"\n"])
        write(file, val)
        overridelist = true
    end

    for t in keys(omc.linearization.linearOptions)
        val = join([t,"=",omc.linearization.linearOptions[t], "\n"])
        write(file, val)
        overridelist = true
    end

    close(file)

    if overridelist
        overrideFlag = join(["-overrideFile=", overridelinearfile])
    else
        overrideFlag = "";
    end

    if omc.inputFlag
        createcsvdata(omc, omc.linearization.linearOptions["startTime"], omc.linearization.linearOptions["stopTime"])
        csvinput = join(["-csvInput=", omc.csvfile])
    else
        csvinput = "";
    end

    if isfile(omc.xmlfile)
        if Sys.iswindows()
            getexefile = replace(joinpath(omc.tempdir, join([omc.modelname,".exe"])), r"[/\\]+" => "/")
        else
            getexefile = replace(joinpath(omc.tempdir, omc.modelname), r"[/\\]+" => "/")
        end
    else
        error("\"$(omc.xmlfile)\" not found, please build the model again using ModelicaSystem()")
    end

    if !isnothing(lintime)
        linruntime = join(["-l=", lintime])
    else
        linruntime = join(["-l=", omc.linearization.linearOptions["stopTime"]])
    end

    # Split `simflags` so each flag is its own argument; see issue #133.
    finalLinearizationexe = filter!(e -> e ≠ "", [getexefile, linruntime, overrideFlag, csvinput])
    append!(finalLinearizationexe, String.(split(simflags)))
    # println(finalLinearizationexe)

    # `cd` into tempdir to run the simulation executable, and restore the
    # caller's working directory on every exit path -- the success path used to
    # `return` straight out and leave the process in a temporary directory that
    # is later removed. See https://github.com/OpenModelica/OMJulia.jl/issues/132
    cd(omc.tempdir)
    try
        if Sys.iswindows()
            installPath = sendExpression(omc, "getInstallationDirectoryPath()")
            envPath = ENV["PATH"]
            newPath = "$(installPath)/bin/;$(installPath)/lib/omc;$(installPath)/lib/omc/cpp;$(installPath)/lib/omc/omsicpp;$(envPath)"
            # println("Path: $newPath")
            withenv("PATH" => newPath) do
                if verbose
                    run(pipeline(`$finalLinearizationexe`))
                else
                    run(pipeline(`$finalLinearizationexe`, stdout="log.txt", stderr="error.txt"))
                end
            end
        else
            if verbose
                run(pipeline(`$finalLinearizationexe`))
            else
                run(pipeline(`$finalLinearizationexe`, stdout="log.txt", stderr="error.txt"))
            end
        end

        omc.linearization.linearmodelname = "linearized_model"
        omc.linearization.linearfile = joinpath(omc.tempdir, join([omc.linearization.linearmodelname,".jl"]))

        # support older openmodelica versions before OpenModelica v1.16.2 where linearize() generates "linear_modelname.mo" file
        if(!isfile(omc.linearization.linearfile))
            omc.linearization.linearmodelname = join(["linear_", omc.modelname])
            omc.linearization.linearfile = joinpath(omc.tempdir, join([omc.linearization.linearmodelname, ".jl"]))
        end

        if isfile(omc.linearization.linearfile)
            omc.linearization.linearFlag = true
            # this function is called from the generated Julia code linearized_model.jl,
            # to improve the performance by directly reading the matrices A, B, C and D from the julia code and avoid building the linearized modelica model
            include(omc.linearization.linearfile)
            ## to be evaluated at runtime, as Julia expects all functions should be known at the compilation time so efficient assembly code can be generated.
            result = invokelatest(linearized_model)
            (n, m, p, x0, u0, A, B, C, D, stateVars, inputVars, outputVars) = result
            omc.linearization.linearstates = stateVars
            omc.linearization.linearinputs = inputVars
            omc.linearization.linearoutputs = outputVars
            return [A, B, C, D]
        else
            errormsg = sendExpression(omc, "getErrorString()")
            error("\"$(omc.linearization.linearfile)\" not found \n$errormsg")
        end
    finally
        cd(omc.currentdir)
    end
end

"""
    getLinearizationOptions(omc, name=nothing)

Return linearization options.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing}`: Names of linearization options.
                                                                       If nothing is provided return all linearization options.
"""
function getLinearizationOptions(omc::OMCSession,
                                 name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing} = nothing)

    if isnothing(name)
        return omc.linearization.linearOptions
    elseif isa(name, String)
        return get(omc.linearization.linearOptions, name, 0)
    elseif isa(name, Array)
        return [get(omc.linearization.linearOptions, x, 0) for x in name]
    end
end

"""
    getLinearInputs(omc)

Return linear input variables after the model is linearized

## Arguments

- `omc::OMCSession`: OpenModelica compiler session.
"""
function getLinearInputs(omc::OMCSession)
    if omc.linearization.linearFlag
        return omc.linearization.linearinputs
    else
        error("Model is not linearized")
    end
end

"""
    getLinearOutputs(omc)

Return linear output variables after the model is linearized

## Arguments

- `omc::OMCSession`: OpenModelica compiler session.
"""
function getLinearOutputs(omc::OMCSession)
    if omc.linearization.linearFlag
        return omc.linearization.linearoutputs
    else
        println("Model is not Linearized")
    end
end

"""
    getLinearStates(omc)

Return linear state variables after the model is linearized

## Arguments

- `omc::OMCSession`: OpenModelica compiler session.
"""
function getLinearStates(omc::OMCSession)
    if omc.linearization.linearFlag
        return omc.linearization.linearstates
    else
        println("Model is not Linearized")
    end
end

"""
    setLinearizationOptions(omc; startTime=nothing, stopTime=nothing, stepSize=nothing, tolerance=nothing)

Set linearization options. Options left at `nothing` keep their current value.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.

## Keyword Arguments

- `startTime`:     Start time of the linearization.
- `stopTime`:      Stop time of the linearization.
- `stepSize`:      Step size of the output interval.
- `tolerance`:     Solver tolerance.
"""
function setLinearizationOptions(omc::OMCSession;
                                 startTime = nothing,
                                 stopTime = nothing,
                                 stepSize = nothing,
                                 tolerance = nothing)
    options = Dict{String, Any}()
    for (option, value) in ("startTime" => startTime,
                            "stopTime" => stopTime,
                            "stepSize" => stepSize,
                            "tolerance" => tolerance)
        isnothing(value) || (options[option] = value)
    end
    return setLinearizationOptions(omc, options)
end

"""
    setLinearizationOptions(omc, options)

Set linearization options from a `Dict`, e.g.
`Dict("stopTime" => 2.0, "tolerance" => 1e-6)`.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.
- `options::AbstractDict`:  Option names mapped to their new values.
                            Values are converted with `string`.
"""
function setLinearizationOptions(omc::OMCSession, options::AbstractDict)
    for (name, value) in options
        option = string(name)
        if !haskey(omc.linearization.linearOptions, option)
            error("\"$option\" is not a linearization option")
        end
        omc.linearization.linearOptions[option] = string(value)
    end
    return nothing
end

"""
    setLinearizationOptions(omc, name)

Deprecated. Use the keyword arguments of [`setLinearizationOptions`](@ref)
instead:

```julia
setLinearizationOptions(omc, stopTime = 2.0, tolerance = 1e-6)
```
"""
function setLinearizationOptions(omc::OMCSession,
                                 name::Union{<:AbstractString, AbstractVector{<:AbstractString}})
    Base.depwarn("`setLinearizationOptions(omc, \"stopTime=2.0\")` is deprecated, use `setLinearizationOptions(omc, stopTime = 2.0)` instead.", :setLinearizationOptions)
    return setLinearizationOptions(omc, keyValuePairs(name))
end
