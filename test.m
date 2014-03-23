
trisurf ( tri_ids, tri_v(:,1), tri_v(:,2), tri_v(:,3), 'FaceColor', 'Interp' );
hold on

xlabel ( '--X axis--' )
ylabel ( '--Y axis--' )
zlabel ( '--Z axis--' )

plane_y = [0 0.39063 0; 10 0.39063 0; 10 0.39063 6; 0 0.39063 6];
fill3(plane_y(:,1),plane_y(:,2),plane_y(:,3),'r')
alpha(0.3)

plane_y = [0 0.59062 0; 10 0.59062 0; 10 0.59062 6; 0 0.59062 6];
fill3(plane_y(:,1),plane_y(:,2),plane_y(:,3),'r')
alpha(0.3)

ccp = ccpoint(tri_ids, tri_v, 0.2)
plot3(ccp(:,1),ccp(:,2),ccp(:,3),'x')