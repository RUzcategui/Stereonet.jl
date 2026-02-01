abstract type AbstractStereonet end

mutable struct GridAttributes
    view::Tuple{Real,Real}
    grid::Symbol
    frame::Symbol
    net::Symbol
    sstep::Int
    gstep::Int
    acor::Real
    grid_color::Symbol
    grid_linestyle::Symbol
    grid_linewidth::Real
    grid_alpha::Real
    size::Tuple{Int,Int}
    ticks::Symbol        # :show | :hide
    tstep::Int           # angular spacing
    tlen::Real           # tick length

    function GridAttributes(;
        view::Tuple{Real,Real}=(0,90), 
        grid::Symbol=:show, 
        frame::Symbol=:show, 
        net::Symbol=:wulff, 
        sstep::Int=10, 
        gstep::Int=10, 
        acor::Real=0, 
        grid_color::Symbol=:gray,
        grid_linestyle::Symbol=:dash, 
        grid_linewidth::Real=0.5, 
        grid_alpha::Real=1.0, 
        size::Tuple{Int,Int} = (600,600),
        ticks::Symbol=:show,
        tstep::Int=10, # Try to use only: [10, 30, 45, 90]
        tlen::Real=0.015
    )
        new(view, grid, frame, net, sstep, gstep, acor, grid_color, grid_linestyle, grid_linewidth, grid_alpha, size, ticks, tstep, tlen)
    end
end

mutable struct Stereonet <: AbstractStereonet
    fig::Figure
    ax::Axis
    att::GridAttributes
end

function draw_hemi!(hp::Stereonet)
  ax = hp.ax
  att = hp.att

    if att.ticks == :show # Modify this use :deg to display degrees, :car to display cardinals or :nothing
        rlab = 1.08  # distance from center
        for θ in 0:att.tstep:(360 - att.tstep)
            θ_tick = θ
            θ_rot = θ_tick + att.view[1] + att.acor  # tick rotation

            # label text (reversed clockwise)
            label_angle = mod(360 - θ_tick, 360)

            # label position shifted 90° anticlockwise around circle
            θ_label_pos = θ_rot + 90
            x, y = cosd(θ_label_pos), sind(θ_label_pos)
            pos = Point2f(rlab * x, rlab * y)

            # text rotation perpendicular to tick (optional)
            rot = deg2rad(θ_rot) - π/2
            if π/2 < rot < 3π/2
                rot += π
            end

            text!(ax, string(label_angle, "°"),
                position = pos,
                rotation = rot,
                align = (:center, :center),
                fontsize = 12,
                color = att.grid_color)
        end
    end


  if att.ticks == :show
    starts, ends = radial_ticks_coords(att.tstep; len = att.tlen)

    pts = Vector{Point2f}(undef, 2 * size(starts, 1))

    k = 1
    for i in eachindex(starts[:, 1])
        pts[k]   = Point2f(starts[i, 1], starts[i, 2])
        pts[k+1] = Point2f(ends[i,   1], ends[i,   2])
        k += 2
    end

    linesegments!(ax, pts;
        color = att.grid_color,
        linewidth = att.grid_linewidth,
        alpha = att.grid_alpha
    )
    end


  # Validate and auto-correct grid setting
  if att.frame == :hide && att.grid == :show
      @warn "grid cannot be :show when frame is :hide, setting grid to :hide"
      att.grid = :hide
  end

  # Compute grid components
  gc = great_circle_grid(att.sstep, att.gstep, att.net, att.view, att.acor)
  sc = small_circle_grid(att.sstep, att.net, att.view, att.acor)
  fc = net_frame(att.net, att.view, att.acor)

  # Always draw outer circle
    
  circle = Circle(Point2f(0, 0), 1)
    lines!(ax, circle, 
      color=att.grid_color,
      linewidth=att.grid_linewidth,
      linestyle=att.grid_linestyle,
      alpha=att.grid_alpha)

    # Determine what grid components to draw
    grid_c = if att.frame == :show && att.grid == :show
        vcat(gc, sc, fc)
    elseif att.frame == :show && att.grid == :hide
        fc 
    else  # att.frame == :hide && att.grid == :hide
        []  
    end

    # Draw grid components
    for line in grid_c
        pts = Point2f.(line[:, 1], line[:, 2])
        lines!(ax, pts, 
            color=att.grid_color,
            linewidth=att.grid_linewidth,
            linestyle=att.grid_linestyle,
            alpha=att.grid_alpha)
    end
    
    return hp
