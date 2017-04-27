%% ================================================
%% Read STL file
%% ================================================

folder = 'C:\Project\Glash\parts';
filename = '0_005stlasc';
% folder = 'STL20151020';

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
step_over = 30;
tool_length = 10;
tool_radius = 2;
offset = [10 10 10];
effective_tool_length = 20;

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

ccpoints_data = ccpoint(T(:,1:3), V, step_over);


%% ================================================
%% build ccpoints normal vector, ccpoints tangential vector
%% ccpoints_data:
%% || v-idx1 || v-idx2 || x   y   z || normal i j k || tangent i j k ||
%% ================================================

ccpoints_data = build_normal(ccpoints_data, V, T);


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

%% ================================================
%% Create cutting area
%% ================================================
% ccp_pairs = cutting_area(cc_points);

%% ================================================================
%% Bucketing, Finding tool-and-part intersection, Gouging avoidance
%% ================================================================

% b = bucket.Builder(T(:,1:3), V, 10);
% tri_buckets = b.buckets;

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

% plot normal vector on top of ccpoints
figure('Name', 'Normal Vector', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
    ccpoints_data(:,6), ccpoints_data(:,7), ccpoints_data(:,8), ...
    3, 'Color','b','LineWidth',1,'LineStyle','-');

% % plot tangen vector on top of ccpoints
figure('Name', 'Tool Orientation Vector (Cross Product)', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
    ccpoints_data(:,9), ccpoints_data(:,10), ccpoints_data(:,11), ...
    1, 'Color','r','LineWidth',1,'LineStyle','-');

% plot extended tangen vector on top of ccpoints
% quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
%     extended_tangen_normal(:,1), extended_tangen_normal(:,2), extended_tangen_normal(:,3), ...
%     1, 'Color','b','LineWidth',1,'LineStyle','-');

