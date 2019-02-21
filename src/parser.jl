module Parser

using PEG

@rule exp = bool, float , integer, string, array, tuple, none, some, record, ident
@rule bool = r"true"ip |> x -> true, r"false"ip |> x -> false
@rule string = r"\"([^\"\\]|\\.)*\""p |> x -> unescape_string(x[2:end-1])
@rule number = r"\d+"w , "123."
@rule integer = r"\d+"w |> x -> parse(Int64, x)
@rule float = r"(\d+[.]\d*|\d*[.]\d+)([eE][+-]?\d+)?|\d+([eE][+-]?\d+)" |> x -> parse(Float64, x)
@rule array = r"{"p & sequence & r"}"p > (x,y,z) -> collect(Base.tuple(y...)) # Fixed the type of the array
@rule tuple = "(" & sequence & ")" > (x,y,z) -> Base.tuple(y...)
@rule sequence = (exp & ( "," & exp > (x,y) -> y )[:*] > (x,y) -> vcat([x],y)) , "" |> x -> []
@rule none = r"NONE"p & r"\("p & r"\)"p |> x -> nothing
@rule some = r"SOME"p & r"\("p & exp & r"\)"p > (x,y,exp,z) -> exp
@rule ident = r"[[:alnum:]_][[:alnum:]_0-9]*"p |> x -> convert(String, x) , r"'([^']|\\.)*'"p |> x -> convert(String, x)
@rule member = ident & r"\s*=\s*" & exp > (x,y,z) -> (x,z)
@rule members = member & (r"\s*,\s*" & member > (x,y) -> y)[:*] > (x,y) -> begin res = Dict(y) ; res[x[1]] = x[2] ; res end, ("" |> x -> Dict{String,Any}())
@rule record = r"record"w & ident & members & r"end"w & ident & ";" > (x,i1,members,e,i2,sc) -> Dict(members)

end
