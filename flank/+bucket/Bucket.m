classdef Bucket < handle
    properties
    end

    properties(SetAccess = private)
        triangles = [];
        x
        y
    end

    methods
        function b = Bucket(x, y)
            b.x = x;
            b.y = y;
        end

        function add(bucket, triangle)
            bucket.triangles = [bucket.triangles; triangle];
        end
    end
end