%% ccpoint  find cutter contact point (ccpoint)
%%          from given triangle structures and vertices,
%%          with stepover is the distance between slices
%%          at different y values.
%% 
%% Returns array of following:
%% ||           vertex indices         ||    CCP    ||
%% || vertex index 1 || vertex index 2 || x   y   z ||
function ccpoints = ccpoint(triangles, vertices, stepover)

    max_min = maxmin(vertices);
    maxmin_y = max_min(:,2);

    lines_y = maxmin_y(2):stepover:maxmin_y(1);
    disp(['all y values', num2str(lines_y)]);

    ccpoints = [];
    
    for triangle_index = 1:size(triangles, 1)

        %% vertex indices of a triangle
        %% e.g. [45 88 90]
        triangle_vertex_indices = triangles(triangle_index,:);

        for i = 0:2
            vertex_index_1 = triangle_vertex_indices(mod(i,3)+1);
            vertex_index_2 = triangle_vertex_indices(mod(i+1,3)+1);

            existing_ccp = [];
            if ~isempty(ccpoints)
                existing_ccp = ccpoints(find(ccpoints(:,1) == vertex_index_1 & ccpoints(:,2) == vertex_index_2),:);
            end

            if isempty(existing_ccp)
                cutting_y = [];
                for i = 1:length(lines_y)
                    y = lines_y(i);
                    if is_in_between(y, vertices(vertex_index_1,:), vertices(vertex_index_2,:))
                        cutting_y = [cutting_y; y];
                    end
                end

                ccp = intersect_triangle_with_lines(vertices(vertex_index_1,:), vertices(vertex_index_2,:), cutting_y);
                if ~isempty(ccp)
                    ccpoints = [ccpoints; vertex_index_1 vertex_index_2 ccp];
                end
            else
                disp('Found existing_ccp');
            end
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

function output = intersect_triangle_with_lines(triangle_vertex_1, triangle_vertex_2, lines)
%% cutting_y    find points of intersection between vector lines [2 4 6 ..]
%%              and 2 of 3 triangle sides. each side might 
%%              return more than one intersection.
    
    output = [];
    for i = 1:length(lines)
        y = lines(i);
        ccp = intersect_triangle_with_y(triangle_vertex_1, triangle_vertex_2, y);
        output = [output; ccp];
    end
end

function output = intersect_triangle_with_y(triangle_vertex_1, triangle_vertex_2, y)
%% intersect_triangle_with_y:   find intersection points between a triangle and a y
%%                              so this will check through all triangle edges.

    output = [];
    ccp = intersect_line_with_y( triangle_vertex_1, triangle_vertex_2, y);
    if ~isnan(ccp)
        output = [output; ccp];
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