end

"""
    hemi(; kwargs...) -> Stereonet

Create a hemispherical stereonet plotting canvas.

This function initializes a `Stereonet` object, including a Makie `Figure`,
an `Axis`, and optional stereonet grid and frame elements. The plot is
immediately drawn and ready for adding graphical elements: planes,
lines, and small circles.

# Keyword Arguments
- `view::Tuple{Real,Real} = (0, 90)`  
  Viewing direction as `(trend, plunge)` in degrees.

- `grid::Symbol = :show`  
  Whether to draw the stereonet grid (`:show` or `:hide`).

- `frame::Symbol = :show`  
  Whether to draw the stereonet frame (`:show` or `:hide`).

- `net::Symbol = :wulff`  
  Projection type. Choose between `:wulff` for equiangular ptojectos and`:schmidt` for equiareal ptojection.

- `sstep::Int = 10`  
  Angular spacing (degrees) for small-circle grid.

- `gstep::Int = 10`  
  Angular spacing (degrees) for great-circle grid.

- `acor::Real = 0`  
  Additional rotation angle (degrees) around the z-axis applied after view transformation.

- `grid_color::Symbol = :gray`  
  Color used for grid and frame elements.

- `grid_linestyle::Symbol = :dash`  
  Line style for grid elements.

- `grid_linewidth::Real = 0.5`  
  Line width for grid elements.

- `grid_alpha::Real = 1.0`  
  Transparency for grid elements.

- `size::Tuple{Real,Real} = (600, 600)`  
  Figure size in pixels.

# Returns
- `Stereonet`  
  A plotting object to which stereonet elements can be added.

# Examples
h = hemi(net = :wulff, view = (0, 90))
"""
function hemi(;
    view::Tuple{Real,Real} = (0, 90),
    grid::Symbol = :show,
    frame::Symbol=:show,
    net::Symbol = :wulff,
    sstep::Int = 10,
    gstep::Int = 10,
    acor::Real = 0,
    grid_color::Symbol = :gray,
    grid_linestyle::Symbol = :dash,
    grid_linewidth::Real = 0.5,
    grid_alpha::Real = 1.0,
    size::Tuple{Real,Real} = (600, 600),
    ticks::Symbol=:hide,
    tstep::Int=10, # Try to use only these values: [10, 30, 45, 90]
    tlen::Real=0.015
    )
    fig = Figure(size = size)
    ax = Axis(fig[1, 1], aspect = DataAspect())
    hidedecorations!(ax)
    hidespines!(ax)

    att = GridAttributes(
        view=view,
        grid=grid,
        frame=frame,
        net=net,
        sstep=sstep,
        gstep=gstep,
        acor=acor,
        grid_color=grid_color,
        grid_linestyle=grid_linestyle,
        grid_linewidth=grid_linewidth,
        grid_alpha=grid_alpha,
        size=size,
        ticks=ticks,
        tstep=tstep,
        tlen=tlen
    )

    hp = Stereonet(fig, ax, att)
    draw_hemi!(hp)

    return hp
end

#######################
######## Lines ########
#######################

#Lines on the unit sphere are displayed as scatter plots

