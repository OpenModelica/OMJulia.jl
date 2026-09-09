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

# Generate a Lexer for OpenModelica output (Values.Value)
# =====================================================================
#
# Run from the repository root:
#
#     julia --project=bin bin/generate_lexer.jl
#
# and commit the regenerated src/lexer.jl.

using Automa

# Describe patterns in regular expressions.
t        = re"[tT][rR][uU][eE]"
f        = re"[fF][aA][lL][sS][eE]"
str      = re"\"([^\"\x5c]|(\x5c.))*\""
# A name is either a plain identifier or a quoted one. OMC prints qualified
# names (`getClassNames(recursive = true)`) as dot-separated names, so accept a
# dotted sequence of them as a single token.
name     = re"[_A-Za-z][_A-Za-z0-9]*|'([^'\x5c]|(\x5c.))+'"
ident    = name * rep(re"\." * name)
int      = re"[-+]?[0-9]+"
prefloat = re"[-+]?([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)"
float    = prefloat | (prefloat | re"[-+]?[0-9]+") * re"[eE][-+]?[0-9]+"
operator = re"[={}(),;]|end"
ws       = re"[\n\t ]+"

# Automa resolves an overlap between two token regexes by preferring the longest
# match, and on a tie by preferring the token *later* in this list. `record`,
# `end`, `true` and `false` are all also valid identifiers and must therefore
# come after `IDENT` to win the tie, while a longer name such as `ending` still
# lexes as an identifier because its match is longer.
@enum OMToken::UInt8 ERROR WS STRING INT FLOAT IDENT OPERATOR RECORD TRUE FALSE

tokens = (ERROR, [
  WS       => ws,
  STRING   => str,
  INT      => int,
  FLOAT    => float,
  IDENT    => ident,
  OPERATOR => operator,
  RECORD   => re"record",
  TRUE     => t,
  FALSE    => f,
])

# `make_tokenizer` returns the definition of `Base.iterate(::Tokenizer)`; the
# enum has to be defined before it, so emit both.
tokenizer_code = Automa.make_tokenizer(tokens)
Base.remove_linenums!(tokenizer_code)

open(joinpath(@__DIR__, "..", "src", "lexer.jl"), "w") do io
  print(io, """# Generated Lexer for OpenModelica Values.Value output
#
# Do not edit by hand. Regenerate with:
#
#     julia --project=bin bin/generate_lexer.jl

@enum OMToken::UInt8 ERROR WS STRING INT FLOAT IDENT OPERATOR RECORD TRUE FALSE

$(tokenizer_code)

\"\"\"
    tokenize(data::String)

Tokenize OpenModelica `Values.Value` output into the values the parser
consumes. Throws [`LexerError`](@ref) on input that is not valid output.
\"\"\"
function tokenize(data::String)
  tokens = Any[]
  for (start, len, token) in Automa.tokenize(OMToken, data)
    stop = start + len - 1
    if token == ERROR
      throw(LexerError("Error while lexing"))
    elseif token == WS
      continue
    elseif token == TRUE
      push!(tokens, true)
    elseif token == FALSE
      push!(tokens, false)
    elseif token == RECORD
      push!(tokens, Record())
    elseif token == OPERATOR
      push!(tokens, Symbol(data[start:stop]))
    elseif token == STRING
      push!(tokens, unescape_string(data[start+1:stop-1]))
    elseif token == IDENT
      push!(tokens, Identifier(unescape_string(data[start:stop])))
    elseif token == INT
      push!(tokens, parse(Int, data[start:stop]))
    elseif token == FLOAT
      push!(tokens, parse(Float64, data[start:stop]))
    end
  end
  return tokens
end
""")
end
