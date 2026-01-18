# UTILS

struct HemiPlotsError <: Exception msg::String end

function normal_vector(dipdir::Real, dip::Real)
    
    α = mod(dipdir, 360)

    return [
        -cosd(α) * sind(dip),
        -sind(α) * sind(dip),
         cosd(dip)
    ]
end

function plane_basis(n::AbstractVector)
    n = n / norm(n)
    a = abs(n[3]) < 0.9999 ? [0.0, 0.0, 1.0] : [1.0, 0.0, 0.0]
    u1 = cross(n, a)
    u1 /= norm(u1)

    u2 = cross(n, u1)
    return u1, u2
end

function cartesian_coords(trd::Union{Real, AbstractVector{<:Real}}, 
                          plg::Union{Real, AbstractVector{<:Real}})
    # Convert scalars to vectors for uniform processing
    trd_vec = trd isa Real ? [trd] : trd
    plg_vec = plg isa Real ? [plg] : plg
    
    length(trd_vec) != length(plg_vec) && throw(ArgumentError("Trend and plunge vectors must have the same length"))
    
    n = length(trd_vec)
    m = Matrix{Float64}(undef, n, 3)
    
    for i in 1:n
        (trd_vec[i] < 0 || trd_vec[i] > 360) && throw(HemiPlotsError("Trend must be between 0° and 360°, got $(trd_vec[i])"))
        (plg_vec[i] < -180 || plg_vec[i] > 180) && throw(HemiPlotsError("Plunge must be between -180° and 180°, got $(plg_vec[i])"))
        m[i,1] = cosd(trd_vec[i]) * cosd(plg_vec[i])  # North (x)
        m[i,2] = sind(trd_vec[i]) * cosd(plg_vec[i])  # East (y)
        m[i,3] = sind(plg_vec[i])                      # Down (z)
    end
    
    return m
end

function select_hemisphere(m::AbstractMatrix{<:Real}, hemi::Symbol)
    size(m, 2) == 3 || error("Matrix must be n×3")

    # Entire curve lies on equator (horizontal great circle)
    if all(abs.(m[:, 3]) .< 1e-10)
        # close curve for plotting
        return vcat(m, m[1:1, :])
    end

    if hemi === :lower
        keep = m[:, 3] .>= -1e-10
    elseif hemi === :upper
        keep = m[:, 3] .<=  1e-10
    else
        error("hemi must be :lower or :upper")
    end

    if !any(keep)
        return Matrix{Float64}(undef, 0, 3)
    end 

    # Handle wrap-around (curve crosses equator twice)
    if keep[1] && keep[end]
        break_idx = findfirst(!, keep)
        if break_idx !== nothing
            keep = circshift(keep, -break_idx + 1)
            m    = circshift(m,    (-break_idx + 1, 0))
        end
    end
 
    return m[keep, :]
end

# PROJECTED COORDINATES

function select_net_equation(net::Symbol)
    
    net == :wulff && return xy_wulff
    net == :schmidt && return xy_schmidt
    throw(HemiPlotsError("Unknown net: $net — expected :wulff or :schmidt"))
    
end

function xy_wulff(matrix::Matrix{Float64})::Matrix{Float64}
    denom = @view(matrix[:,3]) .+ 1 
    x_new = @view(matrix[:,2]) ./ denom
    y_new = @view(matrix[:,1]) ./ denom
    hcat(x_new, y_new)
end

function xy_schmidt(matrix::Matrix{Float64})::Matrix{Float64}
    x, y, z = matrix[:, 1], matrix[:, 2], matrix[:, 3]
    z = clamp.(z, -1.0, 1.0)
    denominator = 1 .+ z
    u = sqrt.(1 ./ denominator) .* y
    v = sqrt.(1 ./ denominator) .* x
    return hcat(u, v)
end

function xy_wulff(matrix::Matrix{Float64}, hemisphere::Symbol)::Matrix{Float64}
    z = @view(matrix[:, 3])
    
    # Adjust z based on hemisphere
    z_proj = hemisphere == :lower ? z : -z
    
    denom = z_proj .+ 1 
    x_new = @view(matrix[:, 2]) ./ denom
    y_new = @view(matrix[:, 1]) ./ denom
    hcat(x_new, y_new)
end

function xy_schmidt(matrix::Matrix{Float64}, hemisphere::Symbol)::Matrix{Float64}
    x, y, z = matrix[:, 1], matrix[:, 2], matrix[:, 3]
    
    # Adjust z based on hemisphere
    z_proj = hemisphere == :lower ? z : -z
    z_proj = clamp.(z_proj, -1.0, 1.0)
    
    denominator = 1 .+ z_proj
    u = sqrt.(1 ./ denominator) .* y
    v = sqrt.(1 ./ denominator) .* x
    return hcat(u, v)
