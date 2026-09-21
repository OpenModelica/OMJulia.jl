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

# Pure functions behind buildCoverageReport.jl: parse each shard's section
# file, aggregate a run's total, and fold it into a small persisted history
# so docs/src/mslCoverage.md can show a trend instead of just one run's
# snapshot. Kept separate from the driver script (same split as
# enumerateExamples.jl / areaCoverageReport.jl) so this is unit-testable
# with synthetic section files -- no omc, no network.
#
# Only Base and the Dates stdlib are used here on purpose: this step of the
# workflow has nothing to do with OMJulia or omc, so it should not need to
# set either up.

import Dates

# How many nightly runs' totals to keep in the history file. At the every-
# third-day cadence that is roughly six months -- long enough to see a
# trend, short enough that the file and the PR diff stay small. Tune freely;
# nothing else depends on this number.
const MAX_HISTORY_RUNS = 60

# How many of the kept runs to show in the rendered history table. The
# sparkline above it still uses the full retained history.
const HISTORY_TABLE_ROWS = 10

const HISTORY_HEADER = "run_id,date,area,pass,total"

# Sentinel area name for the cross-area row appended alongside each run's
# per-area rows. Real MSL area names are Modelica package names, so this
# can't collide with one.
const TOTAL_AREA = "TOTAL"

const SPARK_CHARS = collect("▁▂▃▄▅▆▇█")

"""
One area shard's result, parsed back out of the section file
areaCoverageReport.jl wrote: header line for the numbers, full text kept
verbatim as `body` so it can be reused unchanged in the assembled page.
"""
function parseSection(path::AbstractString)
  text = read(path, String)
  m = match(r"^## MSL coverage -- Modelica\.(.+)\.Examples: (\d+)/(\d+) simulate", text)
  m === nothing && error("$(path): does not start with the expected 'MSL coverage' header line")
  return (area=String(m.captures[1]), pass=parse(Int, m.captures[2]), total=parse(Int, m.captures[3]), body=text)
end

"""
Every `section-*.md` file in `dir`, parsed and sorted by area name so the
page's area order does not depend on filesystem/artifact-download order.
"""
function parseAllSections(dir::AbstractString)
  isdir(dir) || return NamedTuple[]
  files = filter(f -> endswith(f, ".md"), readdir(dir; join=true))
  sort([parseSection(f) for f in files], by=s -> s.area)
end

"""
This run's history rows: one per area plus a `TOTAL_AREA` row summing all
of them, so the history file can show both the per-area and the aggregate
trend without two separate files.
"""
function historyRowsForRun(sections, runId::AbstractString, date::AbstractString)
  rows = [(run_id=runId, date=date, area=s.area, pass=s.pass, total=s.total) for s in sections]
  push!(rows, (run_id=runId, date=date, area=TOTAL_AREA,
               pass=sum(s.pass for s in sections; init=0),
               total=sum(s.total for s in sections; init=0)))
  return rows
end

# Deliberately hand-rolled rather than CSV.jl: every field is a run id, an
# ISO date, an area name or an integer -- none of which can contain a comma
# or a quote -- so a real CSV parser buys nothing here.
function loadHistory(path::AbstractString)
  isfile(path) || return NamedTuple[]
  lines = readlines(path)
  rows = NamedTuple[]
  for line in Iterators.drop(lines, 1) # skip header
    isempty(line) && continue
    f = split(line, ",")
    push!(rows, (run_id=f[1], date=f[2], area=f[3], pass=parse(Int, f[4]), total=parse(Int, f[5])))
  end
  return rows
end

function writeHistory(path::AbstractString, rows)
  open(path, "w") do io
    println(io, HISTORY_HEADER)
    for r in rows
      println(io, "$(r.run_id),$(r.date),$(r.area),$(r.pass),$(r.total)")
    end
  end
end

"""
Append this run's rows to the loaded history and cap it to the most recent
`maxRuns` distinct run ids -- otherwise the file, and the diff
create-pull-request proposes every three days, grows without bound. Sorted
by run id (numeric, monotonically increasing on GitHub Actions) rather than
trusting file order, so a hand-edited or out-of-order history still caps to
the right end.
"""
function appendHistory(history, newRows, maxRuns::Integer)
  combined = sort(vcat(history, newRows), by=r -> parse(Int, r.run_id))
  runIds = unique(r.run_id for r in combined)
  keep = Set(runIds[max(1, end - maxRuns + 1):end])
  return filter(r -> r.run_id in keep, combined)
