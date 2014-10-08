%% layering: 	do layering process to generate roughing path.
%%				 
%% arguments	@intersection_points cell arrays of 
%%					|cc points|slicing line|triangle|normal|,
%%              @points_cloud points cloud
%% returns		ccpoints in sorted order, along with advanced ccpoints under CBV
function [outputs] = layering(maxmin, points_cloud, intersection_points, ...
	vertical_stepover, horizontal_stepover)
	
	outputs = [];

	min_z = maxmin(2,3);
    max_z = maxmin(1,3);

	for z = min_z:vertical_stepover:max_z
        roughing_points_at_z = layering_at(z, points_cloud);
    end
end

%% layering_at: find roughing points at specific z, only returns
%%              ccpoints outside the part
%% arguments    @z at which layering is cutting   
%%              @points_cloud
%%              @intersection_points
%% returns      roughing points at z
function roughing_points = layering_at(z, points_cloud, intersection_points)
    
    points_cloud_at_z = points_cloud;
    points_cloud_at_z(:,:,3) = z;

    roughing_points = find_roughing_points(points_cloud_at_z, intersection_points);
end

%% find_roughing_points:    given points cloud at specified z and vertical intersection, 
%%                          find points that outside the part, which above or below
%%                          intersection points.
%% arguments                @points_cloud_at_z, points cloud at z, and 
%%                          @intersection_points vertical slicing intersection points
%% returns                  points_cloud_at_z outside intersection_points
function [outputs] = find_roughing_points(points_cloud_at_z, intersection_points)
    for i = 1:size(points_cloud_at_z(:,:,1))
        for j = 1:size(points_cloud_at_z(:,:,2))
            point = [points_cloud_at_z(i,j,1) points_cloud_at_z(i,j,2) points_cloud_at_z(i,j,3)]
            if is_outside_part(point, intersection_points)
            end
        end
    end
end

%% is_outside_part: check if a point is outside part
%% arguments        @point to check
%%                  @part_boundary_points boundary points that form the part
%% returns          boolean true if outside, otherwise false if inside or right in its surface
function outside = is_outside_part(point, part_boundary_points)
    slicing_line = point(:,1:2);
    boundary_points_at_this_slicing_line = find_row_in_matrix(slicing_line, part_boundary_points(:,2));
    outside = true;
end