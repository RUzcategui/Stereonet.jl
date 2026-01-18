"""
# HemiPlots.jl

HemiPlots is a lightweight plotting package for hemispherical stereonets
built on top of Makie.

The package provides tools to visualize planar and linear features,
small circles, and daylight envelopes on equal-angle or equal-area
stereonets, with full support for arbitrary viewing directions.

HemiPlots is **purely graphical**: it does not perform geological
interpretation, inversion, or statistical analysis. Higher-level methods
(e.g. stress inversion, misfit analysis, confidence regions) are expected
to live in separate packages built on top of HemiPlots.

## Design principles
- Projection-agnostic plotting (Wulff, Schmidt, etc.)
- View-direction aware rendering
- Minimal public API
- No assumptions about user intent

## Public API
From the HemiPlots side:
- `hemi`
- `smallc!`
- `daylight!`

Makie-compatible plotting:
- `lines!`
- `scatter!`
- `poly!`
- `save`

## Coordinate conventions
- Directions are given as `(trend, plunge)` in degrees
- The unit sphere uses **positive Z downward**
- All geometric objects are internally handled in Cartesian space

HemiPlots is intended for structural geology, rock mechanics,
engineering geology, and related fields where stereographic
visualization is required.
"""
module HemiPlots

#=

terminar los tests

terminar el manual

se usan todas las versiones de change_view_direction?

frame.jl y plot_recipe.jl, que no esta aqui, son para el rim, falta terminar

=#
 
using LinearAlgebra: cross, norm, dot
using Statistics: mean

using Makie: Circle, Figure, Axis, Point2f, Block, GridLayoutBase, get_topscene
using Makie: @recipe, DataAspect, hidedecorations!, hidespines!, current_backend

import Makie: lines!, scatter!, poly!, save, display

include("hemi_plots.jl") 
include("makie_plots.jl") 
include("frame.jl")
include("test_data.jl")

export hemi, smallc!, daylight!

export l1, l2, l3, w1, AF_004, cm1, cm2, cm3, dl, dp

export normal_vector, change_view_direction, change_view_direction, great_circle
export select_hemisphere, small_circle, daylight_coordinates

end