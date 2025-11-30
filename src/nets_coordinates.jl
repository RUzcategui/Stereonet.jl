struct CartesianCoords
    matrix::Matrix{<:Real}
end

struct SphericalCoords
    matrix::Matrix{<:Real}
end

function select_net_equation(net::Symbol)
    
    net == :wulff && return xy_wulff
    net == :schmidt && return xy_schmidt
    
end

function xy_wulff(coords::CartesianCoords)
    matrix = coords.matrix
    denom = @view(matrix[:,3]) .+ 1  # Avoid allocation for denominator
    x_new = @view(matrix[:,2]) ./ denom
    y_new = @view(matrix[:,1]) ./ denom
    hcat(x_new, y_new)
end

function xy_schmidt(coords::CartesianCoords)
    matrix = coords.matrix
    x, y, z = matrix[:, 1], matrix[:, 2], matrix[:, 3]
    denominator = 1 .+ z
    u = sqrt.(1 ./ denominator) .* y
    v = sqrt.(1 ./ denominator) .* x
    
    return hcat(u, v)
end

"""
    trend_plunge_from_cartesian(dc::AbstractVector)

Convert a 3D Cartesian direction vector to geological trend and plunge angles.

This function takes a 3D direction vector in Cartesian coordinates and converts it
to geological orientation measurements: trend (compass direction) and plunge (inclination).

# Arguments
- `dc::AbstractVector`: A 3-element vector representing the Cartesian direction vector [x, y, z].
  The vector is assumed to be normalized (unit length), though the function will handle
  non-unit vectors correctly due to the trigonometric calculations.

# Returns
- `(trd, plg)::Tuple{Float64, Float64}`: A tuple containing:
  - `trd`: Trend angle in degrees [0, 360), measured clockwise from North (positive y-axis).
  - `plg`: Plunge angle in degrees [-90, 90], positive downward from horizontal.

# Details
The conversion follows standard geological conventions:
- **Trend**: The compass direction of the vector's horizontal projection, with 0° = North (positive y-axis),
  90° = East (positive x-axis), 180° = South, 270° = West.
- **Plunge**: The inclination angle from horizontal, where:
  - Positive values: downward inclination (below horizontal plane)
  - Negative values: upward inclination (above horizontal plane)
  - 0°: horizontal
  - ±90°: vertical

The calculation uses:
- `plg = asind(clamp(z, -1, 1))` to compute plunge from the z-component
- `trd = atand_0_360(y, x)` to compute trend from the x and y components

# Examples
```julia
julia> trend_plunge_from_cartesian([0, 1, 0])   # North-pointing horizontal vector
(0.0, 0.0)

julia> trend_plunge_from_cartesian([1, 0, 0])   # East-pointing horizontal vector
(90.0, 0.0)

julia> trend_plunge_from_cartesian([0, 0, 1])   # Downward vertical vector
(0.0, 90.0)

julia> trend_plunge_from_cartesian([0, 0, -1])  # Upward vertical vector
(0.0, -90.0)

julia> trend_plunge_from_cartesian([1, 1, 0])   # Northeast horizontal
(45.0, 0.0)

julia> trend_plunge_from_cartesian([0.707, 0.707, 0.707])  # 45° plunge northeast
(45.0, 45.0)
```
"""
function trend_plunge_from_cartesian(dc::AbstractVector)
    x, y, z = dc
    plg = asind(clamp(z, -1, 1))
    trd = atand_0_360(y, x)
    return (trd, plg)
end

"""
    cartesian_from_trend_plunge(trend::Real, plunge::Real)
    cartesian_from_trend_plunge(m::Matrix{<:Real})

Convert trend/plunge measurements to Cartesian coordinates of a pole unit vector.

# Arguments
- `trend`: Bearing angle in degrees (0-360° clockwise from North)
- `plunge`: Inclination angle in degrees (-90° to +90°, positive downward)
- `matrix`: N×2 matrix where col1 = trends, col2 = plunges

# Returns
- 3-element Vector for single measurement [North, East, Down]
- N×3 Matrix for multiple measurements [North East Down]

# Notes
- Uses geological convention: North=X, East=Y, Down=Z
- Input angles in degrees, output is unit vector
"""
function cartesian_from_trend_plunge(trend::Real, plunge::Real)
    return [
        cosd(trend) * cosd(plunge),  # North (x)
        sind(trend) * cosd(plunge),  # East (y)
        sind(plunge)                # Down (z)
    ]
