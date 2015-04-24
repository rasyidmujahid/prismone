%% ================================================
%% Read STL file
%% ================================================

folder = 'Stl4';
filename = 'setengah-krucut';

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
tool_length = 10;
slice_scale = 50;

%% ================================================
%% Generate CC points
%% ================================================

ccp = ccpoint(T(:,1:3), V, tool_length);
ccp = unique(ccp, 'rows');

%% ================================================
%% Create cutting area
%% E.g.
%% v11 v12
%% v21 v22
%% v31 v32
%% ================================================
rail_pairs = cutting_area(ccp, slice_scale)

%% ================================================================
%% Bucketing, Finding tool-and-part intersection, Gouging avoidance
%% ================================================================

% b = bucket.Builder(T(:,1:3), V, 10);
% tri_buckets = b.buckets;


%% ================================================================
%% Orthogonal projection
%% ================================================================



%% ================================================
%% Plot points
%% ================================================

X = V(:, 1);
Y = V(:, 2);
Z = V(:, 3);

% plotparts = plot3(X, Y, Z, '.', 'LineWidth', 2);
% set('plotparts');
% grid on;


%% ================================================
%% Visualize faceted model
%% ================================================

h3 = trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
  
axis equal;

xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );

hold on;

%% ================================================
%% plot normal vector along with triangle surface
%% ================================================
%quiver3( tricenter(:,1), tricenter(:,2), tricenter(:,3), T(:,4), T(:,5), T(:,6) );

%% ================================================
%% Visualize cpp
%% ================================================

plot3(ccp(:,1), ccp(:,2), ccp(:,3), 'rx', 'MarkerSize', 5);

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
for i = 1:size(rail_pairs,1)
    line(rail_pairs(i, [1,4]), rail_pairs(i, [2,5]), rail_pairs(i, [3,6]), 'Color','b','LineWidth',2,'LineStyle','-')
end