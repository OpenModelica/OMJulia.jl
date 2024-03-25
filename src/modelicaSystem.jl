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
    varFilter

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
                    value = getSolutions(omc, name)
                    value1 = value[1]
                    omc.continuouslist[name] = value1[end]
                catch Exception
                    println(Exception)
                end
            end
            return omc.continuouslist
        elseif isa(name, String)
            if haskey(omc.continuouslist, name)
                value = getSolutions(omc, name)
                value1 = value[1]
                omc.continuouslist[name] = value1[end]
                return get(omc.continuouslist, name, 0)
            else
                error("\"$name\" is not continuous")
            end
        elseif isa(name, Array)
            continuousvaluelist = Any[]
            for x in name
                if haskey(omc.continuouslist, x)
                    value = getSolutions(omc, x)
                    value1 = value[1]
                    omc.continuouslist[x] = value1[end]
                    push!(continuousvaluelist, value1[end])
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
                value = getSolutions(omc, name)
                value1 = value[1]
                omc.outputlist[name] = value1[end]
            end
            return omc.outputlist
        elseif isa(name, String)
            if haskey(omc.outputlist, name)
                value = getSolutions(omc, name)
                value1 = value[1]
                omc.outputlist[name] = value1[end]
                return get(omc.outputlist, name, 0)
            else
                error("\"$name\" is not an output variable")
            end
        elseif isa(name, Array)
            valuelist = Any[]
            for x in name
                if haskey(omc.outputlist, x)
                    value = getSolutions(omc, x)
                    value1 = value[1]
                    omc.outputlist[x] = value1[end]
                    push!(valuelist, value1[end])
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
            ## change to tempdir
            cd(omc.tempdir)
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
            cmd = filter!(e -> e ≠ "", [getexefile,overridevar,csvinput,r,simflags])
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
        else
            error("Simulation Failed")
        end
        ## change to currentworkingdirectory
        cd(omc.currentdir)
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
        return println("length of fileNamePrefix", fileNamePrefix,   "is too long ", length(fileNamePrefix), "fileNamePrefix prefix should be less than 50 characters")
    end

    exp = join(["buildModelFMU(", omc.modelname, ", version=", API.modelicaString(version), ", fmuType=", API.modelicaString(fmuType), ", fileNamePrefix=", API.modelicaString(fileNamePrefix), ", includeResources=", includeResources, ")"])

    fmu = sendExpression(omc, exp)

    if !isfile(fmu)
        return println(sendExpression(omc, "getErrorString()"))
    end

    return fmu
end

"""
function which converts FMU to modelicamodel
"""
function convertFmu2Mo(omc::OMCSession, fmupath)
    if !isfile(fmupath)
        return println(fmupath, " does not exist")
    end

    fmupath = replace(fmupath, r"[/\\]+" => "/")

    filename = sendExpression(omc, "importFMU(\"" * fmupath * "\")")

    if !isfile(filename)
        return println(sendExpression(omc, "getErrorString()"))
    end

    return filename
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
    # Combine parameter names and parameter values into vector of strings
    Vpar0 = [Vp[i] * "=$(par0[i])" for i in 1:nVp]
    VparX = [Vp[i] * "=$(parX[i])" for i in 1:nVp]
    # Simulate nominal system
    simulate(omc)
    # Get nominal SOLutions of variabVes of interest (Vv), converted to 2D array
    sol0 = getSolutions(omc, Vv)
    # Get vector of eXcited SOLutions (2D arrays), one for each parameter (Vp)
    solX = Vector{Array{Array{Float64,1},1}}()
    for p in VparX
         # change to excited parameter
        setParameters(omc, p)
         # simulate perturbed system
        simulate(omc)
         # get eXcited SOLutions (Vv) as 2D array, and append to list
        push!(solX, getSolutions(omc, Vv))
         # reset parameters to nominal values
        setParameters(omc, Vpar0)
    end
    ## Compute sensitivities and add to vector, one 2D array per parameter (Vp)
    VSname = Vector{Vector{String}}()
    VSarray = Vector{Array{Array{Float64,1},1}}() # same shape as solX
    for (i, sol) in enumerate(solX)
        push!(VSarray, ((sol - sol0) / (par0[i] * Ve[i])))
        vsname = Vector{String}()
        for j in 1:nVp
            push!(vsname, "Sensitivity." * Vp[i] * "." * Vv[j])
        end
        push!(VSname, vsname)
    end
    return VSname, VSarray
