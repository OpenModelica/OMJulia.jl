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

# Check that src/lexer.jl still matches the grammar in bin/generate_lexer.jl.
#
#     julia --project=bin bin/check_lexer.jl
#
# Automa numbers the states of the generated machine differently from run to
# run, so regenerating and diffing the file textually reports spurious changes.
# Instead regenerate into a scratch copy and compare what the two lexers
# actually do, over a corpus covering every token kind.

const ROOT = normpath(joinpath(@__DIR__, ".."))
const LEXER = joinpath(ROOT, "src", "lexer.jl")

const CORPUS = [
  "", " ", "\n\t ",
  "123", "-3", "+4", "123.0", "1.", ".2", "1e3", "1e+2", "1.5e-3",
  "tRuE", "false", "TRUE", "FaLsE",
  "\"abc\"", "\"ab\\nc\"", "\"a\\\"b\"", "\"\"",
  "abc_2", "_x", "ending", "recorder", "falsy", "truex", "end",
  "'quoted id'", "'q.x'.y",
  "Modelica.Blocks", "Modelica.Blocks.Examples.PID_Controller",
  "{}", "{1}", "{1,2,3}", "{\"abc\"}", "{a,b}", "( 1 , 2 )",
  "NONE()", "SOME(1)", "{NONE(),SOME(2)}",
  "record ABC end ABC;", "record ABC a = 1, 'b' = 2,\n  c = 3\nend ABC;",
  "{Modelica.Blocks, Modelica.Math}",
  "@bad@", "\"unterminated", "1..2",
]

function load_lexer(path::String, name::Symbol)
  mod = Module(name)
  Core.eval(mod, quote
    struct Identifier; id::String; end
    struct Record; end
    struct LexerError <: Exception; errmsg::AbstractString; end
    import Automa
    using Automa: Tokenizer
  end)
  Base.include(mod, path)
  return mod
end

strip_mod(s::String, mod::Module) =
  replace(s, "Main." * string(nameof(mod)) * "." => "", string(nameof(mod)) * "." => "")

function results(mod::Module)
  map(CORPUS) do s
    try
      strip_mod(string(Base.invokelatest(Base.invokelatest(Base.getglobal, mod, :tokenize), s)), mod)
    catch e
      "ERROR " * strip_mod(string(typeof(e)), mod)
    end
  end
end

committed = read(LEXER, String)
scratch = tempname() * ".jl"
write(scratch, committed)

try
  include(joinpath(@__DIR__, "generate_lexer.jl"))
  regenerated = read(LEXER, String)

  old = results(load_lexer(scratch, :Committed))
  new = results(load_lexer(LEXER, :Regenerated))

  diffs = [(s, o, n) for (s, o, n) in zip(CORPUS, old, new) if o != n]
  if isempty(diffs)
    println("src/lexer.jl is up to date ($(length(CORPUS)) inputs agree).")
  else
    println(stderr, "src/lexer.jl is out of date with bin/generate_lexer.jl:\n")
    for (s, o, n) in diffs
      println(stderr, "  input:     ", repr(s))
      println(stderr, "    committed:   ", o)
      println(stderr, "    regenerated: ", n)
    end
    println(stderr, "\nRun 'julia --project=bin bin/generate_lexer.jl' and commit src/lexer.jl.")
    exit(1)
  end
finally
  write(LEXER, committed)   # leave the working tree as we found it
  rm(scratch, force = true)
end
