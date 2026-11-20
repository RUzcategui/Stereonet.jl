# Core conventions and coordinate operations.
# NED: X = North, Y = East, Z = Down. Right-handed: X × Y = Z.
# Trends/azimuths are clockwise from North. Plunge is retained in [-180, 180].

struct StereonetError <: Exception
    msg::String
end
Base.showerror(io::IO, e::StereonetError) = print(io, e.msg)

@inline function _check_trend(x::Real)
    isfinite(x) && 0 <= x <= 360 ||
        throw(StereonetError("Trend must be between 0° and 360°, got $x"))
    return Float64(x)
end

@inline function _check_plunge(x::Real)
    isfinite(x) && -180 <= x <= 180 ||
        throw(StereonetError("Plunge must be between -180° and 180°, got $x"))
    return Float64(x)
end

function _as_float_vector(x::Union{Real,AbstractVector{<:Real}})
    return x isa Real ? [Float64(x)] : Float64.(collect(x))
end

function cartesian_coords(trd::Union{Real,AbstractVector{<:Real}},
                          plg::Union{Real,AbstractVector{<:Real}})
    tv, pv = _as_float_vector(trd), _as_float_vector(plg)
    length(tv) == length(pv) ||
        throw(ArgumentError("Trend and plunge vectors must have the same length"))
    out = Matrix{Float64}(undef, length(tv), 3)
    @inbounds for i in eachindex(tv)
        t, p = _check_trend(tv[i]), _check_plunge(pv[i])
        out[i, 1] = cosd(t) * cosd(p) # North
        out[i, 2] = sind(t) * cosd(p) # East
        out[i, 3] = sind(p)           # Down
    end
    return out
end

function _unit(v::AbstractVector{<:Real}; name="vector")
    length(v) == 3 || throw(ArgumentError("$name must have three components"))
    nv = norm(v)
    isfinite(nv) && nv > eps(Float64) ||
        throw(ArgumentError("$name must be finite and non-zero"))
    return Float64.(v) ./ nv
end

# Rotation from world NED coordinates into the requested viewing frame.
function rotation_mat(view::Tuple{<:Real,<:Real}, az_correction::Real; reproject::Bool=false)
    vt, vp = _check_trend(mod(Float64(view[1]), 360)), _check_plunge(view[2])
    isfinite(az_correction) || throw(ArgumentError("azimuth correction must be finite"))
    Rz_trend = [cosd(vt) sind(vt) 0.0;
                -sind(vt) cosd(vt) 0.0;
                 0.0 0.0 1.0]
    Ry_plunge = [sind(vp) 0.0 -cosd(vp);
                 0.0 1.0 0.0;
                 cosd(vp) 0.0 sind(vp)]
    Rz_az = [cosd(az_correction) sind(az_correction) 0.0;
             -sind(az_correction) cosd(az_correction) 0.0;
              0.0 0.0 1.0]
    return Rz_az * Ry_plunge * Rz_trend
end

function change_view_direction(v::AbstractVector{<:Real},
                               view::Tuple{<:Real,<:Real},
                               a_cor::Real; reproject::Bool=true)
    length(v) == 3 || throw(ArgumentError("Input vector must have three components"))
    rv = rotation_mat(view, a_cor) * Float64.(v)
    if reproject && rv[3] < 0
        rv .*= -1
    end
    return rv
end

# Return each continuous portion of a sampled curve in the requested
# hemisphere. Exact equator crossings are linearly interpolated and retained.
function select_hemisphere_segments(m::AbstractMatrix{<:Real}, hemi::Symbol;
                                    atol::Real=1e-10,
                                    closed::Bool=true)

    size(m, 2) == 3 || throw(ArgumentError("Matrix must be n×3"))
    hemi in (:lower, :upper) || throw(ArgumentError("hemi must be :lower or :upper"))

    n = size(m, 1)

    n == 0 && return Matrix{Float64}[]

    n == 1 && return ((hemi === :lower ? m[1,3] >= -atol : m[1,3] <= atol) ?
                      [reshape(Float64.(m[1,:]), 1, 3)] : Matrix{Float64}[])

    inside(z) = hemi === :lower ? z >= -atol : z <= atol

    all(inside.(m[:,3])) && return [Float64.(m)]

    all(.!inside.(m[:,3])) && !any(abs.(m[:,3]) .<= atol) &&
        return Matrix{Float64}[]

    segs = Matrix{Float64}[]
    current = Vector{Vector{Float64}}()

    pushpoint!(v) = (isempty(current) || norm(current[end] - v) > atol) &&
                    push!(current, v)

    function finish!()
        if length(current) >= 2
            push!(segs, reduce(vcat, (reshape(v,1,3) for v in current)))
        elseif length(current) == 1
            push!(segs, reshape(current[1],1,3))
        end
        empty!(current)
    end

    # Process only actual sampled edges.
    # The closing edge is included only for closed curves.
    last_edge = closed ? n : n-1

    for i in 1:last_edge
        p = Float64.(m[i,:])
        q = Float64.(m[i == n ? 1 : i+1,:])

        pin, qin = inside(p[3]), inside(q[3])

        if pin && qin
            pushpoint!(p)
            pushpoint!(q)

        elseif pin && !qin
            pushpoint!(p)

            if abs(q[3] - p[3]) > eps(Float64)
                λ = clamp(-p[3] / (q[3] - p[3]), 0.0, 1.0)
                x = p .+ λ .* (q .- p)
                x[3] = 0.0
                pushpoint!(x)
            end

            finish!()

        elseif !pin && qin
            if abs(q[3] - p[3]) > eps(Float64)
                λ = clamp(-p[3] / (q[3] - p[3]), 0.0, 1.0)
                x = p .+ λ .* (q .- p)
                x[3] = 0.0
                pushpoint!(x)
            end

            pushpoint!(q)

        else
            finish!()
        end
    end

    finish!()

    # Join fragments across the cyclic seam only for closed curves.
    if closed && length(segs) > 1 &&
       norm(segs[1][1,:] - segs[end][end,:]) <= 1e-8

        merged = vcat(segs[end], segs[1][2:end,:])
        segs = vcat([merged], segs[2:end-1])
    end

    return segs
end

# Compatibility helper: a single matrix with NaN rows separating fragments.
function select_hemisphere(m::AbstractMatrix{<:Real}, hemi::Symbol)
    segs = select_hemisphere_segments(m, hemi)
    isempty(segs) && return Matrix{Float64}(undef, 0, 3)
    out = Matrix{Float64}(undef, 0, 3)
    for (i, seg) in enumerate(segs)
        i > 1 && (out = vcat(out, fill(NaN,1,3)))
        out = vcat(out, seg)
    end
    return out
end