"""
    scatter!(h::Stereonet, trd, plg; form=:a, kwargs...)

Plot linear features on a stereonet.

Lineations are defined by trend and plunge and rendered as points
on the selected stereonet projection.

# Arguments
- `h::Stereonet`  
  Target stereonet plot.h = hemi(net = :wulff, view = (0, 90))

- `trd::Real or AbstractVector{<:Real}`  
  Trend(s) in degrees.

- `plg::Real or AbstractVector{<:Real}`  
  Plunge(s) in degrees.

# Keyword Arguments
- `form::Symbol or AbstractVector{Symbol} = :a`  

  Whether linear features are treated as axis or vectors.
  Use `:a` to plot lines as axes or `:v` to plot lines as vectors.

- `kwargs...`  
  Additional keyword arguments passed to Makie’s `scatter!`.

# Returns
- Makie plot object.

# Examples
scatter!(h, 45, 30)
scatter!(h, [10, 40], [20, 60])
""" 
function scatter!(
    h::Stereonet,
    trd::Union{Real, AbstractVector{<:Real}},
    plg::Union{Real, AbstractVector{<:Real}};
    form::Union{Symbol, AbstractVector{Symbol}} = :a,
    color=:black,
    markersize =6,
    kwargs...
    )

    !(trd isa AbstractVector) && (trd=[trd])
    !(plg isa AbstractVector) && (plg=[plg])
    
    c = line_coordinates(trd, plg, h.att.net, h.att.view, h.att.acor, form=form)
    c = vcat(c...)

    scatter!(h.ax, c[:,1], c[:,2]; markersize=markersize, color=color, kwargs...)
end

#######################
######## Planes #######
#######################

#Planes on the unit sphere are displayed as line plots


@inline function pole(dipdir::Real, dip::Real)
    trend = dip == 0 ? dipdir : mod(dipdir - 180.0, 360.0)
    plunge = dip == 0 ? 90.0   : 90.0 - abs(dip)
    return trend, plunge
end


 
"""
    lines!(h::Stereonet, dipdir, dip; hemi=:lower, view=:trace, kwargs...)

Plot planar features on a stereonet.

Planes are drawn either as great-circle traces or as poles, depending on
the selected `view` mode. Multiple planes may be plotted in a single call
by passing vectors of equal length.

# Arguments
- `h::Stereonet`  
  Target stereonet plot.

- `dipdir::Real or AbstractVector{<:Real}`  
  Dip direction(s) in degrees.

- `dip::Real or AbstractVector{<:Real}`  
  Dip angle(s) in degrees.

# Keyword Arguments
- `hemi::Symbol = : lower`  
  Hemisphere selection (`:lower` or `:upper`).

- `view::Symbol = :trace`  
  Plot representation:
  - `:trace` — great-circle trace of the plane
  - `:pole`  — pole to the plane

- `kwargs...`  
  Additional keyword arguments passed to Makie’s `lines!` or `scatter!`.

# Returns
- Makie plot object.

# Examples
lines!(h, 120, 45)
lines!(h, [30, 60], [40, 50], view = :pole)
"""
function lines!(
    h::Stereonet,
    dipdir::Union{Real, AbstractVector{<:Real}},
    dip::Union{Real, AbstractVector{<:Real}};
    hemi::Symbol = :lower,
    view::Symbol = :trace,
	color::Symbol = :black,
    linewidth::Real = 1,
    strokewidth=0,
    kwargs...
    )

    view ∈ (:trace, :pole) ||
        throw(StereonetError("view must be :trace or :pole"))

    # Normalize inputs to vectors
    dipdir_vec = dipdir isa AbstractVector ? dipdir : [dipdir]
    dip_vec    = dip    isa AbstractVector ? dip    : [dip]

    length(dipdir_vec) == length(dip_vec) ||
        throw(ArgumentError("dipdir and dip must have the same length"))


    if view === :trace
        curves = plane_coordinates(dipdir_vec, dip_vec, hemi = hemi, h.att.net, h.att.view, h.att.acor)
        
        isa(curves, Matrix) && (curves = [curves])

        for line in curves
            lines!(h.ax, line[:,1], line[:,2]; color=color, linewidth=linewidth, kwargs...)
        end
        return nothing
    end


    # Pole view
    trd = similar(dipdir_vec, Float64)
    plg = similar(dip_vec, Float64)

    for i in eachindex(dipdir_vec)
        trd[i], plg[i] = pole(dipdir_vec[i], dip_vec[i])
    end

    pts = line_coordinates(
        trd,
        plg,
        h.att.net,
        h.att.view,
        h.att.acor;
        form = :a
    )

    pts = vcat(pts...)

    return scatter!(h.ax, pts[:,1], pts[:,2]; strokewidth=strokewidth, kwargs...)
