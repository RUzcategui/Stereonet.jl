```@meta
CurrentModule = Stereonet
```
## Backend Activation

Remember to call a specific backend to render your plots:

```julia
using Stereonet
using CairoMakie, GLMakie

CairoMakie.activate!()
# plot and save with CairoMakie

GLMakie.activate!()
# plot and save with GLMakie
```

## Creating a Stereonet

Create a stereonet with default attributes:
```@example plot1
using Stereonet
using CairoMakie

h = hemi(size=(300, 300))
``` 

## Grid and Frame Attributes

Attributes are defined as keyword arguments. The following table describes each attribute:

```@raw html
<table>
  <thead>
    <tr class = "columnLabelRow">
      <th style = "font-weight: bold; text-align: left;">Attribute</th>
      <th style = "font-weight: bold; text-align: left;">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr class = "dataRow">
      <td style = "text-align: left;">net::Symbol</td>
      <td style = "text-align: left;">Projection type. Choose between :wulff for equiangular projections and :schmidt for equiareal projection. Default: :wulff</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">sstep::Int</td>
      <td style = "text-align: left;">Angular spacing (degrees) for small-circle grid. Default: 10</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">gstep::Int</td>
      <td style = "text-align: left;">Angular spacing (degrees) for great-circle grid. Default: 10</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">view::Tuple{Real,Real}</td>
      <td style = "text-align: left;">Viewing direction as (trend, plunge) in degrees. Default: (0, 90) (vertically downward)</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">acor::Real</td>
      <td style = "text-align: left;">Additional rotation angle (degrees) around the z-axis applied after view transformation. Default: 0</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">frame::Symbol</td>
      <td style = "text-align: left;">Frame consists of NS and EW vertical planes when view=(0, 90). Options: :show or :hide. Default: :show</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">grid::Symbol</td>
      <td style = "text-align: left;">Whether to draw the stereonet grid. Options: :show or :hide. Default: :show. Note: Grid cannot be :show when frame is :hide. Setting this will change grid to :hide with a warning</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">size::Tuple{Int,Int}</td>
      <td style = "text-align: left;">Figure size in pixels. Default: (600, 600)</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">grid_color::Symbol</td>
      <td style = "text-align: left;">Color for grid and frame elements. Default: :gray</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">grid_linestyle::Symbol</td>
      <td style = "text-align: left;">Line style for grid and frame elements. Default: :dash</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">grid_linewidth::Real</td>
      <td style = "text-align: left;">Line width for grid and frame elements. Default: 0.5</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">grid_alpha::Real</td>
      <td style = "text-align: left;">Transparency for grid and frame elements (0.0 to 1.0). Default: 1.0</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">ticks::Symbol</td>
      <td style = "text-align: left;">Whether to draw tick marks outside the primitive circle. Options: :show or :hide. ⚠️ Work in progress - use with caution</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">tstep::Int</td>
      <td style = "text-align: left;">Angular spacing (degrees) for tick marks. Default: 10. ⚠️ Work in progress - use with caution</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">tlen::Real</td>
      <td style = "text-align: left;">Length of tick marks. Default: 0.015. ⚠️ Work in progress - use with caution</td>
    </tr>
  </tbody>
</table>

```
  
## Net view direction

Nets are usually displayed with the primitive oriented horizontally (viewed from above). With the attribute view, a net can be generated from any desired direction:

```@example plot2
using Stereonet
using CairoMakie
h = hemi(
    net = :schmidt, 
    view = (30, 20),
    grid = :show,
    size=(300, 300),
    frame = :show,
    grid_color=:deepskyblue2,
    grid_linestyle=:solid
)
```
## Plotting Linear Features

Linear features are plotted using `lineations!`:

```@example plot3
using Stereonet
using CairoMakie

h = hemi(net = :schmidt, size=(300, 300))
lineations!(h, 300, 20)  # trend=300°, plunge=20°
lineations!(h, [50], [0], marker = :rect, 
        markersize = 11, color = :yellow1)
lineations!(h, [220, 180, 140], [50, 50, 50], marker = :xcross, 
        markersize = 13, color = :green)       
h
``` 

## Linear Features Attributes

`lineations!` attributes are defined as keyword arguments. The following table describes each attribute:

