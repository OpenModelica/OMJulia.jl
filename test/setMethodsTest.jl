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

using OMJulia
using Test

# These cover the argument handling of the set methods and of getSolutions.
# They deliberately touch no OMCSession, so they run without an installed
# OpenModelica compiler.

@testset "Key/value assignments" begin
    @test OMJulia.keyValuePairs("a=3") == Dict("a" => "3")
    @test OMJulia.keyValuePairs(["a=4", "V=200"]) == Dict("a" => "4", "V" => "200")

    # Spaces are insignificant, as they were in the old set methods.
    @test OMJulia.keyValuePairs(" a = 3 ") == Dict("a" => "3")

    # Only the first '=' separates a name from its value.
    @test OMJulia.keyValuePairs("a=b=c") == Dict("a" => "b=c")

    # SubStrings are strings too.
    @test OMJulia.keyValuePairs(split("a=3,b=4", ",")) == Dict("a" => "3", "b" => "4")

    @test_throws ErrorException OMJulia.keyValuePairs("a")
    @test_throws ErrorException OMJulia.keyValuePairs(["a=3", "b"])
end

@testset "Input values" begin
    # Constants keep the string form createcsvdata writes verbatim.
    @test OMJulia.inputValue("100") == "100"
    @test OMJulia.inputValue(100) == "100"
    @test OMJulia.inputValue(2.5) == "2.5"
    @test OMJulia.inputValue("None") == "None"

    # A time table, however it is spelled, becomes [time, value] points.
    expected = [[0, 0], [1, 1]]
    @test OMJulia.inputValue("[(0,0),(1,1)]") == expected
    @test OMJulia.inputValue([(0, 0), (1, 1)]) == expected
    @test OMJulia.inputValue([0 => 0, 1 => 1]) == expected
    @test OMJulia.inputValue([[0, 0], [1, 1]]) == expected

    # Negative and exponent literals are folded by the parser, so they are
    # still Numbers by the time inputPoint sees them.
    @test OMJulia.inputValue("[(0,-1),(1,1e-3)]") == [[0, -1], [1, 1e-3]]

    # A bare list of numbers is a mistake, not a table of self-repeating
    # points.
    @test_throws ErrorException OMJulia.inputValue([1, 2, 3])
    @test_throws ErrorException OMJulia.inputValue([(0, 0, 0)])

    # Nothing that is not a literal time table gets through. createcsvdata
    # used to eval whatever Meta.parse returned here.
    @test_throws ErrorException OMJulia.inputValue("[run(`touch pwned`)]")
    @test_throws ErrorException OMJulia.inputValue("[(0, 1 + 1)]")
    @test_throws ErrorException OMJulia.inputValue("[(0, 0, 0)]")
    @test_throws ErrorException OMJulia.inputValue("(0, 0)")
end

@testset "Result file checks" begin
    # An empty path means the model was never simulated, and says so.
    @test_throws "Model not Simulated" OMJulia.checkResultFile("")

    mktempdir() do dir
        missingfile = joinpath(dir, "nope.mat")
        @test_throws "does not exist" OMJulia.checkResultFile(missingfile)

        present = joinpath(dir, "res.mat")
        write(present, "")
        @test isnothing(OMJulia.checkResultFile(present))
    end
end
