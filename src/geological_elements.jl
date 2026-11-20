# Geological primitives: planes, lines, poles and spherical circles.

function normal_vector(dipdir::Real, dip::Real)
    d = mod(Float64(dipdir), 360)
    δ = Float64(dip)
    isfinite(δ) && -180 <= δ <= 180 ||
        throw(StereonetError("Dip must be between -180° and 180°, got $dip"))
    # In NED, this is perpendicular to strike and down-dip direction.
    return [-cosd(d)*sind(δ), -sind(d)*sind(δ), cosd(δ)]
end

function plane_basis(n::AbstractVector)
    nn = _unit(n; name="plane normal")
    ref = abs(nn[3]) < 0.9999 ? [0.0,0.0,1.0] : [1.0,0.0,0.0]
    u1 = cross(nn, ref)
    u1 ./= norm(u1)
    u2 = cross(nn, u1)
    return u1, u2
end

function great_circle(n::AbstractVector, strike::AbstractVector, sstep::Real;
                      closed::Bool=false, grid::Bool=false)
    isfinite(sstep) && sstep >= 0 || throw(ArgumentError("sstep must be non-negative"))
    nn = _unit(n; name="plane normal")
    ss = Float64.(strike)
    length(ss) == 3 || throw(ArgumentError("strike must have three components"))
    u1 = ss .- dot(ss,nn).*nn
    if norm(u1) < 1e-10
        u1, u2 = plane_basis(nn)
    else
        u1 ./= norm(u1)
        u2 = cross(nn,u1)
        u2 ./= norm(u2)
    end

    horizontal = abs(abs(nn[3])-1) < 1e-10
    θ1, θ2 = if horizontal && grid
        (0.0,360.0)
    elseif !grid
        (Float64(sstep),360.0-Float64(sstep))
    else
        (Float64(sstep),180.0-Float64(sstep))
    end
    θ2 < θ1 && throw(ArgumentError("sstep leaves no samples for great circle"))
    θ = range(deg2rad(θ1),deg2rad(θ2),length=closed ? 361 : 360)
    return reduce(vcat, (reshape(cos(t).*u1 .+ sin(t).*u2,1,3) for t in θ))
end

function small_circle(axis::AbstractVector, cone_angle::Real; npts::Int=360)
    0 <= cone_angle <= 180 || throw(StereonetError("Cone angle must be between 0° and 180°, got $cone_angle"))
    npts >= 3 || throw(ArgumentError("npts must be at least 3"))
    a = _unit(axis; name="cone axis")
    ref = abs(a[3]) < 0.9 ? [0.0,0.0,1.0] : [1.0,0.0,0.0]
    u1 = cross(a,ref); u1 ./= norm(u1)
    u2 = cross(a,u1)
    θ = range(0,2π,length=npts+1)[1:end-1]
    α = deg2rad(cone_angle)
    return reduce(vcat, (reshape(cos(α).*a .+ sin(α).*(cos(t).*u1 .+ sin(t).*u2),1,3) for t in θ))
end

function line_coordinates(t, p, net::Symbol, view::Tuple{<:Real,<:Real}, acor::Real;
                          form::Union{Symbol,AbstractVector{<:Symbol}}=:a)
    tv, pv = _as_float_vector(t), _as_float_vector(p)
    length(tv) == length(pv) || throw(StereonetError("Trend and plunge vectors must have same length"))
    forms = form isa Symbol ? fill(form,length(tv)) : collect(form)
    length(forms) == length(tv) || throw(StereonetError("Trend, plunge and form vectors must have same length"))
    all(f -> f in (:a,:v), forms) || throw(StereonetError("form must be :a (axis) or :v (vector)"))
    project = select_net_equation(net)
    result = Matrix{Float64}[]
	
    for i in eachindex(tv)
        v = vec(cartesian_coords(tv[i],pv[i]))
        v = change_view_direction(v,view,acor; reproject=(forms[i] === :a))
		println([3])
		println(form)
		if forms[i] === :v && v[3] < 0
			v[3] = -v[3]
		end
        push!(result, project(reshape(v,1,3), :lower))
    end
    return result
end

function _plane_curve(dipdir::Real,dip::Real,net::Symbol,view,acor,hemisphere::Symbol)
    d = mod(Float64(dipdir),360)
    δ = Float64(dip)
    n = normal_vector(d,δ)
    strike = [sind(d),-cosd(d),0.0] # RHR strike, axial direction
    nv = change_view_direction(n,view,acor;reproject=false)
    sv = change_view_direction(strike,view,acor;reproject=false)
    gc = great_circle(nv,sv,0)
    segs = select_hemisphere_segments(gc,hemisphere)
    project = select_net_equation(net)
    return [project(s,hemisphere) for s in segs if size(s,1)>=2]
end

function plane_coordinates(dipdir,dip,net::Symbol,view::Tuple{<:Real,<:Real},acor::Real;
                           hemi::Symbol=:lower)
    hemi in (:lower,:upper) || throw(ArgumentError("hemi must be :lower or :upper"))
    dv,pv = _as_float_vector(dipdir),_as_float_vector(dip)
    length(dv)==length(pv) || throw(StereonetError("Dipdir and dip vectors must have same length"))
    result = Matrix{Float64}[]
    for i in eachindex(dv)
        append!(result,_plane_curve(dv[i],pv[i],net,view,acor,hemi))
    end
    return result
end

function small_circle_coords(trd::Real,plg::Real,angle::Real,net::Symbol,
                              view::Tuple{<:Real,<:Real},acor::Real)
    0 <= angle <= 180 || throw(StereonetError("Cone angle must be between 0° and 180°, got '$angle'"))
    axis_world = vec(cartesian_coords(trd,plg))
    axis_view = _unit(change_view_direction(axis_world,view,acor;reproject=false))
    project = select_net_equation(net)
    segments = Matrix{Float64}[]
    for axis in (axis_view,-axis_view)
        sc = small_circle(axis,angle)
        for seg in select_hemisphere_segments(sc,:lower)
            size(seg,1)>=3 && push!(segments,project(seg,:lower))
        end
    end
    return segments
end

@inline function pole(dipdir::Real,dip::Real)
    d,δ = Float64(dipdir),Float64(dip)
    # Pole is the downward-pointing plane normal represented as a line axis.
    n = normal_vector(d,δ)
    if n[3] < 0
        n .*= -1
    end
    trend = mod(rad2deg(atan(n[2],n[1])),360)
    plunge = rad2deg(asin(clamp(n[3],-1,1)))
    return trend,plunge
end
