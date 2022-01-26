using Permutations
using Documenter

DocMeta.setdocmeta!(Permutations, :DocTestSetup, :(using Permutations); recursive=true)

makedocs(;
    modules=[Permutations],
    authors="Ed Scheinerman and contributors",
    repo="https://github.com/gdalle/Permutations.jl/blob/{commit}{path}#{line}",
    sitename="Permutations.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://gdalle.github.io/Permutations.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/gdalle/Permutations.jl",
    devbranch="master",
)
