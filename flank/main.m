%% ================================================
%% Read STL file
%% ================================================

folder = 'C:\Project\Glash\parts';
filename = '0_005stlasc';

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

buckets = bucket.Builder(T(:,1:3), V, 5);



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

plot3(ccp(:,1), ccp(:,2), ccp(:,3), 'x');



%% ================================================
%% Starting line of tool orientation
%% ================================================
% tool_length = 50; % assuming 5cm length
% for i = 0:ccp_per_y.size-1
%     ccp_over_this_line = ccp_per_y.get(i);

%     % only show if smaller than tool length
%     this_y = ccp_over_this_line(1,2);
%     if this_y > tool_length
%         break
%     end

%     for j = 1:size(ccp_over_this_line, 1)
%         line([ccp_over_this_line(j,1) ccp_over_this_line(j,1)], ...
%             [ccp_over_this_line(j,2) 0], ...
%             [ccp_over_this_line(j,3) ccp_over_this_line(j,3)], ...
%             'Color','b','LineWidth',1,'LineStyle','-');
%     end
% end