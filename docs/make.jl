using HemiPlots
using Documenter

DocMeta.setdocmeta!(HemiPlots, :DocTestSetup, :(using HemiPlots); recursive=true)

makedocs(;
    modules=[HemiPlots],
    authors="Redescal Uzcategui <redescaluzcategui@gmail.com>",
    sitename="HemiPlots.jl",
    format=Documenter.HTML(;
        canonical="https://RUzcategui.github.io/HemiPlots.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/RUzcategui/HemiPlots.jl",
    devbranch="main",
)
