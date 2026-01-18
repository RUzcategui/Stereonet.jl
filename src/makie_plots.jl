abstract type AbstractHemi end

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
        size::Tuple{Int,Int} = (600,600)
    )
        new(view, grid, frame, net, sstep, gstep, acor, grid_color, grid_linestyle, grid_linewidth, grid_alpha, size)
    end
end

mutable struct HemiPlot <: AbstractHemi
    fig::Figure
    ax::Axis
    att::GridAttributes
end

function draw_hemi!(hp::HemiPlot)
  ax = hp.ax
  att = hp.att

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
    hemi(; kwargs...) -> HemiPlot

Create a hemispherical stereonet plotting canvas.

This function initializes a `HemiPlot` object, including a Makie `Figure`,
an `Axis`, and optional stereonet grid and frame elements. The plot is
immediately drawn and ready for adding graphical elements such as planes,
lines, small circles, or daylight envelopes.

# Keyword Arguments
- `view::Tuple{Real,Real} = (0, 90)`  
  Viewing direction as `(trend, plunge)` in degrees.

- `grid::Symbol = :show`  
  Whether to draw the stereonet grid (`:show` or `:hide`).

- `frame::Symbol = :show`  
  Whether to draw the stereonet frame (`:show` or `:hide`).

- `net::Symbol = :wulff`  
  Projection type. Supported values depend on the active projection backend
  (e.g. `:wulff`, `:schmidt`).

- `sstep::Int = 10`  
  Angular spacing (degrees) for small-circle grids.

- `gstep::Int = 10`  
  Angular spacing (degrees) for great-circle grids.

- `acor::Real = 0`  
  Additional rotation angle (degrees) applied after view transformation.

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
- `HemiPlot`  
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
    size::Tuple{Real,Real} = (600, 600)
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
        size=size
    )

    hp = HemiPlot(fig, ax, att)
    draw_hemi!(hp)

    return hp
end

#######################
######## Lines ########
#######################

#Lines on the unit sphere are displayed as scatter plots

"""
    scatter!(h::HemiPlot, trd, plg; form=:a, kwargs...)

Plot linear features on a stereonet.

Lineations are defined by trend and plunge and rendered as points
on the selected stereonet projection.

# Arguments
- `h::HemiPlot`  
  Target stereonet plot.

- `trd::Real or AbstractVector{<:Real}`  
  Trend(s) in degrees.

- `plg::Real or AbstractVector{<:Real}`  
  Plunge(s) in degrees.

# Keyword Arguments
- `form::Symbol or AbstractVector{Symbol} = :a`  
  Plotting form passed to the projection backend (e.g. axis-based plotting).

- `kwargs...`  
  Additional keyword arguments passed to Makie’s `scatter!`.

# Returns
- Makie plot object.

# Examples
scatter!(h, 45, 30)
scatter!(h, [10, 40], [20, 60])
""" 
function scatter!(
    h::HemiPlot,
    trd::Union{Real, AbstractVector{<:Real}},
    plg::Union{Real, AbstractVector{<:Real}};
    form::Union{Symbol, AbstractVector{Symbol}} = :a,
    kwargs...
    )

    !(trd isa AbstractVector) && (trd=[trd])
    !(plg isa AbstractVector) && (plg=[plg])
    
    c = line_coordinates(trd, plg, h.att.net, h.att.view, h.att.acor, form=form)
    c = vcat(c...)
    scatter!(h.ax, c[:,1], c[:,2]; kwargs...)
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
    lines!(h::HemiPlot, dipdir, dip; hemi=:lower, view=:trace, kwargs...)

Plot planar features on a stereonet.

Planes are drawn either as great-circle traces or as poles, depending on
the selected `view` mode. Multiple planes may be plotted in a single call
by passing vectors of equal length.

# Arguments
- `h::HemiPlot`  
  Target stereonet plot.

- `dipdir::Real or AbstractVector{<:Real}`  
  Dip direction(s) in degrees.

- `dip::Real or AbstractVector{<:Real}`  
  Dip angle(s) in degrees.

# Keyword Arguments
- `hemi::Symbol = :lower`  
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
    h::HemiPlot,
    dipdir::Union{Real, AbstractVector{<:Real}},
    dip::Union{Real, AbstractVector{<:Real}};
    hemi::Symbol = :lower,
    view::Symbol = :trace,
    kwargs...
    )

    view ∈ (:trace, :pole) ||
        throw(HemiPlotsError("view must be :trace or :pole"))

    # Normalize inputs to vectors
    dipdir_vec = dipdir isa AbstractVector ? dipdir : [dipdir]
    dip_vec    = dip    isa AbstractVector ? dip    : [dip]

    length(dipdir_vec) == length(dip_vec) ||
        throw(ArgumentError("dipdir and dip must have the same length"))


    if view === :trace
        curves = plane_coordinates(dipdir_vec, dip_vec, hemi = hemi, h.att.net, h.att.view, h.att.acor)
        
        isa(curves, Matrix) && (curves = [curves])

        for line in curves
            lines!(h.ax, line[:,1], line[:,2]; kwargs...)
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
        form = :axis
    )

    pts = vcat(pts...)

    return scatter!(h.ax, pts[:,1], pts[:,2]; kwargs...)
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

function close_plath(xy_segments)
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
    smallc!(h::HemiPlot, trd, plg, angle; draw=:line, kwargs...)

Plot small circles on a stereonet.

Small circles are defined by a cone axis (trend and plunge) and an opening
angle. Depending on the view direction, a small circle may appear as a
single closed curve or as two separate curve segments.

