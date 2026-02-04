module Stereonet

using LinearAlgebra: cross, norm, dot
using Statistics: mean

using Makie: linesegments!, text!, Circle, Figure, Axis, Point2f, Block, GridLayoutBase, get_topscene
using Makie: @recipe, DataAspect, hidedecorations!, hidespines!, current_backend

import Makie: color, lines!, scatter!, poly!, save, display

include("stereonet_functions.jl") 
include("makie_plots.jl") 
include("frame.jl")

export lines!, scatter!, hemi, smallc!

end