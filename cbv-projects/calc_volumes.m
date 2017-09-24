%% function calc_volumes: to draw and calculate cbv & obv volumes
function [outputs] = calc_valumes(V, T, roughing_points, tool_length, vertical_stepover)
    X = V(:, 1);
    Y = V(:, 2);
    Z = V(:, 3);
    max_min = maxmin(V);

    all_z = unique(roughing_points(:,3));
    all_y = unique(roughing_points(:,2));

    total_cutting_cbv_volume = 0;

    figure('Name', 'CBV Cut', 'NumberTitle', 'off');
    trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
    axis equal;
    xlabel ( '--X axis--' );
    ylabel ( '--Y axis--' );
    zlabel ( '--Z axis--' );
    hold on;

    % drawn = false;

    for i = 1:size(all_z,1)
        z = all_z(i);
        indices = find_rows_in_matrix(z, roughing_points(:,3));

        roughing_points_at_this_z = roughing_points(indices,:);
        cbv_points_at_this_z = [];
        for j = 1:size(roughing_points_at_this_z,1)
            if (~isequal(roughing_points_at_this_z(j,7:9), [0 0 100]))
                %% find all cbv points at this z : roughing points that its orientation is not skewed
                cbv_points_at_this_z = [cbv_points_at_this_z; roughing_points_at_this_z(j,:)];
            end 
        end
        
        if (isempty(cbv_points_at_this_z))
            continue;
        end

        for j = 1:size(all_y,1)
            y = all_y(j);
            indices = find_rows_in_matrix(y, cbv_points_at_this_z(:,2));

            if (isempty(indices))
                % disp(['y: ', num2str(y)]);
                % disp(['z: ', num2str(z)]);
                continue;
            end

            %% add a new point where the tool-handle comes from
            last_index = indices(end);
            last_cbv_point_at_this_z_y = cbv_points_at_this_z(last_index,:);
            tool_handle_origin_point = last_cbv_point_at_this_z_y(:,4:6) + ...
                tool_length * last_cbv_point_at_this_z_y(:,7:9) / norm(last_cbv_point_at_this_z_y(:,7:9));
            cbv_points_at_this_z = [cbv_points_at_this_z; [0 0 0 tool_handle_origin_point -last_cbv_point_at_this_z_y(:,7:9)]];

            %% update last_cbv_point_at_this_z_y to follow tool_handle_origin_point(x,y)
            last_cbv_point_at_this_z_y(:,4:5) = tool_handle_origin_point(:,1:2);
            cbv_points_at_this_z = [cbv_points_at_this_z; [0 0 0 last_cbv_point_at_this_z_y(:,4:6) 0 0 1]];

            %% =================================================
            %% calculate cut cbv volume
            %% TODO: if two-sided cbv
            %% =================================================
            if (j == 1)
                first_index = indices(1);
                first_cbv_point_at_this_z_y = cbv_points_at_this_z(first_index,4:6);
                last_cbv_point_at_this_z_y = last_cbv_point_at_this_z_y(:,4:6);
                
                u = first_cbv_point_at_this_z_y - tool_handle_origin_point;
                v = last_cbv_point_at_this_z_y - tool_handle_origin_point;

                %% find angle between 2 vector (in radian)
                angle = atan2(norm(cross(u,v)),dot(u,v));
                angle_degree = angle / pi * 180;
                
                %% cylinder part volume I = angle/2π * area * heigth
                cbv_part_volume = angle / (2 * pi) * (pi * tool_length ^ 2) * (max_min(1,2) - max_min(2,2));

                %% cylinder part volume II = angle/2π * area * (tool length - stepover)
                intersected_cbv_volume = angle / (2 * pi) * (pi * (tool_length - vertical_stepover) ^ 2) * (max_min(1,2) - max_min(2,2));

                %% get actual volume, without intersection
                cbv_part_volume = cbv_part_volume - intersected_cbv_volume;
                total_cutting_cbv_volume = total_cutting_cbv_volume + cbv_part_volume;
            end
        end

        % if (drawn) 
        %     continue;
        % end

        %% if two-sided cbv, separated by y = c line, pick random y = middle one
        y = (max_min(1,2) - max_min(2,2)) / 2;
        cbv_points_before_y = cbv_points_at_this_z(find(cbv_points_at_this_z(:,5) < y),:);
        cbv_points_after_y = cbv_points_at_this_z(find(cbv_points_at_this_z(:,5) >= y),:);

        % dt = DelaunayTri(cbv_points_at_this_z(:,4), cbv_points_at_this_z(:,5), cbv_points_at_this_z(:,6));
        % tri = dt(:,:);

        %% before x
        dt = DelaunayTri(cbv_points_before_y(:,4), cbv_points_before_y(:,5), cbv_points_before_y(:,6));
        tri = dt(:,:);

        if isempty(tri)
            continue;
        end

        trisurf(tri, cbv_points_before_y(:,4), cbv_points_before_y(:,5), cbv_points_before_y(:,6));

        %% after x
        dt = DelaunayTri(cbv_points_after_y(:,4), cbv_points_after_y(:,5), cbv_points_after_y(:,6));
        tri = dt(:,:);

        if isempty(tri)
            continue;
        end

        trisurf(tri, cbv_points_after_y(:,4), cbv_points_after_y(:,5), cbv_points_after_y(:,6));

        % cbv_part_volume__ = stlVolume(cbv_points_at_this_z(:,4:6)', tri')

        % drawn = true;
    end

    total_cutting_cbv_volume;

end