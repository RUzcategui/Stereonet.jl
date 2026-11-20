abstract type AbstractStereonet end

mutable struct GridAttributes
    view::Tuple{Real,Real}
    grid::Symbol
    frame::Symbol
    net::Symbol
    sstep::Int
    gstep::Int
    acor::Real
    grid_color::Any
    grid_linestyle::Any
    grid_linewidth::Real
    grid_alpha::Real
    size::Tuple{Int,Int}
    ticks::Symbol
    tstep::Int
    tlen::Real
    function GridAttributes(;view=(0,90),grid=:show,frame=:show,net=:wulff,
        sstep=10,gstep=10,acor=0,grid_color=:gray,grid_linestyle=:dash,
        grid_linewidth=0.5,grid_alpha=1.0,size=(600,600),ticks=:deg,
        tstep=10,tlen=0.015)
        view isa Tuple && length(view)==2 || throw(ArgumentError("view must be (trend, plunge)"))
        grid in (:show,:hide) || throw(ArgumentError("grid must be :show or :hide"))
        frame in (:show,:hide) || throw(ArgumentError("frame must be :show or :hide"))
        net in (:wulff,:schmidt) || throw(ArgumentError("net must be :wulff or :schmidt"))
        ticks in (:deg,:car,:hide) || throw(ArgumentError("ticks must be :deg for degress, :car for cardinals or :hide"))
        sstep>0 && gstep>0 && tstep>0 || throw(ArgumentError("angular steps must be positive"))
        new(view,grid,frame,net,sstep,gstep,acor,grid_color,grid_linestyle,
            grid_linewidth,grid_alpha,(round(Int,size[1]),round(Int,size[2])),ticks,tstep,tlen)
    end
end

mutable struct HemiPlot <: AbstractStereonet
    fig::Figure
    ax::Axis
    att::GridAttributes
end

function radial_ticks_coords(step::Int;r0=1.0,len=0.05)
    step > 0 && 360 % step == 0 || throw(ArgumentError("step must be a positive divisor of 360"))
    θs = 0:step:(360-step)
    starts = Matrix{Float64}(undef,length(θs),2)
    ends = similar(starts)
    for (i,θ) in enumerate(θs)
        x,y = cosd(θ),sind(θ)
        starts[i,:] .= (r0*x,r0*y)
        ends[i,:] .= ((r0+len)*x,(r0+len)*y)
    end
    return starts,ends
end

function draw_hemi!(h::HemiPlot)
    ax,att = h.ax,h.att
    if att.frame===:hide && att.grid===:show
        @warn "grid cannot be :show when frame is :hide; hiding grid"
        att.grid=:hide
    end
	
	if att.ticks===:car && att.view[2]==90
		att.tstep = 90
        label_card = ["N", "W", "S", "E"]
		for (i, θ) in enumerate(0:att.tstep:(360-att.tstep))
			θrot = θ + att.view[1] + att.acor
			x, y = cosd(θrot + 90), sind(θrot + 90)
			rot = deg2rad(θrot) - π/2
			π/2 < mod(rot, 2π) < 3π/2 && (rot += π)
			text!(ax, label_card[i], position = Point2f(1.08x, 1.08y),
			   align = (:center, :center), fontsize = 12, color = att.grid_color)
		end
    end
	 
    if att.ticks===:deg && att.view[2]==90
	 
        starts,ends = radial_ticks_coords(att.tstep;len=att.tlen)
        pts = Point2f[]
        for i in axes(starts,1)
            push!(pts,Point2f(starts[i,1],starts[i,2]),Point2f(ends[i,1],ends[i,2]))
        end
        linesegments!(ax,pts;color=att.grid_color,linewidth=att.grid_linewidth,alpha=att.grid_alpha)
        for θ in 0:att.tstep:(360-att.tstep)
            θrot=θ+att.view[1]+att.acor
            label_angle=mod(360-θ,360)
            x,y=cosd(θrot+90),sind(θrot+90)
            rot=deg2rad(θrot)-π/2
            π/2<mod(rot,2π)<3π/2 && (rot+=π)
            text!(ax,string(label_angle,"°"),position=Point2f(1.08x,1.08y),
                  rotation=rot,align=(:center,:center),fontsize=12,color=att.grid_color)
        end
    end

    lines!(ax,Circle(Point2f(0,0),1);color=att.grid_color,
           linewidth=att.grid_linewidth,linestyle=att.grid_linestyle,alpha=att.grid_alpha)

    if att.frame===:show
        curves = att.grid===:show ?
            vcat(great_circle_grid(att.sstep,att.gstep,att.net,att.view,att.acor),
                 small_circle_grid(att.sstep,att.net,att.view,att.acor),
                 net_frame(att.net,att.view,att.acor)) :
            net_frame(att.net,att.view,att.acor)
        for line in curves
            pts=Point2f[]
            for i in axes(line,1)
                if all(isfinite,line[i,:])
                    push!(pts,Point2f(line[i,1],line[i,2]))
                elseif !isempty(pts)
                    lines!(ax,pts;color=att.grid_color,linewidth=att.grid_linewidth,
                           linestyle=att.grid_linestyle,alpha=att.grid_alpha)
                    empty!(pts)
                end
            end
            !isempty(pts) && lines!(ax,pts;color=att.grid_color,
                linewidth=att.grid_linewidth,linestyle=att.grid_linestyle,alpha=att.grid_alpha)
        end
    end
    return h
