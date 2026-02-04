using PrettyTables

function generate_attributes_table()
    # Define your attributes data
    data = [
        "net::Symbol" "Projection type. Choose between :wulff for equiangular projections and :schmidt for equiareal projection. Default: :wulff";
        "sstep::Int" "Angular spacing (degrees) for small-circle grid. Default: 10";
        "gstep::Int" "Angular spacing (degrees) for great-circle grid. Default: 10";
        "view::Tuple{Real,Real}" "Viewing direction as (trend, plunge) in degrees. Default: (0, 90) (vertically downward)";
        "acor::Real" "Additional rotation angle (degrees) around the z-axis applied after view transformation. Default: 0";
        "frame::Symbol" "Frame consists of NS and EW vertical planes when view=(0, 90). Options: :show or :hide. Default: :show";
        "grid::Symbol" "Whether to draw the stereonet grid. Options: :show or :hide. Default: :show. Note: Grid cannot be :show when frame is :hide. Setting this will change grid to :hide with a warning";
        "size::Tuple{Int,Int}" "Figure size in pixels. Default: (600, 600)";
        "grid_color::Symbol" "Color for grid and frame elements. Default: :gray";
        "grid_linestyle::Symbol" "Line style for grid and frame elements. Default: :dash";
        "grid_linewidth::Real" "Line width for grid and frame elements. Default: 0.5";
        "grid_alpha::Real" "Transparency for grid and frame elements (0.0 to 1.0). Default: 1.0";
        "ticks::Symbol" "Whether to draw tick marks outside the primitive circle. Options: :show or :hide. ⚠️ Work in progress - use with caution";
        "tstep::Int" "Angular spacing (degrees) for tick marks. Default: 10. ⚠️ Work in progress - use with caution";
        "tlen::Real" "Length of tick marks. Default: 0.015. ⚠️ Work in progress - use with caution"
    ]
    
    # Generate HTML table using PrettyTables with correct keywords
    html_output = pretty_table(String, data;
        backend = :html,
        column_labels = ["Attribute", "Description"],  # Changed from header!
        show_column_labels = true,
        stand_alone = false,
        alignment = [:l, :l]
    )
    
    return html_output
end

function generate_scatter_attribute_table()
    data = [
        "form::Union{Symbol, AbstractVector{Symbol}}" "Determines whether linear features are treated as axes or vectors, choose between :a for axes and :v for vectors. Default: :a"
    ]

    html_output = pretty_table(String, data;
        backend = :html,
        column_labels = ["Attribute", "Description"],
        show_column_labels = true,
        stand_alone = false,
        alignment = [:l, :l]
    )

    return html_output
end

function generate_lines_attribute_table()
    data = [
        "hemi::Symbol" "Whether to plot in the lower or upper hemisphere. Options: :lower or :upper. Default: :lower";
        "view::Symbol" "Whether to represent planes as traces or poles. Options:trace or :pole. Default: :trace"
    ]

    html_output = pretty_table(String, data;
        backend = :html,
        column_labels = ["Attribute", "Description"],
        show_column_labels = true,
        stand_alone = false,
        alignment = [:l, :l]
    )

    return html_output
end

function update_guide()

    attrs_table = generate_attributes_table()
    lineations_table   = generate_scatter_attribute_table()
    traces_table   = generate_lines_attribute_table()
    
    guide_path = joinpath(@__DIR__, "src", "guide_and_examples.md")
    
    if !isfile(guide_path)
        error("guide_and_examples.md not found at $guide_path")
    end
    
    guide_content = read(guide_path, String)

    # Insert attributes table
    if contains(guide_content, "<!-- ATTRIBUTES_TABLE -->")
        guide_content = replace(guide_content, 
            "<!-- ATTRIBUTES_TABLE -->" => """
            ```@raw html
            $(attrs_table)
            \```
            """)
        println("✓ Attributes table updated in guide_and_examples.md")
    else
        @warn "No <!-- ATTRIBUTES_TABLE --> placeholder found in guide_and_examples.md"
    end

    # Insert lineations! attribute table
	if contains(guide_content, "<!-- LINEATIONS_TABLE -->")
		guide_content = replace(guide_content,
			"<!-- LINEATIONS_TABLE -->" => """
            ```@raw html
			$(lineations_table)
            \```
		    """)
        println("✓ Lineations attribute table updated in guide_and_examples.md")
	else
		@warn "No <!-- LINEATIONS_TABLE --> placeholder found in guide_and_examples.md"
    end

        # Insert traces! attribute table
	if contains(guide_content, "<!-- TRACES_TABLE -->")
		guide_content = replace(guide_content,
			"<!-- TRACES_TABLE -->" => """
            ```@raw html
			$(traces_table)
            \```
		    """)
        println("✓ Traces attribute table updated in guide_and_examples.md")
	else
		@warn "No <!-- TRACES_TABLE --> placeholder found in guide_and_examples.md"
    end

    # Write back to file
    open(guide_path, "w") do f
        write(f, guide_content)
    end
    println("✓ Tables updated in guide_and_examples.md") 
end

# Run the update
update_guide()

