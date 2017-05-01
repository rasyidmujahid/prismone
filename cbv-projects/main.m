%% ================================================
%% Read STL file
%% ================================================

folder = 'C:\Project\Mas Wawan\cbv\cobabentuk';
% filename = 'coba7';
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
tool_length = 50;
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

%% cbv_points only
cbv_points = [];
for i = 1:size(roughing_points,1)
    if is_under_cbv(roughing_points(i,1:3), intersection_points)
        cbv_points = [cbv_points; roughing_points(i,1:3)];
    end
end

%% ================================================
%% Build ccpoint orientation
%% roughing_points columns:
%% || points_cloud x y z || skewed_points x1 y1 z1 || tool_orientation i j k
%% ================================================

roughing_points = tool_orientation(roughing_points, intersection_points, vertical_stepover, T, V);

%% ================================================
%% save to NC file
%% ================================================
under_cbv_points = roughing_points(find(roughing_points(:,4) ~= 0 & roughing_points(:,5) ~= 0 & roughing_points(:,6) ~= 0),:);
% nc = save_nc_file(under_cbv_points(:,4), under_cbv_points(:,5), under_cbv_points(:,6), ...
%     under_cbv_points(:,7), under_cbv_points(:,8), under_cbv_points(:,9), ...
%     offset(1), offset(2), offset(3), effective_tool_length, 'table', filename);

%% ================================================
%% Volume calculation: Part & CBV
%% ================================================
[partVolume, partArea] = stlVolume(V', T(:,1:3)');
totalVolume = (max_min(1,1) - max_min(2,1)) * (max_min(1,2) - max_min(2,2)) * (max_min(1,3) - max_min(2,3));
invertedVolume = totalVolume - partVolume;

%% DEPRECATED
%% ccpoints that bound the CBV part
% cbv_boundary_points = [];
% for i = 1:size(points_cloud,1)
%     for j = 1:size(points_cloud,2)
%         sl = [points_cloud(i,j,1) points_cloud(i,j,2)];
%         boundary_at_this_slicing_line = get_boundary_points_at(sl, intersection_points);
%         if (size(boundary_at_this_slicing_line,1)) > 2
%             %% it means under cbv
%             cbv_boundary_points = [cbv_boundary_points; boundary_at_this_slicing_line(2:3,1:3)];
%         end
%     end
% end

% %% Creates a Delaunay triangulation from a set of CBV ccpoints
% dt = DelaunayTri(cbv_boundary_points(:,1), cbv_boundary_points(:,2), cbv_boundary_points(:,3));
% tri = dt(:,:);
% cbv_volume = stlVolume(cbv_boundary_points(:,1:3)', tri')
%% END-OF-DEPRECATED


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
%% Plot points
%% ================================================

X = V(:, 1);
Y = V(:, 2);
Z = V(:, 3);

%% plot normal vector along with triangle surface
% quiver3( tricenter(:,1), tricenter(:,2), tricenter(:,3), T(:,4), T(:,5), T(:,6) );

