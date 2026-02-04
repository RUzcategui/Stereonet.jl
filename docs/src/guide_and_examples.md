```@meta
CurrentModule = Stereonet
```

## User Guide

### Creating a Stereonet

Create a stereonet with default attributes:
```@example plot1
using Stereonet
h = hemi(size=(300, 300))
``` 

#### Grid and Frame Attributes

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

#### Net view direction

Nets are usually displayed with the primitive oriented horizontally (viewed from above). With the attribute view, a net can be generated from any desired direction:

```@example plot2
using Stereonet

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
### Plotting Linear Features

Linear features (lines, poles, axes) are plotted using `scatter!`:

```@example plot3
using Stereonet
import Makie: scatter!

h = hemi(net = :schmidt, size=(300, 300))
scatter!(h, 300, 20)  # trend=300°, plunge=20°
scatter!(h, [50], [0], marker = :rect, 
        markersize = 11, color = :yellow1)
scatter!(h, [220, 180, 140], [50, 50, 50], marker = :xcross, 
        markersize = 13, color = :green)       
h
``` 

#### Linear Features Attributes

The `scatter!` function accepts standard Makie scatter attributes plus one special attribute:

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
  </tbody>
</table>
```
		     
		    	    
!!! note
    For linear data, hemisphere selection is encoded in the orientation itself. Plunge sign and form control whether antipodal directions are distinguished:

**Behavior with positive plunge (downward):**
- Both `:a` and `:v` plot the point at the same location on the lower hemisphere

```@example plot4
using Stereonet
import Makie: scatter!

h = hemi(net = :wulff, view = (0, 90), size=(300, 300))
scatter!(h, [90, 90], [45, 45], form = [:v, :a], color = :red)
h
```

**Behavior with negative plunge (upward):**
- `:a` (axis): Plots the antipode point on the lower hemisphere
- `:v` (vector): Plots the point on the upper hemisphere

```@example plot5
using Stereonet
import Makie: scatter!

h = hemi(net=:wulff, view=(0, 90), size=(300, 300))
scatter!(h, [90], [-45], form = [:a], color = :green)
scatter!(h, [90], [-45], form = [:v], color = :red)
h
```

!!! note
    When using :v with negative plunge, you may want to distinguish between lower and upper hemisphere points. One approach is to use hollow markers:

```@example plot6
using Stereonet
import Makie: scatter!

h = hemi(net = :wulff, view = (0, 90), size=(300, 300))
scatter!(h, 270, -20, form = :v, 
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
import Makie: scatter!

trends = [0.0, 45.0, 90.0, 135.0]
plunges = [15.0, 30.0, -45.0, -60.0]
forms = [:a, :v, :a, :v] 

h = hemi(size=(300, 300))
scatter!(h, trends, plunges, form=forms)
h
``` 

##### Same Form for All Points
```@example plot8
using Stereonet
import Makie: scatter!

trends = [0.0, 45.0, 90.0, 135.0]
plunges = [15.0, 30.0, -45.0, -60.0]

h = hemi(size=(300, 300))
scatter!(h, trends, plunges, form=:v)
h
```

### Plotting Planar Features

Planar features (great circles) are plotted using `lines!`:
```@example plot9
using Stereonet
import Makie: lines!

h = hemi(net = :wulff, view = (0, 90), size=(300, 300))
lines!(h, 120, 45)  # strike=120°, dip=45°
lines!(h, [250], [70], color=:darkgreen, linestyle= (:dashdot, :dense), linewidth=2)
h
``` 
#### Planar Features Attributes

The `lines!` function accepts standard Makie scatter attributes plus two special attribute:

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
import Makie: lines!

h = hemi(size=(300, 300))

# Plot multiple planes
strikes = [0, 45, 90, 135]
dips = [30, 45, 60, 75]

for (strike, dip) in zip(strikes, dips)
    lines!(h, strikes, dips, color=:green, linewidth=1)
    lines!(h, strikes, dips, color=:green, view=:pole)
end
h
```

### Small Circles

Small circles are conical sections on a sphere, defined by the axis trend and plunge, and the cone’s half-angle.

#### Small Circles

```@example plot11
using Stereonet
import Makie: lines!
import Makie: poly!

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

#### Why :line and :poly

!!! note
    When a small circle intersects the primitive circle outlining the resulting polygons produces visually poor results. 
    The :line option avoids this by allowing the trace to terminate cleanly at the primitive circle. 

```@example plot12
using Stereonet
import Makie: lines!
import Makie: poly!

h = hemi(size=(300, 300))

# Poor result
smallc!(h, 0, 0, 30, draw=:poly, color=:bisque, strokecolor=:black, strokewidth=2)

# Better!
smallc!(h, 90, 0, 30, draw=:poly, color=:bisque)
smallc!(h, 90, 0, 30, draw=:line, color=:black, linewidth=2)

h
```

### Saving Plots

Stereonet uses Makie's saving functionality. The format is determined by the file extension.

#### Vector Formats (PDF, SVG)

For publication-quality vector graphics, use CairoMakie backend:
```julia
using Stereonet
import Makie: save

h = hemi(size=(300, 300))
# ... add your data ...

# Save as PDF
save("path/to/folder/some_plot.pdf", h)

# Save as SVG 
save("path/to/folder/some_plot.svg", h)
```

#### Raster Formats (PNG)

For raster images, use GLMakie backend with custom resolution:
```julia
using Stereonet, GLMakie
import Makie: save

h = hemi(size=(300, 300))
# ... add your data ...

# Save with default resolution
save("path/to/folder/some_plot.png", h)

# Save with higher resolution (4x)
save("path/to/folder/some_plot.png", h,px_per_unit = 4)

# Save with very high resolution (6x)
save("path/to/folder/some_plot.png", h,px_per_unit = 6)
```

#### Backend Activation

You can explicitly activate backends before saving:
```julia
using Stereonet
using CairoMakie, GLMakie
import Makie: save

h = hemi(size=(300, 300))
# ... add your data ...

# For vector formats
CairoMakie.activate!()

save("path/to/folder/some_plot.pdf", h)
save("path/to/folder/some_plot.psvg", h)

# For raster formats
GLMakie.activate!() 
save("path/to/folder/some_plot.png", h,px_per_unit = 4)
```

!!! tip
    - Use **PDF or SVG** for publications and presentations (scalable, no quality loss)
    - Use **PNG** for web pages and quick previews
    - Increase `px_per_unit` for higher resolution PNGs (values of 2-6 work well)
    - Default size is 600×600 pixels; change with `size=(width, height)` in `hemi()`