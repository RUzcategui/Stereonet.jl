"""
# HemiPlots.jl
HemiPlots.jl is a plotting package for visualizing three-dimensional
orientation data on two-dimensional nets (e.g. equal-angle
and equal-area projections) using Makie.
"""
module HemiPlots

using LinearAlgebra: cross, norm, dot
using Statistics: mean

using Makie: linesegments!, text!, Circle, Figure, Axis, Point2f, Block, GridLayoutBase, get_topscene
using Makie: @recipe, DataAspect, hidedecorations!, hidespines!, current_backend

import Makie: color, lines!, scatter!, poly!, save, display

include("hemiplots_functions.jl") 
include("makie_plots.jl") 
include("frame.jl")

export hemi, smallc!
end