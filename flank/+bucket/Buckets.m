%% Class represents collection of buckets

classdef Buckets < handle
    properties
        bag
    end

    methods
        function buckets = Buckets(F)
            if nargin > 0
                len     = size(F,1);
                width   = size(F,2);

                buckets(len,width) = bucket.Buckets;
                for l = 1:len
                    for w = 1:width
                        buckets(l,w).bag = bucket.Bucket(l,w);
                    end
                end                
            end
        end
    end
end