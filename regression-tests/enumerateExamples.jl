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

# A hand-maintained list of "the MSL models OMJulia covers" goes stale the
# moment MSL changes. These two queries ask omc instead, so the sweep tracks
# whatever Modelica version CI actually has installed.

import OMJulia

"""
Direct children of `Modelica` that themselves contain an `Examples` package,
e.g. "Blocks", "Electrical", "Fluid".
"""
function mslAreasWithExamples(omc::OMJulia.OMCSession)
  top = string.(OMJulia.sendExpression(omc,
      "getClassNames(Modelica, recursive=false, qualified=false, builtin=false, showProtected=false)"))

  areas = String[]
  for name in top
    children = try
      string.(OMJulia.sendExpression(omc,
          "getClassNames(Modelica.$(name), recursive=false, qualified=false, builtin=false, showProtected=false)"))
    catch
      String[]
    end
    if "Examples" in children
      push!(areas, name)
    end
  end
  return areas
end

"""
Fully qualified names of everything simulatable under `Modelica.<area>.Examples`
-- restriction `model` or `block`, and not `partial`. This is a blind sweep:
some non-partial classes under Examples exist to be extended rather than run
directly, and will show up here and then fail to simulate. That is the sweep
finding out, not a bug in the sweep.
"""
function exampleModels(omc::OMJulia.OMCSession, area::AbstractString)
  full = "Modelica.$(area).Examples"
  names = try
    string.(OMJulia.sendExpression(omc,
        "getClassNames($(full), recursive=true, qualified=true, builtin=false, showProtected=false)"))
  catch
    String[]
  end

  models = String[]
  for name in names
    restriction = try
      string(OMJulia.sendExpression(omc, "getClassRestriction($(name))"))
    catch
      ""
    end
    restriction in ("model", "block") || continue

    partial = try
      OMJulia.sendExpression(omc, "isPartial($(name))")
    catch
      true
    end
    partial && continue

    push!(models, name)
  end
  return models
end