```@raw html
<table>
  <thead>
    <tr class = "columnLabelRow">
      <th style = "font-weight: bold; text-align: left;">Attribute</th>
      <th style = "font-weight: bold; text-align: left;">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr class = "dataRow">
      <td style = "text-align: left;">form::Union{Symbol, AbstractVector{Symbol}}</td>
      <td style = "text-align: left;">Determines whether linear features are treated as axes or vectors, choose between :a for axes and :v for vectors. Default: :a</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">color::Symbol</td>
      <td style = "text-align: left;">Fill color of the marker. Default: :black</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">markersize::Real</td>
      <td style = "text-align: left;">Size of the marker. Default: 6</td>
    </tr>
  </tbody>
</table>

```

!!! note
    For linear data, hemisphere selection is encoded in the orientation itself. Plunge sign and form control whether antipodal directions are distinguished:

##### Behavior with positive plunge (downward):
- Both `:a` and `:v` plot the point at the same location on the lower hemisphere

```@example plot4
using Stereonet
using CairoMakie

h = hemi(net = :wulff, view = (0, 90), size=(300, 300))
lineations!(h, [90, 90], [45, 45], form = [:v, :a], color = :red)
h
```

##### Behavior with negative plunge (upward):
- `:a` (axis): Plots the antipode point on the lower hemisphere
- `:v` (vector): Plots the point on the upper hemisphere

```@example plot5
using Stereonet
using CairoMakie

h = hemi(net=:wulff, view=(0, 90), size=(300, 300))
lineations!(h, [90], [-45], form = [:a], color = :green)
lineations!(h, [90], [-45], form = [:v], color = :red)
h
```

!!! note
    When using :v with negative plunge, you may want to distinguish between lower and upper hemisphere points. One approach is to use hollow markers:

