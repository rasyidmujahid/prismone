%% ================================================
%% Read STL file
%% ================================================

folder = 'C:\Project\Mas Wawan\cbv\cobabentuk';
filename = 'bentuk B';

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

density = 20; % density determines how wide points cloud
              % will be, horizontal stepover is also
              % following this density.
horizontal_stepover = density;
vertical_stepover   = 10;
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

cbv_map = map_matrix(intersection_points, points_cloud);

%% ================================================
%% Create horizontal intersection.
%% The direction goes from left to right, top to bottom.
%% Horizontal stepover value is following the density value.
%% This is actually just like ccpoint generation for roughing,
%% but it is connecting the already generated points cloud.
%% ================================================
roughing_points = layering(max_min, points_cloud, intersection_points, ...
    vertical_stepover, horizontal_stepover)

%% ================================================
%% Build ccpoint orientation
%% ================================================

% orientation(roughing_points, intersection_points);

%% ================================================
%% Plot points
%% ================================================

X = V(:, 1);
Y = V(:, 2);
Z = V(:, 3);

trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'white' );
% trisurf ( T(:,1:3), X, Y, Z );

axis equal;

xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );

hold on;

%% plot normal vector along with triangle surface
% quiver3( tricenter(:,1), tricenter(:,2), tricenter(:,3), T(:,4), T(:,5), T(:,6) );

%% plot cc points
plot3(ccp(:,1), ccp(:,2), ccp(:,3), 'b.', 'MarkerSize', 10);

%% plot points cloud
plot3(points_cloud(:,:,1), points_cloud(:,:,2), points_cloud(:,:,3), 'rx', 'MarkerSize', 10)

%% plot roughing_points
plot3(roughing_points(:,1), roughing_points(:,2), roughing_points(:,3), 'r.', 'MarkerSize', 7);