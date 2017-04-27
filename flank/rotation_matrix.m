%% r is the rotation vector, a row vector of four elements, 
%% where the first three elements specify the rotation axis, unit vector (l,m,n) and the last element defines the angle θ.
%% 
%% how to create rotation matrix
%% refs: 
%% https://en.wikipedia.org/wiki/Transformation_matrix#Rotation
%% https://en.wikipedia.org/wiki/Rotation_matrix

%% The matrix to rotate an angle θ about the axis defined by unit vector (l,m,n)
%% [
%%    ll(1 - cosθ) + cosθ       ml(1 - cosθ) - nsinθ     nl(1 - cosθ) + msinθ
%%    lm(1 - cosθ) + nsinθ      mm(1 - cosθ) + cosθ      nm(1 - cosθ) - lsinθ
%%    ln(1 - cosθ) - msinθ      mn(1 - cosθ) + lsinθ     nn(1 - cosθ) + cosθ
%% ]

function matrix = rotation_matrix(r)
    l = r(1);
    m = r(2);
    n = r(3);
    tetha = r(4);

    [ l*l*(1 - cosd(tetha)) + cosd(tetha)    m*l*(1 - cosd(tetha)) - n*sind(tetha)   n*l*(1 - cosd(tetha)) + m*sind(tetha) 
      l*m*(1 - cosd(tetha)) + n*sind(tetha)  m*m*(1 - cosd(tetha)) + cosd(tetha)    n*m*(1 - cosd(tetha)) - l*sind(tetha)
      l*n*(1 - cosd(tetha)) - m*sind(tetha)  m*n*(1 - cosd(tetha)) + l*sind(tetha)  n*n*(1 - cosd(tetha)) + cosd(tetha)
    ]
end