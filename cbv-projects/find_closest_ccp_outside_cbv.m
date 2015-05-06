%% find_closest_ccp_outside_cbv: try to find outside cbv ccpoint to form a vector orientation.
%% 				The logic refers to algorithm step #2
%% arguments:	@point point under cbv to find its neighbour ccp
%% 				@boundary_points interserction points
%% returns:		a point which closest and outside cbv
function ccp_outside_cbv = find_closest_ccp_outside_cbv(point, roughing_points, boundary_points)
	neighbour_points = find_neighbour_points(point, roughing_points, boundary_points);
	ccp_outside_cbv = find_closest_neighbour_outside_cbv(point, neighbour_points, boundary_points);
end

%% find_neighbour_points: find all neighbour points along XYZ axis, which possibly 
%%				fall outside cbv.
%% arguments: 	@point point to find all its neighbour
%% 				@roughing_points
%% returns:		neighbour points that some are outside
function outputs = find_neighbour_points(point, roughing_points, boundary_points)
	outputs = [];

	%% neighbour along X axis: find all points with the same X and Z
	neighbour_x = sortrows(...
		roughing_points(...
			float_equals(roughing_points(:,1), point(1)) & ...
			float_equals(roughing_points(:,3), point(3)), ...
			:), ...
		2);
	if ~are_all_under_cbv(neighbour_x, boundary_points)
		outputs = neighbour_x;
	end

	%% neighbour along Y axis: find all points with the same Y and Z
	neighbour_y = sortrows(...
		roughing_points(...
			float_equals(roughing_points(:,2), point(2)) & ...
			float_equals(roughing_points(:,3), point(3)), ...
			:), ...
		1);
	if ~are_all_under_cbv(neighbour_y, boundary_points)
		outputs = [outputs; neighbour_y];
	end
	
	%% neighbour along Z axis: find all points with the same X and Y
	neighbour_z = sortrows(...
		roughing_points(...
			float_equals(roughing_points(:,1), point(1)) & ...
			float_equals(roughing_points(:,2), point(2)), ...
			:), ...
		3);
	if ~are_all_under_cbv(neighbour_z, boundary_points)
		outputs = [outputs; neighbour_z];
	end
end

%% are_all_under_cbv: check if these points are all under cbv
%% arguments:	@sorted_points points sorted from min to max
%% 				@boundary_points
%% returns:		boolean true if all these @sorted_points are under cbv, false otherwise
function under_cbv = are_all_under_cbv(sorted_points, boundary_points)
	%% check min max points only to consider

	%% TODO: cant check only min and max, since if doubled cbv, 
	%% this function will return true, while should be false.
	 
	under_cbv = is_under_cbv(sorted_points(1,:), boundary_points) & ...
		is_under_cbv(sorted_points(end,:), boundary_points);
end

%% find_closest_neighbour_outside_cbv: given an array of neighbour points, find one that 
%%		fall outside cbv.
%% argument:	@point point to find its closest 
%%				@neighbour_points neighbour points in the same axis either of x-y, x-z, y-z
%%				@boundary_points you know lah
%% returns:		a point closest to @point outside cbv
function output = find_closest_neighbour_outside_cbv(point, neighbour_points, boundary_points)
	output = [];
	point_index = find(ismember(neighbour_points, point, 'rows'));
	if isempty(point_index)
		ME = MException('MyComponent:invalidFormat', ...
			'The point which is to find its closest neighbour is not inside neighbour_points');
        throw(ME);
	else
		len = length(neighbour_points);
		backward_index = point_index;
        forward_index  = point_index;

		while true
			backward_index = backward_index - 1;
			forward_index  = forward_index + 1;

			if backward_index > 0
                closest_ccp = neighbour_points(backward_index, :);
				if ~is_under_cbv(closest_ccp, boundary_points)
					output = closest_ccp;
					break;
				end
			end
			if forward_index > 0 & forward_index <= len
                closest_ccp = neighbour_points(forward_index, :);
				if ~is_under_cbv(closest_ccp, boundary_points)
					output = closest_ccp;
					break;
				end
			end
			if backward_index <= 0 & forward_index > len
				break;
			end
		end
	end
end

%% float_equals: check if two float numbers are equals, with 000.1 tolerance
function is_equal = float_equals(float1, float2)
	tolerance = 0;
	is_equal = abs(float2 - float1) <= tolerance;
end