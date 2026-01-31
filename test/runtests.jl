using LinearAlgebra
using Test
using HemiPlots

@testset "HemiPlots.jl" begin

    # --------------------------------------------------
    # Geometry fundamentals
    # --------------------------------------------------
    @testset "Geometry basics" begin

        @testset "normal_vector" begin
            n = HemiPlots.normal_vector(90, 45)
            @test isapprox(norm(n), 1.0; atol=1e-10)
            @test n[3] > 0                 # downward-positive Z
        end

        @testset "change_view_direction" begin
            view = (40, 45)
            n0 = HemiPlots.normal_vector(120, 30)
            n1 = HemiPlots.change_view_direction(n0, view, 0; reproject=false)

            @test isapprox(norm(n1), 1.0; atol=1e-10)
            @test all(isfinite, n1)

            n0 = HemiPlots.normal_vector(0, 30)
            
            view = (0, 30)
            n1 = HemiPlots.change_view_direction(n0, view, 0; reproject=false)
            @test isapprox(n1[1], -1.0; atol=1e-10)
            @test isapprox(n1[2], 0.0; atol=1e-10)
            @test isapprox(n1[3], 0.0; atol=1e-10)
        end
    end

    # --------------------------------------------------
    # Great circles
    # --------------------------------------------------
    @testset "Great circles" begin

        n = HemiPlots.normal_vector(90, 45)
        strike = [1.0, 0.0, 0.0]
        view = (0, 90)

        gc = HemiPlots.great_circle(n, strike, 5, closed=false)

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

        lower = HemiPlots.select_hemisphere(m, :lower)
        upper = HemiPlots.select_hemisphere(m, :upper)

        @test all(lower[:,3] .≥ -1e-10)
        @test all(upper[:,3] .≤  1e-10)
    end


    # --------------------------------------------------
    # Small circles
    # --------------------------------------------------
    @testset "Small circles" begin

        axis = [1.0, 0.0, 0.0]
        sc = HemiPlots.small_circle(axis, 30)

        @test size(sc, 2) == 3
        @test all(abs.(sqrt.(sum(sc.^2, dims=2)) .- 1) .< 1e-10)
        @test all(isfinite, sc)

    end
end

