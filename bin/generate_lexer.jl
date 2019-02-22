# Generate a Lexer for OpenModelica output (Values.Value)
# =====================================================================

import Automa
import Automa.RegExp: @re_str
import MacroTools
const re = Automa.RegExp

# Describe patterns in regular expression.
t     = re"[tT][rR][uU][eE]"
f     = re"[fF][aA][lL][sS][eE]"
string   = re"\"([^\"\\x5c]|(\\x5c.))*\""
ident    = re"[_A-Za-z][_A-Za-z0-9]*|'([^'\\x5c]|(\\x5c.))+'"
int      = re"[-+]?[0-9]+"
prefloat = re"[-+]?([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)"
float    = prefloat | re.cat(prefloat | re"[-+]?[0-9]+", re"[eE][-+]?[0-9]+")
operator = re"[={}(),;]|end"
number   = int | float
ws       = re"[ ]+"
omtoken  = number | string | ident | operator
omtokens = re.opt(ws) * re.rep(omtoken * re.opt(ws))

# Compile a finite-state machine.
tokenizer = Automa.compile(
  t => :(emit(true)),
  f => :(emit(false)),
  operator => :(emit(Symbol(data[ts:te]))),
  re"record" => :(emit(Record())),
  string => :(emit(unescape_string(data[ts+1:te-1]))),
  ident => :(emit(Identifier(unescape_string(data[ts:te])))), # Should this be a symbol instead?
  int => :(emit(parse(Int, data[ts:te]))),
  float => :(emit(parse(Float64, data[ts:te]))),
  re"[\n\t ]" => :(),
  re"." => :(failed = true)
)

# Generate a tokenizing function from the machine.
ctx = Automa.CodeGenContext()
init_code = MacroTools.prettify(Automa.generate_init_code(ctx, tokenizer))
exec_code = MacroTools.prettify(Automa.generate_exec_code(ctx, tokenizer))

write(open("src/lexer.jl","w"), """# Generated Lexer for OpenModelica Values.Value output

function tokenize(data::String)
  $(init_code)
  p_end = p_eof = sizeof(data)
  failed = false
  tokens = Any[]
  emit(tok) = push!(tokens, tok)
  while p ≤ p_eof && cs > 0
    $(exec_code)
  end
  if cs < 0 || failed
    throw(LexerError("Error while lexing"))
  end
  if p < p_eof
    throw(LexerError("Did not scan until end of file. Remaining: \$(data[p:p_eof])"))
  end
  return tokens
end
""")
