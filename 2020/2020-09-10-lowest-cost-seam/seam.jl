cost_matrix = rand(7, 5)

cost_matrix[:, 3] .= 0

cost_matrix

function find_min_cost_path(cost_matrix, row, col)
    if row == size(cost_matrix, 1)
        return cost_matrix[row, col], [(row, col)]
    else
        if col > 1
            min_cost_left, left_path = find_min_cost_path(cost_matrix, row+1, col-1)
        else
            min_cost_left, left_path = Inf, []
        end

        if col < size(cost_matrix, 2)
            min_cost_right, right_path = find_min_cost_path(cost_matrix, row+1, col+1)
        else
            min_cost_right, right_path = Inf, []
        end

        min_cost_middle, middle_path = find_min_cost_path(cost_matrix, row+1, col)

        min_cost, left_centre_right = findmin([min_cost_left, min_cost_middle, min_cost_right])

        best_path = [left_path, middle_path, right_path][left_centre_right]

        pushfirst!(best_path, (row, col))

        return cost_matrix[row, col] + min_cost, best_path
    end
end


best_paths = [find_min_cost_path(cost_matrix, 1, starty) for starty in 1:size(cost_matrix, 2)]

findmin(best_paths)

cost_matrix = rand(10, 10)

cost_matrix[:, 3] .= 0

cost_matrix

@time best_paths = [find_min_cost_path(cost_matrix, 1, starty) for starty in 1:size(cost_matrix, 2)]

findmin(best_paths)

cost_matrix = rand(11, 11)

cost_matrix[:, 3] .= 0

cost_matrix

@time best_paths = [find_min_cost_path(cost_matrix, 1, starty) for starty in 1:size(cost_matrix, 2)]

findmin(best_paths)


cost_matrix = rand(12, 12)

cost_matrix[:, 3] .= 0

cost_matrix

@time best_paths = [find_min_cost_path(cost_matrix, 1, starty) for starty in 1:size(cost_matrix, 2)]

findmin(best_paths)


cost_matrix = rand(13, 13)

cost_matrix[:, 3] .= 0

cost_matrix

@time best_paths = [find_min_cost_path(cost_matrix, 1, starty) for starty in 1:size(cost_matrix, 2)]

findmin(best_paths)


using Memoize

@memoize function find_min_cost_path(cost_matrix, row, col)
    if row == size(cost_matrix, 1)
        return cost_matrix[row, col], [(row, col)]
    else
        if col > 1
            min_cost_left, left_path = find_min_cost_path(cost_matrix, row+1, col-1)
        else
            min_cost_left, left_path = Inf, [(row, col)]
        end

        if col < size(cost_matrix, 2)
            min_cost_right, right_path = find_min_cost_path(cost_matrix, row+1, col+1)
        else
            min_cost_right, right_path = Inf, [(row, col)]
        end

        min_cost_middle, middle_path = find_min_cost_path(cost_matrix, row+1, col)

        min_cost, left_centre_right = findmin([min_cost_left, min_cost_middle, min_cost_right])

        best_path = [left_path, middle_path, right_path][left_centre_right]

        best_path = vcat([(row, col)], best_path)

        return cost_matrix[row, col] + min_cost, best_path
    end
end

cost_matrix = rand(100, 100)

cost_matrix[:, 3] .= 0

cost_matrix

@time best_paths = [find_min_cost_path(cost_matrix, 1, starty) for starty in 1:size(cost_matrix, 2)];

@time res = sort(best_paths, by=x->x[1])[1]
