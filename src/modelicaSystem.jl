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
    ModelicaSystem(omc, filename, modelname, library=nothing;
                   commandLineOptions=nothing, variableFilter=nothing)

Set command line options for OMCSession and build model `modelname` to prepare for a simulation.

## Arguments

- `omc`:       OpenModelica compiler session, see `OMCSession()`.
- `filename`:  Path to Modelica file.
- `modelname`: Name of Modelica model to build, including namespace if the
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
                        filename::AbstractString,
                        modelname::AbstractString,
                        library::Union{AbstractString, Tuple{AbstractString, AbstractString}, Array{AbstractString}, Array{Tuple{AbstractString, AbstractString}}, Nothing} = nothing;
                        commandLineOptions::Union{AbstractString, Nothing} = nothing,
                        variableFilter::Union{AbstractString, Nothing} = nothing)

    ## check for commandLineOptions
    if (commandLineOptions !== nothing)
        exp = join(["setCommandLineOptions(","","\"",commandLineOptions,"\"" ,")"])
        cmdexp = sendExpression(omc, exp)
        if (!cmdexp)
            return println(sendExpression(omc, "getErrorString()"))
        end
    end

    ## set default command Line Options for linearization as
    ## linearize() will use the simulation executable and runtime
    ## flag -l to perform linearization
    sendExpression(omc, "setCommandLineOptions(\"--linearizationDumpLanguage=julia\")")
    sendExpression(omc, "setCommandLineOptions(\"--generateSymbolicLinearization\")")

    omc.filepath = filename
    omc.modelname = modelname
    omc.variableFilter = variableFilter
    filepath = replace(abspath(filename), r"[/\\]+" => "/")
    if (isfile(filepath))
        loadmsg = sendExpression(omc, "loadFile(\"" * filepath * "\")")
        if (!loadmsg)
            return println(sendExpression(omc, "getErrorString()"))
        end
    else
        return println(filename, "! NotFound")
    end
    omc.tempdir = replace(mktempdir(), r"[/\\]+" => "/")
    if (!isdir(omc.tempdir))
        return println(omc.tempdir, " cannot be created")
    end
    sendExpression(omc, "cd(\"" * omc.tempdir * "\")")
    # load Libraries provided by users
    if (library !== nothing)
        if (isa(library, AbstractString))
            loadLibraryHelper(omc, library)
        # allow users to provide library version e.g. ("Modelica", "3.2.3")
        elseif (isa(library, Tuple{AbstractString, AbstractString}))
            if (!isempty(library[2]))
                loadLibraryHelper(omc, library[1], library[2])
            else
                loadLibraryHelper(omc, library[1])
            end
        elseif (isa(library, Array))
            for i in library
                # allow users to provide library version e.g. ("Modelica", "3.2.3")
                if isa(i, Tuple{AbstractString, AbstractString})
                    if (!isempty(i[2]))
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
    buildModel(omc)
end

function loadLibraryHelper(omc, libname, version=nothing)
    if (isfile(libname))
        libfile = replace(abspath(libname), r"[/\\]+" => "/")
        libfilemsg = sendExpression(omc, "loadFile(\"" * libfile * "\")")
        if (!libfilemsg)
            return println(sendExpression(omc, "getErrorString()"))
        end
    else
        if version === nothing
            libname = join(["loadModel(", libname, ")"])
        else
            libname = join(["loadModel(", libname, ", ", "{", "\"", version, "\"", "}", ")"])
        end
        #println(libname)
        result = sendExpression(omc, libname)
        if (!result)
            return println(sendExpression(omc, "getErrorString()"))
        end
    end
end


