module TestOMJulia

using OMJulia
using Test

@testset "OMJulia" begin

@testset "Parser" begin

function check(string, expected_value, expected_type)
  value = OMJulia.Parser.parseOM(string)
  expected_value == value && expected_type == typeof(value)
end

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

@testset "OpenModelica" begin

omc = OMJulia.OMCSession()

@test "3\n"==omc.sendExpression("1+2")
@test 3==OMJulia.sendExpression(omc, "1+2")

end

end

end
