%% Class represents buckets builder

classdef Builder < handle
    properties
        buckets
        triangles
        vertices
        bucket_size
    end

    properties(SetAccess = private)

    end

    methods
        function builder = Builder(triangles, vertices, bucket_size)
            builder.triangles = triangles;
            builder.vertices = vertices;
            builder.bucket_size = bucket_size;

            minmax = bucket.Util.minmax(vertices);
            builder.create_buckets(minmax);
            builder.bucketize;
        end

        function create_buckets(builder, minmax)
            len = ceil((minmax(2,1) - minmax(1,1)) / builder.bucket_size);
            width = ceil((minmax(2,2) - minmax(1,2)) / builder.bucket_size);

            builder.buckets = bucket.Buckets(zeros(len,width));

            disp(['Created buckets, size ', num2str(len), ' x ', num2str(width)]);
        end

        function bucketize(builder)
            disp('Put triangles into buckets..');
            for i = 1:size(builder.triangles, 1)
                vertex_indices      = builder.triangles(i,:);
                triangle_vertices   = builder.vertices(vertex_indices,:);
                builder.put(triangle_vertices);
            end
        end

        %% put a triangle into buckets
        function put(builder, triangle_vertices)
            identified_buckets = builder.find_bucket_for_triangle(triangle_vertices);
            for i = 1:size(identified_buckets)
                b = identified_buckets(i,:);
                builder.buckets(b(1),b(2)).bag.add(triangle_vertices);
            end
        end

        %% Find bucket for given triangle provided its vertices.
        %% A triangle can be under several buckets (at most 4).
        %% 
        %% Returns array of buckets.
        function identified_buckets = find_bucket_for_triangle(builder, triangle_vertices)
            identified_buckets = [];
            for i = 1:size(triangle_vertices,1)
                vertex = triangle_vertices(i,:);
                x = ceil(vertex(1) / builder.bucket_size);
                y = ceil(vertex(2) / builder.bucket_size);
                
                if x == 0
                    x = 1;
                end

                if y == 0
                    y = 1;
                end

                if ~ismember([x y], identified_buckets, 'rows')
                    identified_buckets = [identified_buckets; [x y]];
                end
            end
        end

    end
end