%% Main

[T, V] = stlreader('parts/0_0075stlasc.stl');

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

X = V(:, 1);
Y = V(:, 2);
Z = V(:, 3);

% plotparts = plot3(X, Y, Z, '.', 'LineWidth', 2);
% set('plotparts');
% grid on;

h3 = trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'Interp' );
  
axis equal;

xlabel ( '--X axis--' )
ylabel ( '--Y axis--' )
zlabel ( '--Z axis--' )

hold on;

%% plot normal vector along with triangle surface
%quiver3( tricenter(:,1), tricenter(:,2), tricenter(:,3), T(:,4), T(:,5), T(:,6) );

ccp = ccpoint(T(:,1:3), V, 2);

plot3(ccp(:,1), ccp(:,2), ccp(:,3), 'x');