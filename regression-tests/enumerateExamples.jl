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
# moment MSL changes. These queries ask omc instead, so the sweep tracks
# whatever Modelica version CI actually has installed.

import OMJulia

"""
Fully qualified names of every `Examples` package anywhere under `Modelica`,
at any depth -- checked against a real omc + MSL 4.1.0: `Examples` sits
directly under some areas (`Modelica.Blocks.Examples`) and one level deeper
under others (`Modelica.Electrical.Analog.Examples`,
`Modelica.Mechanics.MultiBody.Examples`). An earlier version of this file
only looked one level down and silently missed Electrical, Mechanics,
Magnetic, Math and Thermal entirely.
"""
function allExamplesPackages(omc::OMJulia.OMCSession)
  all = string.(OMJulia.sendExpression(omc,
      "getClassNames(Modelica, recursive=true, qualified=true, builtin=false, showProtected=false)"))
  return filter(name -> endswith(name, ".Examples"), all)
end

"""
Direct children of `Modelica` that have an `Examples` package somewhere
beneath them, e.g. "Blocks", "Electrical", "Mechanics" -- the areas the
Nightly workflow's msl-coverage matrix shards over.
"""
function mslAreasWithExamples(omc::OMJulia.OMCSession)
  packages = allExamplesPackages(omc)
  areas = unique(String(split(p, ".")[2]) for p in packages)
  return sort(areas)
end

"""
Fully qualified names of everything simulatable under any `Modelica.<area>.*
.Examples` package -- restriction `model` or `block`, and not `partial`.
This is a blind sweep: some non-partial classes under Examples exist to be
extended rather than run directly, and will show up here and then fail to
simulate. That is the sweep finding out, not a bug in the sweep.
"""
function exampleModels(omc::OMJulia.OMCSession, area::AbstractString)
  packages = filter(p -> split(p, ".")[2] == area, allExamplesPackages(omc))

  models = String[]
  for pkg in packages
    names = try
      string.(OMJulia.sendExpression(omc,
          "getClassNames($(pkg), recursive=true, qualified=true, builtin=false, showProtected=false)"))
    catch
      String[]
    end

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
  end
  return models
end
