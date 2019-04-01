%% ================================================
%% Read STL file
%% ================================================

% folder = 'C:\Repo\Project\Glash\parts\nonmachinable';
% filename = 'model4b';

folder = 'C:\Repo\Project\Glash\parts';
filename = '0_0075stlasc';

stlpath = strcat(folder, '/', filename, '.stl');
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
%% machining parameters
%% ================================================
flank_step_over = 20
point_step_over = 2
tool_length = 40;
tool_radius = 5;
offset = [10 10 10];
effective_tool_length = 40;
elevation = -30;

%% ================================================
%% If need to plot normal vector on each triangle
%% ================================================

%% find center of triangles
%% loop over triangles, foreach triangle T
%% foreach their vertices v
%% calculate their avarages point
tricenter = [];
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
%% Generate CC points
%%
%% ccpoints_data:
%% || vertex index 1 || vertex index 2 || x   y   z ||
%% ================================================

ccpoints_data = ccpoint(T(:,1:3), V, flank_step_over);

%% ================================================
%% build ccpoints normal vector, ccpoints tangential vector
%% ccpoints_data:
%% || v-idx1 || v-idx2 || x   y   z || normal i j k || tangent i j k ||
%% ================================================

[ccpoints_data reversed_ccpoints] = build_normal(ccpoints_data, V, T);

%% ================================================
%% find non-machinable area
%% ================================================
[bucket_index bucket_ccp bucket_triangle bucket_vertex] = find_non_machinable(flank_step_over, flank_step_over, ccpoints_data, V, T);

[tf, loc] = ismember(T(:,1:3), bucket_triangle(:,2:4), 'rows');
%% bucket_id_numbers; for each triangle get bucket number to which it belongs.
%% the bucket number will decide surf color
bucket_id_numbers = bucket_triangle(loc,1);

%% ================================================
%% visualize bucket
%% ================================================
figure('Name', 'Initial Bucket', 'NumberTitle', 'off');
trisurf (T(:,1:3), V(:,1), V(:,2), V(:,3), mod(bucket_id_numbers,10)); %% initial bucket
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );

%% ================================================
%% visualize bucket
%% ================================================
figure('Name', 'Non-Machinable Bucket', 'NumberTitle', 'off');
trisurf (T(:,1:3), V(:,1), V(:,2), V(:,3), mod(bucket_id_numbers.*bucket_index(bucket_id_numbers,4),10)); %% non-machinable bucket
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );

%% check missing vertex from bucket
% plot3(missing_v_from_b(:,1), missing_v_from_b(:,2), missing_v_from_b(:,3), 'rx', 'MarkerSize', 5, 'Color', 'red');

%% ================================================
%% point milling non-machinable area
%% ================================================
bucket_index_not_machinable = bucket_index(bucket_index(:,4) > 0, :);
if ~isempty(bucket_index_not_machinable)
    [tf_t, loc_t] = ismember(bucket_triangle(:,1), bucket_index_not_machinable(:,1), 'rows');
    T_not_mac = bucket_triangle(tf_t,2:7);
    [tf_v, loc_v] = ismember(  bucket_vertex(:,1), bucket_index_not_machinable(:,1), 'rows');
    V_not_mac = bucket_vertex(tf_v,2:4);
    point_mill_ccp = ccpoint(T_not_mac(:,1:3), V, point_step_over);
    [point_mill_ccp blah] = build_normal(point_mill_ccp, V, T_not_mac);
end

%% ================================================
%% save to NC file
%% ================================================
nc = save_nc_file(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
    ccpoints_data(:,9), ccpoints_data(:,10), ccpoints_data(:,11), ...
    offset(1), offset(2), offset(3), effective_tool_length, 'table', filename);

%% leave unique ccpoints only. ccpoints at triangle vertex
%% will happen to be duplicated
%% ccpoints
cc_points = unique(ccpoints_data(:,3:5), 'rows');

