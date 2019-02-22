module Parser

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

include("memory.jl")
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
  if (tok == last)
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
  if (length(tokens)==0)
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
