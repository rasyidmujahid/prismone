%% play_point_simulatin: tool path simulation for point milling
function play_point_simulation(T, V, ccpoints_data, point_mill_ccp, tool_radius, tool_length, bucket_index, bucket_width, bucket_length)

    X = V(:, 1);
    Y = V(:, 2);
    Z = V(:, 3);

    f = figure('Name', 'Point Milling Simulation', 'NumberTitle', 'off');
    trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
    axis equal;
    xlabel ( '--X axis--' );
    ylabel ( '--Y axis--' );
    zlabel ( '--Z axis--' );
    hold on;
    % surf2solid(T(:,1:3),V, 'Elevation', elevation); axis image; camlight; camlight 

    draw_tool_path(bucket_index, point_mill_ccp, bucket_width, bucket_length);

    %% sort by Y then X
    point_mill_ccp = sortrows(point_mill_ccp, [4 3]);

    cylinder_handle = [];
    cylinder_end_1 = [];
    cylinder_end_2 = [];

    for i = 1:size(point_mill_ccp, 1)
        delete(cylinder_handle);
        delete(cylinder_end_1);
        delete(cylinder_end_2);

        p1 = point_mill_ccp(i,3:5);
        p2 = point_mill_ccp(i,3:5) + tool_length * point_mill_ccp(i,6:8) / norm(point_mill_ccp(i,6:8));
        [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, 'y', 1 ,0);
        drawnow;
    end
end

%% tool_path: draw tool path
function draw_tool_path(bucket_index, point_mill_ccp, bucket_width, bucket_length)
    tool_path = [];
    bucket_ccp = bucket_ccp(bucket_index, point_mill_ccp, bucket_width, bucket_length);
    
    last_bucket_id = bucket_ccp(1, 1);
    ccp_match_in_bucket = bucket_ccp(1, 2:7);
    tool_path = [tool_path; ccp_match_in_bucket];

    for i = 2:size(bucket_ccp,1)
        current_bucket_id = bucket_ccp(i, 1);
        ccp_match_in_bucket = bucket_ccp(i, 2:7);

        
    end

    figure('Name', 'Tool Path', 'NumberTitle', 'off');
    trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
    axis equal;
    xlabel ( '--X axis--' );
    ylabel ( '--Y axis--' );
    zlabel ( '--Z axis--' );
    hold on;
    line(point_mill_ccp(:,3), point_mill_ccp(:,4), point_mill_ccp(:,5), 'Color', 'r', 'LineWidth', 2, 'LineStyle', '-');
end

%% bucket_ccp: put point_mill_ccp into bucket
function bucket_ccp = bucket_ccp(bucket_index, point_mill_ccp, bucket_width, bucket_length)
    bucket_ccp = [];
    bucket_index_not_machinable = bucket_index(bucket_index(:,4) > 0, :);

    for i = 1:size(bucket_index_not_machinable,1)
        id_number = bucket_index_not_machinable(i,1);
        xj_1 = bucket_index_not_machinable(i,2)
        xj_2 = xj_1 + bucket_length;

        yi_1 = bucket_index_not_machinable(i,3);
        yi_2 = yi_1 + bucket_width;

        ccp_match_this_bucket = [point_mill_ccp(point_mill_ccp(:,3) >= xj_1 & point_mill_ccp(:,3) <= xj_2, 3:8); 
                                 point_mill_ccp(point_mill_ccp(:,3) >= xj_1 & point_mill_ccp(:,3) <= xj_2, 3:8)];

        if ~isempty(ccp_match_this_bucket)
            ccp_match_this_bucket = horzcat(repmat(id_number, size(ccp_match_this_bucket,1), 1), ccp_match_this_bucket);
            bucket_ccp = [bucket_ccp; ccp_match_this_bucket];
        end
    end
end