classdef Buckets < handle
    properties
        bucket
    end

    methods
        function buckets = Buckets(len, width)
            buckets(len, width) = Buckets;
            for l = 1:len
                for w = 1:width
                    buckets(l,w).bucket = bucket.Bucket(l,w);
                end
            end
        end
    end
end