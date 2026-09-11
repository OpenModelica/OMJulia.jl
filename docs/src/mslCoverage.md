# MSL coverage

This page is regenerated automatically by the `publish-msl-coverage` job in
the [Nightly workflow](https://github.com/OpenModelica/OMJulia.jl/actions/workflows/Nightly.yml),
roughly every third day, from the `msl-coverage` matrix's per-area job
summaries. It has not run yet on this branch, so there is nothing to show.

Which model simulates through OMJulia is a moving target against an
unreleased compiler -- read this as a snapshot from the run it names, not a
promise. A model marked failing is not necessarily broken: the sweep cannot
tell a runnable example from a base class meant to be extended, so some
entries under `Examples` are expected to fail this way. See
[Tested application areas](index.md#Tested-application-areas) for what that
means and does not mean.
