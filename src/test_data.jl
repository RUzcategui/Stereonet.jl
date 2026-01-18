 #=
 Uso de hplines!

Option 1: Scalars without keyword, format defaults to :a
hplines!(w1, 180, 45)

Option 2: Scalars with keyword
hplines!(w1, 90, -45, form=:v) # plots in the upper hemisphere
hplines!(w1, 90, -45, form=:a) # plots in the lower hemisphere
 
Option 3: Vectors without keyword, format defaults to :a
hplines!(w1, [180], [-45])
hplines!(w1, [0, 90, 180, 270], [40, -80, 10, -30])

Option 3: Vectors with keyword
hplines!(w1, [0, 90, 180, 270], [40, -80, 10, -30], form=[:a, :a, :v, :v])
hplines!(w1, [0, 90, 180, 270], [40, -80, 10, -30], form=:v)
hplines!(w1, [0, 90, 180, 270], [40, -80, 10, -30], form=:a)
 =#
 
 # Uso de HPLine
 
 # Option 1: Scalars with keyword
#line1 = HPLine(300, 67.9)  # format defaults to :axis
#line1b = HPLine(300, 67.9; format=:vector)

# Option 2: Vector [trend, plunge]
l1 = [120, 30.0]
#line2 = HPLine(l1)  # format defaults to :axis

# Option 3: Matrix with 2 columns
# form defaults to :axis
l2 = [
    0 45;
    45. 45;
    90 45;
    135 45;
    180 45;
    225 45.;
    270 45;
    315 45
    ]
#line3 = HPLine(l2)  # format defaults to :axis for all rows

# Option 4: Vector with format
l3 = [120.0, 30, :vector]
#line4 = HPLine(l3)

# Option 5: Matrix with format column
l4 = [
    0.0 45 :axis;
    0 45 :vector;
    120 45.0 :axis;
    120.0 45 :vector;
    240 45.0 :axis;
    240.0 45 :vector
]
#line5 = HPLine(l4)
 
# Option 6: Three separate vectors
trends = [0.0, 45.0, 90.0, 135.0]
plunges = [45.0, 45.0, 45.0, 45.0]
formats = [:axis, :vector, :axis, :vector]
#line6 = HPLine(trends, plunges, formats)

# Option 7: Two vectors with default or keyword format
#line7a = HPLine(trends, plunges)  # format defaults to :axis
#line7b = HPLine(trends, plunges; format=:vector)  # all :vector 


    AF_004 = [214 43;
    210	37;
    214	43;
    215	37;
    299	87;
    302	85;
    302	84;
    298	81;
    298	81;
    122	84;
    319	82;
    298	80;
    131	87;
    299	87;
    302	85
    ]

cm1= [
    30 0 20;
    330. 0 20]

cm2= [
    30 0 20;
    330. 20 10]

cm3= [
    30 20 20;
    330. 20 20]

dl = [45 80;
       135 80]
dp = [45 80;
       315 80]
    
#=

hplines!(w1, 0, 45)
hplines!(w1, [60], [45])
hplines!(w1, [10, 75], [45, 34])
hplines!(w1, l1)

l
planes!(w1, l1)



smallc!(w1, 30, 50, 20, draw=:poly)
smallc!(w1, 30, 50, 20, draw=:line)
smallc!(w1, [30, 330], [0, 0], [20, 20], draw=:poly)
smallc!(w1, [30, 330], [0, 0], [20, 20], draw=:line)
smallc!(w1, m, draw=:poly)
smallc!(w1, m, draw=:line)

daylight!(w1, 45, 80, draw=:poly)
daylight!(w1, 45, 80, draw=:line)
daylight!(w1, [45, 315], [80, 80], draw=:poly)
daylight!(w1, [45, 315], [80, 80], draw=:line)
daylight!(w1, m, draw=:poly)
daylight!(w1, m, draw=:line)   

save("..\\figuras\\w1.svg", w1; px_per_unit = 4)

para formato pdf o svf
save("..\\figuras\\w1.svg", w1; backend = CairoMakie)
save("..\\figuras\\w1.pdf", w1; backend = CairoMakie)

para formato png
save("..\\figuras\\w1.png", w1; backend = GLMakie)

To save pngs with higher resolution, do save(...; px_per_unit = 4)
or whatever your desired factor is
GLMakie.activate!()
save("..\\figuras\\w1b.png", w1.fig; px_per_unit = 6)

#para formato png:
GLMakie.activate!()
save("..\\figuras\\w1.png", w1)

para formato pdf o svf
julia> CairoMakie.activate!()
save("..\\figuras\\w1.pdf", w1)
save("..\\figuras\\w1.svg", w1)

CairoMakie despliega en una ventana de Windows
y GLMakie a uma vemtana Makie



s1 = hemi(
    view = (0, 90),
    grid = :show,
    form = :axis,
    net = :schmidt,
    sstep = 5,
    gstep = 5,
    acor = 0,
    grid_color = :black,
    grid_linestyle = :dash,
    grid_linewidth = 0.5,
    grid_alpha = 0.5,
    size = (600,600)
)

w1 = hemi(
    view = (0, 90),
    grid = :show,
    form = :axis,
    net = :wulff,
    sstep = 5,
    gstep = 5,
    acor = 0,
    grid_color = :black,
    grid_linestyle = :dash,
    grid_linewidth = 0.5,
    grid_alpha = 0.5,
    size = (600,600)
)
=#