end

"""
    getSolutions(omc::OMCSession, name=nothing; resultfile=nothing)


Read result file and return simulation results

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing}`:  Names of variables to read from result file.
                                                                        If nothing is provided read all variables.

## Keyword Arguments

- `resultfile::Union{AbstractString, Nothing}`:     Path to result file. If nothing is provided use saved result file.
"""
function getSolutions(omc::OMCSession,
                      name::Union{<:AbstractString, Array{<:AbstractString,1}, Nothing} = nothing;
                      resultfile::Union{AbstractString, Nothing} = nothing)

    if isnothing(resultfile )
        resfile = omc.resultfile
    else
        resfile = resultfile
    end

    # Error handling
    if !isfile(resfile)
        error("Result file $(abspath(resfile)) does not exist !")
    end
    if isempty(resfile)
        error("Model not Simulated, Simulate the model to get the results")
    end

    # Read variables
    simresultvars = sendExpression(omc, "readSimulationResultVars(\"" * resfile * "\")")
    sendExpression(omc, "closeSimulationResultFile()")
    if isnothing(name)
        return simresultvars
    elseif isa(name, String)
        if !(name in simresultvars) && name != "time"
            error("'$name' not found in simulation results")
        end
        resultvar = join(["{",name,"}"])
        simres = sendExpression(omc, "readSimulationResult(\"" * resfile * "\"," * resultvar * ")")
        sendExpression(omc, "closeSimulationResultFile()")
        return simres
    elseif isa(name, Array)
        for var in name
            if !(var in simresultvars) && var != "time"
                error("'$name' not found in simulation results")
            end
        end
        resultvar = join(["{",join(name, ","),"}"])
        # println(resultvar)
        simres = sendExpression(omc, "readSimulationResult(\"" * resfile * "\"," * resultvar * ")")
        sendExpression(omc, "closeSimulationResultFile()")
        return simres
    end
end

"""
    setParameters(omc, name; verbose=true)

Set parameter values for parameter variables defined by users

## Arguments

- `omc::OMCSession`: OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}}`:  String \"Name=value\" or
                                                               vector of strings [\"Name1=value1\",\"Name2=value2\",\"Name3=value3\"])

## Keyword Arguments

- `verbose::Bool`:     Display additional info if setParameters failed.
"""
function setParameters(omc::OMCSession,
                       name::Union{<:AbstractString, Array{<:AbstractString,1}};
                       verbose::Bool = true)

    if isa(name, String)
        name = strip_space(name)
        value = split(name, "=")
        # setxmlfileexpr="setInitXmlStartValue(\""* this.xmlfile * "\",\""* value[1]* "\",\""*value[2]*"\",\""*this.xmlfile*"\")"
        # println(haskey(this.parameterlist, value[1]))
        if haskey(omc.parameterlist, value[1])
            # should we use this ???
            # setparameterValue = join(["setParameterValue(",omc.modelname,",", value[1],",",value[2],")"])
            # println(setparameterValue)
            if isParameterChangeable(omc, value[1], value[2])
                omc.parameterlist[value[1]] = value[2]
                omc.overridevariables[value[1]] = value[2]
            end
        else
            if verbose
                @info("setParameters() failed: \" $(value[1])\" is not a parameter")
            end
        end
    # omc.sendExpression(setxmlfileexpr)
    elseif isa(name, Array)
        name = strip_space(name)
        for var in name
            value = split(var, "=")
            if haskey(omc.parameterlist, value[1])
                if isParameterChangeable(omc, value[1], value[2])
                    omc.parameterlist[value[1]] = value[2]
                    omc.overridevariables[value[1]] = value[2]
                end
            else
                if verbose
                    @info("setParameters() failed: \" $(value[1])\" is not a parameter")
                end
            end
        end
    end
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
            println("| info |  setParameters() failed : It is not possible to set the following signal ", "\"", name, "\"", ", It seems to be structural, final, protected or evaluated or has a non-constant binding, use sendExpression(setParameterValue(", omc.modelname, ", ", name, ", ", value, "), parsed=false)", " and rebuild the model using buildModel() API")
        end
        return false
    end
    return true
