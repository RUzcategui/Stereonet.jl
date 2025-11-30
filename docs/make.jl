using HemiPlots
using Documenter

println("=== Starting documentation build ===")
println("Documenter version: ", pkgversion(Documenter))

DocMeta.setdocmeta!(HemiPlots, :DocTestSetup, :(using HemiPlots); recursive=true)

makedocs(;
    modules=[HemiPlots],
    authors="Redescal Uzcategui <redescaluzcategui@gmail.com>",
    sitename="HemiPlots.jl",
    format=Documenter.HTML(;
        canonical="https://RUzcategui.github.io/HemiPlots.jl",
        edit_link="main",
    ),
    pages=[
        "Home" => "index.md",
        "User Guide" => "guide.md",
        "Examples" => "examples.md",
        "API Reference" => "api.md" ,
    ],
)

deploydocs(;
    repo="github.com/RUzcategui/HemiPlots.jl",
    devbranch="main",
)
