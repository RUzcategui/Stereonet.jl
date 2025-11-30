 module HemiPlots

#Archivos y funciones que deben estar
#el la version final 
include("nets_coordinates.jl") 
export stereonet_coordinates

#Archivos y funciones solo para la version dev
#el la version final 

export great_circles_grid
export slickenline_vector,  change_view_direction, rotation_mat
export cartesian_from_trend_plunge, trend_plunge_from_cartesian
end

