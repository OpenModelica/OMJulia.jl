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

# Unlike enumerateExamplesTest.jl, this needs no omc and no MSL: everything
# coverageReport.jl does is text in, text out, so it is tested against
# synthetic section files instead.
#
#   julia --project=regression-tests regression-tests/coverageReportTest.jl

using Test

include("coverageReport.jl")

@testset "coverageReport" begin
  @testset "parseSection" begin
    mktempdir() do dir
      path = joinpath(dir, "section-Blocks.md")
      write(path, "## MSL coverage -- Modelica.Blocks.Examples: 36/38 simulate\n\n| Model | Status |\n|---|---|\n")
      s = parseSection(path)
      @test s.area == "Blocks"
      @test s.pass == 36
      @test s.total == 38
      @test occursin("| Model | Status |", s.body)
    end
  end

  @testset "parseSection rejects a malformed header" begin
    mktempdir() do dir
      path = joinpath(dir, "section-Bad.md")
      write(path, "not a coverage header\n")
      @test_throws ErrorException parseSection(path)
    end
  end

  @testset "parseAllSections sorts by area, missing dir is empty" begin
    mktempdir() do dir
      write(joinpath(dir, "section-Electrical.md"), "## MSL coverage -- Modelica.Electrical.Examples: 1/2 simulate\n")
      write(joinpath(dir, "section-Blocks.md"), "## MSL coverage -- Modelica.Blocks.Examples: 2/2 simulate\n")
      write(joinpath(dir, "not-a-section.txt"), "ignored")
      sections = parseAllSections(dir)
      @test [s.area for s in sections] == ["Blocks", "Electrical"]
    end

    @test parseAllSections(joinpath(mktempdir(), "missing")) == NamedTuple[]
  end

  @testset "historyRowsForRun adds a TOTAL row" begin
    sections = [(area="Blocks", pass=2, total=2, body=""), (area="Electrical", pass=1, total=2, body="")]
    rows = historyRowsForRun(sections, "100", "2026-01-01")
    @test length(rows) == 3
    total = only(filter(r -> r.area == TOTAL_AREA, rows))
    @test (total.pass, total.total) == (3, 4)
    @test all(r.run_id == "100" && r.date == "2026-01-01" for r in rows)
  end

  @testset "history round-trips through the CSV file" begin
    mktempdir() do dir
      path = joinpath(dir, "history.csv")
      @test loadHistory(path) == NamedTuple[] # no file yet

      rows = [(run_id="1", date="2026-01-01", area="Blocks", pass=2, total=2)]
      writeHistory(path, rows)
      loaded = loadHistory(path)
      @test length(loaded) == 1
      @test loaded[1] == rows[1]
    end
  end

  @testset "appendHistory caps to the most recent run ids, oldest dropped first" begin
    history = [(run_id=string(i), date="2026-01-0$(i)", area=TOTAL_AREA, pass=i, total=10) for i in 1:5]
    newRows = [(run_id="6", date="2026-01-06", area=TOTAL_AREA, pass=6, total=10)]
    capped = appendHistory(history, newRows, 3)
    @test [r.run_id for r in capped] == ["4", "5", "6"]
  end

  @testset "appendHistory tolerates out-of-order input" begin
    # Not expected in practice (rows are only ever appended), but sorting by
    # run id rather than trusting file order should still cap to the newest.
    history = [(run_id="3", date="2026-01-03", area=TOTAL_AREA, pass=3, total=10),
               (run_id="1", date="2026-01-01", area=TOTAL_AREA, pass=1, total=10)]
    newRows = [(run_id="2", date="2026-01-02", area=TOTAL_AREA, pass=2, total=10)]
    capped = appendHistory(history, newRows, 2)
    @test [r.run_id for r in capped] == ["2", "3"]
  end

  @testset "pct" begin
    @test pct(0, 0) == "-"
    @test pct(1, 2) == "50.0%"
    @test pct(3, 4) == "75.0%"
  end

  @testset "sparkline" begin
    @test sparkline(Float64[]) == ""
    @test sparkline([0.0]) == string(SPARK_CHARS[1])
    @test sparkline([100.0]) == string(SPARK_CHARS[end])
    @test length(sparkline([0.0, 50.0, 100.0])) == 3
  end

  @testset "renderPage includes the summary, history and every area section" begin
    sections = [(area="Blocks", pass=2, total=2, body="## MSL coverage -- Modelica.Blocks.Examples: 2/2 simulate"),
                (area="Electrical", pass=1, total=2, body="## MSL coverage -- Modelica.Electrical.Examples: 1/2 simulate")]
    history = appendHistory(NamedTuple[], historyRowsForRun(sections, "42", "2026-01-01"), MAX_HISTORY_RUNS)
    page = renderPage(sections, history, "42", "https://example/runs/42", "https://example", "2026-01-01")

    @test occursin("# MSL coverage", page)
    @test occursin("## Summary", page)
    @test occursin("3/4 models simulate (75.0%) across 2 areas.", page)
    @test occursin("| Blocks | 2/2 | 100.0% |", page)
    @test occursin("Not enough history yet to show a trend.", page) # only one run so far
    @test occursin("[42](https://example/actions/runs/42)", page) # history table links via repoUrl, not runUrl
    @test occursin("## MSL coverage -- Modelica.Blocks.Examples: 2/2 simulate", page)
    @test occursin("## MSL coverage -- Modelica.Electrical.Examples: 1/2 simulate", page)
  end

  @testset "renderPage shows a trend once there is more than one run" begin
    sections = [(area="Blocks", pass=2, total=2, body="## MSL coverage -- Modelica.Blocks.Examples: 2/2 simulate")]
    history = NamedTuple[]
    history = appendHistory(history, historyRowsForRun(sections, "1", "2026-01-01"), MAX_HISTORY_RUNS)
    history = appendHistory(history, historyRowsForRun(sections, "2", "2026-01-02"), MAX_HISTORY_RUNS)
    page = renderPage(sections, history, "2", "https://example/runs/2", "https://example", "2026-01-02")

    @test occursin("Total pass rate, oldest to newest:", page)
    @test occursin("| 2026-01-02 | [2]", page)
    @test occursin("| 2026-01-01 | [1]", page)
  end

  @testset "renderPage with no sections at all" begin
    page = renderPage(NamedTuple[], NamedTuple[], "1", "https://example/runs/1", "https://example", "2026-01-01")
    @test occursin("_No area summaries were produced by this run._", page)
    @test occursin("_No prior runs recorded yet._", page)
  end
end
