%% ================================================
%% Read STL file
%% ================================================

folder = 'C:\Project\Mas Wawan\cbv\cobabentuk';
filename = 'coba kontur';
% filename = 'coba searah y-1';

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
density = 10; % density determines how wide points cloud
              % will be, horizontal stepover is also
              % following this density.
horizontal_stepover = density;
vertical_stepover   = 10;
tool_length = 80;
tool_radius = 8;
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

%% ================================================
%% Build ccpoint orientation
%% roughing_points columns:
%% || points_cloud x y z || skewed_points x1 y1 z1 || tool_orientation i j k
%% ================================================

roughing_points = tool_orientation(roughing_points, intersection_points, vertical_stepover, T, V);

%% cbv_points only
cbv_points = [];
for i = 1:size(roughing_points,1)
    if is_under_cbv(roughing_points(i,1:3), intersection_points)
        cbv_points = [cbv_points; roughing_points(i,:)];
    end
end

%% ================================================
%% Volume calculation: Part & CBV
%% ================================================
[partVolume, partArea] = stlVolume(V', T(:,1:3)');
totalVolume = (max_min(1,1) - max_min(2,1)) * (max_min(1,2) - max_min(2,2)) * (max_min(1,3) - max_min(2,3));
invertedVolume = totalVolume - partVolume;

%% ================================================
%% Volume calculation: OBV
%% ================================================
obv = [];
pc = unique(ccp(:,1:2), 'rows');
max_point_cloud = max(pc);

for i = 1:size(pc, 1)
    find_ccpoint = ccp(find(ccp(:,1) == pc(i,1) & ccp(:,2) == pc(i,2)), :);
    if (isempty(find_ccpoint))
        continue;
    end
    if (size(find_ccpoint,1) > 2 || size(find_ccpoint,1) < 2)
        continue;
    end
    for j = 1:size(find_ccpoint,1)
        if (find_ccpoint(j,3) < max_min(1,3) && find_ccpoint(j,3) > max_min(2,3))
            obv = [obv; find_ccpoint(j,:); find_ccpoint(j,1:2) max_min(1,3)];

            if (pc(i,2) == max_point_cloud(2))
                obv = [obv; find_ccpoint(j,1) max_min(1,2) find_ccpoint(j,3); find_ccpoint(j,1) max_min(1,2) max_min(1,3)];
            end
            if (pc(i,1) == max_point_cloud(1))
                obv = [obv; max_min(1,1) find_ccpoint(j,2:3); max_min(1,1) find_ccpoint(j,2) max_min(1,3)];
            end
        end
    end
end

%% ================================================
%% Volume calculation: Cut CBV
%% ================================================

%% DOWN BELOW

%% ================================================
%% sort points
%% 1. by cbv orientation
%% 2. top layer first
%% ================================================

%% 1. by cbv orientation, [2 1] or [1 2]
cbv_direction = get_cbv_direction(roughing_points, cbv_points, intersection_points);

%% 2. top layer first
roughing_points = sortrows(roughing_points, [-3 cbv_direction]);


%% ================================================
%% Plot points
%% ================================================

X = V(:, 1);
Y = V(:, 2);
Z = V(:, 3);

% %% plot normal vector along with triangle surface
%% quiver3( tricenter(:,1), tricenter(:,2), tricenter(:,3), T(:,4), T(:,5), T(:,6) );

