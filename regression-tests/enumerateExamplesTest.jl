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

# Regression test for enumerateExamples.jl against a real omc + MSL 4.1.0.
# An earlier version of allExamplesPackages/mslAreasWithExamples only looked
# one level under `Modelica`, which silently missed every area where
# `Examples` sits one level deeper -- Electrical, Mechanics, Magnetic, Math,
# Thermal. This pins the areas and a couple of known models down so that
# regression does not go unnoticed again.
#
#   julia --project=regression-tests regression-tests/enumerateExamplesTest.jl

using Test
import OMJulia

include("enumerateExamples.jl")

@testset "enumerateExamples" begin
  omc = OMJulia.OMCSession()
  try
    @test OMJulia.sendExpression(omc, "loadModel(Modelica, {\"4.1.0\"})")

    areas = mslAreasWithExamples(omc)

    # Areas where `Examples` sits directly under `Modelica.<area>`.
    for area in ("Blocks", "Fluid", "Media", "StateGraph", "Clocked")
      @test area in areas
    end

    # Areas where `Examples` is one level deeper -- the case the one-level
    # version of this code missed entirely.
    for area in ("Electrical", "Mechanics", "Magnetic", "Math", "Thermal")
      @test area in areas
    end

    blocksModels = exampleModels(omc, "Blocks")
    @test "Modelica.Blocks.Examples.PID_Controller" in blocksModels
    @test length(blocksModels) > 30 # 38 at MSL 4.1.0; loose bound against churn

    electricalModels = exampleModels(omc, "Electrical")
    @test "Modelica.Electrical.Analog.Examples.CauerLowPassAnalog" in electricalModels
    # Nested one level deeper than Blocks.Examples -- the regression case.
    @test any(startswith(m, "Modelica.Electrical.Analog.Examples.") for m in electricalModels)
    @test any(startswith(m, "Modelica.Electrical.Machines.Examples.") for m in electricalModels)

    mechanicsModels = exampleModels(omc, "Mechanics")
    @test any(startswith(m, "Modelica.Mechanics.MultiBody.Examples.") for m in mechanicsModels)
    @test any(startswith(m, "Modelica.Mechanics.Rotational.Examples.") for m in mechanicsModels)
  finally
    OMJulia.quit(omc)
  end
end
