function ccpoints = ccpoint(triangles, vertices, stepover)
%% ccpoint  find cutter contact point (ccpoint)
%%          from given triangle structures and vertices,
%%          with stepover is the distance between slices
%%          at different y values.

    max_min = maxmin(vertices);
    maxmin_y = max_min(:,2);

    lines_y = maxmin_y(2):stepover:maxmin_y(1);
    disp(['all y values', num2str(lines_y)]);

    ccpoints = [];
    
    for tri = 1:size(triangles, 1)

        %% vertex indices of a triangle
        tri_vertex_ids = triangles(tri,:);

        % from the indices, get the triangle vertices
        tri_vertices = vertices(tri_vertex_ids,:);
        
        % from the triangle vertices, find all y cut across the edges of triangle
        cutting_y = [];
        for i = 1:length(lines_y)
            y = lines_y(i);
            if is_in_between(y, tri_vertices(1,:), tri_vertices(2,:)) || ...
                    is_in_between(y, tri_vertices(1,:), tri_vertices(3,:)) || ...
                    is_in_between(y, tri_vertices(3,:), tri_vertices(2,:))
                cutting_y = [cutting_y; y];
            end 
        end
    
        % now start finding the intersections of this triangle with ys
        ccp = intersect_triangle_with_lines(tri_vertices, cutting_y);
        ccpoints = [ccpoints; ccp];
    end

end

function output = maxmin(vertices)
%% maxmin       find maximum and minimum coordinates
%%              from given vertices
    
    %% [max_x max_y max_z;
    %% min_x min_y min_z]
    output(1,:) = [max(vertices(:,1)) max(vertices(:,2)) max(vertices(:,3))];
    output(2,:) = [min(vertices(:,1)) min(vertices(:,2)) min(vertices(:,3))];
    disp(['max ', num2str(output(1,:)), ' min ', num2str(output(2,:))]);
end

%% is_in_between: check if y is in between two points
function output = is_in_between(y, point_1, point_2)
    if point_2(2) > point_1(2)
        yy = [point_2(2) point_1(2)];
    else
        yy = [point_1(2) point_2(2)];
    end
    output = yy(1) >= y && y >= yy(2);
end

function output = intersect_triangle_with_lines(triangle_vertices, lines)
%% cutting_y    find points of intersection between vector lines [2 4 6 ..]
%%              and 2 of 3 triangle sides. each side might 
%%              return more than one intersection.
    
    output = [];
    for i = 1:length(lines)
        y = lines(i);
        ccp = intersect_triangle_with_y(triangle_vertices, y);
        output = [output; ccp];
    end
end

function output = intersect_triangle_with_y(triangle_vertices, y)
%% intersect_triangle_with_y:   find intersection points between a triangle and a y
%%                              so this will check through all triangle edges.

    output = [];
    % side by vertex 1 & 2, 1 & 3, 2 & 3
    indices = [1 2; 2 3; 3 1];
    for i = 1:length(indices)
        point1 = triangle_vertices( indices(i,1), :);
        point2 = triangle_vertices( indices(i,2), :);
        ccp = intersect_line_with_y( point1, point2, y);
        if ~isnan(ccp)
            output = [output; ccp];
        end    
    end
end

function output = intersect_line_with_y(point_1, point_2, y)
%% intersect_line_with_y: find intersection point between line formed 
%% by (x1,y1,z1) & (x2,y2,z2) and y = a_value

    if is_in_between(y, point_1, point_2)
    
        %% (x - x1)/(x2 - x1) = (y - y1)/(y2 - y1) = (z - z1)/(z2 - z1)
        %% x = (y - y1)/(y2 - y1) * (x2 - x1) + x1
        %% z = (y - y1)/(y2 - y1) * (z2 - z1) + z1

        x = (y - point_1(2)) / (point_2(2) - point_1(2)) * (point_2(1) - point_1(1)) + point_1(1);
        z = (y - point_1(2)) / (point_2(2) - point_1(2)) * (point_2(3) - point_1(3)) + point_1(3);
    
        output = [x y z];
    else
        output = NaN;
    end
end