"""
Standard buildModel API which builds the modelica model

    buildModel(omc; variableFilter=nothing)

## Keyword Arguments

- `variableFilter`:     Regex to filter variables in result file.
"""
function buildModel(omc; variableFilter=nothing)
    if (variableFilter !== nothing)
        omc.variableFilter = variableFilter
    end
    # println(omc.variableFilter)

    if (omc.variableFilter !== nothing)
        varFilter = join(["variableFilter=", "\"", omc.variableFilter, "\""])
    else
        varFilter = join(["variableFilter=\"", ".*" ,"\""])
    end
    # println(varFilter)

    buildmodelexpr = join(["buildModel(",omc.modelname,", ", varFilter,")"])
    # println(buildmodelexpr)

    buildModelmsg = sendExpression(omc, buildmodelexpr)
    # parsebuilexp=Meta.parse(buildModelmsg)
    if (!isempty(buildModelmsg[2]))
        omc.xmlfile = replace(joinpath(omc.tempdir, buildModelmsg[2]), r"[/\\]+" => "/")
        xmlparse(omc)
    else
        return println(sendExpression(omc, "getErrorString()"))
    end
end

"""
This function parses the XML file generated from the buildModel()
and stores the model variable into different categories namely parameter
inputs, outputs, continuous etc..
"""
function xmlparse(omc)
    if (isfile(omc.xmlfile))
        xdoc = parse_file(omc.xmlfile)
        # get the root element
        xroot = root(xdoc)  # an instance of XMLElement
        for c in child_nodes(xroot)  # c is an instance of XMLNode
            if is_elementnode(c)
                e = XMLElement(c)  # this makes an XMLElement instance
                if (name(e) == "DefaultExperiment")
                    omc.simulateOptions["startTime"] = attribute(e, "startTime")
                    omc.simulateOptions["stopTime"] = attribute(e, "stopTime")
                    omc.simulateOptions["stepSize"] = attribute(e, "stepSize")
                    omc.simulateOptions["tolerance"] = attribute(e, "tolerance")
                    omc.simulateOptions["solver"] = attribute(e, "solver")
                end
                if (name(e) == "ModelVariables")
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
                            if (value !== nothing)
                                scalar["start"] = value
                            else
                                scalar["start"] = "None"
                            end
                            if (min !== nothing)
                                scalar["min"] = min
                            else
                                scalar["min"] = "None"
                            end
                            if (max !== nothing)
                                scalar["max"] = max
                            else
                                scalar["max"] = "None"
                            end
                        end
                        if (omc.linearFlag == false)
                            if (scalar["variability"] == "parameter")
                                if haskey(omc.overridevariables, scalar["name"])
                                    omc.parameterlist[scalar["name"]] = omc.overridevariables[scalar["name"]]
                                else
                                    omc.parameterlist[scalar["name"]] = scalar["start"]
                                end
                            end
                            if (scalar["variability"] == "continuous")
                                omc.continuouslist[scalar["name"]] = scalar["start"]
                            end
                            if (scalar["causality"] == "input")
                                omc.inputlist[scalar["name"]] = scalar["start"]
                            end
                            if (scalar["causality"] == "output")
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
standard getXXX() API
function which return list of all variables parsed from xml file
"""
function getQuantities(omc, name=nothing)
    if (name === nothing)
        return omc.quantitieslist
    elseif (isa(name, String))
        return [x for x in omc.quantitieslist if x["name"] == name]
    elseif (isa(name, Array))
        return [x for y in name for x in omc.quantitieslist if x["name"] == y]
    end
end

function getQuantitiesHelper(omc, name=nothing; verbose=true)
    for x in omc.quantitieslist
        if (x["name"] == name)
            return x
        end
    end
    if verbose
        println("| info | getQuantities() failed: ", "\"", name, "\"", " does not exist")
    end
    return []
end

"""
standard getXXX() API
function same as getQuantities(), but returns all the variables as table
"""
function showQuantities(omc, name=nothing)
    q = getQuantities(omc, name);
    # assuming that the keys of the first dictionary is representative for them all
    sym = map(Symbol, collect(keys(q[1])))
    arr = []
    for d in q
        push!(arr, Dict(zip(sym, values(d))))
    end
    return df_from_dicts(arr)
end


## helper function to return getQuantities as table
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
standard getXXX() API
function which returns the parameter variables parsed from xmlfile
"""
function getParameters(omc, name=nothing)
    if (name === nothing)
        return omc.parameterlist
    elseif (isa(name, String))
        return get(omc.parameterlist, name, 0)
    elseif (isa(name, Array))
        return [get(omc.parameterlist, x, 0) for x in name]
    end
