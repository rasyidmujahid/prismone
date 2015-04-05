%% ================================================
%% Read STL file
%% ================================================

folder = 'C:\Project\Glash\parts';
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
%% Generate CC points
%% ================================================

stepover = 10;
ccp = ccpoint(T(:,1:3), V, stepover);
ccp = unique(ccp, 'rows');


%% ================================================================
%% Bucketing, Finding tool-and-part intersection, Gouging avoidance
%% ================================================================

b = bucket.Builder(T(:,1:3), V, 10);
tri_buckets = b.buckets;


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

h3 = trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'w' );
  
axis equal;

xlabel ( '--X axis--' );
ylabel ( '--Y axis--' );
zlabel ( '--Z axis--' );

hold on;

%% plot normal vector along with triangle surface
%quiver3( tricenter(:,1), tricenter(:,2), tricenter(:,3), T(:,4), T(:,5), T(:,6) );

%% ================================================
%% Visualize cpp & flank line
%% ================================================

% plot3(ccp(:,1), ccp(:,2), ccp(:,3), 'x');

colors = ['r';'g';'b';'c';'m';'y';'w';'k'];

%% buckets label
for i = 1:size(tri_buckets,1)
    for j = 1:size(tri_buckets,2)
        selected_bucket = tri_buckets(i,j).bag;
        for n = 1:3:size(selected_bucket.triangles)
            tri1 = selected_bucket.triangles(n,:);
            tri2 = selected_bucket.triangles(n+1,:);
            tri3 = selected_bucket.triangles(n+2,:);
            
            label = selected_bucket.x + selected_bucket.y;
            c = colors(mod(label, size(colors,1)) + 1);

            patch([tri1(1,1); tri2(1,1); tri3(1,1)], ...
                [tri1(1,2); tri2(1,2); tri3(1,2)], ...
                [tri1(1,3); tri2(1,3); tri3(1,3)], c);
        end
        
    end
end