end

# CHANGE OF VIEW DIRECTION

function rotation_mat(view::Tuple{Real,Real}, az_correction::Real; reproject::Bool=true) 
    
    view_trend = view[1]
    view_plunge = view[2]

    #Rotate around Z-axis by trend (changes horizontal direction)
    Rz_trend = [ cosd(view_trend) sind(view_trend) 0.0;
                -sind(view_trend) cosd(view_trend) 0.0;
                 0.0 0.0 1.0 ]

    #Rotate around rotated Y-axis by plunge (tilts view up/down)
    Ry_plunge = [ sind(view_plunge) 0.0 -cosd(view_plunge);
                  0.0 1.0 0.0;
                 cosd(view_plunge) 0.0 sind(view_plunge)]

    #Final rotation around Z-axis by `az_correction` degrees. 
    #Adjusts the orientation within the view plane
    Rz_az = [ cosd(az_correction) sind(az_correction) 0.0;
              -sind(az_correction) cosd(az_correction) 0.0;
              0.0 0.0 1.0]    
    
    rm = Rz_az * Ry_plunge * Rz_trend
    
    return rm
    
end

function change_view_direction( ov::AbstractVector, view::Tuple{Real,Real}, a_cor::Real; reproject::Bool=true) 
    
    rm = rotation_mat(view, a_cor) 
    rv = rm * ov

   if reproject==true 
       rv[3] < 0.0 && (rv = -rv) #plots as an axis
       return rv
    else
        return rv #plots as a vector
    end
end 

# GREAT CIRCLES 
 
function great_circle(
    n::AbstractVector,      
    strike::AbstractVector,
    sstep::Real;
    closed::Bool=false,
    grid::Bool=false
    )
    
    npts=360
    
    # Use the transformed strike direction to constrain u1
    u1 = strike - dot(strike, n) * n
    
    if norm(u1) < 1e-10
        u1, u2 = plane_basis(n)
    else
        u1 = u1 / norm(u1)
        u2 = cross(n, u1)
        u2 /= norm(u2)
    end
    
    # u1 is aligned with the strike direction (horizontal line in the plane)
    # u2 = cross(n, u1) points in the dip direction

    horizontal = (n[3] ≈ 1.0 || n[3] ≈ -1.0)

    θ₁, θ₂ = if horizontal && grid
        (0.0, 360.0)
    elseif !grid
        (0.0 + sstep, 360.0 - sstep)
    else
        (0.0 + sstep, 180.0 - sstep)
    end

    θ = range(
        deg2rad(θ₁),
        deg2rad(θ₂),
        length = closed ? npts + 1 : npts
    )   

    gc = Matrix{Float64}(undef, length(θ), 3)
    @inbounds for (i, t) in enumerate(θ)
        gc[i, :] .= cos(t) * u1 + sin(t) * u2
    end

    return gc    
end

function great_circle_grid(
    sstep::Real,
    gstep::Real,
    net::Symbol,
    view::Tuple{Real,Real},
    acor::Real
    )
    xy_proj_fn = select_net_equation(net)
    
    dipdir = 90
    
    # Calculate strike direction in world space and transform to view space
    strike_world = [-sind(dipdir), cosd(dipdir), 0.0]
    strike_view = change_view_direction(strike_world, view, acor; reproject = false)
    
    result=Vector{Matrix{Float64}}()
    
    dip_ranges = [
        -180+gstep:gstep:-90-gstep,
        -90+gstep:gstep:-gstep,
        gstep:gstep:90-gstep,
        90+gstep:gstep:180-gstep
    ]
      
    for dip_range in dip_ranges
        for dip in dip_range
            nv0 = normal_vector(dipdir, dip)
            nv = change_view_direction(nv0, view, acor; reproject = false)
            gc = great_circle(nv, strike_view, sstep, grid=true)
            if !all(abs.(gc[:, 3]) .< 1e-10)
                sh = select_hemisphere(gc, :lower)
                push!(result, xy_proj_fn(sh, :lower))
            end
        end
    end
    
    return result
end

# SMALL CIRCLES

function small_circle(
    axis::AbstractVector,   # already in view space
    cone_angle::Real;       # degrees
    npts::Int = 360
    )
    a = axis / norm(axis)

    # build a basis perpendicular to the axis
    # choose a stable reference
    ref = abs(a[3]) < 0.9 ? [0.0, 0.0, 1.0] : [1.0, 0.0, 0.0]
    u1 = cross(a, ref)
    u1 /= norm(u1)
    u2 = cross(a, u1)

    θ = range(0, 2π, length = npts + 1)[1:end-1]
    α = deg2rad(cone_angle)

    sc = Matrix{Float64}(undef, length(θ), 3)
    for (i, t) in enumerate(θ)
        sc[i, :] .=
            cos(α) * a +
            sin(α) * (cos(t) * u1 + sin(t) * u2)
    end

    return sc
