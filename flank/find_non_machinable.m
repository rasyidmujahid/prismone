%% find_non_machinable: find non-machinable area with bucketing 
%% params:
%%   bucket_width: set to step-over
%%   bucket_length: set to step-over
%%   ccpoints_data: || v-idx1 || v-idx2 || x   y   z || normal i j k || tangent i j k ||
%%   vertices
%%   triangles
function [bucket_index, bucket_ccp, bucket_triangle, machinable_flag] = find_non_machinable(bucket_width, bucket_length, ccpoints_data, vertices, triangles)
    
    %% sort by Y then X
    ccpoints_data = sortrows(ccpoints_data, [4 3]);
    
    bucket_index = init_bucket(bucket_width, bucket_length, ccpoints_data);

    [bucket_index bucket_ccp bucket_triangle] = run_bucket(ccpoints_data);
end

%% run_bucket:
%% params:
%%   ccpoints_data: || v-idx1 || v-idx2 || x   y   z || normal i j k || tangent i j k ||
function [bucket_index, bucket_ccp, bucket_triangle] = run_bucket(ccpoints_data)
    for i = i:
end

%% init_bucket: create empty bucket with specified size
%% params:
%%  bucket_width
%%  bucket_length
%% returns:
%%   
function bucket_index = init_bucket(bucket_width, bucket_length, ccpoints_data)
    % max_min = maxmin(vertices);

    % offset = 0;
    % min_y = max_min(2,2) + offset;
    % max_y = max_min(1,2) - offset;
    % min_x = max_min(2,1) + offset;
    % max_x = max_min(1,1) - offset;

    % [X Y] = meshgrid(min_x:bucket_width:max_x, min_y:bucket_length:max_y);
    % bucket_index = ;

    %% bucket structure:
    %% [p11 p12 p13 p14]
    %% [p21 p22 p23 p24]
    %% [pn1 pn2 pn3 pn4]

    all_y = unique(ccpoints_data(:,4));

    for i = 1:size(all_y,1)
        y = all_y(i);
        indices = find_rows_in_matrix(y, ccpoints_data(:, 4));
        
        bucket_index = 
    end
end

%% 1. run bucketing
%%    bucket_index: [id_number] => [p1 p2 p3 p4] 
%%    bucket_ccp: [id_number] => [ccpoints_data v-idx1 || v-idx2]
%%    bucket_triangle: [id_number] => [triangle index]
%% 2. foreach bucket, check tangent normal for machinability
%%    
%% 3. build machinable flag
%%    bucket_index = [p1 p2 p3 p4 flag01]