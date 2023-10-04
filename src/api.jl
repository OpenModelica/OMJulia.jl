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
The functions below are generated using the autoGenerate.jl located
in scripts folder, the generated code is 95 % accurate, and we need to
do some fixes manually for certain API's, but in future this could be improved
and completely use the autoGenerate.jl to get 100% correct generated codes
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

    function makeVectorString(args)
        if length(args) == 0
            return "\"\""
        end
        s = []
        for item in args
            args = join(["\"", item , "\""])
            push!(s, args)
        end
        return join(s, ", ")
    end

    """
        loadFile(omc, fileName; encoding = "", uses = true, notify = true, requireExactVersion = false)

    Load file `fileName` (*.mo) and merge it with the loaded AST.
    """
    function loadFile(omc,
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

    function loadModel(omc,
        className::String;
        priorityVersion::Vector{String} = String[],
        notify::Bool = false,
        languageStandard::String = "",
        requireExactVersion::Bool = false
        )
        exp = join(["loadModel", "(", "className", "=", className, ",", "priorityVersion", "=", "{", makeVectorString(priorityVersion), "}", ",", "notify", "=", notify,",", "languageStandard", "=", modelicaString(languageStandard), ",", "requireExactVersion", "=", requireExactVersion,")"])
        return OMJulia.sendExpression(omc, exp)
    end

    """
        simulate(omc, className;
                startTime = 0.0, stopTime = nothing, numberOfIntervals = 500, tolerance = 1e-6,
                method = "", fileNamePrefix=className, options = "", outputFormat = "mat",
                variableFilter = ".*", cflags = "", simflags = "")

    Simulates a modelica model by generating C code, build it and run the simulation executable.
    """
    function simulate(omc,
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

    function buildModel(omc,
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

    function getClassNames(omc;
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

        exp = "getClassNames(" * args * ")"

        try
            return OMJulia.sendExpression(omc, exp)
        finally
            return OMJulia.sendExpression(omc, exp, parsed=false)
        end
    end

    function readSimulationResult(omc,
        filename::String,
        variables::Vector{String} = String[],
        size::Int64 = 0
        )

        exp = join(["readSimulationResult", "(", modelicaString(filename), ",", "{", join(variables, ", "), "}", ", ", size,")"])
        return OMJulia.sendExpression(omc, exp)
    end

    function readSimulationResultSize(omc,
        fileName::String;
        )

        exp = join(["readSimulationResultSize", "(", "fileName", "=", modelicaString(fileName),")"])
        return OMJulia.sendExpression(omc, exp)
    end

    function readSimulationResultVars(omc,
        fileName::String;
        readParameters::Bool = true,
        openmodelicaStyle::Bool = false
        )

        exp = join(["readSimulationResultVars", "(", "fileName", "=", modelicaString(fileName), ",", "readParameters", "=", readParameters,",", "openmodelicaStyle", "=", openmodelicaStyle,")"])
        return OMJulia.sendExpression(omc, exp)
    end

    function closeSimulationResultFile(omc)
        return OMJulia.sendExpression(omc, "closeSimulationResultFile()")
    end

    """
        setCommandLineOptions(omc, option)

    The input is a regular command-line flag given to OMC, e.g. -d=failtrace or -g=MetaModelica.
    """
    function setCommandLineOptions(omc,
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
    """
    function cd(omc,
        newWorkingDirectory::String = "";
        )

        exp = join(["cd", "(", "newWorkingDirectory", "=", modelicaString(newWorkingDirectory),")"])
        workingDirectory = OMJulia.sendExpression(omc, exp)

        if !ispath(workingDirectory)
            throw(ScriptingError(omc, msg = "Failed to change directory to $(modelicaString(newWorkingDirectory))."))
        end
        return workingDirectory
    end

    function linearize(omc,
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
        buildModelFMU(omc, className; version = "2.0", fmuType = "me", fileNamePrefix=className, platforms=["static"], includeResources = false)

    Translates a modelica model into a Functional Mockup Unit.
    The only required argument is the className, while all others have some default values.
    """
    function buildModelFMU(omc,
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
            throw(ScriptingError(omc, msg = "Failed to load file $(modelicaString(fileName))."))
        end
        return generatedFileName
    end

    """
        getErrorString(omc, warningsAsErrors = false)

    Returns the current error message.
    """
    function getErrorString(omc;
        warningsAsErrors::Bool = false
        )

        exp = join(["getErrorString", "(", "warningsAsErrors", "=", warningsAsErrors,")"])
        return OMJulia.sendExpression(omc, exp)
    end

    """
        getVersion(omc)

    Returns the version of the Modelica compiler.
    """
    function getVersion(omc)
        exp = join(["getVersion()"])
        return OMJulia.sendExpression(omc, exp)
    end
end