end

function small_circle_coords(
    trd::Real,
    plg::Real,
    angle::Real,
    net::Symbol,
    view::Tuple{Real,Real},
    acor::Real
    )
    xy_proj_fn = select_net_equation(net)

    if !(0 ≤ angle ≤ 180)        
        throw(HemiPlotsError("Cone angle must be between 0° and 180°, got '$angle'"))
    end

    # Transform axis to view space
    axis_world = cartesian_coords(trd, plg)

    axis_view = change_view_direction(vec(axis_world), view, acor; reproject=false)
    axis_view /= norm(axis_view)

    # Process both axis directions
    function process_axis(axis::AbstractVector)
        sc = small_circle(axis, angle)
        sh = select_hemisphere(sc, :lower)
        xy_proj_fn(sh, :lower)
    end

    result = [process_axis(axis_view), process_axis(-axis_view)]

    return result
end

function small_circle_grid(
    sstep::Real,
    net::Symbol,
    view::Tuple{Real,Real},
    acor::Real
    )
    xy_proj_fn = select_net_equation(net)

    # cone axis: horizontal, N–S
    axis_world = [1.0, 0.0, 0.0]
    axis_view = change_view_direction(axis_world, view, acor; reproject=false)
    axis_view /= norm(axis_view)

    result=Vector{Matrix{Float64}}()

    for α in sstep:sstep:(180 - sstep)
        α == 90 && continue
        sc = small_circle(axis_view, α)
        sh = select_hemisphere(sc, :lower)
        push!(result, xy_proj_fn(sh, :lower))
    end

    return result
end

# LINES 

function line_coordinates(
    t::Union{Real, AbstractVector{<:Real}},
    p::Union{Real, AbstractVector{<:Real}},
    net::Symbol,
    view::Tuple{Real,Real},
    acor::Real;
    form::Union{Symbol, AbstractVector{<:Symbol}}=form,
    )
    xy_proj_fn = select_net_equation(net)

    # Scalar case
    if isa(t, Real) && isa(p, Real)
        t_val, p_val = t, p
        form_val = isa(form, Symbol) ? form : first(form)
        
        if form_val != :v && p_val < 0
            t_val = mod(t_val + 180, 360)
        end
        p_val = abs(p_val)

        # Cartesian and rotation
        c = cartesian_coords(t_val, p_val)

        rotated = change_view_direction(
            c[1, :],
            view,
            acor;
            reproject = (form_val != :v)
        )
        return xy_proj_fn(rotated, :lower)
    end

    # Vector case
    n = length(t)
    
    # Handle form as scalar or vector
    form_vec = isa(form, Symbol) ? fill(form, n) : form
    
    length(t) == length(p) == length(form_vec) ||
        throw(HemiPlotsError("Trend, plunge and form vectors must have same length"))

    cart_mat = Matrix{Float64}(undef, n, 3)
    for i in 1:n
        t_val, p_val = t[i], p[i]

        if form_vec[i] != :v && p_val < 0
            t_val = mod(t_val + 180, 360)
        end
        p_val = abs(p_val)
        cart_mat[i, :] .= cartesian_coords(t_val, p_val)[1, :]
        
        cart_mat[i, :] =
            change_view_direction(
                cart_mat[i, :],
                view,
                acor;
                reproject = (form_vec[i] != :v_)
            )
    end
    
    result = Vector{Matrix{Float64}}(undef, n)
    for i in 1:n
        result[i] = xy_proj_fn([cart_mat[i, 1] cart_mat[i, 2] cart_mat[i, 3]], :lower)
    end
    
    return result
end

# PLANES