end

#######################
#### Small Circles ####
#######################

#Generate points along the smaller circular arc between p1 and p2 on a unit circle.
function circular_arc(p1::Vector{Float64}, p2::Vector{Float64}, step_deg::Float64)

    # Calculate angles in radians
    θ1 = atan(p1[2], p1[1])
    θ2 = atan(p2[2], p2[1])
    
    # Ensure angles are in [0, 2π)
    θ1 = mod(θ1, 2π)
    θ2 = mod(θ2, 2π)
    
    # Calculate both possible angular differences
    Δθ_ccw = mod(θ2 - θ1, 2π)  # Counter-clockwise difference
    Δθ_cw = mod(θ1 - θ2, 2π)    # Clockwise difference
    
    # Determine the shorter arc direction
    if Δθ_ccw ≤ Δθ_cw
        Δθ = Δθ_ccw
        direction = 1  # Counter-clockwise
    else
        Δθ = Δθ_cw
        direction = -1 # Clockwise
    end
    
    # Convert step to radians
    step_rad = deg2rad(step_deg)
    
    # Determine number of steps (excluding endpoints)
    n_steps = floor(Int, Δθ / step_rad)
    
    # Generate points along the arc
    points = Matrix{Float64}(undef, n_steps + 1, 2)
    points[1, :] = p1
    
    for i in 1:n_steps
        θ = θ1 + i * step_rad * direction
        # Handle wrap-around for angles crossing 2π
        θ = mod(θ, 2π)
        points[i+1, :] = [cos(θ), sin(θ)]
    end
    
    # Make sure the last point is exactly p2 (to avoid floating point errors)
    if n_steps > 0 && !isapprox(points[end, :], p2, atol=1e-8)
        points[end, :] = p2
    end
    
    return points
end

function close_path(xy_segments)
    m1 = xy_segments[1]
    m2 = xy_segments[2] 
    arc1 = circular_arc(m1[1,:], m1[end,:], 0.5)
    arc2 = circular_arc(m2[1,:], m2[end,:], 0.5)
    arc1 = reverse(arc1, dims=1)
    arc2 = reverse(arc2, dims=1)
    m1 = vcat(m1, arc1)
    m2 = vcat(m2, arc2)
    return [m1, m2]
end


