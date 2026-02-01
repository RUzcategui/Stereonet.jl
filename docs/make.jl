using Stereonet
using Documenter
using CairoMakie

CairoMakie.activate!(type = "png")

println("=== Starting documentation build ===")
println("Documenter version: ", pkgversion(Documenter))

# Generate tables BEFORE building docs
println("=== Generating tables ===")
include("generate_tables.jl")

DocMeta.setdocmeta!(Stereonet, :DocTestSetup, :(using Stereonet); recursive=true)

makedocs(
    modules=[Stereonet],
    authors="Redescal Uzcategui <redescaluzcategui@gmail.com>",
    sitename="Stereonet.jl",
    format=Documenter.HTML(;
        canonical="https://RUzcategui.github.io/Stereonet.jl",
        edit_link="main",
        assets = ["assets/custom.css"],
        inventory_version = "0.1", 
    ),
    pages=[
        "Home" => "index.md",
        "User Guide and Examples" => "guide_and_examples.md",
        "Work in progress and future directions" => "future_work.md",
        "API Reference" => "api.md",
    ],
)

deploydocs(;
    repo="github.com/RUzcategui/Stereonet.jl",
    devbranch="main",
)