end

function cartesian_from_trend_plunge(m::Matrix{<:Real})
    n = size(m, 1)
    result = Matrix{eltype(m)}(undef, n, 3)
    
    @inbounds for i in 1:n
        trend, plunge = m[i,1], m[i,2]
        result[i,1] = cosd(trend) * cosd(plunge)
        result[i,2] = sind(trend) * cosd(plunge) 
        result[i,3] = sind(plunge)
    end
    return result
end




#=
    rotation_mat(view_trend::Real, view_plunge::Real, az_correction::Real)

    Create a 3D rotation matrix for geological viewing transformations.

    This function constructs a composite rotation matrix that transforms from geographic coordinates
    to a view-oriented coordinate system.

    # Transformation Sequence
    1. Rotate around Z-axis by trend (changes horizontal direction)
    2. Rotate around rotated Y-axis by plunge (tilts view up/down)
    3. Final rotation around Z-axis by `az_correction` degrees. Adjusts the orientation within the view plane

    # Coordinate System
    - **Input**: Geographic coordinates where:
    - X-axis: East, Y-axis: North, Z-axis: Up (vertical)
    - **Output**: View-oriented coordinates where:
    - X-axis: Horizontal in view plane (after transformations)
    - Y-axis: Vertical in view plane
    - Z-axis: Line of sight
=#
function rotation_mat(view_trend::Real, view_plunge::Real, az_correction::Real)     
    
    Rz_trend = [ cosd(view_trend) sind(view_trend) 0.0;
                -sind(view_trend) cosd(view_trend) 0.0;
                 0.0 0.0 1.0 ]

    Ry_plunge = [ sind(view_plunge) 0.0 -cosd(view_plunge);
                  0.0 1.0 0.0;
                 cosd(view_plunge) 0.0 sind(view_plunge)]

    Rz_az = [ cosd(az_correction) sind(az_correction) 0.0;
              -sind(az_correction) cosd(az_correction) 0.0;
              0.0 0.0 1.0]    
    
    rm = Rz_az * Ry_plunge * Rz_trend
    
    return rm
    
end

"""
    change_view_direction(ov::AbstractVector, view_trend, view_plunge, az_correction)
    change_view_direction(trd::Real, plg::Real, view_trend, view_plunge, az_correction)

    Transform geological orientation vectors or angles to a new viewing coordinate system.

    This function provides two methods for transforming geological orientation data:
    1. Transform a Cartesian direction vector to view coordinates
    2. Transform trend/plunge angles to new trend/plunge angles in view coordinates

    # Arguments

    ## Method 1: Cartesian Vector Transformation
    - `ov::AbstractVector`: 3-element Cartesian direction vector [x, y, z] in geographic coordinates
    (X=East, Y=North, Z=Up)
    - `view_trend::Real`: Trend angle in degrees [0, 360] for the viewing direction
    - `view_plunge::Real`: Plunge angle in degrees [-180, 180] for the viewing inclination
    - `az_correction::Real`: Azimuth correction angle in degrees [0, 360] for final orientation adjustment

    ## Method 2: Trend/Plunge Angle Transformation  
    - `trd::Real`: Input trend angle in degrees [0, 360] to be transformed
    - `plg::Real`: Input plunge angle in degrees [-180, 180] to be transformed
    - `view_trend::Real`, `view_plunge::Real`, `az_correction::Real`: View parameters as above

    # Returns

    ## Method 1
    - `ov_view::Vector{Float64}`: Transformed 3D Cartesian vector in view coordinates

    ## Method 2  
    - `(rtrd, rplg)::Tuple{Float64, Float64}`: Transformed trend and plunge angles in degrees
    representing the orientation in the view coordinate system
"""
function change_view_direction(ov::AbstractVector, view_trend::Real, view_plunge::Real, az_correction::Real)

    rm = rotation_mat(view_trend, view_plunge, az_correction) 

    return rm * ov
end