end

"""
standard getXXX() API
function which returns the SimulationOption variables parsed from xmlfile
"""
function getSimulationOptions(omc, name=nothing)
    if (name === nothing)
        return omc.simulateOptions
    elseif (isa(name, String))
        return get(omc.simulateOptions, name, 0)
    elseif (isa(name, Array))
        return [get(omc.simulateOptions, x, 0) for x in name]
    end
end

"""
standard getXXX() API
function which returns the continuous variables parsed from xmlfile
"""
function getContinuous(omc, name=nothing)
    if (omc.simulationFlag == false)
        if (name === nothing)
            return omc.continuouslist
        elseif (isa(name, String))
            return get(omc.continuouslist, name, 0)
        elseif (isa(name, Array))
            return [get(omc.continuouslist, x, 0) for x in name]
        end
    end
    if (omc.simulationFlag == true)
        if (name === nothing)
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
        elseif (isa(name, String))
            if (haskey(omc.continuouslist, name))
                value = getSolutions(omc, name)
                value1 = value[1]
                omc.continuouslist[name] = value1[end]
                return get(omc.continuouslist, name, 0)
            else
                return println(name, "  is not continuous")
            end
        elseif (isa(name, Array))
            continuousvaluelist = Any[]
            for x in name
                if (haskey(omc.continuouslist, x))
                    value = getSolutions(omc, x)
                    value1 = value[1]
                    omc.continuouslist[x] = value1[end]
                    push!(continuousvaluelist, value1[end])
                else
                    return println(x, "  is not continuous")
                end
            end
            return continuousvaluelist
        end
    end
end

"""
standard getXXX() API
function which returns the input variables parsed from xmlfile
"""
function getInputs(omc, name=nothing)
    if (name === nothing)
        return omc.inputlist
    elseif (isa(name, String))
        return get(omc.inputlist, name, 0)
    elseif (isa(name, Array))
        return [get(omc.inputlist, x, 0) for x in name]
    end
end

"""
standard getXXX() API
function which returns the output variables parsed from xmlfile
"""
function getOutputs(omc, name=nothing)
    if (omc.simulationFlag == false)
        if (name === nothing)
            return omc.outputlist
        elseif (isa(name, String))
            return get(omc.outputlist, name, 0)
        elseif (isa(name, Array))
            return [get(omc.outputlist, x, 0) for x in name]
        end
    end
    if (omc.simulationFlag == true)
        if (name === nothing)
            for name in keys(omc.outputlist)
                value = getSolutions(omc, name)
                value1 = value[1]
                omc.outputlist[name] = value1[end]
            end
            return omc.outputlist
        elseif (isa(name, String))
            if (haskey(omc.outputlist, name))
                value = getSolutions(omc, name)
                value1 = value[1]
                omc.outputlist[name] = value1[end]
                return get(omc.outputlist, name, 0)
            else
                return println(name, "is not Output")
            end
        elseif (isa(name, Array))
            valuelist = Any[]
            for x in name
                if (haskey(omc.outputlist, x))
                    value = getSolutions(omc, x)
                    value1 = value[1]
                    omc.outputlist[x] = value1[end]
                    push!(valuelist, value1[end])
                else
                    return println(x, "is not Output")
                end
            end
            return valuelist
        end
    end
end

