%% ================================================
%% Read STL file
%% ================================================

folder = 'D:\Glash\parts';
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
%% Generate CC points
%% ================================================

stepover = 10;
ccp = ccpoint(T(:,1:3), V, stepover);
ccp = unique(ccp, 'rows');

%% ================================================
%% Generate flank line directions
%% ================================================

% sort by y
lines_y   = sort( unique(ccp(:,2)) );
ccp_per_y = java.util.ArrayList;
for i = 1:size(lines_y, 1)
    line_y = lines_y(i);
    ccp_over_this_line = ccp( ccp(:,2) == line_y,: );
    ccp_per_y.add( sortrows(ccp_over_this_line,1) );
end

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

plot3(ccp(:,1), ccp(:,2), ccp(:,3), 'o');

for i = 0:ccp_per_y.size-2
    ccp_over_this_line  = ccp_per_y.get(i);
    ccp_after_this_line = ccp_per_y.get(i + 1);
    
    size_taken = size(ccp_over_this_line, 1);
    if size_taken > size(ccp_after_this_line, 1)
        size_taken = size(ccp_after_this_line, 1);
    end
    
    % line([ccp_over_this_line(1:size_taken,1) ccp_after_this_line(1:size_taken,1)], ...
    %     [ccp_over_this_line(1:size_taken,2) ccp_after_this_line(1:size_taken,2)], ...
    %     [ccp_over_this_line(1:size_taken,3) ccp_after_this_line(1:size_taken,3)]);

    for j = 1:size_taken
        line([ccp_over_this_line(j,1) ccp_after_this_line(j,1)], ...
            [ccp_over_this_line(j,2) ccp_after_this_line(j,2)], ...
            [ccp_over_this_line(j,3) ccp_after_this_line(j,3)]);
    end
end