%% ================================================================
%% Multiple ray triangle intersections
%% ================================================================

%% resize destination vector into tool length
extended_tangen_normal = line_cut(ccpoints_data, tool_length, T, V);

%% ================================================
%% Plot points
%% ================================================

X = V(:, 1);
Y = V(:, 2);
Z = V(:, 3);

%% ================================================
%% Visualize faceted model
%% ================================================

figure('Name', 'CC Points', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;

% ================================================
% plot normal vector on top of triangle surface
% ================================================
% quiver3( tricenter(:,1), tricenter(:,2), tricenter(:,3), T(:,4), T(:,5), T(:,6), ...
% 	1, 'Color','r','LineWidth',1,'LineStyle','-');

%% ================================================
%% plot cpp
%% ================================================

plot3(cc_points(:,1), cc_points(:,2), cc_points(:,3), 'rx', 'MarkerSize', 5, 'Color', 'white');
surf2solid(T(:,1:3),V, 'Elevation', elevation); axis image; camlight; camlight 

%% ================================================
% plot normal vector on top of ccpoints, flank milling
%% ================================================
figure('Name', 'Flank Milling - Normal Vector', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
    ccpoints_data(:,6), ccpoints_data(:,7), ccpoints_data(:,8), ...
    3, 'Color','b','LineWidth',1,'LineStyle','-');
surf2solid(T(:,1:3),V, 'Elevation', elevation); axis image; camlight; camlight 

%% ================================================
%% plot normal vector on top of ccpoints, point milling
%% ================================================
figure('Name', 'Point Milling - Normal Vector', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
quiver3(point_mill_ccp(:,3), point_mill_ccp(:,4), point_mill_ccp(:,5), ...
    point_mill_ccp(:,6), point_mill_ccp(:,7), point_mill_ccp(:,8), ...
    5, 'Color','b','LineWidth',1,'LineStyle','-');
surf2solid(T(:,1:3),V, 'Elevation', elevation); axis image; camlight; camlight 

%% ================================================
%% plot tangen vector on top of ccpoints
%% ================================================
figure('Name', 'Tool Orientation Vector (Cross Product) .2', 'NumberTitle', 'off');
% trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
trisurf ( T(:,1:3), X, Y, Z, mod(bucket_id_numbers,10));
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
    ccpoints_data(:,9), ccpoints_data(:,10), ccpoints_data(:,11), ...
    1, 'Color','white','LineWidth',1,'LineStyle','-');
surf2solid(T(:,1:3),V, 'Elevation', elevation); axis image; camlight; camlight 

%% ================================================
%% plot feed direction on top of ccpoints
%% ================================================
figure('Name', 'Feed Direction Vector .2', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
    ccpoints_data(:,15), ccpoints_data(:,16), ccpoints_data(:,17), ...
    1, 'Color','white','LineWidth',1,'LineStyle','-');
surf2solid(T(:,1:3),V, 'Elevation', elevation); axis image; camlight; camlight 

% plot extended tangen vector on top of ccpoints
% quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
%     extended_tangen_normal(:,1), extended_tangen_normal(:,2), extended_tangen_normal(:,3), ...
%     1, 'Color','b','LineWidth',1,'LineStyle','-');

%% ================================================
%% draw flank lines
%% ccpoints_data:
%% || v-idx1 || v-idx2 || x1   y1   z1 || normal i j k || tangent i j k || x2 y2 z2 || feed_direction i j k
%% ================================================
ccpoints_data(:,12) = ccpoints_data(:,3) + extended_tangen_normal(:,1);
ccpoints_data(:,13) = ccpoints_data(:,4) + extended_tangen_normal(:,2);
ccpoints_data(:,14) = ccpoints_data(:,5) + extended_tangen_normal(:,3);

play_flank_simulation(T, V, ccpoints_data, tool_radius, tool_length);

play_point_simulation(T, V, ccpoints_data, point_mill_ccp, tool_radius, tool_length, bucket_index);