end



"""
    hemi(; kwargs...) -> HemiPlot

Create a hemispherical stereonet plotting canvas.

This function initializes a `HemiPlot` object, including a Makie `Figure`,
an `Axis`, and optional stereonet grid and frame elements. The plot is
immediately drawn and ready for adding graphical elements: planes,
lines, and small circles.

# Keyword Arguments
- `view::Tuple{Real,Real}`: Viewing direction as `(trend, plunge)` in degrees. 
  Default is `(0, 90)`.
- `acor::Real`: Additional rotation angle (degrees) around the z-axis applied 
  after view transformation. Default is `0`.
- `net::Symbol`: Projection type. Choose between `:wulff` for equiangular 
  projection and `:schmidt` for equal-area projection. Default is `:wulff`.  
- `grid::Symbol`: Whether to draw the stereonet grid (`:show` or `:hide`). 
  Default is `:show`.
- `frame::Symbol`: Whether to draw the stereonet frame (`:show` or `:hide`). 
  Default is `:show`.
- `ticks::Symbol`: Marks and labels drawn around the stereonet's outer circle, use `:deg` for degrees, `:car` for cardinals or `:hide`.
- `tstep::Int`: Angular spacing in degrees between tick marks. Default is `10`.
- `tlen::Real`: Length of the tick marks as a fraction of the radius. Default is `0.015`.
- `sstep::Int`: Angular spacing (degrees) for small-circle grid. Default is `10`.
- `gstep::Int`: Angular spacing (degrees) for great-circle grid. Default is `10`.
- `grid_color::Symbol`: Color used for grid and frame elements. Default is `:gray`.
- `grid_linestyle::Symbol`: Line style for grid elements. Default is `:dash`.
- `grid_linewidth::Real`: Line width for grid elements. Default is `0.5`.
- `grid_alpha::Real`: Transparency for grid elements. Default is `1.0`.
- `size::Tuple{Real,Real}`: Figure size in pixels. Default is `(600, 600)`.

# Returns
- `HemiPlot`: A plotting object to which elements can be added.

# Examples
```julia
h = hemi(net = :wulff, view = (0, 90))
```
"""
function hemi(;view=(0,90),grid=:show,frame=:show,net=:wulff,sstep=10,gstep=10,
    acor=0,grid_color=:gray,grid_linestyle=:dash,grid_linewidth=0.5,
    grid_alpha=1.0,size=(600,600),ticks=:deg,tstep=10,tlen=0.015)
	
	_check_interactive_backend()
    att=GridAttributes(;view,grid,frame,net,sstep,gstep,acor,grid_color,
        grid_linestyle,grid_linewidth,grid_alpha,size,ticks,tstep,tlen)
    fig=Figure(size=att.size)
    ax=Axis(fig[1,1],aspect=DataAspect())
    hidedecorations!(ax); hidespines!(ax)
    h=HemiPlot(fig,ax,att)
    draw_hemi!(h)
    return h
end

"""
    lineations!(h::HemiPlot, trd, plg; form=:a, kwargs...)

Plot linear features on a stereonet.

Lineations are defined by trend and plunge and rendered as points
on the selected stereonet projection.

# Arguments
- `h::HemiPlot`: Target stereonet plot.
- `trd::Real` or `AbstractVector{<:Real}`: Trend(s) in degrees.
- `plg::Real` or `AbstractVector{<:Real}`: Plunge(s) in degrees.

# Keyword Arguments
- `form::Symbol` or `AbstractVector{Symbol}`: Whether linear features are treated 
  as axes or vectors. Use `:a` to plot lines as axes or `:v` to plot lines as 
  vectors. Default is `:a`.
- `color::Symbol`: Fill color of the marker. Default is `:black`.
- `markersize::Real`: Size of the marker. Default is `6`.
- `kwargs...`: Additional keyword arguments passed to Makie's `scatter!`.

# Returns
- Makie plot object.

# Examples
```julia
lineations!(h, 45, 30)
lineations!(h, [10, 40], [20, 60])
```
"""  
function lineations!(h::HemiPlot,trd,plg;form=:a,color=:black,markersize=6,kwargs...)
    pts=line_coordinates(trd,plg,h.att.net,h.att.view,h.att.acor;form)
    isempty(pts) && return nothing
    xy=vcat(pts...)
    scatter!(h.ax,xy[:,1],xy[:,2];markersize,color,kwargs...)
	return h
