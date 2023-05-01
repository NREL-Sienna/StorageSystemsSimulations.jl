using Documenter
using PowerSystems
using StorageSystemsSimulations
using DataStructures

pages = OrderedDict(
    "Welcome Page" => "index.md",
    "Quick Start Guide" => "quick_start_guide.md",
    "Code Base Developer Guide" => Any[
        "Developer Guide" => "code_base_developer_guide/developer.md",
    ],
    "Formulation Library" => Any[
        "Storage" => "formulation_library/Storage.md",
    ],
    "API Reference" => "api/StorageSystemsSimulations.md",
)

makedocs(;
    modules = [StorageSystemsSimulations],
    format = Documenter.HTML(; prettyurls = haskey(ENV, "GITHUB_ACTIONS")),
    sitename = "StorageSystemsSimulations.jl",
    authors = "Sourabh Dalvi, Jose Daniel Lara",
    pages = Any[p for p in pages],
)

deploydocs(;
    repo = "github.com/NREL-Sienna/StorageSystemsSimulations.jl.git",
    target = "build",
    branch = "gh-pages",
    devbranch = "master",
    devurl = "dev",
    push_preview = true,
    versions = ["stable" => "v^", "v#.#"],
)
