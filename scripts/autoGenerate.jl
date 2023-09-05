"""
    Module which takes the OpenModelica.Scripting API from
    https://build.openmodelica.org/Documentation/OpenModelica.Scripting.html
    and convert them to julia format, the translated code is approximately
    100 % correct in most cases, but it is also possible some generated codes
    needs to be fixed manually
"""

module autogenerateAPI
    using DataStructures

    function checkEqualsExist(args)
        for item in args
            if (item == "=")
                return true
            end
        end
        return false
    end

    function mapTypes(type)
        if (type == "Boolean")
            return Bool
        elseif (type == "Real")
            return Float64
        elseif (type == "Integer")
            return Int64
        elseif (type == "String[:]")
            return Vector{String}
        end
        return String
    end

    function mapDefaultValues(value, argumentType)
        if (argumentType == Vector{String})
            return Vector{String}()
        end
        if (value == "\"<default>\"")
            return "\"\""
        elseif (value == "startTime")
            return 0.0
        end
        return value
    end

    function writeFunctionArguments(file, args::OrderedDict)
        fnargs = join(["fnargs = ", "[", join(keys(args), ", "), "]",])
        write(file, "\n    ")
        write(file, fnargs)
        write(file, "\n")
    end

    function makeDoubleQuotes(args)
        return join(["\"", args, "\"", ", "])
    end

    function keyHasClassName(name)
        if (name == "className")
            return name
        else
            return join(["modelicaString(", name, ")"])
        end
    end

    function writeModelicaExpression(file, args::OrderedDict, apiName::String)
        write(file, "\n    ")
        write(file, "exp = join([")
        api = join([makeDoubleQuotes(apiName), makeDoubleQuotes("(")])
        write(file, api)
        size = length(keys(args))
        count = 1
        for (key, type) in args
            if (type == String)
                if (count < size)
                    exp = join([makeDoubleQuotes(key), makeDoubleQuotes("="), keyHasClassName(key), ", ", makeDoubleQuotes(",")])
                else
                    exp = join([makeDoubleQuotes(key), makeDoubleQuotes("="), keyHasClassName(key), ","])
                end
            elseif (type == Vector{String})
                    if (count < size)
                        exp = join([makeDoubleQuotes(key), makeDoubleQuotes("="), makeDoubleQuotes("{"), "makeVectorString","(", key, ")", ", ", makeDoubleQuotes("}"), makeDoubleQuotes(",")])
                    else
                        exp = join([makeDoubleQuotes(key), makeDoubleQuotes("="), makeDoubleQuotes("{"), "makeVectorString","(", key, ")", ", ", makeDoubleQuotes("}"), ","])
                    end
            else
                if (count < size)
                    exp = join([makeDoubleQuotes(key), makeDoubleQuotes("="), key, ",", makeDoubleQuotes(",")])
                else
                    exp = join([makeDoubleQuotes(key), makeDoubleQuotes("="), key, ","])
                end
            end
            count = count + 1
            write(file, exp)
        end

        write(file, join(["\"", ")", "\""]))
        write(file, "])")
        write(file, "\n    return sendExpression(omc, exp)\n")
    end

    function writeFunctionArguments(file, expList)
        size = length(expList)
        count = 1
        for item in expList
            if (size == count) ## get the last item
                write(file, replace(item, "," => ""))
            else
                write(file, item)
            end
            count = count + 1
        end
    end

    """
        function which reads the API from a txt file see "api.txt" which is taken from
        https://build.openmodelica.org/Documentation/OpenModelica.Scripting.html and translates the code
        to julia syntax with typing
    """
    function readFile(filePath::String)

        if (!isfile(filePath))
            return @error ("filePath does not exit " , filePath)
        end

        file = readlines(filePath)
        @info ("reading file: ", filePath)

        @info ("Translating function Started, writing to file api.jl")

        f = open("api.jl", "w")
        functionArgumentNames = OrderedDict()
        apiName = ""
        expList = []
        namedArgs = true
        for line in file
            args = split(line)
            if (length(args) > 0)
                if (args[1] == "function")
                    fnheader = join([args[1], " ", args[2], "(", "omc,", "\n", "    "])
                    apiName = String(args[2])
                    # write(f, fnheader)
                    @info ("Translating function ", apiName)
                    push!(expList, fnheader)
                end

                if (args[1] == "input")
                    if (checkEqualsExist(args))
                        argumentName = args[3]
                        argumentType = mapTypes(args[2])
                        argumentDefaultValue = replace(mapDefaultValues(args[5], argumentType), ";" => "")
                        argumentList = join([argumentName, "::", argumentType, " = ", argumentDefaultValue, ",\n", "    "])
                    else
                        argumentType = mapTypes(args[2])
                        argumentName = replace(mapDefaultValues(args[3], argumentType), ";" => "")
                        argumentList = join([argumentName, "::", argumentType, ",\n", "    "])
                    end
                    # println(expList)
                    # println(argumentList)
                    push!(expList, argumentList)
                    if (namedArgs == true)
                        index = lastindex(expList)
                        expList[index] = replace(expList[index], "," => ";")
                        namedArgs = false
                    end
                    # write(f, argumentList)
                    functionArgumentNames[argumentName] = argumentType
                end

                if (args[1] == "end")
                    # println(expList)
                    writeFunctionArguments(f, expList)
                    write(f, ")   \n")
                    writeModelicaExpression(f, functionArgumentNames, apiName)
                    write(f, args[1])
                    write(f, "\n\n")
                    functionArgumentNames = OrderedDict()
                    expList = []
                    namedArgs = true
                end
            end
        end
        @info ("Translating function completed")
        close(f)
    end
end

autogenerateAPI.readFile("api.txt")
