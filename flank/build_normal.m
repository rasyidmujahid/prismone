%% build_normal: build ccp normal vector
function normals = build_normal(vertex_idx_to_cc_points, vertices, triangles)

    normals = vertex_idx_to_cc_points;
    
    for i = 1:length(vertex_idx_to_cc_points)
        vertex_idx_1 = vertex_idx_to_cc_points(i,1);
        vertex_idx_2 = vertex_idx_to_cc_points(i,2);

        vertex_1 = vertices(vertex_idx_1,:);
        vertex_2 = vertices(vertex_idx_2,:);
        ccpoint = vertex_idx_to_cc_points(i,3:5);

        if pdist([ccpoint; vertex_1]) < eps
            %% if ccp lies on vertex 1
            normal = build_normal_on_vertex(vertex_idx_1, triangles);
        elseif pdist([ccpoint; vertex_2]) < eps
            %% if ccp lies on vertex 2
            normal = build_normal_on_vertex(vertex_idx_2, triangles);
        else
            %% 2. if ccp lies on edge
            normal = build_normal_on_edge(vertex_idx_1, vertex_idx_2, triangles);
        end
        normals(i,6:8) = normal;
    end
end

%% build_normal_on_vertex: build vertex normal vector
function normal = build_normal_on_vertex(vertex_index, triangles)
    
    %% find all triangles that have this vertex as one of its vertices
    [row, col] = find(triangles(:,1:3) == vertex_index);
    neighbor_triangle_normal_vectors = triangles(row, 4:6);

    %% vector sum
    normal = sum(neighbor_triangle_normal_vectors);
end

%% build_normal_on_edge: build ccpoint normal vector
function normal = build_normal_on_edge(vertex_idx_1, vertex_idx_2, triangles)
    
    %% find all triangles having vertex_idx_1 and vertex_idx_2 as its two of its vertices
    [row, col] = find(triangles(:,1:3) == vertex_idx_1);
    [row, col] = find(triangles(row,1:3) == vertex_idx_2);

    neighbor_triangle_normal_vectors = triangles(row, 4:6);

    %% vector sum
    normal = sum(neighbor_triangle_normal_vectors);
end