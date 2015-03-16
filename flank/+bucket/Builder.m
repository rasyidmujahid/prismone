classdef Builder < handle
    properties
        buckets
        triangles
        vertices
        width
    end

    properties(SetAccess = private)

    end

    methods
        function builder = Builder(triangles, vertices, width)
            builder.triangles = triangles;
            builder.vertices = vertices;
            builder.width = width

            minmax = bucket.Util.minmax(vertices);
            builder.create_buckets(minmax)
            bucketize
        end

        function create_buckets(builder, minmax)
            len_x = ceil((minmax(2,1) - minmax(1,1)) / builder.width);
            len_y = ceil((minmax(2,2) - minmax(1,2)) / builder.width);

            builder.buckets = bucket.Buckets(len_x, len_y);
        end

        function bucketize(builder)
            for i = 1:size(builder.triangles, 1)
                vertex_indices      = builder.triangles(i,:);
                triangle_vertices   = builder.vertices(vertex_indices,:);
                identified_buckets  = find_bucket_for(triangle_vertices);

            end
        end

        %% find bucket for given triangle provided its vertices.
        %% A triangle can be under several bucket (at most 4).
        %% 
        %% Returns bucket object.
        function find_bucket_for(builder, triangle_vertices)
            in_buckets = [];
            
        end

    end
end