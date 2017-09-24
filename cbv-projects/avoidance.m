function output = avoidance(object1, object2)
% avoidance Given object1 and object1, each are defined by triangles, 
%           return object2's transformation untill free gouging.
%           
% object1   nine columns matrix, defining the vertices of
%           the triangles (x1, y1, z1, x2, y2, z2, x3, y3, z3)
% object2   idem as object1
% 
% return    transformation matrix, twelve columns (e1, ..., e12) defines a single transformation matrix:
%
%           [ e4  e5  e6 e1]
%           [ e7  e8  e9 e2]
%           [e10 e11 e12 e3]
%           [  0   0   0  1]

    output = [];

end


function output = transform(object, direction)
end

function output = find_direction(ccpoint)

end