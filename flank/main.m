%% ================================================
%% Read STL file
%% ================================================

folder = 'C:\Project\Glash\parts';
filename = '0_005stlasc';
% folder = 'STL4';
% filename = 'setengah-krucut';

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
step_over = 2;
tool_length = 10;
% rail_scale = 50;
% slice_width = 5;

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

%% ccpoints
cc_points = unique(ccpoints_data(:,3:5), 'rows');

%% ================================================
%% Create cutting area
%% ================================================
ccp_pairs = cutting_area(cc_points);

%% ================================================================
%% Bucketing, Finding tool-and-part intersection, Gouging avoidance
%% ================================================================

% b = bucket.Builder(T(:,1:3), V, 10);
% tri_buckets = b.buckets;

%% ================================================================
%% Multiple ray triangle intersections
%% ================================================================

%% resize destination vector into tool length
extended_tangen_normal = zeros(size(ccpoints_data,1), 3);
for i = 1:size(extended_tangen_normal ,1)
	extended_tangen_normal(i,:) = tool_length / norm(ccpoints_data(i,9:11)) * ccpoints_data(i,9:11);
end
vertex1 = V(T(:,1),:);
vertex2 = V(T(:,2),:);
vertex3 = V(T(:,3),:);

disp(['size ccpoints_data(:,3:5) ', num2str(size(ccpoints_data(:,3:5)))]);
disp(['size extended_tangen_normal ', num2str(size(extended_tangen_normal))]);
disp(['size vertices ', num2str(size(vertex1))]);

page_size = size(extended_tangen_normal, 1)
from = 1
to = from + page_size - 1

while to <= size(vertex1,1)

	[intersect, t, u, v, xcoor] = TriangleRayIntersection(ccpoints_data(:,3:5), extended_tangen_normal, ...
		vertex1(from:to,:), vertex1(from:to,:), vertex1(from:to,:), ...
		'lineType', 'segment');

	from = to + 1
	to = from + page_size - 1
end

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
% plot normal vector along with triangle surface
% ================================================
% quiver3( tricenter(:,1), tricenter(:,2), tricenter(:,3), T(:,4), T(:,5), T(:,6), ...
% 	1, 'Color','r','LineWidth',1,'LineStyle','-');

%% ================================================
%% Visualize cpp
%% ================================================

% plot3(cc_points(:,1), cc_points(:,2), cc_points(:,3), 'rx', 'MarkerSize', 5);

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

% plot tangen vector on top of ccpoints
quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
    ccpoints_data(:,9), ccpoints_data(:,10), ccpoints_data(:,11), ...
    1, 'Color','r','LineWidth',1,'LineStyle','-');

% plot extended tangen vector on top of ccpoints
quiver3(ccpoints_data(:,3), ccpoints_data(:,4), ccpoints_data(:,5), ...
    extended_tangen_normal(:,1), extended_tangen_normal(:,2), extended_tangen_normal(:,3), ...
    1, 'Color','b','LineWidth',1,'LineStyle','-');