function change_view_direction(trd::Real, plg::Real, view_trend::Real, view_plunge::Real, az_correction::Real)

    ov = cartesian_from_trend_plunge(trd, plg)
    
    ov = change_view_direction(ov, view_trend, view_plunge, az_correction)

    rtrd, rplg = trend_plunge_from_cartesian(ov)

    return (rtrd, rplg)
end

#=
    slickenline_vector(plane::Plane, rake)

Convert strike, dip, and rake to a slickenline unit vector.

Parameters:
- `strike`: Dip direction angle in degrees
- `dip`: Dip angle in degrees 
- `rake`: Rake angle in degrees

Returns:
- A 3D unit vector representing the slickenline in [East, North, Up] coordinates

Conventions:
- [North, East, Down] coordinates system
- Dip  is measured positive down from horizontal
- Rake is measured clockwise from strike
=#
function slickenline_vector(plane, rake)
    strike = plane.strike
    dip = plane.dip
    
    return [
    cosd(rake) * cosd(strike) - sind(rake) * sind(strike) * cosd(dip),
    cosd(rake) * sind(strike) + sind(rake) * cosd(strike) * cosd(dip),
    sind(rake) * sind(dip)
    ]
    
end
 
#=
    slickenline_vector(strike, dip, rake)

Convert strike, dip, and rake to a slickenline unit vector.

Parameters:
- `strike`: Dip direction angle in degrees
- `dip`: Dip angle in degrees 
- `rake`: Rake angle in degrees

Returns:
- A 3D unit vector representing the slickenline in [East, North, Up] coordinates

Conventions:
- [North, East, Down] coordinates system
- Dip  is measured positive down from horizontal
- Rake is measured clockwise from strike
=#
function slickenline_vector(strike, dip, rake)
    [
        cosd(rake) * cosd(strike) - sind(rake) * cosd(dip) * sind(strike),
        cosd(rake) * sind(strike) + sind(rake) * cosd(dip) * cosd(strike),
        sind(rake) * sind(dip)
    ]
end

#=
This function calculates the X, Y, Z coordinates of the major circles grid on a unit
sphere, Then the view direction is changet to v_trd, v_plg.

The major circles are separated a distance gc_step.

To improve the final plot, major circles with dips other than 0, 90, 180, and 270 
do not converge at the N and S poles, but remain separated from them by a distance sc_step

The variable a_cor (expressed in degrees) rotates the plot around the z-axis,
perpendicular to the equatorial plane.
=#

function great_circles_grid(v_trd, v_plg, a_cor, gc_step, sc_step)
    #variando rake con buz ctte se construyen circulos mayores
    allc = []
    strike = 0.0

    dip_rng = 0:gc_step:360-gc_step

    for dip in dip_rng
        
        sc = []
        if dip in [0, 90, 180, 270]
            
            rk_rng = 0:0.5:180
			
        else # Avoid reaching the plot N and S poles by starting/ending at a sc_step distance from the poles, the plot looks better
            rk_rng = 0+sc_step:0.5:180-sc_step
        end
        
        dip == 180 && (dip=179.99999)
        for rake in rk_rng
            rake == 0 && (rake=0.00001)
            rake == 180 && (rake=179.99999)
            d = slickenline_vector(strike, dip, rake)
            push!(sc, d)
        end
        sc = stack(sc, dims=1)        
        push!(allc, sc)
    end
    
    #Change view direction
    for i in 1:size(allc)[1]
        for j in 1:size(allc[i])[1]

            #reproject= false, es un vector
            allc[i][j,:] = change_view_direction(allc[i][j,:], v_trd, v_plg, a_cor)
            
        end   
    end
    #filter for lower hemisphere points
    [matrix[matrix[:, 3] .>= 0, :] for matrix in allc]

end

#=
This function calculates the X, Y, Z coordinates of the minor circles grid on a unit
sphere. Then the view direction is changet to v_trd, v_plg.

The minor circles are separated a distance sc_step.

