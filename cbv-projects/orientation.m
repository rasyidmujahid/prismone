%% orientation:		set ccpoint orientation
%% arguments: 		@points roughing points that want to find their tool orientation
%%					@boundary_points intersection points of vertical slicing lines and 
%%					model that formed a boundar points 
%% returns:			each point in @points + orientation vector
function points_with_orientation = orientation(points, boundary_points, triangles, vertices)

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

	points_with_orientation = [points zeros(size(points))];

	for i = 1:size(points,1)
		point = points(i,:);
		if is_under_cbv(point, boundary_points)
			ccp_outside_cbv = find_closest_ccp_outside_cbv(point, points, boundary_points);
			to_point 		= [ccp_outside_cbv(1) ccp_outside_cbv(2) max(points(:,3))];
			orientation 	= skewed_orientation(point, to_point);
		else
			orientation = [0 0 100];
        end
        points_with_orientation(i, 4:6) = orientation;
    end
end

%% skewed_orientation: build orientation vector from @from point towards @to
function orientation = skewed_orientation(from, to)
	orientation = [to(1)-from(1) to(2)-from(2) to(3)-from(3)];
end