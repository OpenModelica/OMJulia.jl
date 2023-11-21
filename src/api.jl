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

# The functions below are generated using the autoGenerate.jl located
# in scripts folder, the generated code is 95 % accurate, and we need to
# do some fixes manually for certain API's, but in future this could be improved
# and completely use the autoGenerate.jl to get 100% correct generated codes

"""

"""
module API

    import ..OMJulia

    """
        ScriptingError <: Exception

    OpenModelica scripting error with message `msg` and
    additional `error string` from `getErrroString`.
    """
    struct ScriptingError <: Exception
        "Error message"
        msg::String
        "Error string from getErrorString()"
        errorString::String

        """
            ScriptingError(omc=nothing; msg = "", errorString=nothing)

        Construct error message from `msg` and `errorString`.
        If OMCSession `omc` is available and `errorString=nothing` call `API.getErrorString()`.
        """
        function ScriptingError(omc::Union{OMJulia.OMCSession, Nothing} = nothing;
                                msg::String = "",
                                errorString::Union{String, Nothing} = nothing)

            if isnothing(errorString) && !isnothing(omc)
                errorString = strip(OMJulia.sendExpression(omc, "getErrorString()"))
            elseif isnothing(errorString)
                errorString = ""
            end
            return new(msg, errorString)
        end

      function Base.showerror(io::IO, e::ScriptingError)
        println(io, e.msg)
        println(io, e.errorString)
      end
    end

    """
        modelicaString(name)

    Wrappes string in quotes and replaces Windows style path seperation `\\` with `/`.
    """
    function modelicaString(name::String)
        formattedString = join(["\"", name, "\""])
        return replace(formattedString, "\\" => "/")
    end

    """
        modelicaString(vec)

    Wrappes array in brackets and for each elemetn add quotes and replaces Windows style path seperation `\\` with `/`.
    """
    function modelicaString(vec::Vector{String})
        return "{" .* join(modelicaString.(vec), ", ") .* "}"
    end

    """
        makeVectorString(vec)

    Add quotes around each string element.
    """
    function makeVectorString(vec::Vector{String})
        if length(vec) == 0
            return "\"\""
        end
        return join("\"" .* vec .* "\"", ", ")
    end

    """
        loadFile(omc, fileName;
                 encoding = "",
                 uses = true,
                 notify = true,
                 requireExactVersion = false)

    Load file `fileName` (*.mo) and merge it with the loaded AST.
    See [OpenModelica scripting API `loadFile`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#loadfile).
    """
    function loadFile(omc::OMJulia.OMCSession,
        fileName::String;
        encoding::String = "",
        uses::Bool = true,
        notify::Bool = true,
        requireExactVersion::Bool = false
        )

        exp = join(["loadFile", "(", "fileName", "=", modelicaString(fileName), ",", "encoding", "=", modelicaString(encoding), ",", "uses", "=", uses,",", "notify", "=", notify,",", "requireExactVersion", "=", requireExactVersion,")"])
        success = OMJulia.sendExpression(omc, exp)

        if !success
            throw(ScriptingError(omc, msg = "Failed to load file $(modelicaString(fileName))."))
        end
        return success
    end

    """
        loadModel(omc, className;
                  priorityVersion = String[],
                  notify = false,
                  languageStandard = "",
                  requireExactVersion = false)

    Loads a Modelica library.

    See [OpenModelica scripting API `loadModel`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#loadmodel).
    """
    function loadModel(omc::OMJulia.OMCSession,
        className::String;
        priorityVersion::Vector{String} = String[],
        notify::Bool = false,
        languageStandard::String = "",
        requireExactVersion::Bool = false
        )
        exp = join(["loadModel", "(", "className", "=", className, ",", "priorityVersion", "=", "{", makeVectorString(priorityVersion), "}", ",", "notify", "=", notify,",", "languageStandard", "=", modelicaString(languageStandard), ",", "requireExactVersion", "=", requireExactVersion,")"])
        
        success = OMJulia.sendExpression(omc, exp)

        if !success
            throw(ScriptingError(omc, msg = "Failed to load model $(className)."))
        end
        return success
    end

    """
        simulate(omc, className;
                startTime = 0.0,
                stopTime = nothing,
                numberOfIntervals = 500,
                tolerance = 1e-6,
                method = "",
                fileNamePrefix=className,
                options = "",
                outputFormat = "mat",
                variableFilter = ".*",
                cflags = "",
                simflags = "")

    Simulates a modelica model by generating C code, build it and run the simulation executable.

    See [OpenModelica scripting API `simulate`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#simulate).
    """
    function simulate(omc::OMJulia.OMCSession,
        className::String;
        startTime::Float64 = 0.0,
        stopTime::Union{Float64, Nothing} = nothing,
        numberOfIntervals::Int64 = 500,
        tolerance::Float64 = 1e-6,
        method::String = "",
        fileNamePrefix::String = className,
        options::String = "",
        outputFormat::String = "mat",
        variableFilter::String = ".*",
        cflags::String = "",
        simflags::String = ""
        )

        exp = join(["simulate", "(", className, ",",
                                  "startTime", "=", startTime, ","])
        # There is no default value for stopTime we can provide that behaves like not giving any value and using the stopTime from the experiment annotation...
        if !isnothing(stopTime)
            exp *= "stopTime = $stopTime,"
        end
        exp *= join(["numberOfIntervals", "=", numberOfIntervals, ",",
                     "tolerance", "=", tolerance, ",",
                     "method", "=", modelicaString(method), ",",
                     "fileNamePrefix", "=", modelicaString(fileNamePrefix), ",",
                     "options", "=", modelicaString(options), ",",
                     "outputFormat", "=", modelicaString(outputFormat), ",",
                     "variableFilter", "=", modelicaString(variableFilter), ",",
                     "cflags", "=", modelicaString(cflags), ",",
                     "simflags", "=", modelicaString(simflags), ")"])
        simulationResults = OMJulia.sendExpression(omc, exp)

        if !haskey(simulationResults, "resultFile") || isempty(simulationResults["resultFile"])
            if haskey(simulationResults, "messages")
                throw(ScriptingError(omc, msg = "Failed to simulate $(className).\n" * simulationResults["messages"] ))
            else
                throw(ScriptingError(omc, msg = "Failed to simulate $(className)."))
            end
        end
        return simulationResults
    end

    """
        buildModel(omc, className;
                   startTime = 0.0,
                   stopTime = 1.0,
                   numberOfIntervals = 500,
                   tolerance = 1e-6,
                   method = "",
                   fileNamePrefix = className,
                   options = "",
                   outputFormat = "mat",
                   variableFilter = ".*",
                   cflags = "",
                   simflags = "")

    Build Modelica model by generating C code and compiling it into an executable simulation.
    It does not run the simulation!

    See [OpenModelica scripting API `buildModel`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#buildmodel).
    """
    function buildModel(omc::OMJulia.OMCSession,
        className::String;
        startTime::Float64 = 0.0,
        stopTime::Float64 = 1.0,
        numberOfIntervals::Int64 = 500,
        tolerance::Float64 = 1e-6,
        method::String = "",
        fileNamePrefix::String = className,
        options::String = "",
        outputFormat::String = "mat",
        variableFilter::String = ".*",
        cflags::String = "",
        simflags::String = ""
        )

        exp = join(["buildModel", "(", className, ",", "startTime", "=", startTime,",", "stopTime", "=", stopTime,",", "numberOfIntervals", "=", numberOfIntervals,",", "tolerance", "=", tolerance,",", "method", "=", modelicaString(method), ",", "fileNamePrefix", "=", modelicaString(fileNamePrefix), ",", "options", "=", modelicaString(options), ",", "outputFormat", "=", modelicaString(outputFormat), ",", "variableFilter", "=", modelicaString(variableFilter), ",", "cflags", "=", modelicaString(cflags), ",", "simflags", "=", modelicaString(simflags),")"])
        return OMJulia.sendExpression(omc, exp)
    end

    """
        getClassNames(omc;
                      class_ = "",
                      recursive = false,
                      qualified = false,
                      sort = false,
                      builtin = false,
                      showProtected = false,
                      includeConstants = false)

    Returns the list of class names defined in the class.

    See [OpenModelica scripting API `getClassNames`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#getclassnames).
    """
    function getClassNames(omc::OMJulia.OMCSession;
                           class_::String = "",
                           recursive::Bool = false,
                           qualified::Bool = false,
                           sort::Bool = false,
                           builtin::Bool = false,
                           showProtected::Bool = false,
                           includeConstants::Bool = false
                           )
        if (class_ == "")
            args = join(["recursive", "=", recursive, ", ", "qualified", "=", qualified, ", ", "sort", "=", sort, ", ", "builtin", "=", builtin, ", ", "showProtected", "=", showProtected, ", ", "includeConstants", "=", includeConstants])
        else
            args = join(["class_", "=", class_, ", ", "recursive", "=", recursive, ", ", "qualified", "=", qualified, ", ", "sort", "=", sort, ", ", "builtin", "=", builtin, ", ", "showProtected", "=", showProtected, ", ", "includeConstants", "=", includeConstants])
        end

        exp = "getClassNames($args)"

        return OMJulia.sendExpression(omc, exp)
    end

    """
        readSimulationResult(omc, filename,
                             variables = String[],
                             size = 0)

    Reads a result file, returning a matrix corresponding to the variables and size given.

    See [OpenModelica scripting API `readSimulationResult`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#readsimulationresult).
    """
    function readSimulationResult(omc::OMJulia.OMCSession,
        filename::String,
        variables::Vector{String} = String[],
        size::Int64 = 0
        )

        exp = join(["readSimulationResult", "(", modelicaString(filename), ",", "{", join(variables, ", "), "}", ", ", size,")"])
        return OMJulia.sendExpression(omc, exp)
    end

    """
        readSimulationResultSize(omc, fileName)

    The number of intervals that are present in the output file.

    See [OpenModelica scripting API `readSimulationResultSize`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#readsimulationresultsize).
    """
    function readSimulationResultSize(omc::OMJulia.OMCSession,
        fileName::String
        )

        exp = join(["readSimulationResultSize", "(", "fileName", "=", modelicaString(fileName),")"])
        return OMJulia.sendExpression(omc, exp)
    end

    """
    readSimulationResultVars(omc, fileName;
                             readParameters = true,
                             openmodelicaStyle = false)

    Returns the variables in the simulation file; you can use val() and plot() commands using these names.

    See [OpenModelica scripting API `readSimulationResultVars`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#readsimulationresultvars).
    """
    function readSimulationResultVars(omc::OMJulia.OMCSession,
        fileName::String;
        readParameters::Bool = true,
        openmodelicaStyle::Bool = false
        )

        exp = join(["readSimulationResultVars", "(", "fileName", "=", modelicaString(fileName), ",", "readParameters", "=", readParameters,",", "openmodelicaStyle", "=", openmodelicaStyle,")"])
        return OMJulia.sendExpression(omc, exp)
    end

    """
            closeSimulationResultFile(omc)

    Closes the current simulation result file.
    Only needed by Windows. Windows cannot handle reading and writing to the same file from different processes.
    To allow OMEdit to make successful simulation again on the same file we must close the file after reading the Simulation Result Variables.
    Even OMEdit only use this API for Windows.

    See [OpenModelica scripting API `closeSimulationResultFile`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#closesimulationresultfile).
    """
    function closeSimulationResultFile(omc::OMJulia.OMCSession)
        return OMJulia.sendExpression(omc, "closeSimulationResultFile()")
    end

    """
        setCommandLineOptions(omc, option)

    The input is a regular command-line flag given to OMC, e.g. -d=failtrace or -g=MetaModelica.

    See [OpenModelica scripting API `setCommandLineOptions`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#setcommandlineoptions).
    """
    function setCommandLineOptions(omc::OMJulia.OMCSession,
        option::String
        )

        exp = join(["setCommandLineOptions", "(", "option", "=", modelicaString(option),")"])
        success = OMJulia.sendExpression(omc, exp)
        if !success
            throw(ScriptingError(omc, msg = "Failed to set command line options $(modelicaString(option))."))
        end
        return success
    end

    """
        cd(omc, newWorkingDirectory="")

    Change directory to the given path `newWorkingDirectory` (which may be either relative or absolute).
    Returns the new working directory on success or a message on failure.
    If the given path is the empty string, the function simply returns the current working directory.

    See [OpenModelica scripting API `cd`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#cd).
    """
    function cd(omc::OMJulia.OMCSession,
        newWorkingDirectory::String = "";
        )

        exp = join(["cd", "(", "newWorkingDirectory", "=", modelicaString(newWorkingDirectory),")"])
        workingDirectory = OMJulia.sendExpression(omc, exp)

        if !ispath(workingDirectory)
            throw(ScriptingError(omc, msg = "Failed to change directory to $(modelicaString(newWorkingDirectory))."))
        end
        return workingDirectory
    end

    """
    Creates a model with symbolic linearization matrices.

    See [OpenModelica scripting API `linearize`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#linearize).
    """
    function linearize(omc::OMJulia.OMCSession,
        className::String;
        startTime::Float64 = 0.0,
        stopTime::Float64 = 1.0,
        numberOfIntervals::Int64 = 500,
        stepSize::Float64 = 0.002,
        tolerance::Float64 = 1e-6,
        method::String = "",
        fileNamePrefix::String = className,
        options::String = "",
        outputFormat::String = "mat",
        variableFilter::String = ".*",
        cflags::String = "",
        simflags::String = ""
        )

        exp = join(["linearize", "(", className, ",", "startTime", "=", startTime,",", "stopTime", "=", stopTime,",", "numberOfIntervals", "=", numberOfIntervals,",", "stepSize", "=", stepSize,",", "tolerance", "=", tolerance,",", "method", "=", modelicaString(method), ",", "fileNamePrefix", "=", modelicaString(fileNamePrefix), ",", "options", "=", modelicaString(options), ",", "outputFormat", "=", modelicaString(outputFormat), ",", "variableFilter", "=", modelicaString(variableFilter), ",", "cflags", "=", modelicaString(cflags), ",", "simflags", "=", modelicaString(simflags),")"])
        return OMJulia.sendExpression(omc, exp)
    end

    """
        buildModelFMU(omc, className;
                      version = "2.0",
                      fmuType = "me",
                      fileNamePrefix=className,
                      platforms=["static"],
                      includeResources = false)

    Translates a modelica model into a Functional Mockup Unit.
    The only required argument is the className, while all others have some default values.

    See [OpenModelica scripting API `buildModelFMU`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#buildmodelfmu).
    """
    function buildModelFMU(omc::OMJulia.OMCSession,
        className::String;
        version::String = "2.0",
        fmuType::String = "me",
        fileNamePrefix::String = className,
        platforms::Vector{String} = String["static"],
        includeResources::Bool = false
        )

        exp = join(["buildModelFMU", "(", className, ",", "version", "=", modelicaString(version), ",", "fmuType", "=", modelicaString(fmuType), ",", "fileNamePrefix", "=", modelicaString(fileNamePrefix), ",", "platforms", "=", "{", makeVectorString(platforms), "}", ",", "includeResources", "=", includeResources,")"])
        generatedFileName = OMJulia.sendExpression(omc, exp)

        if !isfile(generatedFileName) || !endswith(generatedFileName, ".fmu")
            throw(ScriptingError(omc, msg = "Failed to load file $(modelicaString(generatedFileName))."))
        end
        return generatedFileName
    end

    """
        getErrorString(omc, warningsAsErrors = false)

    Returns the current error message.

    See [OpenModelica scripting API `getErrorString`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#geterrorstring).
    """
    function getErrorString(omc::OMJulia.OMCSession;
        warningsAsErrors::Bool = false
        )

        exp = join(["getErrorString", "(", "warningsAsErrors", "=", warningsAsErrors,")"])
        return OMJulia.sendExpression(omc, exp)
    end

    """
        getVersion(omc)

    Returns the version of the Modelica compiler.

    See [OpenModelica scripting API `getVersion`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#getversion).
    """
    function getVersion(omc::OMJulia.OMCSession)
        exp = join(["getVersion()"])
        return OMJulia.sendExpression(omc, exp)
    end

    """
        getInstallationDirectoryPath(omc)

    This returns `OPENMODELICAHOME` if it is set; on some platforms the default path is returned if it is not set.

    See [OpenModelica scripting API `getInstallationDirectoryPath`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#getinstallationdirectorypath).
    """
    function getInstallationDirectoryPath(omc::OMJulia.OMCSession)
        exp = join(["getInstallationDirectoryPath()"])
        return OMJulia.sendExpression(omc, exp)
    end

    """
        diffSimulationResults(omc, actualFile, expectedFile, diffPrefix;
                              relTol = 1e-3,
                              relTolDiffMinMax = 1e-4,
                              rangeDelta = 0.002,
                              vars = String[],
                              keepEqualResults = false)

    Compares simulation results.

    See [OpenModelica scripting API `diffSimulationResults`](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html#diffsimulationresults).
    """
    function diffSimulationResults(omc::OMJulia.OMCSession,
        actualFile::String,
        expectedFile::String,
        diffPrefix::String;
        relTol::Float64 = 1e-3,
        relTolDiffMinMax::Float64 = 1e-4,
        rangeDelta::Float64 = 0.002,
        vars::Vector{String} = String[],
        keepEqualResults::Bool = false)

        exp = "diffSimulationResults($(modelicaString(actualFile)),
                                     $(modelicaString(expectedFile)),
                                     $(modelicaString(diffPrefix)),
                                     relTol=$relTol,
                                     relTolDiffMinMax=$relTolDiffMinMax,
                                     rangeDelta=$rangeDelta,
                                     vars=$(modelicaString(vars)),
                                     keepEqualResults=$keepEqualResults)"
        @debug "$exp"
        ret = OMJulia.sendExpression(omc, exp)

        if isnothing(ret)
            return (true, String[])
        else
            return (ret[1], convert(Vector{String}, ret[2]))
        end
    end
end