% %% plot points cloud
figure('Name', 'Points Cloud & Vertical Slices', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'Inter' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;

% plot3(points_cloud(:,:,1), points_cloud(:,:,2), points_cloud(:,:,3), 'm.', 'MarkerSize', 5)

% %% draw vertical slice
% for i = 1:size(points_cloud, 1)
%     for j = 1:size(points_cloud, 2)
%         x = points_cloud(i,j,1);
%         y = points_cloud(i,j,2);
%         z = points_cloud(i,j,3);
%         z_max = max_min(1,3);
%         line([x; x], [y; y], [z; z_max], 'Color','b','LineWidth',1,'LineStyle','-');
%     end
% end

% %% plot cc points/intersection points/boundary points
% figure('Name', 'Intersection Points (Boundary Points)', 'NumberTitle', 'off');
% trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
% axis equal;
% xlabel ( '--X axis--' );
% ylabel ( '--Y axis--' );
% zlabel ( '--Z axis--' );
% hold on;
% plot3(ccp(:,1), ccp(:,2), ccp(:,3), 'r.', 'MarkerSize', 10);

%% plot cbv points
figure('Name', 'CBV Points', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
plot3(cbv_points(:,1), cbv_points(:,2), cbv_points(:,3), 'rx', 'MarkerSize', 10);

% %% plot cbv volume part
% % figure('Name', 'CBV Volume Part', 'NumberTitle', 'off');
% % trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
% % axis equal;
% % xlabel ( '--X axis--' );
% % ylabel ( '--Y axis--' );
% % zlabel ( '--Z axis--' );
% % hold on;
% % trisurf(tri, cbv_boundary_points(:,1), cbv_boundary_points(:,2), cbv_boundary_points(:,3));

%% plot all roughing_points with cbv skewed orientation
figure('Name', 'Roughing Points (Skewed)', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
plot3(roughing_points(:,1), roughing_points(:,2), roughing_points(:,3), 'b.', 'MarkerSize', 10);
plot3(roughing_points(:,4), roughing_points(:,5), roughing_points(:,6), 'b.', 'MarkerSize', 10);

%% plot roughing_points orientation
figure('Name', 'Tool Orientation', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
quiver3( cbv_points(:,4), cbv_points(:,5), cbv_points(:,6), ...
    cbv_points(:,7), cbv_points(:,8), cbv_points(:,9), ...
    10, 'Color','r','LineWidth',2,'LineStyle','-' );

% %% ================================================
% %% plot cutting cbv
% %% ================================================
% calc_volumes(V, T, roughing_points, tool_length, vertical_stepover);

% %% ================================================
% %% plot obv
% %% ================================================
% figure('Name', 'OBV', 'NumberTitle', 'off');
% trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
% axis equal;
% xlabel ( '--X axis--' );
% ylabel ( '--Y axis--' );
% zlabel ( '--Z axis--' );
% hold on;

% % dt = DelaunayTri(obv(:,1), obv(:,2), obv(:,3));
% dt = delaunayn(obv);
% tri = dt(:,:);
% obv_volume = stlVolume(obv', tri');

% trisurf(tri, obv(:,1), obv(:,2), obv(:,3));

% non_machinable_volume = invertedVolume - abs(obv_volume) - abs(total_cutting_cbv_volume);

%% ================================================
%% Toolpath simulation + gouging detection
%% ================================================
gouging_iteration(V, T, roughing_points, tool_length, tool_radius);

%% ================================================
%% save to NC file
%% ================================================
%% || points_cloud x y z || skewed_points x1 y1 z1 || tool_orientation i j k

%% opt-out if to save cbv points only
% nc_points = roughing_points(find(roughing_points(:,7) ~= 0 & roughing_points(:,8) ~= 0 & roughing_points(:,9) ~= 100),:);

%% otherwise
nc_points = roughing_points;

nc = save_nc_file(nc_points(:,4), nc_points(:,5), nc_points(:,6), ...
                  nc_points(:,7), nc_points(:,8), nc_points(:,9), ...
                  offset(1), offset(2), offset(3), effective_tool_length, 'table', filename);

% %% ================================================
% %% draw tool path
% %% ================================================
% % toolpath = [];

% % z = flipud(unique(roughing_points(:,6)));
% % direction = NaN;

% % direction_type = 1;

% % for i = 1:size(z)
% %     roughing_points_at_z = roughing_points(roughing_points(:,6) == z(i),:);

% %     if mod(i,2) == 0
% %         y = unique(roughing_points_at_z(:,direction_type));
% %     else
% %         y = flipud(unique(roughing_points_at_z(:,direction_type)));
% %     end

% %     for j = 1:size(y)
% %         roughing_points_at_y = roughing_points_at_z(roughing_points_at_z(:,direction_type) == y(j),:);

% %         if isnan(direction)
% %             direction = mod(j,2) == 0;
% %         end
        
% %         if direction
% %             toolpath = [toolpath; roughing_points_at_y];
% %         else
% %             toolpath = [toolpath; flipud(roughing_points_at_y)];
% %         end
        
% %         direction = ~direction;
% %     end
% % end

% % line(toolpath(:,1), toolpath(:,2), toolpath(:,3), 'Color', 'b', 'LineWidth', 2, 'LineStyle', '-');
