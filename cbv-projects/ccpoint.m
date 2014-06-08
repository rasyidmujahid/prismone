function ccpoints = ccpoint(triangles, vertices, density)
%% ccpoint  find cutter contact point (ccpoint)
%%          from given triangle structures and vertices,
%%          with density determines the distance among
%%          slicing lines (SL).

    max_min     = maxmin(vertices);
    sl_points   = points_cloud(max_min, density);
    ccpoints    = slicing(sl_points, triangles, vertices);

    disp(ccpoints);

    % X = sl_points(:,:,1);
    % Y = sl_points(:,:,2);
    % Z = sl_points(:,:,3);
    % ccpoints = [X(:) Y(:) Z(:)];
end

%% slicing:     find all cutter contact points between given
%%              points cloud with triangles
function outputs = slicing(points_cloud, triangles, vertices)
    outputs = [];
    for tri = 1:size(triangles, 1)
        tri_vertex_ids  = triangles(tri,:);                         % vertex indices of a triangle
        tri_vertices    = vertices(tri_vertex_ids,:);               % from the indices, get the triangle vertices
        tri_sl          = cutting_sl(tri_vertices, points_cloud);   % from the triangle vertices, find all SL 
                                                                    % that possibly cut thru the triangle
        disp(['triangle ', mat2str(tri_vertices)]);
        
        x = tri_sl(:,:,1);
        y = tri_sl(:,:,2);
        z = tri_sl(:,:,3);

        sl = [x(:) y(:) z(:)];

        disp('slicing');
        disp(sl);

        if (isempty(tri_sl))
            continue;
        end
        for sl_idx = 1:size(sl, 1)
            ccp = intersect( tri_vertices, sl(sl_idx, :));
            if (~isempty(ccp))
                outputs = [outputs; ccp];
            end
        end
    end
end

%% intersect:   find intersection between a line with a triangle
%%              Returns (x,y,z) intersection point
function outputs = intersect(tri_vertices, slicing_line)
    % origin          = [slicing_line(1,1,1) slicing_line(1,1,2) slicing_line(1,1,3)];
    % disp(['tri_vertices ', mat2str(tri_vertices)]);
    % disp(['origin ', mat2str(origin)]);
    origin          = slicing_line;
    direction       = [0 0 20];
    [flag, u, v, t] = rayTriangleIntersection(origin, direction, tri_vertices(1,:), tri_vertices(2,:), tri_vertices(3,:));
    % disp(['flag ', num2str(flag)]);
    
    outputs = [];
    if (flag == 1)
        outputs = origin + t * direction;    
    end
end


%% cutting_sl:  find all SL that cutting thru a triangle.
%%              tri_vertices is matrix 3x3 contains all vertices of the triangle
%%              that want to find its SL.
%%              This returns sub elements of points cloud.
function outputs = cutting_sl(tri_vertices, points_cloud)

    % m = 1 3 5 7 ...      => 2 * n + ( start - 2 )
    % m = 5 8 11 14 ...    => 3 * n + ( start - 3 )
    % m = density * n + ( start - density ),  n [1,2,..]
    % n = ( m + density - start ) / density

    % m = 1 3 5 7 ...
    % if m = 6, n = (6 + 2 - 1) / 2 = 3.5
    % index in m = if from: ceil(3.5) elseif to: floor(3.5)

    % disp(['tri_vertices ', mat2str(tri_vertices)]);

    mins        = min(tri_vertices);
    maxs        = max(tri_vertices);
    density     = points_cloud(1,2,1) - points_cloud(1,1,1);
    min_x       = points_cloud(1,1,1);                          % start

    from_x      = mins(1);                                      % m
    sl_x_from   = ceil( (from_x + density - min_x) / density ); % find n

    to_x        = maxs(1);                                      % m
    sl_x_to     = floor( (to_x + density - min_x) / density );  % find n 

    % disp(['mins ', mat2str(mins)]);
    % disp(['maxs ', mat2str(maxs)]);

    min_y       = points_cloud(1,1,2);
    from_y      = mins(2);
    to_y        = maxs(2);
    sl_y_from   = ceil( (from_y + density - min_y) / density );
    sl_y_to     = floor( (to_y + density - min_y) / density );
    
    % disp(['points_cloud size ', mat2str(size(points_cloud))]);
    % disp(['x ranges ', mat2str(sl_x_from:sl_x_to)]);
    % disp(['y ranges ', mat2str(sl_y_from:sl_y_to)]);

    outputs     = points_cloud( sl_y_from:sl_y_to, sl_x_from:sl_x_to, : );
end

function output = points_cloud(max_min, density)
%% points_cloud     populate all points cloud given max_min matrix (maximum 
%%                  and minimum coordinates) and returns 3D matrix of points
%%                  cloud (X x Y x 3)
    
    disp('Generating points cloud..');
    
    %% Iterating all slicing lines to cut through the part.
    %% Okay, now, generate all possible slicing lines (SL).
    %% An SL is expressed with (i,j) i in X and j in Y.
    min_y = max_min(2,2);
    max_y = max_min(1,2);
    min_x = max_min(2,1);
    max_x = max_min(1,1);

    Y = [min_y:density:max_y max_y];
    X = [min_x:density:max_x max_x];
    
    % disp(X);
    % disp(Y);
    
    output = zeros(length(Y), length(X), 3);
    
    for iy = 1:length(Y)
        for ix = 1:length(X)
            output(iy, ix, 1) = X(ix);
            output(iy, ix, 2) = Y(iy);
            output(iy, ix, 3) = 0;
        end
    end
end

function output = maxmin(vertices)
%% maxmin       find maximum and minimum coordinates
%%              from given vertices
    
    %% [max_x max_y max_z;
    %% min_x min_y min_z]
    output(1,:) = [max(vertices(:,1)) max(vertices(:,2)) max(vertices(:,3))];
    output(2,:) = [min(vertices(:,1)) min(vertices(:,2)) min(vertices(:,3))];
    % disp(['max ', num2str(output(1,:)), ' min ', num2str(output(2,:))]);
end
