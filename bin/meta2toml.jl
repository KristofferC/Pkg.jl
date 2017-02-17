#!/usr/bin/env julia

using SHA
# using TOML # not the registered one, but https://github.com/StefanKarpinski/TOML.jl
using Base.Random: UUID

function uuid5(namespace::UUID, key::String)
    data = [reinterpret(UInt8, [namespace.value]); Vector{UInt8}(key)]
    u = reinterpret(UInt128, sha1(data)[1:16])[1]
    u &= 0xffffffffffff0fff3fffffffffffffff
    u |= 0x00000000000050008000000000000000
    return UUID(u)
end

const uuid_dns = UUID(0x6ba7b810_9dad_11d1_80b4_00c04fd430c8)
const uuid_julia = uuid5(uuid_dns, "julialang.org")

const dir = length(ARGS) >= 1 ? ARGS[1] : Pkg.dir("METADATA")
const names = sort!(readdir(dir), by=lowercase)
const packages = Dict()

for (i, pkg) in enumerate(names)
    path = joinpath(dir, pkg)
    urlf = joinpath(path, "url")
    vers = joinpath(path, "versions")
    isfile(urlf) && isdir(vers) || continue
    versions = sort!(readdir(vers), by=VersionNumber)
    isempty(versions) && continue
    # we should emit a package entry
    url = readchomp(urlf)
    uuid = uuid5(uuid_julia, pkg)
    println("""
    [$pkg]
    uuid = "$uuid"
    repository = "$url"
    """)
    for (j, v) in enumerate(versions)
        verd = joinpath(vers, v)
        sha1f = joinpath(verd, "sha1")
        isfile(sha1f) || continue
        sha1 = readchomp(sha1f)
        println("""
            [[$pkg.version]]
            version = "$v"
            SHA1 = "$sha1"
        """)
    end
end
