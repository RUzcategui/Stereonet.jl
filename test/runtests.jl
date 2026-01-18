using Test
using HemiPlots
using LinearAlgebra

@testset "HemiPlots.jl" begin

    # --------------------------------------------------
    # Geometry fundamentals
    # --------------------------------------------------
    @testset "Geometry basics" begin

        @testset "normal_vector" begin
            n = normal_vector(90, 45)
            @test isapprox(norm(n), 1.0; atol=1e-10)
            @test n[3] > 0                 # downward-positive Z
        end

        @testset "change_view_direction" begin
            view = (40, 45)
            n0 = normal_vector(120, 30)
            n1 = change_view_direction(n0, view, 0; reproject=false)

            @test isapprox(norm(n1), 1.0; atol=1e-10)
            @test all(isfinite, n1)

            n0 = normal_vector(0, 30)
            
            view = (0, 30)
            n1 = change_view_direction(n0, view, 0; reproject=false)
            @test isapprox(n1[1], -1.0; atol=1e-10)

            view = (0, 30)
            n1 = change_view_direction(n0, view, 0; reproject=false)
            @test isapprox(n1[3], 1.0; atol=1e-10)
        end

    end


    # --------------------------------------------------
    # Great circles
    # --------------------------------------------------
    @testset "Great circles" begin

        n = normal_vector(90, 45)
        strike = [1.0, 0.0, 0.0]
        view = (0, 90)

        gc = great_circle(n, strike, 5, closed=false)

        @test size(gc, 2) == 3
        @test all(abs.(sqrt.(sum(gc.^2, dims=2)) .- 1) .< 1e-10)
        @test all(isfinite, gc)

    end


    # --------------------------------------------------
    # Hemisphere selection
    # --------------------------------------------------
    @testset "Hemisphere selection" begin

        m = [
            0.0  0.0  1.0;
            0.0  1.0 -1.0;
            1.0  0.0  1.0
        ]

        lower = select_hemisphere(m, :lower)
        upper = select_hemisphere(m, :upper)

        @test all(lower[:,3] .≥ -1e-10)
        @test all(upper[:,3] .≤  1e-10)
    end


    # --------------------------------------------------
    # Small circles
    # --------------------------------------------------
    @testset "Small circles" begin

        axis = [1.0, 0.0, 0.0]
        sc = small_circle(axis, 30)

        @test size(sc, 2) == 3
        @test all(abs.(sqrt.(sum(sc.^2, dims=2)) .- 1) .< 1e-10)
        @test all(isfinite, sc)

    end


    # --------------------------------------------------
    # Daylight envelope
    # --------------------------------------------------
    @testset "Daylight envelope" begin

        segs = daylight_coordinates(90, 45, :wulff, (0, 90), 0)

        @test length(segs) ≥ 1

        for s in segs
            @test size(s, 2) == 2
            @test all(isfinite, s)
        end

    end


    # --------------------------------------------------
    # View robustness
    # --------------------------------------------------
    @testset "View robustness" begin

        segs1 = daylight_coordinates(90, 45, :wulff, (0, 90), 0)
        segs2 = daylight_coordinates(90, 45, :wulff, (40, 45), 0)

        @test length(segs1) ≥ 1
        @test length(segs2) ≥ 1
    end

end

