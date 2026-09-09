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

module Parser

# Proposed for Julia 1.5.x
#if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
#    @eval Base.Experimental.@optlevel 1
#end

struct Identifier
  id::String
end

struct Record
end

struct ParseError <: Exception
  errmsg::AbstractString
end

struct LexerError <: Exception
  errmsg::AbstractString
end

import Automa
using Automa: Tokenizer

include("lexer.jl")

show(io::IO, exc::ParseError) = print(io, string("Parse error: ",exc.errmsg))

function parseOM(t::Union{Int,Float64,String,Bool}, tokens)
  return t
end

function checkToken(sym::Symbol, tok)
  if tok != sym
    throw(ParseError("Expected token of type $sym, got $(tok)"))
  end
  tok
end

function checkToken(t, tok)
  if typeof(tok) != t
    throw(ParseError("Expected token of type $t, got $(typeof(tok))"))
  end
  tok
end

function parseSequence(tokens, last)
  res = []
  tok = popfirst!(tokens)
  if tok == last
    return res
  end
  push!(res, parseOM(tok, tokens))
  tok = popfirst!(tokens)
  while tok == Symbol(",")
    push!(res, parseOM(popfirst!(tokens), tokens))
    tok = popfirst!(tokens)
  end
  checkToken(last, tok)
  return collect(tuple(res...))
end

function parseOM(t::Symbol, tokens)
  if t == Symbol("(")
    res = tuple(parseSequence(tokens, Symbol(")"))...)
  elseif t == Symbol("{")
    res = parseSequence(tokens, Symbol("}"))
  end
end

function parseOM(t::Identifier, tokens)
  if t.id == "NONE"
    checkToken(Symbol("("), popfirst!(tokens))
    checkToken(Symbol(")"), popfirst!(tokens))
    return nothing
  elseif t.id == "SOME"
    checkToken(Symbol("("), popfirst!(tokens))
    res = parseOM(popfirst!(tokens), tokens)
    checkToken(Symbol(")"), popfirst!(tokens))
    return res
  else
    return Symbol(t.id)
  end
end

function parseOM(t::Record, tokens)
  res = Tuple{String,Any}[]

  checkToken(Identifier, popfirst!(tokens))
  tok = popfirst!(tokens)
  if tok != :end
    id = checkToken(Identifier, tok)
    checkToken(Symbol("="), popfirst!(tokens))
    val = parseOM(popfirst!(tokens), tokens)
    push!(res, (id.id, val))
    tok = popfirst!(tokens)
    while tok == Symbol(",")
      id = checkToken(Identifier, popfirst!(tokens))
      checkToken(Symbol("="), popfirst!(tokens))
      val = parseOM(popfirst!(tokens), tokens)
      push!(res, (id.id, val))
      tok = popfirst!(tokens)
    end
  end
  checkToken(:end, tok)
  checkToken(Identifier, popfirst!(tokens))
  checkToken(Symbol(";"), popfirst!(tokens))
  # Fixes the type of the dictionary
  if isempty(res)
    return Dict(res)
  end
  return Dict(collect(Base.tuple(res...)))
end

function parseOM(tokens::AbstractArray{Any,1})
  if length(tokens)==0
    return nothing
  end
  t = popfirst!(tokens)
  res = parseOM(t, tokens)
  if !isempty(tokens)
    throw(ParseError("Expected EOF, got output $tokens"))
  end
  res
end

function parseOM(str::String)
  parseOM(tokenize(str))
end

end
