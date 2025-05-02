using Documenter
using PowerSystems
using StorageSystemsSimulations
using DataStructures
using DocumenterInterLinks

links = InterLinks(
    "PowerSimulations" => "https://nrel-sienna.github.io/PowerSimulations.jl/latest/",
)

pages = OrderedDict(
    "Welcome Page" => "index.md",
    "Tutorials" => Any[
        "Single State Model" => "tutorials/single_stage_model.md",
        "Simulation Model" => "tutorials/simulation_tutorial.md",
    ],
    # TODO Add sections here once there is content
    # "Explanation" => "explanation/stub.md",
    # "How-to-Guides" => "how_to/stub.md",
    "Reference" => Any[
        "Formulation Library" => [
            "Storage Dispatch with Reserves" => "reference/StorageDispatchWithReserves.md",
        ],
        "Public API" => "reference/public.md",
        "Developers" => [
            "Developer Guidelines" => "reference/developer_guidelines.md",
            "Internals" => "reference/internal.md",
        ],
    ],
)

makedocs(;
    modules=[StorageSystemsSimulations],
    format=Documenter.HTML(; prettyurls=haskey(ENV, "GITHUB_ACTIONS")),
    sitename="StorageSystemsSimulations.jl",
    authors="Jose Daniel Lara, Rodrigo Henriquez-Auba, Sourabh Dalvi",
    pages=Any[p for p in pages],
    plugins=[links],
)

deploydocs(;
    repo="github.com/NREL-Sienna/StorageSystemsSimulations.jl.git",
    target="build",
    branch="gh-pages",
    devbranch="main",
    devurl="dev",
    push_preview=true,
    versions=["stable" => "v^", "v#.#"],
)
