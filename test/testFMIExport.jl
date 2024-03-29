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

using Test
import OMJulia

@testset "testFMIExport" begin
    workdir = abspath(joinpath(@__DIR__, "test_fmi_export"))
    rm(workdir, recursive=true, force=true)
    mkpath(workdir)

    mod = OMJulia.OMCSession()
    OMJulia.ModelicaSystem(mod, modelName="Modelica.Electrical.Analog.Examples.CauerLowPassAnalog", library="Modelica")
    fmu1 = OMJulia.convertMo2FMU(mod)
    @test isfile(fmu1)

    OMJulia.ModelicaSystem(mod, modelName="Modelica.Fluid.Examples.DrumBoiler.DrumBoiler", library="Modelica")
    fmu2 = OMJulia.convertMo2FMU(mod)
    @test isfile(fmu2)

    OMJulia.quit(mod)
end
