
function ticks_coords(len, step)
    t = []  
    for θ in 0:step:360
        xi, yi = cosd(θ), sind(θ)
        xf, yf = (1 + len) .* (xi, yi)
        
        push!(t, [xi yi 0.0])
        push!(t, [xf yf 0.0])
        push!(t, [NaN NaN NaN])
    end
    
    return vcat(t...,)
end

function filter_ticks(matrix::Matrix{Float64})
    #extract end point of each tick line
    n_rows = size(matrix, 1)
    selected_rows = Int[]
    for i in 2:3:n_rows-2
        push!(selected_rows, i)
    end
    return matrix[selected_rows, 1:2]
end

step_to_strings(step::Int) = [lpad(string(n), 3, '0') for n in 0:step:(360-step)]



function extract_coordinate_groups(matrix)
    """
    Extract groups of coordinate rows separated by NaN rows.
    
    Args:
        matrix: n×2 matrix containing coordinates and NaN separators
    
    Returns:
        Vector of matrices, each containing one group of coordinates
    """
    
    # Find rows that are NOT all NaN
    valid_rows = .!all(isnan.(matrix), dims=2)[:]
    
    # Find the start and end indices of consecutive valid row groups
    groups = Vector{Matrix{Float64}}()
    
    if !any(valid_rows)
        return groups  # Return empty if no valid rows
    end
    
    # Find transitions from invalid to valid (group starts) and valid to invalid (group ends)
    group_starts = Int[]
    group_ends = Int[]
    
    in_group = false
    for i in 1:length(valid_rows)
        if valid_rows[i] && !in_group
            # Start of a new group
            push!(group_starts, i)
            in_group = true
        elseif !valid_rows[i] && in_group
            # End of current group
            push!(group_ends, i-1)
            in_group = false
        end
    end
    
    # Handle case where matrix ends with a valid group
    if in_group
        push!(group_ends, length(valid_rows))
    end
    
    # Extract each group
    for i in 1:length(group_starts)
        start_idx = group_starts[i]
        end_idx = group_ends[i]
        group_matrix = matrix[start_idx:end_idx, :]
        push!(groups, group_matrix)
    end
    
    return groups
end

function translate_tick(tick, pos)

    x1, y1 = pos 
    centroid = [mean(tick[:, 1]), mean(tick[:, 2])]
    translation = [x1 - centroid[1], y1 - centroid[2]]
    translated_tick = tick .+ translation'

    return translated_tick
    
end

function ticks_in_legend(a)
    return [2a - 1, 2a]
end

function legend_ticks_coords(in_legend, lb, tks)
    
    # Constants
    base_x = 1.3
    base_y = -0.6
    y_offset = 0.125
    separator = [NaN NaN]
    
    pos = indexin(lb[BitVector(in_legend)], lb)
    cil = count(in_legend)
    
    result = []
    
    for i in 1:cil
        y_coord = base_y - (i - 1) * y_offset
        a, b = ticks_in_legend(pos[i])
        
        tk1 = translate_tick(tks[a], (base_x, y_coord))
        tk2 = translate_tick(tks[b], (base_x, y_coord))
        
        append!(result, [tk1, separator, tk2])
        if i < cil
            push!(result, separator)
        end
    end
    
    return vcat(result...)
end
