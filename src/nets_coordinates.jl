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