"""
    simulate(omc; resultfile=nothing, simflags=nothing, verbose=true)

Simulate modelica model.

## Arguments

- `omc`:        OpenModelica compiler session, see `OMCSession()`.

## Keyword Arguments

- `resultFile`: Result file to write simulation results into.
- `simflags`:   Simulation flags, see [Simulation Runtime Flags](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/simulationflags.html).

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
function simulate(omc; resultfile=nothing, simflags=nothing, verbose=true)
    # println(this.xmlfile)
    if (resultfile === nothing)
        r = ""
        omc.resultfile = replace(joinpath(omc.tempdir, join([omc.modelname,"_res.mat"])), r"[/\\]+" => "/")
    else
        r = join(["-r=",resultfile])
        omc.resultfile = replace(joinpath(omc.tempdir, resultfile), r"[/\\]+" => "/")
    end

    if (simflags === nothing)
        simflags = ""
    end

    if (isfile(omc.xmlfile))
        if (Sys.iswindows())
            getexefile = replace(joinpath(omc.tempdir, join([omc.modelname,".exe"])), r"[/\\]+" => "/")
        else
            getexefile = replace(joinpath(omc.tempdir, omc.modelname), r"[/\\]+" => "/")
        end
        if (isfile(getexefile))
            ## change to tempdir
            cd(omc.tempdir)
            if (!isempty(omc.overridevariables) | !isempty(omc.simoptoverride))
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
            if (omc.inputFlag == true)
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
            if (Sys.iswindows())
                installPath = sendExpression(omc, "getInstallationDirectoryPath()")
                envPath = ENV["PATH"]
                newPath = "$(envPath);$(installPath)/bin/;$(installPath)/lib/omc;$(installPath)/lib/omc/cpp;$(installPath)/lib/omc/omsicpp"
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
            return println("! Simulation Failed")
        end
        ## change to currentworkingdirectory
        cd(omc.currentdir)
    end
end

"""
function which converts modelicamodel to FMU
"""
function convertMo2FMU(omc)
    if (!isempty(omc.modelname))
        fmuexpression = join(["translateModelFMU(",omc.modelname,")"])
        sendExpression(omc, fmuexpression)
    else
        println(sendExpression(omc, "getErrorString()"))
    end
end

"""
function which converts FMU to modelicamodel
"""
function convertFmu2Mo(omc, fmupath)
    fmupath = replace(abspath(fmupath), r"[/\\]+" => "/")
    if (isfile(fmupath))
        result = sendExpression(omc, "importFMU(\"" * fmupath * "\")")
        return joinpath(omc.tempdir, result)
    else
        println(fmupath, " ! Fmu not Found")
    end
end

"""
Method for computing numeric sensitivity of OpenModelica object

   Arguments:
   ----------
   1st arg: Vp  # Array of strings of Modelica Parameter names
   2nd arg: Vv  # Array of strings of Modelica Variable names
   3rd arg: Ve  # Array of float Excitations of parameters; defaults to scalar 1e-2

   Returns:
   --------
   1st return: VSname # Vector of Sensitivity names
   2nd return: Sarray # Array of sensitivies: vector of elements per parameter,
   each element containing time series per variable
"""
function sensitivity(omc, Vp, Vv, Ve=[1e-2])
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
standard getXXX() API
Function which reads the result file and return the simulation results to user
which can be used for plotting or further anlaysis
"""
function getSolutions(omc, name=nothing; resultfile=nothing)
    if (resultfile === nothing)
        resfile = omc.resultfile
    else
        resfile = resultfile
    end
    if (!isfile(resfile))
        println("ResultFile does not exist !", abspath(resfile))
        return
    end
    if (!isempty(resfile))
        simresultvars = sendExpression(omc, "readSimulationResultVars(\"" * resfile * "\")")
        sendExpression(omc, "closeSimulationResultFile()")
        if (name === nothing)
            return simresultvars
        elseif (isa(name, String))
            if (!(name in simresultvars) && name != "time")
                println(name, " does not exist\n")
                return
            end
            resultvar = join(["{",name,"}"])
            simres = sendExpression(omc, "readSimulationResult(\"" * resfile * "\"," * resultvar * ")")
            sendExpression(omc, "closeSimulationResultFile()")
            return simres
        elseif (isa(name, Array))
            for var in name
                if (!(var in simresultvars) && var != "time")
                    println(var, " does not exist\n")
                    return
                end
            end
            resultvar = join(["{",join(name, ","),"}"])
            # println(resultvar)
            simres = sendExpression(omc, "readSimulationResult(\"" * resfile * "\"," * resultvar * ")")
            sendExpression(omc, "closeSimulationResultFile()")
            return simres
        end
    else
        return println("Model not Simulated, Simulate the model to get the results")
    end
