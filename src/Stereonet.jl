module Stereonet

using REPL
using LinearAlgebra: cross, norm, dot
using Statistics: mean
using Makie: linesegments!, text!, Circle, Figure, Axis, Point2f, DataAspect,
             hidedecorations!, hidespines!, current_backend, getscreen
import Makie: lines!, scatter!, poly!, save, display

include("stereonet_core.jl")
include("projections.jl")
include("geological_elements.jl")
include("net.jl")
include("makie_plots.jl")

export hemi, lineations!, traces!, smallc!, StereonetError,
       cartesian_coords, normal_vector, plane_basis, great_circle,
       small_circle, select_hemisphere, select_hemisphere_segments,
       xy_wulff, xy_schmidt, rotation_mat, change_view_direction,
       plane_coordinates, line_coordinates, small_circle_coords

end