%% plot points cloud
figure('Name', 'Points Cloud & Vertical Slices', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;

plot3(points_cloud(:,:,1), points_cloud(:,:,2), points_cloud(:,:,3), 'm.', 'MarkerSize', 5)

%% draw vertical slice
for i = 1:size(points_cloud, 1)
    for j = 1:size(points_cloud, 2)
        x = points_cloud(i,j,1);
        y = points_cloud(i,j,2);
        z = points_cloud(i,j,3);
        z_max = max_min(1,3);
        line([x; x], [y; y], [z; z_max], 'Color','b','LineWidth',1,'LineStyle','-');
    end
end

%% plot cc points/intersection points/boundary points
figure('Name', 'Intersection Points (Boundary Points)', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
plot3(ccp(:,1), ccp(:,2), ccp(:,3), 'r.', 'MarkerSize', 10);

%% plot cbv points
figure('Name', 'CBV Points', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
plot3(cbv_points(:,1), cbv_points(:,2), cbv_points(:,3), 'rx', 'MarkerSize', 10);

%% plot cbv volume part
% figure('Name', 'CBV Volume Part', 'NumberTitle', 'off');
% trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
% axis equal;
% xlabel ( '--X axis--' );
% ylabel ( '--Y axis--' );
% zlabel ( '--Z axis--' );
% hold on;
% trisurf(tri, cbv_boundary_points(:,1), cbv_boundary_points(:,2), cbv_boundary_points(:,3));

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
quiver3( roughing_points(:,4), roughing_points(:,5), roughing_points(:,6), ...
    roughing_points(:,7), roughing_points(:,8), roughing_points(:,9), ...
    10, 'Color','r','LineWidth',1,'LineStyle','-' );

%% ================================================
%% plot cutting cbv
%% ================================================
all_z = unique(roughing_points(:,3));
all_y = unique(roughing_points(:,2));

total_cutting_cbv_volume = 0;

figure('Name', 'CBV Cut', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;

% drawn = false;

for i = 1:size(all_z,1)
    z = all_z(i);
    indices = find_rows_in_matrix(z, roughing_points(:,3));

    roughing_points_at_this_z = roughing_points(indices,:);
    cbv_points_at_this_z = [];
    for j = 1:size(roughing_points_at_this_z,1)
        if (~isequal(roughing_points_at_this_z(j,7:9), [0 0 100]))
            %% find all cbv points at this z : roughing points that its orientation is not skewed
            cbv_points_at_this_z = [cbv_points_at_this_z; roughing_points_at_this_z(j,:)];
        end 
    end
    
    if (isempty(cbv_points_at_this_z))
        continue;
    end

    for j = 1:size(all_y,1)
        y = all_y(j);
        indices = find_rows_in_matrix(y, cbv_points_at_this_z(:,2));

        if (isempty(indices))
            % disp(['y: ', num2str(y)]);
            % disp(['z: ', num2str(z)]);
            continue;
        end

        %% add a new point where the tool-handle comes from
        last_index = indices(end);
        last_cbv_point_at_this_z_y = cbv_points_at_this_z(last_index,:);
        tool_handle_origin_point = last_cbv_point_at_this_z_y(:,4:6) + ...
            tool_length * last_cbv_point_at_this_z_y(:,7:9) / norm(last_cbv_point_at_this_z_y(:,7:9));
        cbv_points_at_this_z = [cbv_points_at_this_z; [0 0 0 tool_handle_origin_point -last_cbv_point_at_this_z_y(:,7:9)]];

        %% update last_cbv_point_at_this_z_y to follow tool_handle_origin_point(x,y)
        last_cbv_point_at_this_z_y(:,4:5) = tool_handle_origin_point(:,1:2);
        cbv_points_at_this_z = [cbv_points_at_this_z; [0 0 0 last_cbv_point_at_this_z_y(:,4:6) 0 0 1]];

        %% =================================================
        %% calculate cut cbv volume
        %% TODO: if two-sided cbv
        %% =================================================
        if (j == 1)
            first_index = indices(1);
            first_cbv_point_at_this_z_y = cbv_points_at_this_z(first_index,4:6);
            last_cbv_point_at_this_z_y = last_cbv_point_at_this_z_y(:,4:6);
            
            u = first_cbv_point_at_this_z_y - tool_handle_origin_point;
            v = last_cbv_point_at_this_z_y - tool_handle_origin_point;

            %% find angle between 2 vector (in radian)
            angle = atan2(norm(cross(u,v)),dot(u,v));
            angle_degree = angle / pi * 180;
            
            %% cylinder part volume I = angle/2π * area * heigth
            cbv_part_volume = angle / (2 * pi) * (pi * tool_length ^ 2) * (max_min(1,2) - max_min(2,2));

            %% cylinder part volume II = angle/2π * area * (tool length - stepover)
            intersected_cbv_volume = angle / (2 * pi) * (pi * (tool_length - vertical_stepover) ^ 2) * (max_min(1,2) - max_min(2,2));

            %% get actual volume, without intersection
            cbv_part_volume = cbv_part_volume - intersected_cbv_volume;
            total_cutting_cbv_volume = total_cutting_cbv_volume + cbv_part_volume;
        end
    end

    % if (drawn) 
    %     continue;
    % end

    %% if two-sided cbv, separated by y = c line, pick random y = middle one
    y = (max_min(1,2) - max_min(2,2)) / 2;
    cbv_points_before_y = cbv_points_at_this_z(find(cbv_points_at_this_z(:,5) < y),:);
    cbv_points_after_y = cbv_points_at_this_z(find(cbv_points_at_this_z(:,5) >= y),:);

    % dt = DelaunayTri(cbv_points_at_this_z(:,4), cbv_points_at_this_z(:,5), cbv_points_at_this_z(:,6));
    % tri = dt(:,:);

    %% before x
    dt = DelaunayTri(cbv_points_before_y(:,4), cbv_points_before_y(:,5), cbv_points_before_y(:,6));
    tri = dt(:,:);

    if isempty(tri)
        continue;
    end

    trisurf(tri, cbv_points_before_y(:,4), cbv_points_before_y(:,5), cbv_points_before_y(:,6));

    %% after x
    dt = DelaunayTri(cbv_points_after_y(:,4), cbv_points_after_y(:,5), cbv_points_after_y(:,6));
    tri = dt(:,:);

    if isempty(tri)
        continue;
    end

    trisurf(tri, cbv_points_after_y(:,4), cbv_points_after_y(:,5), cbv_points_after_y(:,6));

    % cbv_part_volume__ = stlVolume(cbv_points_at_this_z(:,4:6)', tri')

    % drawn = true;
end

total_cutting_cbv_volume;


%% ================================================
%% plot obv
%% ================================================
figure('Name', 'OBV', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;

% dt = DelaunayTri(obv(:,1), obv(:,2), obv(:,3));
dt = delaunayn(obv);
tri = dt(:,:);
obv_volume = stlVolume(obv', tri');

trisurf(tri, obv(:,1), obv(:,2), obv(:,3));

non_machinable_volume = invertedVolume - abs(obv_volume) - abs(total_cutting_cbv_volume);

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

%% ================================================
%% Toolpath simulation + gouging detection
%% ================================================
roughing_points = sortrows(roughing_points, [-3 2 1]);
cylinder_handle = [];
cylinder_end_1 = [];
cylinder_end_2 = [];
CL = 0;

f = figure('Name', 'Simulation', 'NumberTitle', 'off');
trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
axis equal;
xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );
hold on;
 
for i = 1:size(roughing_points,1)

    %% skip if not cbv
    if isequal(roughing_points(i,4:6), [0 0 0])
        continue;
    end

    if roughing_points(i,3) < 60
        continue;
    end

    set(0,'CurrentFigure',f);
    
    %% build endpoints for cylinder
    if isequal(roughing_points(i,4:6), [0 0 0])
        p1 = roughing_points(i,1:3);
        p2 = roughing_points(i,1:3) + tool_length * roughing_points(i,7:9) / norm(roughing_points(i,7:9));
    else
        p1 = roughing_points(i,4:6);
        p2 = roughing_points(i,4:6) + tool_length * roughing_points(i,7:9) / norm(roughing_points(i,7:9));
    end
    
    [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, 'y', 1 ,0);
    drawnow;

    %% gouging detection with v-collide
    %% use this transformation matrix, means no transformation at all
    % [1 0 0 0]
    % [0 1 0 0]
    % [0 0 1 0]
    % [0 0 0 1]
    % [ e4  e5  e6 e1]
    % [ e7  e8  e9 e2]
    % [e10 e11 e12 e3]
    % [  0   0   0  1]
    tri = surf2patch(cylinder_handle, 'triangles');
    cylinder_tri = [tri.vertices(tri.faces(:,1),:) tri.vertices(tri.faces(:,2),:) tri.vertices(tri.faces(:,3),:)];
    working_part = [V(T(:,1),:) V(T(:,2),:) V(T(:,3),:)];
    trans1 = [0 0 0 1 0 0 0 1 0 0 0 1];
    trans2 = [0 0 0 1 0 0 0 1 0 0 0 1];
    CL = coldetect(cylinder_tri, working_part, trans1, trans2);

    %% ================================================
    %% Gouging avoidance
    %% ================================================
    iteration = 0;
    max_iteration = 140;
    tetha = 0.5;
    incremental_tetha = 0.5;
    r = []; %% working rotation matrix

    while (CL > 0) && (iteration < max_iteration)
        % always taking rx=[0 1 0] as rotation axis
        rotation_matrix = vrrotvec2mat([0 1 0 deg2rad(tetha)]);
        r = rotation_matrix;

        %% https://en.wikipedia.org/wiki/Transformation_matrix#Affine_transformations
        %% [r1 r2 r3 0]
        %% [r4 r5 r6 0]
        %% [r7 r8 r9 0]
        %% [0  0  0  1]

        %% TRANS parameters
        %% [ e4  e5  e6 e1]
        %% [ e7  e8  e9 e2]
        %% [e10 e11 e12 e3]
        %% [  0   0   0  1]
        %% adjust to trans1 = (e1, ..., e12)
        % trans1 = [0 0 0 r(1,:) r(2,:) r(3,:)];

        %% workaround: trans param doesnt work, do our own rotate then coldetect.
        %% ==============================================================
        delete(cylinder_handle);
        delete(cylinder_end_1);
        delete(cylinder_end_2);

        roughing_points(i,7:9) = (r * roughing_points(i,7:9)')';

        %% redraw cylinder after free gouging trial
        p1 = roughing_points(i,4:6);
        p2 = roughing_points(i,4:6) + tool_length * roughing_points(i,7:9) / norm(roughing_points(i,7:9));

        [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, 'y', 1 ,0);
        tri = surf2patch(cylinder_handle, 'triangles');
        cylinder_tri = [tri.vertices(tri.faces(:,1),:) tri.vertices(tri.faces(:,2),:) tri.vertices(tri.faces(:,3),:)];
        working_part = [V(T(:,1),:) V(T(:,2),:) V(T(:,3),:)];
        %% ==============================================================

        CL = coldetect(cylinder_tri, working_part, trans1, trans2)

        tetha = tetha + incremental_tetha
        iteration = iteration + 1
    end

    %% mark gouging, left the cylinder drawn
    % if CL == 0
    %     delete(cylinder_handle);
    %     delete(cylinder_end_1);
    %     delete(cylinder_end_2);
    % else
    %     set(cylinder_handle, 'FaceColor', 'r');
    %     drawnow;
    % end

    % if ~isempty(r)
        
    %     %% new tool orientation
    %     %% rotate tangent vector by rotation matrix r
    %     %% Ref. https://en.wikipedia.org/wiki/Rotation_matrix, the rule is following
    %     %% [xy'] = [r]*[xy] where [xy] is column vector.
    %     roughing_points(i,7:9) = (r * roughing_points(i,7:9)')';

    %     %% redraw cylinder after free gouging trial
    %     p1 = roughing_points(i,4:6);
    %     p2 = roughing_points(i,4:6) + tool_length * roughing_points(i,7:9) / norm(roughing_points(i,7:9));

    %     [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, 'y', 1 ,0);

    %     %% if free gouging, mark cylinder as green, otherwise keep red
        if CL == 0
            set(cylinder_handle, 'FaceColor', 'g');
        else
            set(cylinder_handle, 'FaceColor', 'r');
        end
        drawnow;
    % end
end