function plane_coordinates(
    dipdir::Union{Real, AbstractVector{<:Real}},
    dip::Union{Real, AbstractVector{<:Real}},
    net::Symbol,
    view::Tuple{Real,Real},
    acor::Real;
    hemi::Symbol=:lower
    )
     
    sstep = 0
    xy_proj_fn = select_net_equation(net)

    # Scalar case NO SE USA 
    if isa(dipdir, Real) && isa(dip, Real)

        hemi == :upper && (dipdir = mod(dipdir-180, 360))

        strike_world = [-sind(dipdir), cosd(dipdir), 0.0]
        strike_view = change_view_direction(strike_world, view, acor; reproject=false)
        nv0 = normal_vector(dipdir, dip)
        nv = change_view_direction(nv0, view, acor; reproject = false)
        gc = great_circle(nv, strike_view, sstep)
        sh = select_hemisphere(gc, :lower)
        result = [xy_proj_fn(sh, :lower)]  # Return as vector of matrices
        return result

    end

    # Vector case
    n = length(dipdir)

    length(dipdir) == length(dip) ||
        throw(HemiPlotsError("Dipdir and dip vectors must have same length"))

    result = Vector{Matrix{Float64}}(undef, n)
    
    for i in 1:n
        dd_val, d_val = dipdir[i], dip[i]
        
        dd_val_adj = hemi == :upper ? mod(dd_val-180, 360) : dd_val

        strike_world = [-sind(dd_val_adj), cosd(dd_val_adj), 0.0]
        strike_view = change_view_direction(strike_world, view, acor; reproject=false)
        nv0 = normal_vector(dd_val_adj, d_val)
        nv = change_view_direction(nv0, view, acor; reproject = false)

        gc = great_circle(nv, strike_view, sstep)
        sh = select_hemisphere(gc, :lower)
        result[i] = xy_proj_fn(sh, :lower)
    end
    
    return result

end

# DAYLIGHT

function safe_acosd(x::Real)
    
    if x ≈ 1
        return 0.0
    elseif x ≈ -1
        return 180.0
    else
        return acosd(x)
    end
    
end

function envelope_cartesian(
    slope_strike, 
    slope_dip,
    view, 
    acor;
    step = 0.1
    )
    pts = Vector{Vector{Float64}}()

    for rake in 0:step:180
        plunge = slope_dip != 0 ?
            asind(sind(slope_dip) * sind(rake)) : 0.0

        eff_strike = slope_dip == 0 ? rake : slope_strike
        angle = safe_acosd(cosd(rake) / cosd(plunge))

        trd = mod(eff_strike + angle + 180, 360)
        plg = 90 - plunge

        cart_c = cartesian_coords(trd, plg)

        cart_c = change_view_direction(vec(cart_c), view, acor; reproject=false)

        push!(pts, vec(cart_c))

    end

    push!(pts, pts[1])
    return reduce(vcat, permutedims.(pts))
end

function find_crossings(m::Matrix{Float64}; atol = 1e-10)

    size(m, 2) == 3 || error("Matrix must be n×3")

    z = m[:, 3]
    n = size(m, 1)

    # classify points
    signz = sign.(z)
    signz[abs.(z) .< atol] .= 0

    # find crossings
    cut_idx = Int[]
    for i in 1:n-1
        if signz[i] * signz[i+1] < 0

            push!(cut_idx, i)
        end
    end
    return cut_idx
end

function split_by_equator(m::Matrix{Float64})

    cut_idx = find_crossings(m)
    # no crossings → single segment
    if isempty(cut_idx)
        return [m]
    end
    
    i1, i2 = cut_idx

    seg1 = m[i1+1:i2, :]
    seg2 = vcat(m[i2+1:end, :], m[1:i1, :])

    return [seg1, seg2]
end

function daylight_coordinates(
    slope_strike::Real,
    slope_dip::Real,
    net::Symbol,
    view::Tuple,
    acor::Real
    )

    envelope_xyz = envelope_cartesian(slope_strike, slope_dip, view, acor) 
    segments = split_by_equator(envelope_xyz)
    
    xy_proj_fn = select_net_equation(net)
    xy_segments = Vector{Matrix{Float64}}()

    for seg in segments
        z_mean=mean(seg[:, 3])
        z_mean < 0.0 && (seg=-seg)
        push!(xy_segments, xy_proj_fn(seg, :lower))
    end
    return xy_segments

end

# FRAME

function net_frame(
    net::Symbol,
    view::Tuple{Real,Real},
    acor::Real
    )
    xy_proj_fn = select_net_equation(net)
    
    function process_dip(dipdir::Real, dip::Real)
        strike_world = [-sind(dipdir), cosd(dipdir), 0.0]
        strike_view = change_view_direction(strike_world, view, acor; reproject = false)
        nv_world = normal_vector(dipdir, dip)
        nv_view = change_view_direction(nv_world, view, acor; reproject = false)
        gc = great_circle(nv_view, strike_view, 0)
        sh = select_hemisphere(gc, :lower) 
        xy_proj_fn(sh)
    end
    
    dip_configs = if view == (90, 0)
        [(0, 0), (0, 180), (0, 90), (0, -90)]

    elseif view[1] in (-180, 0, 180) && view[2] in (-180, 0, 180)
        [(0, 0), (90, 90), (90, -90)]

    elseif view[1] in (-180, -90, 0, 90, 180) && view[2] in (90, -90)
        [(90, 90), (0, 90)]

    else
        [(90, 90), (0, 90), (90, 0)]
    end

    return [process_dip(dipdir, dip) for (dipdir, dip) in dip_configs]
end