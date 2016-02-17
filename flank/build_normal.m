%% build_normal: build ccp normal vector
function normals = build_normal(vertex_idx_to_cc_points, vertices, triangles)

    vertex_idx_to_cc_points = sortrows(vertex_idx_to_cc_points, [4 3]);
    normals = vertex_idx_to_cc_points;
    leng = length(vertex_idx_to_cc_points);
    
    for i = 1:leng

        %% normal vector
        vertex_idx_1 = vertex_idx_to_cc_points(i,1);
        vertex_idx_2 = vertex_idx_to_cc_points(i,2);

        vertex_1 = vertices(vertex_idx_1,:);
        vertex_2 = vertices(vertex_idx_2,:);
        ccpoint = vertex_idx_to_cc_points(i,3:5);

        %% if ccp lies on vertex 1
        if pdist([ccpoint; vertex_1]) < eps
            normal = build_normal_on_vertex(vertex_idx_1, triangles);

        %% if ccp lies on vertex 2
        elseif pdist([ccpoint; vertex_2]) < eps
            normal = build_normal_on_vertex(vertex_idx_2, triangles);

        %% 2. if ccp lies on edge
        else
            normal = build_normal_on_edge(vertex_idx_1, vertex_idx_2, triangles);
        end
        
        normals(i,6:8) = normal;

        %% tangent vector
        to_reverse = false;
        if (i+1) > leng
            next_ccpoint = vertex_idx_to_cc_points(i-1, 3:5);
            to_reverse = true;
        else
            next_ccpoint = vertex_idx_to_cc_points(i+1, 3:5);
        end
        
        if next_ccpoint(:,2) ~= ccpoint(:,2)
            %% if not lies on the same y
            to_reverse = true;
            next_ccpoint = vertex_idx_to_cc_points(i-1, 3:5);

            if next_ccpoint(:,2) ~= ccpoint(:,2)
                next_ccpoint = [];
            end
        end

        if ~isempty(next_ccpoint)
            tangent = build_tangent_normal(normal, (next_ccpoint - ccpoint), to_reverse);
            
            %% reverse negative k in vector (i,j,k)
            if tangent(3) < 0
                tangent = -tangent;
            end
            
            normals(i,9:11) = tangent / norm(tangent);
        end
    end
end

%% build_normal_on_vertex: build vertex normal vector
function normal = build_normal_on_vertex(vertex_index, triangles)
    
    %% find all triangles that have this vertex as one of its vertices
    [row, col] = find(triangles(:,1:3) == vertex_index);
    neighbor_triangle_normal_vectors = triangles(row, 4:6);

    %% vector sum
    if size(neighbor_triangle_normal_vectors,1) > 1
        normal = sum(neighbor_triangle_normal_vectors);
    else
        normal = neighbor_triangle_normal_vectors;
    end
end

%% build_normal_on_edge: build ccpoint normal vector
function normal = build_normal_on_edge(vertex_idx_1, vertex_idx_2, triangles)
    
    %% find all triangles having vertex_idx_1 and vertex_idx_2 as its two of its vertices
    [row1, col] = find(triangles(:,1:3) == vertex_idx_1);
    [row2, col] = find(triangles(row1,1:3) == vertex_idx_2);

    row = row1(row2);
    neighbor_triangle_normal_vectors = triangles(row, 4:6);

    %% vector sum
    if size(neighbor_triangle_normal_vectors,1) > 1
        normal = sum(neighbor_triangle_normal_vectors);
    else
        normal = neighbor_triangle_normal_vectors;
    end
end

%% build_tangent_normal: cross product of orthogonal vector to given normal vector
function tangent = build_tangent_normal(normal, orthogonal, to_reverse)
    tangent = cross(orthogonal, normal);
    if to_reverse
        tangent = -tangent;
    end
end