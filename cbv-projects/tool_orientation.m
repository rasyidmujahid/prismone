%% orientation:		set ccpoint orientation
%% arguments: 		@points roughing points that want to find their tool orientation
%%					@boundary_points intersection points of vertical slicing lines and 
%%					model that formed a boundary points 
%% returns:			each point in @points + orientation vector
function points_with_orientation = tool_orientation(points, boundary_points, vertical_stepover, triangles, vertices)

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
	top_most = max(points(:,3));
	cbv_points_no_outside_neighbour = [];

	for i = 1:size(points,1)
		point = points(i,:);
		points_with_orientation(i, 1:3) = point;
		if is_under_cbv(point, boundary_points)
			new_point = [];
			ccp_outside_cbv = find_closest_ccp_outside_cbv(point, points, boundary_points);

			if ~isempty(ccp_outside_cbv)
				virtual_tool_length = top_most - ccp_outside_cbv(3);
				to_point = [ccp_outside_cbv(1) ccp_outside_cbv(2) top_most];
				[new_point, orientation] = skewed_orientation(point, to_point, virtual_tool_length);

				% check for gouging
				orientation = adjust_after_gouging(orientation);

				points_with_orientation(i, 4:6) = new_point;
			else
				% orientation = [0 0 0];

				disp('Retry, with upper z ...');
				% in case of no neighbour, use upper z
				point(3) = point(3) + vertical_stepover;

				if is_under_cbv(point, boundary_points)
					ccp_outside_cbv = find_closest_ccp_outside_cbv(point, points, boundary_points);

					if ~isempty(ccp_outside_cbv)
						point(3) = point(3) - vertical_stepover;
						virtual_tool_length = top_most - ccp_outside_cbv(3) + vertical_stepover;
						to_point = [ccp_outside_cbv(1) ccp_outside_cbv(2) top_most];
						[new_point, orientation] = skewed_orientation(point, to_point, virtual_tool_length);

						% check for gouging
						orientation = adjust_after_gouging(orientation);

						points_with_orientation(i, 4:6) = new_point;
					else
						disp('ccp_outside_cbv is empty.');
						orientation = [0 0 0];
					end
				else
					disp('is_under_cbv false.');
				end
			end
		else
			orientation = [0 0 100];
        end
        points_with_orientation(i, 7:9) = orientation / norm(orientation);
    end

 %    if ~isempty(cbv_points_no_outside_neighbour)
	% 	% copy to cbv_points without_outside_neighbour
	% 	for m = 1:size(cbv_points_no_outside_neighbour)
	% 		temp_id = cbv_points_no_outside_neighbour(m);
	% 		to_fix_point = points(temp_id,:);
			
	% 		% find cbv_points_no_outside_neighbour that has the same x,y as this point
	% 		neighbour_point_ids = find(points(:,1) == to_fix_point(:,1) & points(:,2) == to_fix_point(:,2))
	% 		to_fix_to_point = [points_with_orientation(neighbour_point_ids(1),[1:2]) top_most]
			
	% 		[to_fix_new_point, to_fix_orientation] = skewed_orientation(to_fix_point, to_fix_to_point, virtual_tool_length);
	% 		points_with_orientation(temp_id,:) = [to_fix_new_point to_fix_orientation];
	% 	end
	% end
end

%% skewed_orientation: build orientation vector from @from point towards @to
function [new_point, orientation] = skewed_orientation(from, to, virtual_tool_length)
	distance = pdist([from; to]);
	new_point = from + (1 - virtual_tool_length / distance) * (to - from);
	orientation = to - from;
end

%% adjust_after_gouging: adjust @orientation to avoid gouging
function after_gouging_orientatation = adjust_after_gouging(orientation)
	after_gouging_orientatation = orientation;
end