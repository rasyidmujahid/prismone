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
step_over = 15;
tool_length = 10;
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
%% ================================================
ccpoints_data = ccpoint(T(:,1:3), V, step_over);

%% build ccpoints normal vector, ccpoints tangential vector
ccpoints_data = build_normal(ccpoints_data, V, T);

%% order by x,y to print to NC file
save_nc_file(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
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

h3 = trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
  
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

%% ================================================
%% Draw colored buckets
%% ================================================
% colors = ['r';'g';'b';'c';'m';'y';'w';'k'];
% for i = 1:size(tri_buckets,1)
%     for j = 1:size(tri_buckets,2)
%         selected_bucket = tri_buckets(i,j).bag;
%         for n = 1:3:size(selected_bucket.triangles)
%             tri1 = selected_bucket.triangles(n,:);
%             tri2 = selected_bucket.triangles(n+1,:);
%             tri3 = selected_bucket.triangles(n+2,:);
            
%             label = selected_bucket.x + selected_bucket.y;
%             c = colors(mod(label, size(colors,1)) + 1);

%             patch([tri1(1,1); tri2(1,1); tri3(1,1)], ...
%                 [tri1(1,2); tri2(1,2); tri3(1,2)], ...
%                 [tri1(1,3); tri2(1,3); tri3(1,3)], c);
%         end
        
%     end
% end

%% ================================================
%% Draw rails
%% ================================================
% for i = 1:size(ccp_pairs,1)
%     line(ccp_pairs(i, [1,4]), ccp_pairs(i, [2,5]), ccp_pairs(i, [3,6]), 'Color','b','LineWidth',2,'LineStyle','-')
% end

% plot normal vector on top of ccpoints
% quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
%     ccpoints_data(:,6), ccpoints_data(:,7), ccpoints_data(:,8), ...
%     3, 'Color','b','LineWidth',1,'LineStyle','-');

% % plot tangen vector on top of ccpoints
% quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
%     ccpoints_data(:,9), ccpoints_data(:,10), ccpoints_data(:,11), ...
%     1, 'Color','r','LineWidth',1,'LineStyle','-');

% plot extended tangen vector on top of ccpoints
% quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
%     extended_tangen_normal(:,1), extended_tangen_normal(:,2), extended_tangen_normal(:,3), ...
%     1, 'Color','b','LineWidth',1,'LineStyle','-');

%% ================================================
%% draw flank lines
%% ================================================
ccpoints_data(:,12) = ccpoints_data(:,3) + extended_tangen_normal(:,1);
ccpoints_data(:,13) = ccpoints_data(:,4) + extended_tangen_normal(:,2);
ccpoints_data(:,14) = ccpoints_data(:,5) + extended_tangen_normal(:,3);

% extended_tangen_normal(:,1:3)
% ccpoints_data(:,12:14)

ccpoints_data = sortrows(ccpoints_data, [4 3]);

for i = 1:size(ccpoints_data,1)-1

    % line(ccpoints_data(i,[3 12]), ccpoints_data(i,[4 13]), ccpoints_data(i,[5 14]), 'Color','red','LineWidth',2,'LineStyle','-');

    if ccpoints_data(i,4) ~= ccpoints_data(i+1,4)
        continue;
    end

    d1 = ccpoints_data(i,4) < ccpoints_data(i,13);
    d2 = ccpoints_data(i+1,4) < ccpoints_data(i+1,13);

    if xor(d1,d2)
        continue;
    end

    rx = [ccpoints_data(i,3) ccpoints_data(i+1,3) ccpoints_data(i+1,12) ccpoints_data(i,12)];
    ry = [ccpoints_data(i,4) ccpoints_data(i+1,4) ccpoints_data(i+1,13) ccpoints_data(i,13)];
    rz = [ccpoints_data(i,5) ccpoints_data(i+1,5) ccpoints_data(i+1,14) ccpoints_data(i,14)];
    % c = 'red';
    % patch(rx,ry,rz,c);
    
    f2 = [1 2 3 4];
    v2 = [rx' ry' rz'];
    col = [0; 6; 4];
    patch('Faces',f2,'Vertices',v2,'EdgeColor','blue','FaceColor','red','LineWidth',2);
end