# sendExpression

Start a new `OMCSession` and send
[scripting API](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html)
expressions to the omc session with `sendExpression()`.

```@docs
sendExpression
```

## Examples

```@repl
using OMJulia       # hide
omc = OMJulia.OMCSession()  # hide
version = OMJulia.sendExpression(omc, "getVersion()")
OMJulia.quit(omc)
```