end

# "-" rather than dividing by zero for an area with no simulatable models at
# all (an empty Examples package, or a shard that produced nothing).
pct(pass::Integer, total::Integer) = total == 0 ? "-" : string(round(100 * pass / total; digits=1), "%")

"""
One block character per value (0..100), for a compact "how has this moved"
line in plain markdown -- no charting library, this is the ceiling of
fanciness a Documenter.jl page gets. Empty input renders as the empty
string; callers that want a placeholder for "not enough history yet" check
for that themselves.
"""
function sparkline(percentages)
  isempty(percentages) && return ""
  levels = length(SPARK_CHARS)
  join(SPARK_CHARS[clamp.(round.(Int, percentages ./ 100 .* (levels - 1)) .+ 1, 1, levels)])
end

totalsInOrder(history) = sort(filter(r -> r.area == TOTAL_AREA, history), by=r -> parse(Int, r.run_id))

function renderAreaTable(sections, history)
  lines = ["| Area | Pass/Total | % | Trend |", "|---|---|---|---|"]
  for s in sections
    areaHistory = sort(filter(r -> r.area == s.area, history), by=r -> parse(Int, r.run_id))
    trend = sparkline([100 * r.pass / max(r.total, 1) for r in areaHistory])
    push!(lines, "| $(s.area) | $(s.pass)/$(s.total) | $(pct(s.pass, s.total)) | $(trend) |")
  end
  join(lines, "\n")
end

function renderHistoryTable(history, repoUrl::AbstractString)
  totals = totalsInOrder(history)
  isempty(totals) && return "_No prior runs recorded yet._"
  shown = reverse(totals[max(1, end - HISTORY_TABLE_ROWS + 1):end]) # newest first
  lines = ["| Date | Run | Pass/Total | % |", "|---|---|---|---|"]
  for r in shown
    push!(lines, "| $(r.date) | [$(r.run_id)]($(repoUrl)/actions/runs/$(r.run_id)) | $(r.pass)/$(r.total) | $(pct(r.pass, r.total)) |")
  end
  join(lines, "\n")
end

"""
Assemble the full docs/src/mslCoverage.md content: preamble, an aggregate
summary and history for this run, then every area's section verbatim.
`history` must already include this run's own rows (the caller appends
before rendering) so the summary's trend line and table are current.
"""
function renderPage(sections, history, runId::AbstractString, runUrl::AbstractString, repoUrl::AbstractString, date::AbstractString)
  io = IOBuffer()
  println(io, "# MSL coverage")
  println(io)
  println(io, "Generated by [Nightly run $(runId)]($(runUrl)) against the nightly omc build, on $(date).")
  println(io)
  println(io, "Which model simulates through OMJulia is a moving target against an unreleased compiler -- read this as that run's snapshot, not a promise. A model marked failing is not necessarily broken: the sweep cannot tell a runnable example from a base class meant to be extended, so some entries under `Examples` are expected to fail this way. See [Tested application areas](index.md#Tested-application-areas) for what that means and does not mean.")
  println(io)
  println(io, "## Summary")
  println(io)
  if isempty(sections)
    println(io, "_No area summaries were produced by this run._")
  else
    totalPass = sum(s.pass for s in sections)
    totalTotal = sum(s.total for s in sections)
    println(io, "**$(totalPass)/$(totalTotal) models simulate ($(pct(totalPass, totalTotal))) across $(length(sections)) areas.**")
    println(io)
    println(io, renderAreaTable(sections, history))
  end
  println(io)
  println(io, "### History")
  println(io)
  trendPcts = [100 * r.pass / max(r.total, 1) for r in totalsInOrder(history)]
  if length(trendPcts) <= 1
    println(io, "Not enough history yet to show a trend.")
  else
    println(io, "Total pass rate, oldest to newest: `$(sparkline(trendPcts))`")
    println(io)
  end
  println(io, renderHistoryTable(history, repoUrl))
  println(io)
  for s in sections
    println(io, s.body)
    println(io)
  end
  return String(take!(io))
end