"""
    smallc!(h::Stereonet, trd, plg, angle; draw=:line, kwargs...)

Plot small circles on a stereonet.

Small circles are defined by a cone axis (trend and plunge) and an opening
angle. Depending on the view direction, a small circle may appear as a
single closed curve or as two separate curve segments.

# Arguments
- `h::Stereonet`  
  Target stereonet plot.

- `trd::Real or AbstractVector{<:Real}`  
  Trend(s) of the cone axis in degrees.

- `plg::Real or AbstractVector{<:Real}`  
  Plunge(s) of the cone axis in degrees.

- `angle::Real or AbstractVector{<:Real}`  
  Cone opening angle(s) in degrees.

# Keyword Arguments
- `draw::Symbol = :line`  
  Drawing mode:
  - `:line` — draw curve(s)
  - `:poly` — draw filled polygon(s)

- `color::Symbol = :skyblue1`  
  Fill color when `draw = :poly`.

- `strokewidth::Real = 1`  
  Line width for outlines.

- `kwargs...`  
  Additional keyword arguments passed to Makie.

# Returns
- Makie plot object.

# Examples
smallc!(h, 0, 0, 30)
smallc!(h, [0, 90], [0, 0], [20, 40])
"""
function smallc!(
    h::Stereonet,
    trd::Union{Real, AbstractVector{<:Real}},
    plg::Union{Real, AbstractVector{<:Real}},
    angle::Union{Real, AbstractVector{<:Real}};
    draw::Symbol = :line,
	color::Symbol = :black,
    linewidth::Real = 1,
    kwargs...
    )

    draw ∈ [:line, :poly] || throw(StereonetError("draw must be :line or :poly"))

    n = length(trd)
    pts1 = Matrix{Float64}[]
    pts2 = Matrix{Float64}[]
    polys = Vector{Vector{Point2f}}()

    #fill arrays
    for i in 1:n
        segments = small_circle_coords(trd[i], plg[i], angle[i], h.att.net, h.att.view, h.att.acor)

        if draw == :line
            if length(segments) == 1
                push!(pts1, segments[1], [NaN NaN])
            else
                push!(pts2, segments[1], [NaN NaN], segments[2], [NaN NaN])
            end

        elseif draw == :poly
            if length(segments) == 2
                segments = close_path(segments)
            end
            for m in segments
                push!(polys, Point2f.(m[:, 1], m[:, 2]))
            end
             
        end
    end

    #plot
    if draw == :line
        if !isempty(pts1) && isempty(pts2)
            return lines!(h.ax, vcat(pts1...); color=color, linewidth=linewidth, kwargs...)
        elseif isempty(pts1) && !isempty(pts2)
            return lines!(h.ax, vcat(pts2...); color=color, linewidth=linewidth, kwargs...)
        else
            return lines!(h.ax, vcat(vcat(pts1...), vcat(pts2...), [NaN NaN]); kwargs...)
        end
    elseif draw == :poly
        if !isempty(polys)
            return poly!(h.ax, polys; color = color, strokewidth = 0 ,kwargs...)
        end 
    end
      
end

##############################
#### save, display, show  ####
##############################

"""
     (filename::String, h::Stereonet; kwargs...) -> String

Save a `Stereonet` to disk.

The output format is inferred from the file extension. Vector formats
such as PDF and SVG require `CairoMakie` to be available.

# Arguments
- `filename::String`  
  Output file path.

- `h::Stereonet`  
  Plot to save.

- `kwargs...`  
  Additional keyword arguments forwarded to the backend save function.

# Returns
- Absolute path to the saved file.

# Examples
save("stereonet.png", h)
save("stereonet.pdf", h)
"""
function save(name::String, h::Stereonet; kwargs...)
    abspath_file = abspath(name)
    dir = dirname(abspath_file)
    if !isdir(dir) && dir != ""
        mkpath(dir)
    end
    
    ext = lowercase(splitext(name)[2])
    
    # For vector formats, we need CairoMakie
    if ext in [".pdf", ".svg", ".eps"]
        if !isdefined(Main, :CairoMakie)
            StereonetError("
            To save to $ext format, you need CairoMakie:
            using CairoMakie
            ")
        end
        Main.CairoMakie.save(name, h.fig; kwargs...)
    else
        save(name, h.fig; kwargs...)
    end

    return abspath_file
end

function display(hp::Stereonet)

    if current_backend() isa Module
        backend = current_backend()
        if isdefined(backend, :Screen)
            display(backend.Screen(), hp.fig)
        else
            display(hp.fig)
        end
    else
        display(hp.fig)
    end
end

function Base.show(io::IO, ::MIME"text/plain", h::Stereonet)
    println(io, "Stereonet(view=$(h.att.view), net=$(h.att.net))")
end

# For Jupyter/inline display
function Base.show(io::IO, mime::MIME"image/png", h::Stereonet)
    show(io, mime, h.fig)
end

function Base.show(io::IO, mime::MIME"image/svg+xml", h::Stereonet)
    show(io, mime, h.fig)
end
