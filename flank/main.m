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
flank_step_over = 10
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

%% visualize bucket
[tf, loc] = ismember(T(:,1:3), bucket_triangle(:,2:4), 'rows');
C = bucket_triangle(loc,1);

figure('Name', 'Non-Machinable Bucket', 'NumberTitle', 'off');
% trisurf (T(:,1:3), V(:,1), V(:,2), V(:,3), mod(C,10)); %% initial bucket
trisurf (T(:,1:3), V(:,1), V(:,2), V(:,3), mod(C.*bucket_index(C,4),10)); %% non-machinable bucket
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );

% %% ================================================
% %% point milling non-machinable area
% %% ================================================
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

plot3(cc_points(:,1), cc_points(:,2), cc_points(:,3), 'rx', 'MarkerSize', 5);
surf2solid(T(:,1:3),V, 'Elevation', elevation); axis image; camlight; camlight 

%% ================================================
% plot normal vector on top of ccpoints
%% ================================================
figure('Name', 'Normal Vector', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
% quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
%     ccpoints_data(:,6), ccpoints_data(:,7), ccpoints_data(:,8), ...
%     3, 'Color','b','LineWidth',1,'LineStyle','-');
quiver3(point_mill_ccp(:,3), point_mill_ccp(:,4), point_mill_ccp(:,5), ...
    point_mill_ccp(:,6), point_mill_ccp(:,7), point_mill_ccp(:,8), ...
    3, 'Color','b','LineWidth',1,'LineStyle','-');
surf2solid(T(:,1:3),V, 'Elevation', elevation); axis image; camlight; camlight 