```@example plot6
using Stereonet
using CairoMakie

h = hemi(net = :wulff, view = (0, 90), size=(300, 300))
lineations!(h, 270, -20, form = :v, 
            color = :transparent, 
            strokewidth = 1, 
            marker = :hexagon,
            markersize = 15,
            strokecolor = :blue)
h
```
    
    See discussion: [Markers without fill in Makie.jl](https://discourse.julialang.org/t/how-to-have-markers-without-fill-color-in-makie-jl/88698)

##### Different Form for Each Point

```@example plot7
using Stereonet
using CairoMakie

trends = [0.0, 45.0, 90.0, 135.0]
plunges = [15.0, 30.0, -45.0, -60.0]
forms = [:a, :v, :a, :v] 

h = hemi(size=(300, 300))
lineations!(h, trends, plunges, form=forms)
h
``` 

##### Same Form for All Points

```@example plot8
using Stereonet
using CairoMakie

trends = [0.0, 45.0, 90.0, 135.0]
plunges = [15.0, 30.0, -45.0, -60.0]

h = hemi(size=(300, 300))
lineations!(h, trends, plunges, form=:v)
h
```

## Plotting Planar Features

Planar features are plotted using `traces!`:
```@example plot9
using Stereonet
using CairoMakie

h = hemi(net = :wulff, view = (0, 90), size=(300, 300))
traces!(h, 120, 45)  # strike=120°, dip=45°
traces!(h, [250], [70], color=:darkgreen, linestyle= (:dashdot, :dense), linewidth=2)
h
``` 
## Planar Features Attributes

`traces!` attributes are defined as keyword arguments. The following table describes each attribute:

```@raw html
<table>
  <thead>
    <tr class = "columnLabelRow">
      <th style = "font-weight: bold; text-align: left;">Attribute</th>
      <th style = "font-weight: bold; text-align: left;">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr class = "dataRow">
      <td style = "text-align: left;">hemi::Symbol</td>
      <td style = "text-align: left;">Whether to plot in the lower or upper hemisphere. Options: :lower or :upper. Default: :lower</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">view::Symbol</td>
      <td style = "text-align: left;">Whether to represent planes as traces or poles. Options:trace or :pole. Default: :trace</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">polecolor::Symbol</td>
      <td style = "text-align: left;">Fill color of the pole. Default: :black</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">polealpha::Real</td>
      <td style = "text-align: left;">Alpha value of the pole fill color attribute. Default: 1.0</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">strokecolor::Symbol</td>
      <td style = "text-align: left;">Stroke color for pole outlines. Default: :black</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">strokewidth::Real</td>
      <td style = "text-align: left;">Line width for pole outlines. Default: 0</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">linecolor::Symbol</td>
      <td style = "text-align: left;">Line color for traces. Default: :black</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">linewidth::Real</td>
      <td style = "text-align: left;">Line width for traces. Default: 1.3</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">linealpha::Real</td>
      <td style = "text-align: left;">Line alpha value for traces. Default: 1.0</td>
    </tr>
  </tbody>
</table>

```

!!! note
    Plane traces are invariant under hemisphere–dip sign changes; for example,
    (dipdir, dip, hemi = :upper) and (dipdir, -dip, hemi = :lower) produce
    identical great-circle traces.

#### Example: Multiple Planes
```@example plot10
using Stereonet
using CairoMakie

h = hemi(size=(300, 300))

# Plot multiple planes
strikes = [0, 45, 90, 135]
dips = [30, 45, 60, 75]

for (strike, dip) in zip(strikes, dips)
    traces!(h, strikes, dips, color=:green, linewidth=1)
    traces!(h, strikes, dips, color=:green, view=:pole)
end
h
```

## Small Circles

Small circles are conical sections on a sphere, defined by the axis trend and plunge, and the cone’s half-angle.

```@example plot11
using Stereonet
using CairoMakie

h = hemi(size=(300, 300))

# Single small circle
smallc!(h, 0, 90, 30, draw=:line, color=:blue, linewidth=1)    # Draw as line
smallc!(h, 0, 90, 30, draw=:poly, color=:ivory3)    # Draw as filled polygon

# Multiple small circles
trends = [45, 135]
plunges = [15, 5]
half_angles = [15, 15]
smallc!(h, trends, plunges, half_angles, draw=:poly, color=:skyblue)
h
```
## Small Circles Features Attributes

`smallc!` attributes are defined as keyword arguments. The following table describes each attribute:

```@raw html
<table>
  <thead>
    <tr class = "columnLabelRow">
      <th style = "font-weight: bold; text-align: left;">Attribute</th>
      <th style = "font-weight: bold; text-align: left;">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr class = "dataRow">
      <td style = "text-align: left;">draw::Symbol</td>
      <td style = "text-align: left;">Drawing mode. Options are :line (draw circles outlines) or :poly (draw filled cirles). Default is :line</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">fill::Symbol</td>
      <td style = "text-align: left;">Fill color of circles. Default: :skyblue1</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">polyalpha::Real</td>
      <td style = "text-align: left;">Alpha value of the fill attribute. Default: 0.3</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">linecolor::Symbol</td>
      <td style = "text-align: left;">Line color for circles outlines. Default: :black</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">linewidth::Real</td>
      <td style = "text-align: left;">Line width for circles outlines. Default: 1.3</td>
    </tr>
    <tr class = "dataRow">
      <td style = "text-align: left;">linealpha::Real</td>
      <td style = "text-align: left;">Line alpha value for circles outlines. Default: 0.5</td>
    </tr>
  </tbody>
</table>

```

#### Why :line and :poly?

!!! note
    When a small circle intersects the primitive circle outlining the resulting polygons produces visually poor results. 
    The :line option avoids this by allowing the trace to terminate cleanly at the primitive circle. 

```@example plot12
using Stereonet
using CairoMakie

h = hemi(size=(300, 300))

# Poor result
smallc!(h, 0, 0, 30, draw=:poly, color=:bisque, strokecolor=:black, strokewidth=2)

# Better!
smallc!(h, 90, 0, 30, draw=:poly, color=:bisque)
smallc!(h, 90, 0, 30, draw=:line, color=:black, linewidth=2)

h
```

## Saving Plots

Stereonet uses Makie's saving functionality. The format is determined by the active backend and the file extension.

```julia
using Stereonet
using CairoMakie, GLMakie

h = hemi(size=(300, 300))
# ... add your data ...

CairoMakie.activate!()
# Save as PDF
save("path/to/folder/some_plot.pdf", h)

# Save as SVG 
save("path/to/folder/some_plot.svg", h)

GLMakie.activate!()
# Save as PNG
# Default resolution
save("path/to/folder/some_plot.png", h)

# Higher resolution (4x)
save("path/to/folder/some_plot.png", h, px_per_unit = 4)

# Very high resolution (6x)
save("path/to/folder/some_plot.png", h, px_per_unit = 6)
```

!!! tip
    - Use **PDF or SVG** for publications and presentations (scalable, no quality loss)
    - Use **PNG** for web pages and quick previews
    - Increase `px_per_unit` for higher resolution PNGs (values of 2-6 work well)
    - Default size is 600×600 pixels; change with `size=(width, height)` in `hemi()`