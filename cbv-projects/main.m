%% ================================================
%% Read STL file
%% ================================================

folder = 'C:\Project\Mas Wawan\cbv\cobabentuk';
% filename = 'coba10';
filename = 'coba kontur';
% filename = 'bentuk A';

stlpath = strcat(folder, '/', filename, '.txt');
triangles_csv = strcat(folder, '/', filename, '_t.csv');
vertices_csv = strcat(folder, '/', filename, '_v.csv');

if exist(triangles_csv) && exist(vertices_csv)
	disp(['Read from file...', triangles_csv, ' and ', vertices_csv, '.']);
	T = csvread(triangles_csv);
	V = csvread(vertices_csv);
else
	[T, V] = stlreader(stlpath);
	csvwrite(triangles_csv, T);
	csvwrite(vertices_csv, V);
end

[partVolume, partArea] = stlVolume(V', T(:,1:3)')

%% ================================================
%% If need to plot normal vector on each triangle
%% ================================================

%% find center of triangles
%% loop over triangles, foreach triangle T
%% foreach their vertices v
%% calculate their avarages point
for i = 1:size(T,1)
    vid1 = T(i,1);  % first vertex ID
    vid2 = T(i,2);
    vid3 = T(i,3);
    centerX = ( V(vid1,1) + V(vid2,1) + V(vid3,1) ) / 3;
    centerY = ( V(vid1,2) + V(vid2,2) + V(vid3,2) ) / 3;
    centerZ = ( V(vid1,3) + V(vid2,3) + V(vid3,3) ) / 3;
    tricenter(i,:) = [centerX centerY centerZ];
end

%% ================================================
%% Roughing parameters
%% ================================================
density = 5; % density determines how wide points cloud
              % will be, horizontal stepover is also
              % following this density.
horizontal_stepover = density;
vertical_stepover   = 5;
tool_length = 10;
offset = [10 10 10];
effective_tool_length = 20;

max_min = maxmin(V);

%% ================================================
%% Generate cutter contact points
%% ================================================
[intersection_points, points_cloud] = ccpoint(T(:,1:3), V, T(:,4:6), ...
    max_min, horizontal_stepover);
ccp = cell2mat(intersection_points(:,1));

%% ================================================
%% Create map matrix
%% ================================================

% cbv_map = map_matrix(intersection_points, points_cloud);

%% ================================================
%% Create horizontal intersection.
%% The direction goes from left to right, top to bottom.
%% Horizontal stepover value is following the density value.
%% This is actually just like ccpoint generation for roughing,
%% but it is connecting the already generated points cloud.
%% ================================================
roughing_points = layering(max_min, points_cloud, intersection_points, ...
    vertical_stepover, horizontal_stepover);

%% cbv_points only
cbv_points = [];
for i = 1:size(roughing_points,1)
    if is_under_cbv(roughing_points(i,1:3), intersection_points)
        cbv_points = [cbv_points; roughing_points(i,1:3)];
    end
end

%% ================================================
%% Build ccpoint orientation
%% ================================================

roughing_points = tool_orientation(roughing_points, intersection_points, vertical_stepover, T, V);

%% ================================================
%% save to NC file
%% ================================================
under_cbv_points = roughing_points(find(roughing_points(:,4) ~= 0 & roughing_points(:,5) ~= 0 & roughing_points(:,6) ~= 0),:);
nc = save_nc_file(under_cbv_points(:,3), under_cbv_points(:,4), under_cbv_points(:,5), ...
    under_cbv_points(:,7), under_cbv_points(:,8), under_cbv_points(:,9), ...
    offset(1), offset(2), offset(3), effective_tool_length, 'table', filename);

%% ================================================
%% Volume calculation: Part & CBV
%% ================================================

totalVolume = (max_min(1,1) - max_min(2,1)) * (max_min(1,2) - max_min(2,2)) * (max_min(1,3) - max_min(2,3))
invertedVolume = totalVolume - partVolume

cbv_boundary_points = [];
for i = 1:size(points_cloud,1)
    for j = 1:size(points_cloud,2)
        sl = [points_cloud(i,j,1) points_cloud(i,j,2)];
        boundary_at_this_slicing_line = get_boundary_points_at(sl, intersection_points);
        if (size(boundary_at_this_slicing_line,1)) > 2
            %% it means under cbv
            cbv_boundary_points = [cbv_boundary_points; boundary_at_this_slicing_line(2:3,1:3)];
        end
    end
end

dt = DelaunayTri(cbv_boundary_points(:,1), cbv_boundary_points(:,2), cbv_boundary_points(:,3));
tri = dt(:,:);
cbv_volume = stlVolume(cbv_boundary_points(:,1:3)', tri')

%% ================================================
%% Volume calculation: Cut CBV
%% ================================================

%% DOWN BELOW

%% ================================================
%% Plot points
%% ================================================

X = V(:, 1);
Y = V(:, 2);
Z = V(:, 3);

trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
% trisurf ( T(:,1:3), X, Y, Z );

axis equal;

xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );

hold on;

%% plot cbv volume part
% trisurf(tri, cbv_boundary_points(:,1), cbv_boundary_points(:,2), cbv_boundary_points(:,3));

