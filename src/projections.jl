# Stereographic (Wulff) and equal-area (Schmidt) lower-hemisphere projections.
# The upper-hemisphere variant mirrors Z before projection, retaining X and Y.

function select_net_equation(net::Symbol)
    net === :wulff && return xy_wulff
    net === :schmidt && return xy_schmidt
    throw(StereonetError("Unknown net: $net — expected :wulff or :schmidt"))
end

function _project(matrix::AbstractMatrix{<:Real}, hemisphere::Symbol, kind::Symbol)
    size(matrix,2) == 3 || throw(ArgumentError("Input matrix must be n×3"))
    hemisphere in (:lower,:upper) || throw(ArgumentError("hemi must be :lower or :upper"))
    out = Matrix{Float64}(undef, size(matrix,1), 2)
    @inbounds for i in axes(matrix,1)
        x, y, z = Float64(matrix[i,1]), Float64(matrix[i,2]), Float64(matrix[i,3])
        if !(isfinite(x) && isfinite(y) && isfinite(z))
            out[i,:] .= NaN
            continue
        end
        zp = hemisphere === :lower ? z : -z
        den = 1 + zp
        if den <= 1e-14
            out[i,:] .= NaN
        elseif kind === :wulff
            out[i,1] = y / den
            out[i,2] = x / den
        else
            f = inv(sqrt(den))
            out[i,1] = y * f
            out[i,2] = x * f
        end
    end
    return out
end

xy_wulff(m::AbstractMatrix{<:Real}) = _project(m, :lower, :wulff)
xy_schmidt(m::AbstractMatrix{<:Real}) = _project(m, :lower, :schmidt)
xy_wulff(m::AbstractMatrix{<:Real}, h::Symbol) = _project(m, h, :wulff)
xy_schmidt(m::AbstractMatrix{<:Real}, h::Symbol) = _project(m, h, :schmidt)

function project_to_net(c::AbstractVector{<:AbstractVector{<:Real}},
    net::Symbol)

    project = select_net_equation(net)

    result::Vector{Matrix{Float64}} = Matrix{Float64}[]

    for i in eachindex(c)

        length(c[i]) == 3 ||
            throw(ArgumentError(
                "Input vectors must have three components"
            ))

        v::Matrix{Float64} = reshape(Float64.(c[i]), 1, 3)

        push!(result, project(v, :lower))

    end

    return result
end
