classdef Builder < handle
	properties
		buckets
		triangles
		vertices
		width
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

		function bucketize
			
		end

	end
end