#=
This file is part of OpenModelica.
Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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
omc process error
"""
struct OMCError <: Exception
    cmd::Cmd
    stdout_file::Union{String, Missing}
    stderr_file::Union{String, Missing}

    function OMCError(cmd, stdout_file=missing, stderr_file=missing)
        new(cmd, stdout_file, stderr_file)
    end
end
"""
Show error from log files
"""
function Base.showerror(io::IO, e::OMCError)
    println(io, "OMCError ")
    println(io, "Command $(e.cmd) failed")
    if !ismissing(e.stdout_file)
        println(io,  read(e.stdout_file, String))
        rm(e.stdout_file, force=true)
    end
    if !ismissing(e.stdout_file)
        print(io, read(e.stderr_file, String))
        rm(e.stderr_file, force=true)
    end
end

"""
Timeout error
"""
struct TimeoutError <: Exception
    msg::String
end
function Base.showerror(io::IO, e::TimeoutError)
  println(io, "TimeoutError")
  print(e.msg)
end
