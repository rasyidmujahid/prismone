%% sort_by_cbv_direction: sort rows by cbv direction
function outputs = get_cbv_direction(roughing_points, cbv_points, boundary_points)

    % take one cbv point randomly
    middle_row = floor(size(cbv_points) / 2);
    point = cbv_points(middle_row(1),:);

    % find the point's neigbour to check for cbv
    neighbour_x = sortrows(...
        roughing_points(...
            float_equals(roughing_points(:,1), point(1)) & ...
            float_equals(roughing_points(:,3), point(3)), ...
            :), ...
        2);
    neighbour_y = sortrows(...
        roughing_points(...
            float_equals(roughing_points(:,2), point(2)) & ...
            float_equals(roughing_points(:,3), point(3)), ...
            :), ...
        1);

    if ~isempty(neighbour_x) && are_all_under_cbv(neighbour_x, boundary_points)
        outputs = [1 2];
    elseif ~isempty(neighbour_y) && are_all_under_cbv(neighbour_y, boundary_points)
        outputs = [2 1];
    else
        outputs = [1 2];
    end
end

%% float_equals: check if two float numbers are equals, with 0.0001 tolerance
function is_equal = float_equals(float1, float2)
    tolerance = 0.0001;
    is_equal = abs(float2 - float1) <= tolerance;
end