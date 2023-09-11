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

    using OMJulia

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

    function loadFile(omc,
        fileName::String;
        encoding::String = "",
        uses::Bool = true,
        notify::Bool = true,
        requireExactVersion::Bool = false
        )

        exp = join(["loadFile", "(", "fileName", "=", modelicaString(fileName), ",", "encoding", "=", modelicaString(encoding), ",", "uses", "=", uses,",", "notify", "=", notify,",", "requireExactVersion", "=", requireExactVersion,")"])
        return sendExpression(omc, exp)

    end

    function loadModel(omc,
        className::String;
        priorityVersion::Vector{String} = String[],
        notify::Bool = false,
        languageStandard::String = "",
        requireExactVersion::Bool = false
        )
        exp = join(["loadModel", "(", "className", "=", className, ",", "priorityVersion", "=", "{", makeVectorString(priorityVersion), "}", ",", "notify", "=", notify,",", "languageStandard", "=", modelicaString(languageStandard), ",", "requireExactVersion", "=", requireExactVersion,")"])
        return sendExpression(omc, exp)
    end

    function simulate(omc,
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

        exp = join(["simulate", "(", className, ",", "startTime", "=", startTime,",", "stopTime", "=", stopTime,",", "numberOfIntervals", "=", numberOfIntervals,",", "tolerance", "=", tolerance,",", "method", "=", modelicaString(method), ",", "fileNamePrefix", "=", modelicaString(fileNamePrefix), ",", "options", "=", modelicaString(options), ",", "outputFormat", "=", modelicaString(outputFormat), ",", "variableFilter", "=", modelicaString(variableFilter), ",", "cflags", "=", modelicaString(cflags), ",", "simflags", "=", modelicaString(simflags),")"])
        return sendExpression(omc, exp)
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
        return sendExpression(omc, exp)
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
            return sendExpression(omc, exp)
        finally
            return sendExpression(omc, exp, parsed=false)
        end
    end

    function readSimulationResult(omc,
        filename::String,
        variables::Vector{String} = String[],
        size::Int64 = 0
        )

        exp = join(["readSimulationResult", "(", modelicaString(filename), ",", "{", join(variables, ", "), "}", ", ", size,")"])
        return sendExpression(omc, exp)
    end

    function readSimulationResultSize(omc,
        fileName::String;
        )

        exp = join(["readSimulationResultSize", "(", "fileName", "=", modelicaString(fileName),")"])
        return sendExpression(omc, exp)
    end

    function readSimulationResultVars(omc,
        fileName::String;
        readParameters::Bool = true,
        openmodelicaStyle::Bool = false
        )

        exp = join(["readSimulationResultVars", "(", "fileName", "=", modelicaString(fileName), ",", "readParameters", "=", readParameters,",", "openmodelicaStyle", "=", openmodelicaStyle,")"])
        return sendExpression(omc, exp)
    end

    function closeSimulationResultFile(omc)
        return sendExpression(omc, "closeSimulationResultFile()")
    end

    function setCommandLineOptions(omc,
        option::String;
        )

        exp = join(["setCommandLineOptions", "(", "option", "=", modelicaString(option),")"])
        return sendExpression(omc, exp)
    end

    function cd(omc,
        newWorkingDirectory::String = "";
        )

        exp = join(["cd", "(", "newWorkingDirectory", "=", modelicaString(newWorkingDirectory),")"])
        return sendExpression(omc, exp)
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
        return sendExpression(omc, exp)
    end

    function buildModelFMU(omc,
        className::String;
        version::String = "2.0",
        fmuType::String = "me",
        fileNamePrefix::String = className,
        platforms::Vector{String} = String["static"],
        includeResources::Bool = false
        )

        exp = join(["buildModelFMU", "(", className, ",", "version", "=", modelicaString(version), ",", "fmuType", "=", modelicaString(fmuType), ",", "fileNamePrefix", "=", modelicaString(fileNamePrefix), ",", "platforms", "=", "{", makeVectorString(platforms), "}", ",", "includeResources", "=", includeResources,")"])
        return sendExpression(omc, exp)
    end

    function getErrorString(omc;
        warningsAsErrors::Bool = false
        )

        exp = join(["getErrorString", "(", "warningsAsErrors", "=", warningsAsErrors,")"])
        return sendExpression(omc, exp)
    end
end