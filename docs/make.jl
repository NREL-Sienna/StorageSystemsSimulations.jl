using Documenter
using PowerSystems
using StorageSystemsSimulations
using DataStructures
using DocumenterInterLinks
using Literate

links = InterLinks(
    "PowerSimulations" => "https://nrel-sienna.github.io/PowerSimulations.jl/latest/",
)

# Function to clean up old generated files
function clean_old_generated_files(dir::String; remove_all_md::Bool=false)
    if !isdir(dir)
        @warn "Directory does not exist: $dir"
        return
    end
    if remove_all_md
        generated_files = filter(f -> endswith(f, ".md"), readdir(dir))
    else
        generated_files = filter(f -> startswith(f, "generated_") && endswith(f, ".md"), readdir(dir))
    end
    for file in generated_files
        rm(joinpath(dir, file), force=true)
        @info "Removed old generated file: $file"
    end
end

# Function to add download links to generated markdown
function add_download_links(content, jl_file, ipynb_file)
    download_section = """

*To follow along, you can download this tutorial as a [Julia script (.jl)](../$(jl_file)) or [Jupyter notebook (.ipynb)]($(ipynb_file)).*

"""
    m = match(r"^(#+ .+)$"m, content)
    if m !== nothing
        heading = m.match
        content = replace(content, r"^(#+ .+)$"m => heading * download_section, count=1)
    end
    return content
end

# Process tutorials with Literate
# Exclude helper scripts that start with "_"
tutorial_files = filter(x -> occursin(".jl", x) && !startswith(x, "_"), readdir("docs/src/tutorials"))
if !isempty(tutorial_files)
    tutorial_outputdir = joinpath(pwd(), "docs", "src", "tutorials", "generated")
    clean_old_generated_files(tutorial_outputdir; remove_all_md=true)
    mkpath(tutorial_outputdir)
    
    for file in tutorial_files
        @show file
        infile_path = joinpath(pwd(), "docs", "src", "tutorials", file)
        execute = occursin("EXECUTE = TRUE", uppercase(readline(infile_path))) ? true : false
        execute && include(infile_path)
        
        outputfile = replace("$file", ".jl" => "")
        
        # Generate markdown
        Literate.markdown(infile_path,
                          tutorial_outputdir;
                          name = outputfile,
                          credit = false,
                          flavor = Literate.DocumenterFlavor(),
                          documenter = true,
                          postprocess = (content -> add_download_links(content, file, string(outputfile, ".ipynb"))),
                          execute = execute)
        
        # Generate notebook
        Literate.notebook(infile_path,
                          tutorial_outputdir;
                          name = outputfile,
                          credit = false,
                          execute = false)
    end
end

pages = OrderedDict(
    "Welcome Page" => "index.md",
    "Tutorials" => Any[
        "Single State Model" => "tutorials/generated/single_stage_model.md",
        "Simulation Model" => "tutorials/generated/simulation_tutorial.md",
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