%% plot cutting cbv
all_z = unique(roughing_points(:,3));
all_y = unique(roughing_points(:,2));
total_cutting_cbv_volume = 0;
for i = 1:size(all_z,1)
    z = all_z(i);
    indices = find_rows_in_matrix(z, roughing_points(:,3));

    roughing_points_at_this_z = roughing_points(indices,:);
    cbv_points_at_this_z = [];
    for j = 1:size(roughing_points_at_this_z,1)
        if (~isequal(roughing_points_at_this_z(j,7:9), [0 0 100]))
            cbv_points_at_this_z = [cbv_points_at_this_z; roughing_points_at_this_z(j,:)];
        end 
    end
    
    if (isempty(cbv_points_at_this_z))
        continue;
    end

    for j = 1:size(all_y,1)
        y = all_y(j);
        indices = find_rows_in_matrix(y, cbv_points_at_this_z(:,2));
        last_index = indices(end);
        last_cbv_point_at_this_z_y = cbv_points_at_this_z(last_index,:);
        tool_handle_origin_point = last_cbv_point_at_this_z_y(:,4:6) + ...
            tool_length * last_cbv_point_at_this_z_y(:,7:9) / norm(last_cbv_point_at_this_z_y(:,7:9));
        cbv_points_at_this_z = [cbv_points_at_this_z; [0 0 0 tool_handle_origin_point -last_cbv_point_at_this_z_y(:,7:9)]];

        %% =================================================
        %% calculate cutting cbv volume
        %% =================================================
        if (j == 1)
            first_index = indices(1);
            first_cbv_point_at_this_z_y = cbv_points_at_this_z(first_index,4:6);
            last_cbv_point_at_this_z_y = last_cbv_point_at_this_z_y(:,4:6);
            u = first_cbv_point_at_this_z_y - tool_handle_origin_point;
            v = last_cbv_point_at_this_z_y - tool_handle_origin_point;
            angle = atan2(norm(cross(u,v)),dot(u,v))
            angle_degree = angle / pi * 180
            cbv_part_volume = angle / (2 * pi) * (pi * tool_length ^ 2) * (max_min(1,2) - max_min(2,2))
            intersected_cbv_volume = angle / (2 * pi) * (pi * (tool_length - vertical_stepover) ^ 2) * (max_min(1,2) - max_min(2,2))
            cbv_part_volume = cbv_part_volume - intersected_cbv_volume
            total_cutting_cbv_volume = total_cutting_cbv_volume + cbv_part_volume;
        end
    end

    dt = DelaunayTri(cbv_points_at_this_z(:,4), cbv_points_at_this_z(:,5), cbv_points_at_this_z(:,6));
    tri = dt(:,:);

    if isempty(tri)
        continue;
    end

    trisurf(tri, cbv_points_at_this_z(:,4), cbv_points_at_this_z(:,5), cbv_points_at_this_z(:,6));
    cbv_part_volume__ = stlVolume(cbv_points_at_this_z(:,4:6)', tri')
end

total_cutting_cbv_volume

%% plot normal vector along with triangle surface
%%% quiver3( tricenter(:,1), tricenter(:,2), tricenter(:,3), T(:,4), T(:,5), T(:,6) );

%% plot points cloud
% plot3(points_cloud(:,:,1), points_cloud(:,:,2), points_cloud(:,:,3), 'm.', 'MarkerSize', 5)

%% draw vertical slice
% for i = 1:size(points_cloud, 1)
%     for j = 1:size(points_cloud, 2)
%         x = points_cloud(i,j,1);
%         y = points_cloud(i,j,2);
%         z = points_cloud(i,j,3);
%         z_max = max_min(1,3);
%         line([x; x], [y; y], [z; z_max], 'Color','b','LineWidth',1,'LineStyle','-');
%     end
% end

%% plot cc points/intersection points/boundary points
plot3(ccp(:,1), ccp(:,2), ccp(:,3), 'r.', 'MarkerSize', 10);

%% plot cbv points
plot3(cbv_points(:,1), cbv_points(:,2), cbv_points(:,3), 'rx', 'MarkerSize', 10);

%% plot all roughing_points with cbv skewed orientation
plot3(roughing_points(:,4), roughing_points(:,5), roughing_points(:,6), 'b.', 'MarkerSize', 10);

%% plot roughing_points orientation
% quiver3( roughing_points(:,4), roughing_points(:,5), roughing_points(:,6), ...
%     roughing_points(:,7), roughing_points(:,8), roughing_points(:,9), ...
%     1, 'Color','r','LineWidth',1,'LineStyle','-' );

%% draw tool path
% toolpath = [];

% z = flipud(unique(roughing_points(:,6)));
% direction = NaN;

% direction_type = 1;

% for i = 1:size(z)
%     roughing_points_at_z = roughing_points(roughing_points(:,6) == z(i),:);

%     if mod(i,2) == 0
%         y = unique(roughing_points_at_z(:,direction_type));
%     else
%         y = flipud(unique(roughing_points_at_z(:,direction_type)));
%     end

%     for j = 1:size(y)
%         roughing_points_at_y = roughing_points_at_z(roughing_points_at_z(:,direction_type) == y(j),:);

%         if isnan(direction)
%             direction = mod(j,2) == 0;
%         end
        
%         if direction
%             toolpath = [toolpath; roughing_points_at_y];
%         else
%             toolpath = [toolpath; flipud(roughing_points_at_y)];
%         end
        
%         direction = ~direction;
%     end
% end

% line(toolpath(:,1), toolpath(:,2), toolpath(:,3), 'Color', 'b', 'LineWidth', 2, 'LineStyle', '-');