The variable a_cor (expressed in degrees) rotates the plot around the z-axis,
perpendicular to the equatorial plane.
=#
function small_circles_grid(v_trd, v_plg, a_cor, sc_step)
    #variando dip con rake ctte se construyen circulos menores
    allcd = []
    allcu = []
    strike = 0.0
    
    for rake in 0.0+sc_step:sc_step:180-sc_step 
        scu = []
        scd = []
        
        for dip in 0:1:180
            d = slickenline_vector(strike, dip, rake)
            push!(scu, d)
        end
        
        for dip in 180:1:360
            d = slickenline_vector(strike, dip, rake)
            push!(scd, d)
        end
        
        scd = stack(scd, dims=1)
        scu = stack(scu, dims=1)
        push!(allcd, scd)
        push!(allcu, scu)
    end

    #Change view direction
    for i in 1:size(allcd)[1]
        for j in 1:size(allcd[i])[1]

            #reproject= false, es un vector
            allcd[i][j,:] = change_view_direction(allcd[i][j,:], v_trd, v_plg, a_cor)
            
        end
    end
    
    for i in 1:size(allcu)[1]
        for j in 1:size(allcu[i])[1]
            
            #reproject= false, es un vector
            allcu[i][j,:] = change_view_direction(allcu[i][j,:], v_trd, v_plg, a_cor)
            
        end    
    end

    #filter for lower hemisphere points
    allcu = filter_circles(allcu)
    allcd = filter_circles(allcd)
    
    return vcat(allcu, allcd)
end 


#=
En la receta las coordenadas del estereograma estan en strgrm.coords

En el constructor se calcula con: coords = Stereonet_Coordinates(view.trend, view.plunge, gstep, sstep, net, acor)

aqui esta en minusculas y es lo que debe recibir Makie

REVISAR=el cambio de la direccion de vista se hace separadamente para cada grid
porque no hacerlo una sola vez antes de proyectar?
=#
function stereonet_coordinates(trd1, plg1, gc_step, sc_step, net, acor1)
    gc = great_circles_grid(trd1, plg1, acor1, gc_step, sc_step)
    sc = small_circles_grid(trd1, plg1, acor1, sc_step)
    gs = vcat(gc, sc)
    xyc = []

    #Project into net

    xy_proj_fn = select_net_equation(net)
    
    for i in 1:size(gs)[1]
        gs[i] = CartesianCoords(gs[i])
        xy= xy_proj_fn(gs[i])
        push!(xyc, xy)
    end

    # Prepare Data for plotting in recipe
    for i in 1:size(xyc)[1]
        xyc[i] = vcat(xyc[i], [NaN NaN])
    end
    
    return vcat(xyc...,)
    
end

function filter_circles(dat)
    result = []
    
    for small_circle in dat
        # Find all rows where z >= 0
        valid_rows = small_circle[:, 3] .>= 0
        valid_indices = findall(valid_rows)
        
        # If all or none are valid, handle simply
        if all(valid_rows)
            push!(result, small_circle)
        elseif !any(valid_rows)
            continue  # skip entirely if no valid points
        else
            # Check if the valid indices are contiguous
            if maximum(valid_indices) - minimum(valid_indices) + 1 == length(valid_indices)
                # Single contiguous block - keep as one matrix
                push!(result, small_circle[valid_indices, :])
            else
                # Split into multiple contiguous blocks
                current_start = valid_indices[1]
                for i in 2:length(valid_indices)
                    if valid_indices[i] != valid_indices[i-1] + 1
                        # End of current block, start of new block
                        push!(result, small_circle[current_start:valid_indices[i-1], :])
                        current_start = valid_indices[i]
                    end
                end
                # Add the last block
                push!(result, small_circle[current_start:valid_indices[end], :])
            end
        end
    end
    
    return result
end

#=
    atand_0_360(y, x)

Compute the angle in degrees from the x-axis (N) to the point (x, y), normalized to the range [0, 360).

The function `atand(y, x)` computes the initial angle, handles all four quadrants, avoids division by zero,
but returns negative angles, these are converted to positive by adding 360 degrees.

# Arguments
- `y::Real`: The y-coordinate (vertical component).
- `x::Real`: The x-coordinate (horizontal component).

# Returns
- `angle::Float64`: The angle in degrees between the positive x-axis and the vector to the point (x, y).
=#
function atand_0_360(y, x)
    angle = atand(y, x)
    return angle < 0 ? angle + 360 : angle
end