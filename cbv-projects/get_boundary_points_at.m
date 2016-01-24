%% get_boundary_points_at: get boundary points at specified slicing line
function boundary_at_this_slicing_line = get_boundary_points_at(slicing_line, boundary_points)
    % slicing_line
    % cell2mat(boundary_points(:,2))
    boundary_at_this_slicing_line = [];
	row_indices = find_rows_in_matrix(slicing_line, cell2mat(boundary_points(:,2)));
    if ~isempty(row_indices)
        boundary_at_this_slicing_line = sortrows(cell2mat(boundary_points(row_indices,:)), 3);
    end
end