%% ================================================
%% plot tangen vector on top of ccpoints
%% ================================================
figure('Name', 'Tool Orientation Vector (Cross Product) .2', 'NumberTitle', 'off');
% trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
trisurf ( T(:,1:3), X, Y, Z, mod(C,10));
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
    1, 'Color','r','LineWidth',1,'LineStyle','-');
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
f = figure('Name', 'Simulation .2', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
% surf2solid(T(:,1:3),V, 'Elevation', elevation); axis image; camlight; camlight 

ccpoints_data(:,12) = ccpoints_data(:,3) + extended_tangen_normal(:,1);
ccpoints_data(:,13) = ccpoints_data(:,4) + extended_tangen_normal(:,2);
ccpoints_data(:,14) = ccpoints_data(:,5) + extended_tangen_normal(:,3);

%% ================================================
%% Toolpath simulation + gouging detection
%% ================================================

%% sort by Y then X
ccpoints_data = sortrows(ccpoints_data, [4 3]);

cylinder_handle = [];
cylinder_end_1 = [];
cylinder_end_2 = [];
CL = 0;

for i = 1:size(ccpoints_data,1)-1

    % if ccpoints_data(i,4) < 140 || ccpoints_data(i,4) > 180
    %     continue;
    % end

    set(0,'CurrentFigure',f);

    % line(ccpoints_data(i,[3 12]), ccpoints_data(i,[4 13]), ccpoints_data(i,[5 14]), 'Color','red','LineWidth',2,'LineStyle','-');

    % skip points reside under diffrent line y
    if ccpoints_data(i,4) ~= ccpoints_data(i+1,4)
        disp(['Skip swept area', mat2str(ccpoints_data(i,3:5)), ' with ', mat2str(ccpoints_data(i+1,3:5)), '.']);
        continue;
    end

    % remember: we do inverse tool orientation based on positive or negative slope. 
    % this to make sure that cylinder is built only with 2 lines having the same slope.
    d1 = ccpoints_data(i,4) < ccpoints_data(i,13);
    d2 = ccpoints_data(i+1,4) < ccpoints_data(i+1,13);

    % if xor(d1,d2)
    %     continue;
    % end

    %% ================================
    %% draw swept area
    %% ccpoints_data:
    %% || v-idx1 || v-idx2 || x1   y1   z1 || normal i j k || tangent i j k || x2 y2 z2 || feed_direction i j k
    %% ================================
    rx = [ccpoints_data(i,3) ccpoints_data(i+1,3) ccpoints_data(i+1,12) ccpoints_data(i,12)];
    ry = [ccpoints_data(i,4) ccpoints_data(i+1,4) ccpoints_data(i+1,13) ccpoints_data(i,13)];
    rz = [ccpoints_data(i,5) ccpoints_data(i+1,5) ccpoints_data(i+1,14) ccpoints_data(i,14)];

    tangent = cross(ccpoints_data(i+1,6:8), ccpoints_data(i+1,15:17));
    tangent = tangent / norm(tangent);
    if tangent ~= ccpoints_data(i+1,9:11)
        normal_ = ccpoints_data(i+1,9:11);
        c = 'green';
    else
        c = 'magenta';
    end
    patch(rx,ry,rz,c);
    
    f2 = [1 2 3 4];
    v2 = [rx' ry' rz'];
    col = [0; 6; 4];
    patch('Faces',f2,'Vertices',v2,'EdgeColor','blue','FaceColor','none','LineWidth',2);

    % %% ================================
    % %% simulate cylinder
    % %% ================================
    
    % % if correction succeeded clear cylinder, otherwise keep with red color.
    % % if CL == 0
    % %     delete(cylinder_handle);
    % %     delete(cylinder_end_1);
    % %     delete(cylinder_end_2);
    % % else
    % %     set(cylinder_handle, 'FaceColor', 'r');
    % % end

    % p1 = ccpoints_data(i,3:5) + tool_radius * ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8));
    % p2 = ccpoints_data(i,12:14) + tool_radius * ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8));
    % [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, 'y', 1 ,0);
    % drawnow;

    % tri = surf2patch(cylinder_handle, 'triangles');
    % cylinder_tri = [tri.vertices(tri.faces(:,1),:) tri.vertices(tri.faces(:,2),:) tri.vertices(tri.faces(:,3),:)];
    % working_part = [V(T(:,1),:) V(T(:,2),:) V(T(:,3),:)];
    % trans1 = [0 0 0 1 0 0 0 1 0 0 0 1];
    % trans2 = [0 0 0 1 0 0 0 1 0 0 0 1];
    % CL = coldetect(cylinder_tri, working_part, trans1, trans2);

    % %% mark gouging as red cylinder. if no gouging, clear cylinder.
    % if CL == 0
    %     delete(cylinder_handle);
    %     delete(cylinder_end_1);
    %     delete(cylinder_end_2);
    % else
    %     set(cylinder_handle, 'FaceColor', 'r');
    %     drawnow;
    % end

    % ================================
    % gouging avoidance
    % ================================
    % iteration = 0;
    % max_iteration = 20;
    % tetha = 0.01;
    % incremental_tetha = 0.01;
    % r = []; %% working rotation matrix
    % while (CL > 0) && (iteration < max_iteration)

    %     %% ccpoints_data:
    %     %% || v-idx1 || v-idx2 || x1   y1   z1 || normal i j k || tangent i j k || x2 y2 z2 || feed_direction i j k

    %     %% taking feed direction vector as rotation axis, and θ = incremental angle.
    %     feed_direction = ccpoints_data(i,15:17);
        
    %     %% rotation_matrix results 3x3 matrix
    %     rotation_matrix = vrrotvec2mat([feed_direction deg2rad(tetha)]);
    %     r = rotation_matrix;
    %     %% https://en.wikipedia.org/wiki/Transformation_matrix#Affine_transformations
    %     %% [r1 r2 r3 0]
    %     %% [r4 r5 r6 0]
    %     %% [r7 r8 r9 0]
    %     %% [0  0  0  1]

    %     %% TRANS parameters
    %     %% [ e4  e5  e6 e1]
    %     %% [ e7  e8  e9 e2]
    %     %% [e10 e11 e12 e3]
    %     %% [  0   0   0  1]
    %     %% adjust to trans1 = (e1, ..., e12)
    %     trans1 = [0 0 0 r(1,:) r(2,:) r(3,:)];
    %     CL = coldetect(cylinder_tri, working_part, trans1, trans2);

    %     tetha = tetha + incremental_tetha;
    %     iteration = iteration + 1;
    % end

    % %% print last tetha
    % % tetha

    % %% if gouging avoidance succeeded, mark cylinder as green
    % if ~isempty(r)

    %     delete(cylinder_handle);
    %     delete(cylinder_end_1);
    %     delete(cylinder_end_2);

    %     %% new tangent orientation
    %     % r %% display 'r' rotation_matrix
    %     tool_orientation_before_gouging_avoidance = ccpoints_data(i,9:11);
    %     %% rotate tangent vector by rotation matrix r
    %     %% Ref. https://en.wikipedia.org/wiki/Rotation_matrix, the rule is following
    %     %% xy' = r*xy where xy is column vector.
    %     ccpoints_data(i,9:11) = (r * ccpoints_data(i,9:11)')';
    %     tool_orientation_after_vcollide = ccpoints_data(i,9:11);

    %     %% adjust points x2 y2 z2 following new tangent orientation
    %     ccpoints_data(i,12:14) = ccpoints_data(i,3:5) + tool_length / norm(ccpoints_data(i,9:11)) * ccpoints_data(i,9:11);

    %     %% also do normal vector orientation
    %     ccpoints_data(i,6:8) = (r * ccpoints_data(i,6:8)')';

    %     %% Redraw after free gouging trial
    %     p1 = ccpoints_data(i,3:5) + tool_radius * ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8));
    %     p2 = ccpoints_data(i,12:14) + tool_radius * ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8));
    %     [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, 'y', 1 ,0);

    %     %% if free gouging, mark cylinder as green, otherwise keep red
    %     if CL == 0
    %         set(cylinder_handle, 'FaceColor', 'g');
    %     else
    %         set(cylinder_handle, 'FaceColor', 'r');
    %     end
    %     drawnow;
    % end
end

% we have some issues:
% FIXED 1. rotation doesnt work for some ccpoints. only works for inversed orientation.
% => was due to wrong cross product in build_tangent_normal function, which resulted wrong inversed tangent orientation. 
% FIXED 2. collision detection doesnt seem to work as expected. expected to be collided true, but it aint.
% => wrong cylinder re-draw. should also rotate normal vector to get correct adjustment as far as tool_radius
% FIXED 3. rotation direction should be negative, means clockwise.
% => no need. vrrotvec2mat works in righ-hand rule rotation
