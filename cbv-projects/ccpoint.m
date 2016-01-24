%% ccpoint  find cutter contact point (ccpoint)
%%          from given triangle structures and vertices,
%%          with density determines the distance among
%%          vertical slicing lines (SL).
%%          This function returns cc points along with each slicing coordinate
%%          and its triangle index and normal vector.
function [ccpoints, sl_points] = ccpoint(triangles, vertices, faces, max_min, density)
    sl_points   = points_cloud(max_min, density);
    ccpoints    = slicing(sl_points, triangles, vertices, faces);
end

%% slicing:     find all cutter contact points between given
%%              points cloud with triangles.
%%              This function results cell array of following :
%%
%% ;; intersection point ;; slicing line coordinate ;; triangle index ;; normal vector
%% ;;  [inter_points]    ;;  [sli_coordinate]       ;; [tri_index]    ;;   [normal]
function outputs = slicing(points_cloud, triangles, vertices, faces)
    outputs = {};

    for tri = 1:size(triangles, 1)
        tri_vertex_ids   = triangles(tri,:);                         % vertex indices of a triangle
        tri_vertices     = vertices(tri_vertex_ids,:);               % from the indices, get the triangle vertices
        tri_sl           = cutting_sl(tri_vertices, points_cloud);   % from the triangle vertices, find all SL
                                                                     % along with SL index.
        if (isempty(tri_sl))
            continue;
        end

        % convert 3D slicing lines into 2D
        x  = tri_sl(:,:,1);
        y  = tri_sl(:,:,2);
        z  = tri_sl(:,:,3);
        sl = [x(:) y(:) z(:)];

        for sli = 1:size(sl, 1)
            ccp = intersect( tri_vertices, sl(sli, :));

            if ( ~isempty(ccp))
                if (isempty(outputs))
                    outputs = { ccp, sl(sli,1:2), tri, faces(tri,:) };
                else
                    %% avoid duplicate, as 2/more triangles can share an intersection point
                    %% for e.g. if intersection happens at triangle vertex.
                    if (~ismember(ccp, cell2mat(outputs(:,1)), 'rows'))
                        outputs = [ outputs; { ccp, sl(sli,1:2), tri, faces(tri,:) } ];
                    end
                end
            end
        end
    end
end

%% intersect:   find intersection between a line with a triangle
%%              Returns (x,y,z) intersection point
function outputs = intersect(tri_vertices, slicing_line)
    origin          = slicing_line;
    direction       = [0 0 20];
    [flag, u, v, t] = rayTriangleIntersection(origin, direction, tri_vertices(1,:), tri_vertices(2,:), tri_vertices(3,:));

    outputs = [];
    if (flag == 1)
        outputs = origin + t * direction;
    end
end


%% cutting_sl:  find all SL that cutting thru a triangle.
%%              tri_vertices is matrix 3x3 contains all vertices of the triangle
%%              that want to find its SL.
%%              This returns sub elements of points cloud 'sub_points'.
%%              'sub_points_idx' contains indices of 'sub_points' in points_cloud.
function sub_points = cutting_sl(tri_vertices, points_cloud)

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

    min_y       = points_cloud(1,1,2);
    from_y      = mins(2);
    to_y        = maxs(2);
    sl_y_from   = ceil( (from_y + density - min_y) / density );
    sl_y_to     = floor( (to_y + density - min_y) / density );

    sub_points      = points_cloud( sl_y_from:sl_y_to, sl_x_from:sl_x_to, : );
end

function output = points_cloud(max_min, density)
%% points_cloud     populate all points cloud given max_min matrix (maximum
%%                  and minimum coordinates) and returns 3D matrix of points
%%                  cloud (X x Y x 3)

    %% Iterating all slicing lines to cut through the part.
    %% Okay, now, generate all possible slicing lines (SL).
    %% An SL is expressed with (i,j) i in X and j in Y.
    offset = 0.001;
    min_y = max_min(2,2) + offset;
    max_y = max_min(1,2) - offset;
    min_x = max_min(2,1) + offset;
    max_x = max_min(1,1) - offset;

    [output(:,:,1), output(:,:,2), output(:,:,3)] = meshgrid(min_x:density:max_x, min_y:density:max_y, 0);

    %% append the last with max values if does not include
end