%% is_under_cbv: to check if a point is inside closed bounded volume
function inside = is_under_cbv(point, boundary_points)
    slicing_line = point(1:2);
    boundary_at_this_slicing_line = get_boundary_points_at(slicing_line, boundary_points);
    
    inside = true;
    boundary_length = size(boundary_at_this_slicing_line,1);
    if mod(boundary_length,2) == 0 && boundary_length > 2
        % only take into action if boundary is a pair
        for m = 2:2:boundary_length-1
            inside = inside && ( boundary_at_this_slicing_line(m,3) < point(1,3) && point(1,3) < boundary_at_this_slicing_line(m+1,3) );
        end
    else
        inside = false;
    end
end

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

