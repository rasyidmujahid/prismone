%% orientation:		set ccpoint orientation
%% arguments: 		@points roughing points that want to find their tool orientation
%%					@boundary_points intersection points of vertical slicing lines and 
%%					model that formed a boundar points 
%% returns:			each point in @points + orientation vector
function outputs = orientation(points, boundary_points, triangles, vertices)

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

	outputs = [];

	for i = 1:size(points,1)
		point = points(i,:);
		if is_under_cbv(point, boundary_points))
			ccp_outside_cbv = find_closest_ccp_outside_cbv(point, points, boundary_points);
			orientation = skewed_orientation(point, ccp_outside_cbv);
			
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
	
	orientation_vector = [];
end

%% turning_point_before_cbv: find slicing line right before enter cbv
function output = turning_points_before_cbv(boundary_points)

	output = [];
end