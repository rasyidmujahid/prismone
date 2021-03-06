%% ================================================
%% Toolpath simulation + gouging detection
%% ================================================

%% play_flank_simulation: tool path simulation
%% || v-idx1 || v-idx2 || x1   y1   z1 || normal i j k || tangent i j k || x2 y2 z2 || feed_direction i j k || cylinder origin || cylinder dest || CL
function result = play_flank_simulation(T, V, ccpoints_data, tool_radius, tool_length, ...
        is_simulation_enabled, is_gouging_avoidance_enabled)

    result = [];

    X = V(:, 1);
    Y = V(:, 2);
    Z = V(:, 3);
    elevation = -30;

    f = figure('Name', 'Flank Simulation', 'NumberTitle', 'off');
    trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'none' );
    axis equal;
    xlabel ( '--X axis--' );
    ylabel ( '--Y axis--' );
    zlabel ( '--Z axis--' );
    hold on;
    % surf2solid(T(:,1:3),V, 'Elevation', elevation); axis image; camlight; camlight;

    %% sort by Y then X
    ccpoints_data = sortrows(ccpoints_data, [4 3]);

    cylinder_handle = [];
    cylinder_end_1 = [];
    cylinder_end_2 = [];

    cylinder_handle_arbor = [];
    cylinder_end_1_arbor = [];
    cylinder_end_2_arbor = [];

    arbor_radius = tool_radius + 5;
    arbor_length = tool_length;

    CL = 0;

    for i = 1:size(ccpoints_data,1)-1

        % if ccpoints_data(i,4) < 60 || ccpoints_data(i,4) > 80
        %     continue;
        % end

        if is_simulation_enabled
            set(0,'CurrentFigure',f);
        end

        % line(ccpoints_data(i,[3 12]), ccpoints_data(i,[4 13]), ccpoints_data(i,[5 14]), 'Color','red','LineWidth',2,'LineStyle','-');

        % skip points reside under diffrent line y
        if ccpoints_data(i,4) ~= ccpoints_data(i+1,4)
            disp(['Skip swept area', mat2str(ccpoints_data(i,3:5)), ' with ', mat2str(ccpoints_data(i+1,3:5)), '.']);
            continue;
        end

        % remember: we do inverse tool orientation based on positive or negative slope. 
        % this to make sure that cylinder is built only with 2 lines having the same slope.
        d1 = ccpoints_data(i,4) < ccpoints_data(i,13);
        d2 = ccpoints_data(i+1,4) < ccpoints_data(i+1,13);

        % if xor(d1,d2)
        %     continue;
        % end

        %% ================================
        %% draw swept area
        %% ccpoints_data:
        %% || v-idx1 || v-idx2 || x1   y1   z1 || normal i j k || tangent i j k || x2 y2 z2 || feed_direction i j k
        %% ================================
        if is_simulation_enabled
            rx = [ccpoints_data(i,3) ccpoints_data(i+1,3) ccpoints_data(i+1,12) ccpoints_data(i,12)];
            ry = [ccpoints_data(i,4) ccpoints_data(i+1,4) ccpoints_data(i+1,13) ccpoints_data(i,13)];
            rz = [ccpoints_data(i,5) ccpoints_data(i+1,5) ccpoints_data(i+1,14) ccpoints_data(i,14)];

            tangent = cross(ccpoints_data(i+1,6:8), ccpoints_data(i+1,15:17));
            tangent = tangent / norm(tangent);
            if tangent ~= ccpoints_data(i+1,9:11)
                normal_ = ccpoints_data(i+1,9:11);
                c = 'green';
            else
                c = 'magenta';
            end
            patch(rx,ry,rz,c);
            
            f2 = [1 2 3 4];
            v2 = [rx' ry' rz'];
            col = [0; 6; 4];
            patch('Faces',f2,'Vertices',v2,'EdgeColor','blue','FaceColor','none','LineWidth',2);
        end

        %% ================================
        %% simulate cylinder of tool and arbor
        %% ================================
        
        p1 = ccpoints_data(i,3:5) + tool_radius * ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8));
        p2 = ccpoints_data(i,12:14) + tool_radius * ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8));
        p3 = p2 + ccpoints_data(i,9:11) * arbor_length;
        if ccpoints_data(i,7) > 0
            color = 'y'; else color = 'm';
        end
        [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, color, 1 ,0);
        [cylinder_handle_arbor cylinder_end_1_arbor cylinder_end_2_arbor] = Cylinder(p2, p3, arbor_radius, 20, color, 1 ,0);

        %% keep the center point as another ccp
        %% ccpoints_data:
        %% || v-idx1 || v-idx2 || x1   y1   z1 || normal i j k || tangent i j k || x2 y2 z2 || feed_direction i j k || p1 p1 p1 || p2 p2 p2
        ccpoints_data(i,18:20) = p1;
        ccpoints_data(i,21:23) = p2;

        if is_simulation_enabled
            drawnow;
        end

        tri = surf2patch(cylinder_handle, 'triangles');
        cylinder_tri = [tri.vertices(tri.faces(:,1),:) tri.vertices(tri.faces(:,2),:) tri.vertices(tri.faces(:,3),:)];
        working_part = [V(T(:,1),:) V(T(:,2),:) V(T(:,3),:)];
        trans1 = [0 0 0 1 0 0 0 1 0 0 0 1];
        trans2 = [0 0 0 1 0 0 0 1 0 0 0 1];
        CL = coldetect(cylinder_tri, working_part, trans1, trans2);

        %% TODO
        %% calculate CL for cylinder_handle_arbor to detect gouging by arbor

        %% if no gouging, clear cylinder, otherwise color based on tool's j to see tool switch
        if CL == 0
            delete(cylinder_handle);
            delete(cylinder_end_1);
            delete(cylinder_end_2);

            delete(cylinder_handle_arbor);
            delete(cylinder_end_1_arbor);
            delete(cylinder_end_2_arbor);
        else
            set(cylinder_handle, 'FaceColor', color);
            drawnow;
        end

        % ================================
        % gouging avoidance
        % ================================
        if is_gouging_avoidance_enabled
            iteration = 0;
            max_iteration = 3;
            tetha = 1;
            incremental_tetha = 1;
            r = [1]; %% working rotation matrix
            while (CL > 0) && (iteration < max_iteration)
                %% ccpoints_data:
                %% || v-idx1 || v-idx2 || x1   y1   z1 || normal i j k || tangent i j k || x2 y2 z2 || feed_direction i j k || cylinder origin || cylinder dest

                %% taking feed direction vector as rotation axis, and θ = incremental angle.
                feed_direction = ccpoints_data(i,15:17);
                
                %% rotation_matrix results 3x3 matrix
                rotation_matrix = vrrotvec2mat([feed_direction deg2rad(tetha)]);
                r = rotation_matrix;
                %% https://en.wikipedia.org/wiki/Transformation_matrix#Affine_transformations
                %% [r1 r2 r3 0]
                %% [r4 r5 r6 0]
                %% [r7 r8 r9 0]
                %% [0  0  0  1]

                %% TRANS parameters
                %% [ e4  e5  e6 e1]
                %% [ e7  e8  e9 e2]
                %% [e10 e11 e12 e3]
                %% [  0   0   0  1]
                %% adjust to trans1 = (e1, ..., e12)
                trans1 = [0 0 0 r(1,:) r(2,:) r(3,:)];
                CL = coldetect(cylinder_tri, working_part, trans1, trans2);

                tetha = tetha + incremental_tetha;
                iteration = iteration + 1;
            end

            %% print last tetha
            % tetha

            %% if gouging avoidance succeeded, mark cylinder as green
            if ~isempty(r)

                delete(cylinder_handle);
                delete(cylinder_end_1);
                delete(cylinder_end_2);

                %% new tangent orientation
                % r %% display 'r' rotation_matrix
                tool_orientation_before_gouging_avoidance = ccpoints_data(i,9:11);

                %% rotate tangent vector by rotation matrix r
                %% Ref. https://en.wikipedia.org/wiki/Rotation_matrix, the rule is following
                %% xy' = r*xy where xy is column vector.
                ccpoints_data(i,9:11) = (r * ccpoints_data(i,9:11)')';
                tool_orientation_after_vcollide = ccpoints_data(i,9:11);

                %% adjust points x2 y2 z2 following new tangent orientation
                ccpoints_data(i,12:14) = ccpoints_data(i,3:5) + tool_length / norm(ccpoints_data(i,9:11)) * ccpoints_data(i,9:11);

                %% also adjust normal vector orientation
                ccpoints_data(i,6:8) = (r * ccpoints_data(i,6:8)')';

                %% Redraw after free gouging trial
                p1 = ccpoints_data(i,3:5) + tool_radius * ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8));
                p2 = ccpoints_data(i,12:14) + tool_radius * ccpoints_data(i,6:8) / norm(ccpoints_data(i,6:8));
                if ccpoints_data(i,7) > 0
                    color = 'y'; else color = 'm'; end;
                [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, color, 1 ,0);

                ccpoints_data(i,18:20) = p1;
                ccpoints_data(i,21:23) = p2;

                %% if free gouging, mark cylinder as green, otherwise keep red
                if CL == 0
                    set(cylinder_handle, 'FaceColor', 'g');
                else
                    set(cylinder_handle, 'FaceColor', 'r');
                end
                drawnow;
            end
        end %% is_gouging_avoidance_enabled

        ccpoints_data(i,24) = CL;
    end %% for

    result = ccpoints_data;
end