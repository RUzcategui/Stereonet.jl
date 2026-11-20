# Stereonet graticule construction in view-space Cartesian coordinates.

function great_circle_grid(
    sstep::Real,
    gstep::Real,
    net::Symbol,
    view::Tuple{<:Real,<:Real},
    acor::Real
)
    gstep > 0 || throw(ArgumentError("gstep must be positive"))

    project = select_net_equation(net)
    result = Matrix{Float64}[]

    # Reference strike in world NED coordinates.
    dipdir = 90.0
    strike_world = [sind(dipdir), -cosd(dipdir), 0.0]

    # Transform the reference strike into the viewing frame.
    strike_view = change_view_direction(
        strike_world, view, acor;
        reproject=false
    )

    # Generate the original family of great circles.
    for dip in (-180+gstep):gstep:(180-gstep)
        abs(dip) == 90 && continue

        n = change_view_direction(
            normal_vector(dipdir, dip),
            view,
            acor;
            reproject=false
        )

        gc = great_circle(
            n,
            strike_view,
            sstep;
            grid=true
        )

        for seg in select_hemisphere_segments(gc, :lower; closed=false)
            size(seg, 1) >= 2 &&
                push!(result, project(seg, :lower))
        end
    end

    return result
end

function small_circle_grid(sstep::Real,net::Symbol,
                           view::Tuple{<:Real,<:Real},acor::Real)
    sstep > 0 || throw(ArgumentError("sstep must be positive"))
    project = select_net_equation(net)
    axis = change_view_direction([1.0,0.0,0.0],view,acor;reproject=false)
    result = Matrix{Float64}[]
    for α in sstep:sstep:(180-sstep)
        α == 90 && continue
        sc = small_circle(axis,α)
        for seg in select_hemisphere_segments(sc,:lower)
            size(seg,1)>=2 && push!(result,project(seg,:lower))
        end
    end
    return result
end

function net_frame(net::Symbol,view::Tuple{<:Real,<:Real},acor::Real)
    project = select_net_equation(net)
    configs = if view == (90,0)
        [(0,0),(0,180),(0,90),(0,-90)]
    elseif view[1] in (-180,0,180) && view[2] in (-180,0,180)
        [(0,0),(90,90),(90,-90)]
    elseif view[1] in (-180,-90,0,90,180) && view[2] in (90,-90)
        [(90,90),(0,90)]
    else
        [(90,90),(0,90),(90,0)]
    end
    result = Matrix{Float64}[]
    for (dd,dip) in configs
        append!(result,_plane_curve(dd,dip,net,view,acor,:lower))
    end
    return result
end