end

"""
standard setXXX() API
function which sets new Parameter values for parameter variables defined by users
"""
function setParameters(omc, name;verbose=true)
    if (isa(name, String))
        name = strip_space(name)
        value = split(name, "=")
        # setxmlfileexpr="setInitXmlStartValue(\""* this.xmlfile * "\",\""* value[1]* "\",\""*value[2]*"\",\""*this.xmlfile*"\")"
        # println(haskey(this.parameterlist, value[1]))
        if (haskey(omc.parameterlist, value[1]))
            # should we use this ???
            # setparameterValue = join(["setParameterValue(",omc.modelname,",", value[1],",",value[2],")"])
            # println(setparameterValue)
            if (isParameterChangeable(omc, value[1], value[2]))
                omc.parameterlist[value[1]] = value[2]
                omc.overridevariables[value[1]] = value[2]
            end
        else
            if verbose
                println("| info |  setParameters() failed: ", "\"", value[1], "\"", " is not a parameter")
            end
        end
    # omc.sendExpression(setxmlfileexpr)
    elseif (isa(name, Array))
        name = strip_space(name)
        for var in name
            value = split(var, "=")
            if (haskey(omc.parameterlist, value[1]))
                if (isParameterChangeable(omc, value[1], value[2]))
                    omc.parameterlist[value[1]] = value[2]
                    omc.overridevariables[value[1]] = value[2]
                end
            else
                if verbose
                    println("| info |  setParameters() failed: ", "\"", value[1], "\"", " is not a parameter")
                end
            end
        end
    end
end

"""
check for parameter modifiable or not
"""
function isParameterChangeable(omc, name, value; verbose=true)
    q = getQuantities(omc, String(name))
    if (isempty(q))
        println(name, " does not exist in the model")
        return false
    elseif (q[1]["changeable"] == "false")
        if verbose
            println("| info |  setParameters() failed : It is not possible to set the following signal ", "\"", name, "\"", ", It seems to be structural, final, protected or evaluated or has a non-constant binding, use sendExpression(setParameterValue(", omc.modelname, ", ", name, ", ", value, "), parsed=false)", " and rebuild the model using buildModel() API")
        end
        return false
    end
    return true
end

"""
standard setXXX() API
function which sets new Simulation Options values defined by users
"""
function setSimulationOptions(omc, name)
    if (isa(name, String))
        name = strip_space(name)
        value = split(name, "=")
        if (haskey(omc.simulateOptions, value[1]))
            omc.simulateOptions[value[1]] = value[2]
            omc.simoptoverride[value[1]] = value[2]
        else
            return println(value[1], "  is not a SimulationOption")
        end
    elseif (isa(name, Array))
        name = strip_space(name)
        for var in name
            value = split(var, "=")
            if (haskey(omc.simulateOptions, value[1]))
                omc.simulateOptions[value[1]] = value[2]
                omc.simoptoverride[value[1]] = value[2]
            else
                return println(value[1], "  is not a SimulationOption")
            end
        end
    end
end