end

"""
    traces!(h::HemiPlot, dipdir, dip; hemi=:lower, view=:trace, kwargs...)

Plot planar features on a stereonet.

Planes are drawn either as great-circle traces or as poles, depending on
the selected `view` mode. Multiple planes may be plotted in a single call
by passing vectors of equal length.

# Arguments
- `h::HemiPlot`: Target stereonet plot.
- `dipdir::Real` or `AbstractVector{<:Real}`: Dip direction(s) in degrees.
- `dip::Real` or `AbstractVector{<:Real}`: Dip angle(s) in degrees.

# Keyword Arguments
- `hemi::Symbol`: Hemisphere selection (`:lower` or `:upper`). Default is `:lower`.
- `view::Symbol`: Planar feature representation. Options are `:trace` (great-circle 
  trace of the plane) or `:pole` (pole to the plane). Default is `:trace`.
- `polecolor::Symbol`: Fill color of the pole. Default is `:black`.
- `polealpha::Real`: Alpha value of the pole fill color attribute. Default is `1.0`.
- `strokecolor::Symbol`: Stroke color for pole outlines. Default is `:black`.
- `strokewidth::Real`: Line width for pole outlines. Default is `0`.
- `linecolor::Symbol`: Line color for traces. Default is `:black`.
- `linewidth::Real`: Line width for traces. Default is `1.3`.
- `linealpha::Real`: Line alpha value for traces. Default is `1.0`.
- `kwargs...`: Additional keyword arguments passed to Makie's `lines!` or `scatter!`.

# Returns
- Makie plot object.

# Examples
```julia
traces!(h, 120, 45)
traces!(h, [30, 60], [40, 50], view = :pole)
```
"""
function traces!(h::HemiPlot,dipdir,dip;hemi=:lower,view=:trace,
    polecolor=:black,polealpha=1,strokecolor=:black,strokewidth=0,
    linecolor=:black,linewidth=1.3,linealpha=1,kwargs...)
    view in (:trace,:pole) || throw(StereonetError("view must be :trace or :pole"))
    dv,pv=_as_float_vector(dipdir),_as_float_vector(dip)
    length(dv)==length(pv) || throw(ArgumentError("dipdir and dip must have the same length"))
    if view===:trace
        curves=plane_coordinates(dv,pv,h.att.net,h.att.view,h.att.acor;hemi)
        plots=Any[]
        for curve in curves
            push!(plots,lines!(h.ax,curve[:,1],curve[:,2];color=linecolor,
                               alpha=linealpha,linewidth,kwargs...))
        end
        return plots
    end
    poles=[pole(dv[i],pv[i]) for i in eachindex(dv)]
    isempty(poles) && return nothing
    pts=line_coordinates(first.(poles),last.(poles),h.att.net,h.att.view,h.att.acor;form=:a)
    xy=vcat(pts...)
    return scatter!(h.ax,xy[:,1],xy[:,2];color=polecolor,alpha=polealpha,
                    strokecolor,strokewidth,kwargs...)
end

function circular_arc(p1::Vector{Float64},p2::Vector{Float64},step_deg::Float64)
    step_deg>0 || throw(ArgumentError("step_deg must be positive"))
    θ1,θ2=mod(atan(p1[2],p1[1]),2π),mod(atan(p2[2],p2[1]),2π)
    ccw=mod(θ2-θ1,2π)
    direction=ccw<=π ? 1.0 : -1.0
    Δ=direction==1 ? ccw : mod(θ1-θ2,2π)
    n=max(1,ceil(Int,rad2deg(Δ)/step_deg))
    θs=range(θ1,step=direction*Δ/n,length=n+1)
    out=hcat(cos.(θs),sin.(θs))
    out[1,:].=p1; out[end,:].=p2
    return out
end

function close_path(xy_segments)
    length(xy_segments)==2 || throw(ArgumentError("close_path expects exactly two segments"))
    m1,m2=xy_segments
    a1=reverse(circular_arc(vec(m1[1,:]),vec(m1[end,:]),0.5),dims=1)
    a2=reverse(circular_arc(vec(m2[1,:]),vec(m2[end,:]),0.5),dims=1)
    return [vcat(m1,a1),vcat(m2,a2)]
end

