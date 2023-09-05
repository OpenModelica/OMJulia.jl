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

using OMJulia

function check(string, expected_value, expected_type)
    value = OMJulia.Parser.parseOM(string)
    return expected_value == value && expected_type == typeof(value)
end

@testset "Parser" begin
    @test check("123.0", 123.0, Float64)
    @test check("123", 123, Int)
    @test check("1.", 1.0, Float64)
    @test check(".2", 0.2, Float64)
    @test check("1e3", 1e3, Float64)
    @test check("1e+2", 1e+2, Float64)
    @test check("tRuE", true, Bool)
    @test check("false", false, Bool)
    @test check("\"ab\\nc\"", "ab\nc", String)
    @test check("{\"abc\"}", ["abc"], Array{String,1})
    @test check("{1}", [1], Array{Int,1})
    @test check("{1,2,3}", [1,2,3], Array{Int,1})
    @test check("(1,2,3)", (1,2,3), Tuple{Int,Int,Int})
    @test check("NONE()", nothing, Nothing)
    @test check("SOME(1)", 1, Int)
    @test check("abc_2", :abc_2, Symbol)
    @test check("record ABC end ABC;", Dict(), Dict{String,Any})
    @test check("record ABC a = 1, 'b' = 2,\n  c = 3\nend ABC;", Dict("a" => 1, "'b'" => 2, "c" => 3), Dict{String,Int})
    @test check("", nothing, Nothing)
end