"""
standard setXXX() API
function which sets new input values for input variables defined by users
"""
function setInputs(omc, name)
    if (isa(name, String))
        name = strip_space(name)
        value = split(name, "=")
        if (haskey(omc.inputlist, value[1]))
            newval = Meta.parse(value[2])
            if (isa(newval, Expr))
                omc.inputlist[value[1]] = [v.args for v in newval.args]
            else
                omc.inputlist[value[1]] = value[2]
            end
            omc.inputFlag = true
        else
            return println(value[1], "  is not a Input")
        end
    elseif (isa(name, Array))
        name = strip_space(name)
        for var in name
            value = split(var, "=")
            if (haskey(omc.inputlist, value[1]))
                newval = Meta.parse(value[2])
                if (isa(newval, Expr))
                    omc.inputlist[value[1]] = [v.args for v in newval.args]
                else
                    omc.inputlist[value[1]] = value[2]
                end
                # omc.overridevariables[value[1]]=value[2]
                omc.inputFlag = true
            else
                return println(value[1], "  is not a Input")
            end
        end
    end
end

function strip_space(name)
    if (isa(name, String))
        return filter(x -> !isspace(x), name)
    elseif (isa(name, Array))
        return [filter(x -> !isspace(x), s) for s in name]
    end
end

"""
Function which returns the working directory of current OMJulia Session
for each session a temporary directory is created and the simulation results
are generated
"""
function getWorkDirectory(omc)
    return omc.tempdir
end

"""
function which creates the csvinput when user specify new values
for input variables, this function is used in context with setInputs()
"""
function createcsvdata(omc, startTime, stopTime)
    omc.csvfile = joinpath(omc.tempdir, join([omc.modelname,".csv"]))
    file = open(omc.csvfile, "w")
    write(file, join(["time",",",join(keys(omc.inputlist), ","),",","end","\n"]))
    csvdata = deepcopy(omc.inputlist)
    value = values(csvdata)

    time = Any[]
    for val in value
        if (isa(val, Array))
            checkflag = "true"
            for v in val
                push!(time, v[1])
            end
        end
    end

    if (length(time) == 0)
        push!(time, startTime)
        push!(time, stopTime)
    end

    previousvalue = Dict()
    for i in sort(time)
        if (isa(i, SubString{String}) || isa(i, String))
            write(file, i, ",")
        else
            write(file, join(i, ","), ",")
        end
        listcount = 1
        for val in value
            if (isa(val, Array))
                newval = val
                count = 1
                found = "false"
                for v in newval
                    if (i == v[1])
                        data = eval(v[2])
                        write(file, join(data, ","), ",")
                        previousvalue[listcount] = data
                        deleteat!(newval, count)
                        found = "true"
                        break
                    end
                    count = count + 1
                end
                if (found == "false")
                    write(file, join(previousvalue[listcount], ","), ",")
                end
            end

            if (isa(val, String))
                if (val == "None")
                    val = "0"
                else
                    val = val
                end
                write(file, val, ",")
                previousvalue[listcount] = val
            end

            if (isa(val, SubString{String}))
                if (val == "None")
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

