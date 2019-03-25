%% find_non_machinable: find non-machinable area with bucketing 
%% params:
%%   bucket_width: set to step-over
%%   bucket_length: set to step-over
%%   ccpoints_data: || v-idx1 || v-idx2 || x   y   z || normal i j k || tangent i j k ||
%%   vertices
%%   triangles
function [bucket_index, bucket_ccp, bucket_triangle] = find_non_machinable(bucket_width, bucket_length, ccpoints_data, vertices, triangles)
    
    %% sort by Y then X
    ccpoints_data = sortrows(ccpoints_data, [4 3]);
    
    [bucket_index bucket_ccp bucket_triangle] = init_bucket(bucket_width, bucket_length, ccpoints_data, vertices, triangles);

    run_bucket(ccpoints_data, bucket_index, bucket_ccp, bucket_triangle);
end

%% run_bucket:
%% params:
%%   ccpoints_data: || v-idx1 || v-idx2 || x   y   z || normal i j k || tangent i j k ||
%%   bucket_index:
%%   bucket_ccp:
%%   bucket_triangle:
%% desc: put the result of machinability into bucket_index, in 0 or 1
function run_bucket(ccpoints_data, bucket_index, bucket_ccp, bucket_triangle)
    for i = 1:size(bucket_index, 1)
        id_number = bucket_index(i, 1);
        vertid_in_this_bucket = bucket_ccp(bucket_ccp(:,1) == id_number, :);
        [tf, loc] = ismember(vertid_in_this_bucket(:,2:3), ccpoints_data(:,1:2), 'rows');
        ccp_in_this_bucket = ccpoints_data(loc, :);

        %% decide
        
    end
end

%% init_bucket: create empty bucket with specified size
%% params:
%%  bucket_width
%%  bucket_length
%% returns:
%%   
function [bucket_index, bucket_ccp, bucket_triangle] = init_bucket(bucket_width, bucket_length, ccpoints_data, vertices, triangles)
    max_min = maxmin(vertices);
    bucket_index = [];
    bucket_ccp = [];
    bucket_triangle = []; 

    offset = 0;
    min_y = max_min(2,2) + offset;
    max_y = max_min(1,2) - offset;
    min_x = max_min(2,1) + offset;
    max_x = max_min(1,1) - offset;
    all_x = min_x:bucket_width:max_x;

    %% bucket index structure:
    %% [x1 y1]
    %% [x2 y1]
    %% ..
    %% [x1 y3]
    %% [xj yi]
    %% y1 >> x1---x2---x3-----
    %% y2 >> x1---x2---x3-----
    %% y3 >> x1---x2---x3-----
    %%
    %% bucket area is xj, xj + bucket_length, yi, yi + bucket_width

    %% y are sorted ascending
    all_y = unique(ccpoints_data(:,4));

    %% primary key
    id_number = 1;

    for i = 1:size(all_y, 1) - 1
        yi_1 = all_y(i);
        yi_2 = yi_1 + bucket_width;
        indices1 = find_rows_in_matrix(yi_1, ccpoints_data(:, 4));
        indices2 = find_rows_in_matrix(yi_2, ccpoints_data(:, 4));

        ccpoints_data_at_y1 = ccpoints_data(indices1, :);
        ccpoints_data_at_y2 = ccpoints_data(indices2, :);

        for j = 1:size(all_x, 2)
            xj_1 = all_x(j);
            xj_2 = xj_1 + bucket_length;

            bucket_index = [bucket_index; id_number xj_1 yi_1];

            %% bucket_ccp structure:
            %% 
            %% id_number | v-idx1 | v-idx2 |
            %%
            %%      find all cc points that fall between x1y1 and x2y1 inclusive
            %% and, find all cc points that fall between x1y2 and x2y2 inclusive
            %%
            ccp_match_this_bucket = [ccpoints_data_at_y1(ccpoints_data_at_y1(:,3) >= xj_1 & ccpoints_data_at_y1(:,3) <= xj_2, 1:2); 
                                     ccpoints_data_at_y2(ccpoints_data_at_y2(:,3) >= xj_1 & ccpoints_data_at_y2(:,3) <= xj_2, 1:2)];

            if ~isempty(ccp_match_this_bucket)
                ccp_match_this_bucket = horzcat(repmat(id_number, size(ccp_match_this_bucket,1), 1), ccp_match_this_bucket);
                bucket_ccp = [bucket_ccp; ccp_match_this_bucket];
            end

            %% bucket_triangle structure:
            %%
            %% id_number | tri_index
            %%
            %% find 
            %% 
            vert_match_this_bucket = vertices(vertices(:,1) >= xj_1 & vertices(:,1) <= xj_2 & ...
                                              vertices(:,2) >= yi_1 & vertices(:,2) <= yi_2, :);
            tri_match_this_bucket = unique([
                                            triangles(ismember(vertices(triangles(:,1),:), vert_match_this_bucket, 'rows'), :);
                                            triangles(ismember(vertices(triangles(:,2),:), vert_match_this_bucket, 'rows'), :);
                                            triangles(ismember(vertices(triangles(:,3),:), vert_match_this_bucket, 'rows'), :)
                                        ], 'rows');

            %% example:
            %% vert_match_this_bucket = V(V(:,1) >= 10 & V(:,1) <= 20 & V(:,2) >= 0 & V(:,2) <= 10, :);
            %% tri_match_this_bucket = T(ismember(V(T(:,1),:), vert_match_this_bucket, 'rows'), :)

            if ~isempty(tri_match_this_bucket)
                tri_match_this_bucket = horzcat(repmat(id_number, size(tri_match_this_bucket,1), 1), tri_match_this_bucket);
                bucket_triangle = [bucket_triangle; tri_match_this_bucket];
            end
            
            id_number = id_number + 1;
        end
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