# Arguments
- `h::HemiPlot`  
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
    h::HemiPlot,
    trd::Union{Real, AbstractVector{<:Real}},
    plg::Union{Real, AbstractVector{<:Real}},
    angle::Union{Real, AbstractVector{<:Real}};
    draw::Symbol = :line,
    color::Symbol = :skyblue1,
    strokewidth::Real = 1,
    kwargs...
    )

    draw ∈ [:line, :poly] || throw(HemiPlotsError("draw must be :line or :poly"))

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
            if size(segments[1])[1] != 0 && size(segments[2])[1] != 0
                segments = close_plath(segments)
            end
            for m in segments
                push!(polys, Point2f.(m[:, 1], m[:, 2]))
            end
            
        end
    end

    #plot
    if draw == :line
        if !isempty(pts1) && isempty(pts2)
            return lines!(h.ax, vcat(pts1...); kwargs...)
        elseif isempty(pts1) && !isempty(pts2)
            return lines!(h.ax, vcat(pts2...); kwargs...)
        else
            return lines!(h.ax, vcat(vcat(pts1...), vcat(pts2...), [NaN NaN]); kwargs...)
        end
    elseif draw == :poly
        return poly!(h.ax, polys; color = color, strokewidth = 0 ,kwargs...)
    end
      
end

###########################
#### Daylight Envelope ####
###########################

"""
    daylight!(h::HemiPlot, stk, dip; draw=:line, kwargs...)

Plot daylight envelopes for planar surfaces on a stereonet.

The daylight envelope represents orientations for which a plane would
daylight under the specified slope geometry. Depending on the view
direction, the envelope may be rendered as a single closed curve or as
two open segments.

# Arguments
- `h::HemiPlot`  
  Target stereonet plot.

- `stk::Real or AbstractVector{<:Real}`  
  Strike(s) of the slope plane(s) in degrees.

- `dip::Real or AbstractVector{<:Real}`  
  Dip angle(s) of the slope plane(s) in degrees.

# Keyword Arguments
- `draw::Symbol = :line`  
  Drawing mode:
  - `:line` — draw envelope as curve(s)
  - `:poly` — draw filled envelope(s)

- `color::Symbol = :skyblue1`  
  Fill color when `draw = :poly`.

- `strokewidth::Real = 1`  
  Line width for outlines.

- `kwargs...`  
  Additional keyword arguments passed to Makie.

# Returns
- Makie plot object.

# Examples
daylight!(h, 90, 45)
daylight!(h, [0, 90], [30, 45], draw = :poly)
"""
function daylight!(
    h::HemiPlot,
    stk::Union{Real, AbstractVector{<:Real}},
    dip::Union{Real, AbstractVector{<:Real}};
    draw::Symbol = :line,
    color::Symbol = :skyblue1,
    strokewidth::Real = 1,
    kwargs...
    )

    draw ∈ [:line, :poly] || throw(HemiPlotsError("draw must be :line or :poly"))

    n = length(stk)
    pts1 = Matrix{Float64}[]
    pts2 = Matrix{Float64}[]
    polys = Vector{Vector{Point2f}}()

    #fill arrays
    for i in 1:n
        segments = daylight_coordinates(stk[i], dip[i], h.att.net, h.att.view, h.att.acor)

        if draw == :line
            if length(segments) == 1
                push!(pts1, segments[1], [NaN NaN])
            else
                push!(pts2, segments[1], [NaN NaN], segments[2], [NaN NaN])
            end

        elseif draw == :poly
            if size(segments)[1] == 2
                segments = close_plath(segments)
            end
            for m in segments
                push!(polys, Point2f.(m[:, 1], m[:, 2]))
            end
            
        end
    end

    #plot
    if draw == :line
        if !isempty(pts1) && isempty(pts2)
            return lines!(h.ax, vcat(pts1...); kwargs...)
        elseif isempty(pts1) && !isempty(pts2)
            return lines!(h.ax, vcat(pts2...); kwargs...)
        else
            return lines!(h.ax, vcat(vcat(pts1...), vcat(pts2...), [NaN NaN]); kwargs...)
        end
    elseif draw == :poly
        return poly!(h.ax, polys; color = color, strokewidth = 0 ,kwargs...)
    end
      
end

##############################
#### save, display, show  ####
##############################

"""
     (filename::String, h::HemiPlot; kwargs...) -> String

Save a `HemiPlot` to disk.

The output format is inferred from the file extension. Vector formats
such as PDF and SVG require `CairoMakie` to be available.

# Arguments
- `filename::String`  
  Output file path.

- `h::HemiPlot`  
  Plot to save.

- `kwargs...`  
  Additional keyword arguments forwarded to the backend save function.

# Returns
- Absolute path to the saved file.

# Examples
save("stereonet.png", h)
save("stereonet.pdf", h)
"""
function save(name::String, h::HemiPlot; kwargs...)
    abspath_file = abspath(name)
    dir = dirname(abspath_file)
    if !isdir(dir) && dir != ""
        mkpath(dir)
    end
    
    ext = lowercase(splitext(name)[2])
    
    # For vector formats, we need CairoMakie
    if ext in [".pdf", ".svg", ".eps"]
        if !isdefined(Main, :CairoMakie)
            HemiPlotsError("
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

function display(hp::HemiPlot)

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

function Base.show(io::IO, ::MIME"text/plain", h::HemiPlot)
    println(io, "HemiPlot(view=$(h.att.view), net=$(h.att.net))")
end

# For Jupyter/inline display
function Base.show(io::IO, mime::MIME"image/png", h::HemiPlot)
    show(io, mime, h.fig)
end

function Base.show(io::IO, mime::MIME"image/svg+xml", h::HemiPlot)
    show(io, mime, h.fig)
end
 