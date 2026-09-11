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

# The one-model-per-process counterpart to runSingleTest.jl, minus the FMU
# export/import/diff -- the MSL sweep only asks "does it still simulate",
# across far more models than the curated FMU round-trip list, so it needs
# to be cheap per model. Runs out of process, like runSingleTest.jl, so one
# model hanging or crashing omc does not take the rest of the sweep with it.

import Pkg; Pkg.activate(@__DIR__)
import OMJulia

function runSimulateOnly(library, version, model, modeldir)
  mkpath(modeldir)
  omc = OMJulia.OMCSession()
  try
    OMJulia.API.cd(omc, modeldir)

    if !OMJulia.API.loadModel(omc, library; priorityVersion=[version], requireExactVersion=true)
      @error "Failed to load $library $version" errorString = OMJulia.sendExpression(omc, "getErrorString()")
      return 1
    end

    res = OMJulia.API.simulate(omc, model; outputFormat="csv")
    resultFile = get(res, "resultFile", "")
    if isfile(resultFile)
      return 0
    else
      @error "No result file for $model" res
      return 1
    end
  catch e
    @error "Exception simulating $model" exception = (e, catch_backtrace())
    return 1
  finally
    OMJulia.quit(omc)
  end
end

if !isempty(PROGRAM_FILE)
  if length(ARGS) == 4
    exit(runSimulateOnly(ARGS[1], ARGS[2], ARGS[3], ARGS[4]))
  else
    @error "Wrong number of arguments"
    for a in ARGS
      println(a)
    end
    exit(-1)
  end
end
