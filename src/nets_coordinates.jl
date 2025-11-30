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