%% ================================================
%% draw flank lines
%% ccpoints_data:
%% || v-idx1 || v-idx2 || x1   y1   z1 || normal i j k || tangent i j k || x2 y2 z2
%% ================================================
f = figure('Name', 'Simulation', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;

ccpoints_data(:,12) = ccpoints_data(:,3) + extended_tangen_normal(:,1);
ccpoints_data(:,13) = ccpoints_data(:,4) + extended_tangen_normal(:,2);
ccpoints_data(:,14) = ccpoints_data(:,5) + extended_tangen_normal(:,3);

% extended_tangen_normal(:,1:3)
% ccpoints_data(:,12:14)

%% ================================================
%% Toolpath simulation + gouging detection
%% ================================================

ccpoints_data = sortrows(ccpoints_data, [4 3]);

cylinder_handle = [];
cylinder_end_1 = [];
cylinder_end_2 = [];
CL = 0;

for i = 1:size(ccpoints_data,1)-1

    set(0,'CurrentFigure',f);

    % line(ccpoints_data(i,[3 12]), ccpoints_data(i,[4 13]), ccpoints_data(i,[5 14]), 'Color','red','LineWidth',2,'LineStyle','-');

    % skip points reside under diffrent line y
    if ccpoints_data(i,4) ~= ccpoints_data(i+1,4)
        continue;
    end

    % remember: we do inverse tool orientation based on positive or negative slope. 
    % this to make sure that cylinder is built only with 2 lines having the same slope.
    d1 = ccpoints_data(i,4) < ccpoints_data(i,13);
    d2 = ccpoints_data(i+1,4) < ccpoints_data(i+1,13);

    if xor(d1,d2)
        continue;
    end

    %% ================================
    %% draw swept area
    %% ================================
    rx = [ccpoints_data(i,3) ccpoints_data(i+1,3) ccpoints_data(i+1,12) ccpoints_data(i,12)];
    ry = [ccpoints_data(i,4) ccpoints_data(i+1,4) ccpoints_data(i+1,13) ccpoints_data(i,13)];
    rz = [ccpoints_data(i,5) ccpoints_data(i+1,5) ccpoints_data(i+1,14) ccpoints_data(i,14)];
    % c = 'red';
    % patch(rx,ry,rz,c);
    
    f2 = [1 2 3 4];
    v2 = [rx' ry' rz'];
    col = [0; 6; 4];
    patch('Faces',f2,'Vertices',v2,'EdgeColor','blue','FaceColor','red','LineWidth',2);

    %% ================================
    %% simulate cylinder
    %% ================================
    
    %% if correction succeeded clear cylinder, otherwise keep with red color.
    % if CL == 0
    %     delete(cylinder_handle);
    %     delete(cylinder_end_1);
    %     delete(cylinder_end_2);
    % else
    %     set(cylinder_handle, 'FaceColor', 'r');
    % end

    p1 = ccpoints_data(i,3:5) + tool_radius * ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8));
    p2 = ccpoints_data(i,12:14) + tool_radius * ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8));
    [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, 'y', 1 ,0);
    drawnow;

    tri = surf2patch(cylinder_handle, 'triangles');
    cylinder_tri = [tri.vertices(tri.faces(:,1),:) tri.vertices(tri.faces(:,2),:) tri.vertices(tri.faces(:,3),:)];
    working_part = [V(T(:,1),:) V(T(:,2),:) V(T(:,3),:)];
    trans1 = [0 0 0 1 0 0 0 1 0 0 0 1];
    trans2 = [0 0 0 1 0 0 0 1 0 0 0 1];
    CL = coldetect(cylinder_tri, working_part, trans1, trans2);

    %% mark gouging as red cylinder. if no gouging, clear cylinder.
    if CL == 0
        delete(cylinder_handle);
        delete(cylinder_end_1);
        delete(cylinder_end_2);
    else
        set(cylinder_handle, 'FaceColor', 'r');
        drawnow;
    end

    %% ================================
    %% gouging avoidance
    %% ================================
    iteration = 0;
    max_iteration = 10;
    tetha = 2;
    incremental_tetha = -60;
    r = []; %% working rotation matrix
    while (CL > 0) && (iteration < max_iteration)

        %% ccpoints_data:
        %% || v-idx1 || v-idx2 || x1   y1   z1 || normal i j k || tangent i j k || x2 y2 z2

        %% taking feed direction vector as rotation axis, and θ = incremental 1 degree.
        %% feed_direction = tangent x normal
        feed_direction = cross(ccpoints_data(i,9:11), ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8)));
        rotation_matrix = vrrotvec2mat([feed_direction deg2rad(tetha)]);
        r = rotation_matrix;

        %% rotation_matrix results 3x3 matrix
        %% TRANS argument:
        %% (e1, ..., e12)
        %% [ e4  e5  e6 e1]
        %% [ e7  e8  e9 e2]
        %% [e10 e11 e12 e3]
        %% [  0   0   0  1]
        trans1 = [0 0 0 r(1,:) r(2,:) r(3,:)];
        CL = coldetect(cylinder_tri, working_part, trans1, trans2);

        tetha = tetha + incremental_tetha;
        iteration = iteration + 1;
    end

    %% print last tetha
    % tetha

    %% if gouging avoidance succeeded, mark cylinder as green
    if ~isempty(r) && CL == 0

        delete(cylinder_handle);
        delete(cylinder_end_1);
        delete(cylinder_end_2);

        %% new tangent orientation
        r
        tool_orientation_before_gouging_avoidance = ccpoints_data(i,9:11)
        ccpoints_data(i,9:11) = ccpoints_data(i,9:11) * r;
        tool_orientation_after_vcollide = ccpoints_data(i,9:11)

        %% adjust points x2 y2 z2 following new tangent orientation
        ccpoints_data(i,12:14) = ccpoints_data(i,3:5) + tool_length / norm(ccpoints_data(i,9:11)) * ccpoints_data(i,9:11);

        % Redraw after free gouging trial
        p1 = ccpoints_data(i,3:5) + tool_radius * ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8));
        p2 = ccpoints_data(i,12:14) + tool_radius * ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8));
        [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, 'y', 1 ,0);

        % mark cylinder as green
        set(cylinder_handle, 'FaceColor', 'g');
        drawnow;
    end
end

% we have some issues:
% 1. rotation doesnt work for some ccpoints. only works for inversed orientation.
% 2. collision detection doesnt seem to work as expected. expected to be collided true, but it aint.
% 3. rotation direction should be negative, means clockwise.