"""
    smallc!(h::HemiPlot, trd, plg, angle; draw=:line, kwargs...)

Plot small circles on a stereonet.

Small circles are defined by a cone axis (trend and plunge) and an opening
angle. Depending on the view direction, a small circle may appear as a
single closed curve or as two separate curve segments.

# Arguments
- `h::HemiPlot`: Target stereonet plot.
- `trd::Real` or `AbstractVector{<:Real}`: Trend(s) of the cone axis in degrees.
- `plg::Real` or `AbstractVector{<:Real}`: Plunge(s) of the cone axis in degrees.
- `angle::Real` or `AbstractVector{<:Real}`: Cone opening angle(s) in degrees.

# Keyword Arguments
- `draw::Symbol`: Drawing mode. Options are `:line` (draw circles outlines) or `:poly` 
  (draw filled cirles). Default is `:line`.
- `fill::Symbol`: Fill color of circles. Default is `:skyblue1`.
- `polyalpha::Real`: Alpha value of the fill attribute. Default is `0.3`.
- `linecolor::Symbol`: Line color for circles outlines. Default is `:black`.
- `linewidth::Real`: Line width for circles outlines. Default is `1.3`.
- `linealpha::Real`: Line alpha value for circles outlines. Default is `0.5`.
- `kwargs...`: Additional keyword arguments passed to Makie.

# Returns
- Makie plot object.

# Examples
```julia
smallc!(h, 0, 0, 30)
smallc!(h, [0, 90], [0, 0], [20, 40])
```
"""   
function smallc!(h::HemiPlot,trd,plg,angle;draw=:line,fill=:skyblue1,
    polyalpha=0.3,linecolor=:black,linewidth=1.3,linealpha=0.3,kwargs...)
    draw in (:line,:poly) || throw(StereonetError("draw must be :line or :poly"))
    tv,pv,av=_as_float_vector(trd),_as_float_vector(plg),_as_float_vector(angle)
    length(tv)==length(pv)==length(av) || throw(ArgumentError("trend, plunge and angle must have equal lengths"))
    lineplots=Any[]; polyplots=Any[]
    for i in eachindex(tv)
        segs=small_circle_coords(tv[i],pv[i],av[i],h.att.net,h.att.view,h.att.acor)
        if draw===:line
            for seg in segs
                push!(lineplots,lines!(h.ax,seg[:,1],seg[:,2];color=linecolor,
                                       alpha=linealpha,linewidth,kwargs...))
            end
        else
            polygons=length(segs)==2 ? close_path(segs) : segs
            for seg in polygons
                push!(polyplots,poly!(h.ax,Point2f.(seg[:,1],seg[:,2]);
                                      color=fill,alpha=polyalpha,strokewidth=0,kwargs...))
            end
        end
    end
    return draw===:line ? lineplots : polyplots
end

function _check_interactive_backend()
    backend = current_backend()
    if !isnothing(backend) && nameof(backend) === :CairoMakie
        # Detect if an integrated graphical environment (VS Code, IJulia, Pluto, etc.) is active
        # Excludes REPL, TextDisplay, and Makie's external image viewer display
        has_integrated_display = any(Base.Multimedia.displays) do d
            !(d isa REPL.REPLDisplay || d isa TextDisplay || nameof(parentmodule(typeof(d))) === :Makie)
        end
        if !has_integrated_display
            @warn """
            CairoMakie is active in a terminal without an integrated plot pane: every command that returns the figure will open a new window in your system's image viewer.
            • To update a single interactive window in real time, activate GLMakie:
                using GLMakie; GLMakie.activate!()
            • If you prefer to keep using CairoMakie, end mutating calls with `;` (e.g., `traces!(h, ...);`) and evaluate `h` at the end to view the final result.
            """ maxlog=1
        end
    end
end


function Base.display(hp::HemiPlot)
    backend = current_backend()
    if !isnothing(backend) && isdefined(backend, :Screen)
        screen = getscreen(hp.fig.scene)
        if isnothing(screen) || !isopen(screen)
            # La figura aún no tiene ventana (o se cerró): abre una nueva exclusiva para ella
            return display(getfield(backend, :Screen)(), hp.fig)
        else
            # La figura ya está abierta en su propia ventana: solo la devuelve sin duplicarla
            return screen
        end
    end
    return display(hp.fig)
end
Base.show(io::IO,::MIME"text/plain",h::HemiPlot)=
    print(io,"HemiPlot(view=$(h.att.view), net=$(h.att.net))")
Base.show(io::IO,mime::MIME"image/png",h::HemiPlot)=show(io,mime,h.fig)
Base.show(io::IO,mime::MIME"image/svg+xml",h::HemiPlot)=show(io,mime,h.fig)

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
function save(name::String,h::HemiPlot;kwargs...)
    path=abspath(name)
    mkpath(dirname(path))
    ext=lowercase(splitext(name)[2])
    if ext in (".pdf",".svg",".eps")
        if !isdefined(Main,:CairoMakie)
            throw(StereonetError("To save to $ext, load CairoMakie first: using Cairo
			 "))
        end
        Main.CairoMakie.save(path,h.fig;kwargs...)
    else
        save(path,h.fig;kwargs...)
    end
    return path
end