- `omc`:        OpenModelica compiler session, see `OMCSession()`.

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
function linearize(omc; lintime = nothing, simflags= nothing, verbose=true)

    if (isempty(omc.xmlfile))
        return println("Linearization cannot be performed as the model is not build, use ModelicaSystem() to build the model first")
    end

    if (simflags === nothing)
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

    for t in keys(omc.linearOptions)
        val = join([t,"=",omc.linearOptions[t], "\n"])
        write(file, val)
        overridelist = true
    end

    close(file)

    if (overridelist == true)
        overrideFlag = join(["-overrideFile=", overridelinearfile])
    else
        overrideFlag = "";
    end

    if (omc.inputFlag == true)
        createcsvdata(omc, omc.linearOptions["startTime"], omc.linearOptions["stopTime"])
        csvinput = join(["-csvInput=", omc.csvfile])
    else
        csvinput = "";
    end

    if (isfile(omc.xmlfile))
        if (Sys.iswindows())
            getexefile = replace(joinpath(omc.tempdir, join([omc.modelname,".exe"])), r"[/\\]+" => "/")
        else
            getexefile = replace(joinpath(omc.tempdir, omc.modelname), r"[/\\]+" => "/")
        end
    else
        return println("Linearization cannot be performed as : " + omc.xmlfile + " not found, please build the modelica again using ModelicaSystem()")
    end

    if (lintime !== nothing)
        linruntime = join(["-l=", lintime])
    else
        linruntime = join(["-l=", omc.linearOptions["stopTime"]])
    end

    finalLinearizationexe = filter!(e -> e ≠ "", [getexefile, linruntime, overrideFlag, csvinput, simflags])
    # println(finalLinearizationexe)

    cd(omc.tempdir)
    if (Sys.iswindows())
        installPath = sendExpression(omc, "getInstallationDirectoryPath()")
        envPath = ENV["PATH"]
        newPath = "$(envPath);$(installPath)/bin/;$(installPath)/lib/omc;$(installPath)/lib/omc/cpp;$(installPath)/lib/omc/omsicpp"
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

    omc.linearmodelname = "linearized_model"
    omc.linearfile = joinpath(omc.tempdir, join([omc.linearmodelname,".jl"]))

    # support older openmodelica versions before OpenModelica v1.16.2 where linearize() generates "linear_modelname.mo" file
    if(!isfile(omc.linearfile))
        omc.linearmodelname = join(["linear_", omc.modelname])
        omc.linearfile = joinpath(omc.tempdir, join([omc.linearmodelname, ".jl"]))
    end

    if (isfile(omc.linearfile))
        omc.linearFlag = true
        # this function is called from the generated Julia code linearized_model.jl,
        # to improve the performance by directly reading the matrices A, B, C and D from the julia code and avoid building the linearized modelica model
        include(omc.linearfile)
        ## to be evaluated at runtime, as Julia expects all functions should be known at the compilation time so efficient assembly code can be generated.
        result = invokelatest(linearized_model)
        (n, m, p, x0, u0, A, B, C, D, stateVars, inputVars, outputVars) = result
        omc.linearstates = stateVars
        omc.linearinputs = inputVars
        omc.linearoutputs = outputVars
        return [A, B, C, D]
    else
        errormsg = sendExpression(omc, "getErrorString()")
        return println("Linearization failed: ","\"" , omc.linearfile,"\"" ," not found \n", errormsg)
    end
    cd(omc.currentdir)
end

"""
standard getXXX() API
function which returns the LinearizationOptions
"""
function getLinearizationOptions(omc, name=nothing)
    if (name === nothing)
        return omc.linearOptions
    elseif (isa(name, String))
        return get(omc.linearOptions, name, 0)
    elseif (isa(name, Array))
        return [get(omc.linearOptions, x, 0) for x in name]
    end
end

"""
standard getXXX() API
function which returns the LinearInput variables after the model is linearized
"""
function getLinearInputs(omc)
    if (omc.linearFlag == true)
        return omc.linearinputs
    else
        println("Model is not Linearized")
    end
end

"""
standard getXXX() API
function which returns the LinearOutput variables after the model is linearized
"""
function getLinearOutputs(omc)
    if (omc.linearFlag == true)
        return omc.linearoutputs
    else
        println("Model is not Linearized")
    end
end

"""
standard getXXX() API
function which returns the LinearStates variables after the model is linearized
"""
function getLinearStates(omc)
    if (omc.linearFlag == true)
        return omc.linearstates
    else
        println("Model is not Linearized")
    end
end

"""
standard setXXX() API
function which sets the LinearizationOption values defined by users
"""
function setLinearizationOptions(omc, name)
    if (isa(name, String))
        name = strip_space(name)
        value = split(name, "=")
        if (haskey(omc.linearOptions, value[1]))
            omc.linearOptions[value[1]] = value[2]
        else
            return println(value[1], "  is not a LinearizationOption")
        end
    elseif (isa(name, Array))
        name = strip_space(name)
        for var in name
            value = split(var, "=")
            if (haskey(omc.linearOptions, value[1]))
                omc.linearOptions[value[1]] = value[2]
            else
                return println(value[1], "  is not a LinearizationOption")
            end
        end
    end
end