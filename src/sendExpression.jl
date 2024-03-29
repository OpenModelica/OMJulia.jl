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

"""
    sendExpression(omc, expr; parsed=true)

Send API call to OpenModelica ZMQ server.
See [OpenModelica User's Guide Scripting API](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html)
for a complete list of all functions.

!!! note
    Some characters in argument `expr` need to be escaped.
    E.g. `"` becomes `\\"`.
    For example scripting API call
    
    ```modelica
    loadFile("/path/to/M.mo")
    ```
    
    will translate to
    
    ```julia
    sendExpression(omc, "loadFile(\\"/path/to/M.mo\\")")
    ```

!!! warn
    On Windows path separation symbol `\\` needs to be escaped `\\\\`
    or replaced to Unix style path `/` to prevent warnings.

    ```modelica
    loadFile("C:\\\\path\\\\to\\\\M.mo")
    ```

    translate to

    ```julia
    sendExpression(omc, "loadFile(\\"C:\\\\\\\\path\\\\\\\\to\\\\\\\\M.mo\\")")  # Windows
    sendExpression(omc, "loadFile(\\"/c/path/to/M.mo\\")")           # Windows
    ```

## Example

```julia
using OMJulia
omc = OMJulia.OMCSession()
OMJulia.sendExpression(omc, "getVersion()")
```
"""
function sendExpression(omc::OMCSession, expr::String; parsed=true)
    if !process_running(omc.zmqSession.omcprocess)
        return error("Process Exited, No connection with OMC. Create a new instance of OMCSession")
    end

    @debug "sending expression: $(expr)"
    ZMQ.Sockets.send(omc.zmqSession.socket, expr)
    @debug "Receiving message from ZMQ socket"
    message = ZMQ.Sockets.recv(omc.zmqSession.socket)
    @debug "Recieved message"
    if parsed
        return Parser.parseOM(unsafe_string(message))
    else
        return unsafe_string(message)
    end
end
