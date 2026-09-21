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

# publish-msl-coverage's "Build docs/src/mslCoverage.md" step: folds this
# run's per-area section files (downloaded from the msl-coverage matrix's
# artifacts) into the docs page, and appends this run's totals to the
# persisted history file so the page can show a trend across runs rather
# than only ever the latest snapshot. The history file already exists in
# the checkout this step runs in (a real committed file, not an artifact),
# so it round-trips across runs the same way any other tracked file does.
#
#   julia buildCoverageReport.jl <sections-dir> <history-csv> <output-md> \
#       <run-id> <run-url> <repo-url> [date=today, UTC]

include("coverageReport.jl")

length(ARGS) >= 6 || error("usage: buildCoverageReport.jl <sections-dir> <history-csv> <output-md> <run-id> <run-url> <repo-url> [date]")
sectionsDir, historyPath, outputPath, runId, runUrl, repoUrl = ARGS[1:6]
date = length(ARGS) >= 7 ? ARGS[7] : Dates.format(Dates.now(Dates.UTC), "yyyy-mm-dd")

sections = parseAllSections(sectionsDir)

history = loadHistory(historyPath)
history = appendHistory(history, historyRowsForRun(sections, runId, date), MAX_HISTORY_RUNS)
writeHistory(historyPath, history)

write(outputPath, renderPage(sections, history, runId, runUrl, repoUrl, date))
