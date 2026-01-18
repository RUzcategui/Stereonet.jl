# HemiPlots.jl

**HemiPlots.jl** is a Julia package for plotting hemispherical projection
using Makie.

It provides fast, flexible visualization of planes, lines, small circles,
and daylight envelopes under arbitrary viewing directions.

> HemiPlots is a plotting-only package, etc...

---

## Installation
] add HemiPlots

## Basic usage

using HemiPlots
using GLMakie

## Create a stereonet:

h = hemi(net = :wulff, view = (0, 90))
display(h)

## Plot planes

lines!(h, 120, 45)                 # plane trace
lines!(h, 120, 45, view = :pole)   # pole to plane

Multiple planes:

lines!(h, [30, 60, 90], [40, 50, 60])

## Plot lineations

scatter!(h, 45, 30)
scatter!(h, [10, 40], [20, 60])

## Small circles

smallc!(h, 0, 0, 30)
smallc!(h, [0, 90], [0, 0], [20, 40])

Filled small circles

smallc!(h, 0, 0, 30, draw = :poly)

## Datlight envelopes

daylight!(h, 90, 45)
daylight!(h, 90, 45, draw = :poly)

Filled small circles

Explicar...

## Saving figures

save("stereonet.png", h)
save("stereonet.pdf", h)  # requires CairoMakie

esxplicar los detalles

## Citation

como se hace la cita de una repo github
