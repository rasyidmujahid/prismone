%% play_point_simulatin: tool path simulation for point milling
%% returns
%%      point_tool_path: x1 y1 z1 ||  normal i j k
%%      flank_tool_path: x1 y1 z1 ||  normal i j k || cylinder origin || cylinder dest
function [point_tool_path, flank_tool_path] = play_toolpath_simulation(T, V, ccpoints_data, point_mill_ccp, tool_radius, ...
        tool_length, bucket_index, bucket_width, bucket_length)

    X = V(:, 1);
    Y = V(:, 2);
    Z = V(:, 3);
    elevation = -30;

    f = figure('Name', 'Point/Flank Toolpath', 'NumberTitle', 'off');
    trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
    axis equal;
    xlabel ( '--X axis--' );
    ylabel ( '--Y axis--' );
    zlabel ( '--Z axis--' );
    hold on;
    % surf2solid(T(:,1:3),V, 'Elevation', elevation); axis image; camlight; camlight 

    %% sort by Y then X
    point_mill_ccp = sortrows(point_mill_ccp, [4 3]);
    flank_mill_cpp = bucketize_ccp(bucket_index, ccpoints_data, bucket_width, bucket_length, 'machinable')

    %% point_mill_ccp
    %% || v-idx1 || v-idx2 || x1   y1   z1 || normal i j k || tangent i j k || 0 0 0 || feed_direction i j k

    %% flank_mill_cpp
    %% bucket_id || v-idx1 || v-idx2 || x1   y1   z1 || normal i j k || tangent i j k || x2 y2 z2 || feed_direction i j k || cylinder origin || cylinder dest || CL

    flank_tool_path = draw_tool_path(T, X, Y, Z, bucket_index, flank_mill_cpp, bucket_width, bucket_length, 'y', 'machinable');
    play_tool_simulation(flank_tool_path, tool_length, tool_radius);

    % point_tool_path = draw_tool_path(T, X, Y, Z, bucket_index, point_mill_ccp, bucket_width, bucket_length, 'r', 'non-machinable');
    % play_tool_simulation(point_tool_path, tool_length, tool_radius);
end

%% play_point_tool_simulation: play tool simulation
function play_tool_simulation(point_tool_path, tool_length, tool_radius)
    disp('play_tool_simulation...');

    cylinder_handle = [];
    cylinder_end_1 = [];
    cylinder_end_2 = [];

    cylinder_handle_arbor = [];
    cylinder_end_1_arbor = [];
    cylinder_end_2_arbor = [];

    arbor_radius = tool_radius + 5;
    arbor_length = tool_length;

    for i = 1:size(point_tool_path, 1)
        delete(cylinder_handle);
        delete(cylinder_end_1);
        delete(cylinder_end_2);

        delete(cylinder_handle_arbor);
        delete(cylinder_end_1_arbor);
        delete(cylinder_end_2_arbor);

        %% point milling matrix has 6 columns, otherwise flank
        if size(point_tool_path,2) == 6
            p1 = point_tool_path(i,1:3);
            p2 = point_tool_path(i,1:3) + tool_length * point_tool_path(i,4:6) / norm(point_tool_path(i,4:6));
            p3 = point_tool_path(i,1:3) + (tool_length + arbor_length) * point_tool_path(i,4:6) / norm(point_tool_path(i,4:6));
            color = 'y';
        else
            p1 = point_tool_path(i,7:9);
            p2 = point_tool_path(i,10:12);
            p3 = p2 + point_tool_path(i,4:6) * arbor_length;
            if point_tool_path(i,5) > 0
                color = 'y'; else color = 'm'; 
            end
        end
        
        [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, color, 1 ,0);
        [cylinder_handle_arbor cylinder_end_1_arbor cylinder_end_2_arbor] = Cylinder(p2, p3, arbor_radius, 20, color, 1 ,0);
        % pause(0.1);
        drawnow;
    end
end

%% tool_path: draw tool path
%% x1 y1 z1 ||  tool orientation i j k || cylinder origin || cylinder dest
function tool_path = draw_tool_path(T, X, Y, Z, bucket_index, source_mill_ccp, ...
        bucket_width, bucket_length, color, mode)

    disp('draw_tool_path...');
    lifting_height = 10;
    tool_path = []; %source_mill_ccp(:, 3:5);

    if strcmp(mode, 'machinable')
        %% select ccp, tangent vector, cylinder origin & dest center
        select_indices = [4:6,10:12,19:24];
    else
        %% select ccp and normal vector
        select_indices = 3:8;
    end

    for i = 1:size(source_mill_ccp, 1) - 1
        p1 = source_mill_ccp(i, select_indices);
        p2 = source_mill_ccp(i + 1, select_indices);
        tool_path = [tool_path; p1];

        if p1(2) ~= p2(2)
            %% lies at different y
            tool_path = [tool_path; [p1(1:2) p1(3) + lifting_height p1(4:end)]];
            tool_path = [tool_path; [p2(1:2) p2(3) + lifting_height p2(4:end)]];
        elseif abs(p1(1) - p2(1)) >= bucket_width - 0.5
            %% jump between x
            tool_path = [tool_path; [p1(1:2) p1(3) + lifting_height p1(4:end)]];
            tool_path = [tool_path; [p2(1:2) p2(3) + lifting_height p2(4:end)]];
        end
    end
    %% the last one
    tool_path = [tool_path; source_mill_ccp(end, select_indices)];

    % figure('Name', 'Point Milling Simulation', 'NumberTitle', 'off');
    % trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
    % axis equal;
    % xlabel ( '--X axis--' );
    % ylabel ( '--Y axis--' );
    % zlabel ( '--Z axis--' );
    % hold on;
    line(tool_path(:,1), tool_path(:,2), tool_path(:,3), 'Color', color, 'LineWidth', 2, 'LineStyle', '-');
end

%% bucket_ccp: put ccpoints into bucket
function bucket_ccp = bucketize_ccp(bucket_index, milling_ccpoints, bucket_width, bucket_length, mode)
    disp('bucketize_ccp...');
    bucket_ccp = [];

    if strcmp(mode, 'machinable')
        filtered_bucket_index = bucket_index(bucket_index(:,4) == 0, :);
    else
        filtered_bucket_index = bucket_index(bucket_index(:,4) > 0, :);
    end
    
    for i = 1:size(filtered_bucket_index,1)
        id_number = filtered_bucket_index(i,1);
        xj_1 = filtered_bucket_index(i,2);
        xj_2 = xj_1 + bucket_length;

        yi_1 = filtered_bucket_index(i,3);
        yi_2 = yi_1 + bucket_width;

        ccp_match_this_bucket = milling_ccpoints(milling_ccpoints(:,3) >= xj_1 & milling_ccpoints(:,3) < xj_2 & ... 
                                               milling_ccpoints(:,4) >= yi_1 & milling_ccpoints(:,4) < yi_2, :);

        if ~isempty(ccp_match_this_bucket)
            %% id_number || [ccpoints_data]
            ccp_match_this_bucket = horzcat(repmat(id_number, size(ccp_match_this_bucket,1), 1), ccp_match_this_bucket);
            bucket_ccp = [bucket_ccp; ccp_match_this_bucket];
        end
    end
end
