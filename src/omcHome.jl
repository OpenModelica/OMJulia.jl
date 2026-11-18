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

# Where to find OpenModelica if several versions are installed.
#
# The Windows installer keeps `OPENMODELICAHOME` for the version selected as the
# default one and sets `OPENMODELICAHOME_<version>` for each installed version,
# with every character of the version that is not a letter or a digit replaced by
# an underscore: version 1.27.0 is found via `OPENMODELICAHOME_1_27_0`.

const OMHOME_ENV = "OPENMODELICAHOME"
const OMHOME_ENV_VERSION_PREFIX = string(OMHOME_ENV, "_")

"""
    versionEnvName(version::AbstractString)::String

Name of the environment variable that holds the installation directory of an
OpenModelica version: `OPENMODELICAHOME_1_27_0` for `"1.27.0"`. A leading `v`
(as in the git tag `v1.27.0`) is ignored.
"""
function versionEnvName(version::AbstractString)::String
    version = strip(version)
    if occursin(r"^[vV][0-9]", version)
        version = version[2:end]
    end
    return string(OMHOME_ENV_VERSION_PREFIX, replace(version, r"[^0-9A-Za-z]" => "_"))
end

"""
Sort key for the names `OPENMODELICAHOME_<version>`; the newest version has the
highest key.

The version is `<major>_<minor>_<patch>` followed by nothing for a release
(`1_27_0`), by a pre-release part for a build before that release
(`1_28_0_dev_1962_g6e348e217c`) or by the number of commits for a build after
that release (`1_27_0_5_g0123456789`). For the same `<major>_<minor>_<patch>` a
pre-release is older than the release, which is older than a build after it; the
numbers that follow (e.g. the number of commits) decide between two builds of the
same kind.
"""
function versionSortKey(name::AbstractString)
    isnumber(part) = !isempty(part) && all(isdigit, part)
    parts = split(name[length(OMHOME_ENV_VERSION_PREFIX)+1:end], "_")
    numbers = Int[]
    while !isempty(parts) && isnumber(parts[1]) && length(numbers) < 3
        push!(numbers, parse(Int, popfirst!(parts)))
    end
    append!(numbers, zeros(Int, 3 - length(numbers)))

    kind = if isempty(parts)
        1 # release
    elseif isnumber(parts[1])
        2 # commits after the release
    else
        0 # dev, alpha, beta, rc, ...
    end
    return (numbers, kind, [parse(Int, part) for part in parts if isnumber(part)])
end

"Whether there is an omc executable in the installation directory `omhome`."
function hasOMC(omhome::AbstractString)::Bool
    return isfile(joinpath(omhome, "bin", "omc")) || isfile(joinpath(omhome, "bin", "omc.exe"))
end

"Path to the omc executable in the installation directory `omhome`."
function omcExecutable(omhome::AbstractString)::String
    omc = joinpath(omhome, "bin", "omc.exe")
    return isfile(omc) ? omc : joinpath(omhome, "bin", "omc")
end

"""
    installedVersions(env=ENV)::Vector{Pair{String, String}}

The OpenModelica installations registered as `OPENMODELICAHOME_<version>` in the
environment `env`, newest version first, as pairs of the name of the environment
variable and the installation directory. Variables which point to a directory
without an omc executable are left out.
"""
function installedVersions(env=ENV)::Vector{Pair{String, String}}
    versions = Pair{String, String}[]
    for (name, value) in env
        # the names of environment variables are case-insensitive on Windows
        if startswith(uppercase(name), OMHOME_ENV_VERSION_PREFIX) && !isempty(value) && hasOMC(value)
            push!(versions, String(name) => String(value))
        end
    end
    return sort!(versions; by = version -> versionSortKey(first(version)), rev = true)
end

"""
    versionOMC(version, versions)::String

Path to the omc executable of `version` among the installations `versions` (see
[`installedVersions`](@ref)): the one of `OPENMODELICAHOME_<version>`, or of the
newest `OPENMODELICAHOME_<version>...` if only the start of a version is given
(`"1.27"` for the newest 1.27.x). It is an error if that version is not
installed.
"""
function versionOMC(version::AbstractString, versions::Vector{Pair{String, String}})::String
    name = uppercase(versionEnvName(version))
    for (installed, omhome) in versions
        if uppercase(installed) == name
            return omcExecutable(omhome)
        end
    end
    # versions are sorted, newest first
    for (installed, omhome) in versions
        if startswith(uppercase(installed), string(name, "_"))
            return omcExecutable(omhome)
        end
    end
    installed = isempty(versions) ? "none" : join(first.(versions), ", ")
    error(string("Cannot find OpenModelica version \"$version\": no environment variable ",
                 "$name or $(name)_*. Installed versions: $installed"))
end

"""
    windowsDefaultOMC(env=ENV, versions=installedVersions(env))::Union{String, Nothing}

The omc executable that is started on Windows if neither an omc nor a version is
asked for: the one in `OPENMODELICAHOME`, else the one of the newest
`OPENMODELICAHOME_<version>`, else `nothing` for `omc` from `PATH`.

It only reads `env` and the file system, so it gives the same answer on every
platform; [`locateOMC`](@ref) calls it on Windows only.
"""
function windowsDefaultOMC(env=ENV, versions::Vector{Pair{String, String}}=installedVersions(env))::Union{String, Nothing}
    omhome = get(env, OMHOME_ENV, "")
    # Without versioned installations the path is used as it is, as it always
    # was. With them, a path left behind by an uninstalled version is skipped.
    if !isempty(omhome) && (isempty(versions) || hasOMC(omhome))
        return joinpath(omhome, "bin", "omc.exe")
    end
    if !isempty(versions)
        return omcExecutable(last(first(versions)))
    end
    return nothing
end

# The omc to start if neither an omc nor a version is asked for; the platform is
# known when the package is compiled.
@static if Sys.iswindows()
    defaultOMC(env) = windowsDefaultOMC(env)
else
    defaultOMC(env) = nothing
end

"""
    locateOMC(omc=nothing; version=nothing, env=ENV)::Union{String, Nothing}

Path to the omc executable to start, or `nothing` to start `omc` from `PATH`.
The first one that applies is used:

1. `omc`
2. `version`: `OPENMODELICAHOME_<version>`, or the newest
   `OPENMODELICAHOME_<version>...` if only the start of a version is given
   (`"1.27"` for the newest 1.27.x). It is an error if that version is not
   installed.
3. on Windows, `OPENMODELICAHOME`, if there is an omc executable in it
4. on Windows, the newest `OPENMODELICAHOME_<version>`
5. `omc` from `PATH`

On Linux and macOS `omc` from `PATH` is used unless `omc` or `version` is given.
"""
function locateOMC(omc::Union{AbstractString, Nothing}=nothing;
                   version::Union{AbstractString, Nothing}=nothing,
                   env=ENV)::Union{String, Nothing}
    if !isnothing(omc)
        return String(omc)
    end
    if !isnothing(version)
        return versionOMC(version, installedVersions(env))
    end
    return defaultOMC(env)
end
