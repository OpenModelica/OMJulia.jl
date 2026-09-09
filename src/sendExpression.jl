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

"""
How long to block in a single `recv` before looking up to check on omc, in
milliseconds. This is not a timeout on the call: a slow API call simply goes
around the loop again. It only bounds how long we can sit in an unreturnable
`recv` after omc is already gone.
"""
const RECEIVE_POLL_INTERVAL_MS = 500

"""
    receiveMessage(omc, expr, timeout)

Wait for omc's reply to `expr`.

`ZMQ.recv` on its own blocks forever, so an omc that dies mid-call -- or never
answers -- hangs the caller with no way out but killing Julia. Poll instead,
and between polls check that omc is still alive.

`timeout` in seconds puts a hard cap on the wait; `nothing` waits as long as
omc is running, which is what a long `simulate` needs.
"""
function receiveMessage(omc::OMCSession, expr::AbstractString, timeout::Union{Real, Nothing})
    socket = omc.zmqSession.socket
    previousTimeout = socket.rcvtimeo
    deadline = isnothing(timeout) ? nothing : time() + timeout
    try
        while true
            # Never block past the caller's deadline. Polling on a fixed
            # interval rounded every shorter timeout up to it, so a small
            # `timeout` gave up late, or -- if omc answered inside the first
            # poll -- not at all.
            poll = RECEIVE_POLL_INTERVAL_MS
            if !isnothing(deadline)
                remaining = (deadline - time()) * 1000
                if remaining <= 0
                    error("No reply from omc for `$(expr)` after $(timeout) s. " *
                          "omc is still running, so it may just be slow -- pass a " *
                          "larger `timeout`, or `nothing` to wait indefinitely.")
                end
                poll = min(poll, max(1, ceil(Int, remaining)))
            end
            socket.rcvtimeo = poll
            try
                return ZMQ.Sockets.recv(socket)
            catch err
                err isa ZMQ.TimeoutError || rethrow()
                if !process_running(omc.zmqSession.omcprocess)
                    error("omc exited while waiting for a reply to `$(expr)`. " *
                          "The session is dead; create a new OMCSession. " *
                          "See the omc stdout/stderr logs for why it stopped.")
                end
                if !isnothing(deadline) && time() >= deadline
                    error("No reply from omc for `$(expr)` after $(timeout) s. " *
                          "omc is still running, so it may just be slow -- pass a " *
                          "larger `timeout`, or `nothing` to wait indefinitely.")
                end
            end
        end
    finally
        socket.rcvtimeo = previousTimeout
    end
end

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
function sendExpression(omc::OMCSession, expr::String; parsed=true, timeout::Union{Real, Nothing}=nothing)
    if !process_running(omc.zmqSession.omcprocess)
        return error("Process Exited, No connection with OMC. Create a new instance of OMCSession")
    end

    @debug "sending expression: $(expr)"
    ZMQ.Sockets.send(omc.zmqSession.socket, expr)
    @debug "Receiving message from ZMQ socket"
    message = receiveMessage(omc, expr, timeout)
    @debug "Recieved message"
    if parsed
        return Parser.parseOM(unsafe_string(message))
    else
        return unsafe_string(message)
    end
end
