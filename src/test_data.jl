
 
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

l3 = [120.0, 30, :v]
 

# Option 5: Matrix with format column
l4 = [
    0.0 45 :axis;
    0 45 :vector;
    120 45.0 :axis;
    120.0 45 :vector;
    240 45.0 :axis;
    240.0 45 :vector
]
 
 
# Option 6: Three separate vectors
trends = [0.0, 45.0, 90.0, 135.0]
plunges = [45.0, 45.0, 45.0, 45.0]
formats = [:a, :v, :a, :v]
 


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