end

"""
    setSimulationOptions(omc, name)

Set simulation option values like `stopTime` or `stepSize`.

## Arguments

- `omc::OMCSession`: OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}}`:  String \"Name=value\" or
                                                               vector of strings [\"Name1=value1\",\"Name2=value2\",\"Name3=value3\"])
"""
function setSimulationOptions(omc::OMCSession, name::Union{<:AbstractString, Array{<:AbstractString,1}})
    if isa(name, String)
        name = strip_space(name)
        value = split(name, "=")
        if haskey(omc.simulateOptions, value[1])
            omc.simulateOptions[value[1]] = value[2]
            omc.simoptoverride[value[1]] = value[2]
        else
            error("\"$(value[1])\" is not a simulation option")
        end
    elseif isa(name, Array)
        name = strip_space(name)
        for var in name
            value = split(var, "=")
            if haskey(omc.simulateOptions, value[1])
                omc.simulateOptions[value[1]] = value[2]
                omc.simoptoverride[value[1]] = value[2]
            else
                error("\"$(value[1])\" is not a simulation option")
            end
        end
    end
end

"""
    setInputs(omc, name)

Set new values for input variables.

## Arguments

- `omc::OMCSession`: OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}}`:  String \"Name=value\" or
                                                               vector of strings [\"Name1=value1\",\"Name2=value2\",\"Name3=value3\"])
"""
function setInputs(omc::OMCSession, name)
    if isa(name, String)
        name = strip_space(name)
        value = split(name, "=")
        if haskey(omc.inputlist, value[1])
            newval = Meta.parse(value[2])
            if isa(newval, Expr)
                omc.inputlist[value[1]] = [v.args for v in newval.args]
            else
                omc.inputlist[value[1]] = value[2]
            end
            omc.inputFlag = true
        else
            error("$(value[1]) is not an input variable")
        end
    elseif isa(name, Array)
        name = strip_space(name)
        for var in name
            value = split(var, "=")
            if haskey(omc.inputlist, value[1])
                newval = Meta.parse(value[2])
                if isa(newval, Expr)
                    omc.inputlist[value[1]] = [v.args for v in newval.args]
                else
                    omc.inputlist[value[1]] = value[2]
                end
                # omc.overridevariables[value[1]]=value[2]
                omc.inputFlag = true
            else
                error("$(value[1]) is not an input variable")
            end
        end
    end
end

function strip_space(name)
    if isa(name, String)
        return filter(x -> !isspace(x), name)
    elseif isa(name, Array)
        return [filter(x -> !isspace(x), s) for s in name]
    end
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
                        data = eval(v[2])
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

    finalLinearizationexe = filter!(e -> e ≠ "", [getexefile, linruntime, overrideFlag, csvinput, simflags])
    # println(finalLinearizationexe)

    cd(omc.tempdir)
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
        cd(omc.currentdir)
        error("\"$(omc.linearization.linearfile)\" not found \n$errormsg")
    end
    cd(omc.currentdir)
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
    setLinearizationOptions(omc, name)

Set linearization options.

## Arguments

- `omc::OMCSession`:        OpenModelica compiler session.
- `name::Union{<:AbstractString, Array{<:AbstractString,1}}`:  String \"Name=value\" or
                                                               vector of strings [\"Name1=value1\",\"Name2=value2\",\"Name3=value3\"])

"""
function setLinearizationOptions(omc::OMCSession, name)
    if isa(name, String)
        name = strip_space(name)
        value = split(name, "=")
        if haskey(omc.linearization.linearOptions, value[1])
            omc.linearization.linearOptions[value[1]] = value[2]
        else
            error("\"$(value[1])\" is not a linearization option")
        end
    elseif isa(name, Array)
        name = strip_space(name)
        for var in name
            value = split(var, "=")
            if haskey(omc.linearization.linearOptions, value[1])
                omc.linearization.linearOptions[value[1]] = value[2]
            else
                error("\"$(value[1])\" is not a linearization option")
            end
        end
    end
end
