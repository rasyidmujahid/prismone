%% orientation:		set ccpoint orientation
%% arguments: 		@points roughing points that want to find their tool orientation
%%					@boundary_points intersection points of vertical slicing lines and 
%%					model that formed a boundar points 
%% returns:			each point in @points + orientation vector
function outputs = orientation(points, boundary_points)
	outputs = [];


	%% algorithm:
	%% 1. loop over ccpoints under CBV
	%% 2. foreach the ccpoint, find neighbour ccpoint that fall outside CBV
	%%    How to find that neighbour ccp:
	%%    a. loop over all ccp along x,y,z coordinate
	%%    b.        .  .
	%%              . .
	%%    ..........o...........>
	%%            . .
	%%           .  .
	%% 3. if ccp outside CBV found, take its max z-upper as end-point to where 
	%%    ccp will skew its orientation
	%% 4. check for gouging, if it is, take lower z-upper
	%% 5. done



	turning_points = [];
	for i = 1:size(points,1)
		point = points(i,:);
		if is_under_cbv(point, get_boundary_points_at(point(1:2), boundary_points))
			orientation = skewed_orientation(point, boundary_points);
		else
			orientation = [point(1) point(2) point(3)+5];
		end
		outputs = [outputs; [point  orientation]];
	end
end

%% skewed_orientation: 	build a vector from this point towards another point outside cbv 
%%						closest to this point
%% arguments:			@point point that want to find its vector
%%						@boundary_points intersection points
%% returns: 			orientation vector thru ccp outside cbv
function orientation_vector = skewed_orientation(point, boundary_points)
	ccp_outside_cbv = find_closest_ccp_outside_cbv(point, boundary_points);
	orientation_vector = [];
end

%% find_closest_ccp_outside_cbv: try to find outside cbv ccpoint to form a vector orientation
function closest_ccp = find_closest_ccp_outside_cbv(point, boundary_points)

	closest_ccp = [];
end

%% turning_point_before_cbv: find slicing line right before enter cbv
function output = turning_points_before_cbv(boundary_points)

	output = [];
end

%% get_boundary_points_at: get boundary points at specified slicing line
function boundary_at_this_slicing_line = get_boundary_points_at(slicing_line, boundary_points)
	row_indices = find_rows_in_matrix(slicing_line, cell2mat(boundary_points(:,2)));
    boundary_at_this_slicing_line = cell2mat(boundary_points(row_indices,:));
    
    % sort by z value ascending
    boundary_at_this_slicing_line = sortrows(boundary_at_this_slicing_line, 3);
end

%% is_under_cbv: to check if a point is inside closed bounded volume
function inside = is_under_cbv(point, boundary_at_this_slicing_line)
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