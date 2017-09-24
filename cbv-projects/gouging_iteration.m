%% function for toolpath simulation + gouging detection
function result = gouging_iteration(V, T, roughing_points, tool_length, tool_radius)
    X = V(:, 1);
    Y = V(:, 2);
    Z = V(:, 3);

    cylinder_handle = [];
    cylinder_end_1 = [];
    cylinder_end_2 = [];
    CL = 0;

    f = figure('Name', 'Simulation', 'NumberTitle', 'off');
    trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'Inter' );
    axis equal;
    xlabel ( '--X axis--' );
    ylabel ( '--Y axis--' );
    zlabel ( '--Z axis--' );
    hold on;
     
    for i = 1:size(roughing_points,1)

        %% skip if not cbv
        % if isequal(roughing_points(i,7:9), [0 0 100])
        %     continue;
        % end

        % if roughing_points(i,3) < 40
        %    continue;
        % end

        set(0,'CurrentFigure',f);
        
        %% build endpoints for cylinder
        if isequal(roughing_points(i,7:9), [0 0 100])
            p1 = roughing_points(i,1:3);
            p2 = roughing_points(i,1:3) + tool_length * roughing_points(i,7:9) / norm(roughing_points(i,7:9));
        else
            p1 = roughing_points(i,4:6);
            p2 = roughing_points(i,4:6) + tool_length * roughing_points(i,7:9) / norm(roughing_points(i,7:9));
        end
        
        [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, 'y', 1 ,0);
        drawnow;

        %% gouging detection with v-collide
        %% use this transformation matrix, means no transformation at all
        % [1 0 0 0]
        % [0 1 0 0]
        % [0 0 1 0]
        % [0 0 0 1]
        % [ e4  e5  e6 e1]
        % [ e7  e8  e9 e2]
        % [e10 e11 e12 e3]
        % [  0   0   0  1]
        tri = surf2patch(cylinder_handle, 'triangles');
        cylinder_tri = [tri.vertices(tri.faces(:,1),:) tri.vertices(tri.faces(:,2),:) tri.vertices(tri.faces(:,3),:)];
        working_part = [V(T(:,1),:) V(T(:,2),:) V(T(:,3),:)];
        trans1 = [0 0 0 1 0 0 0 1 0 0 0 1];
        trans2 = [0 0 0 1 0 0 0 1 0 0 0 1];
        CL = coldetect(cylinder_tri, working_part, trans1, trans2);

        %% ================================================
        %% Gouging avoidance
        %% ================================================
        iteration = 0;
        max_iteration = 90;

        tetha = 3; %% in degree
        incremental_tetha = 3;
        r = []; %% working rotation matrix
        max_tetha = 30; 

        translate_to = 1;
        translate_step = 2;
        trx = []; %% working translation matrix

        %% rotation direction follows tool orientation
        if roughing_points(i,7:9) == [0 0 100]
            %% do nothing
            rotation_axis = [0 0 0];
        elseif roughing_points(i,7) == 0 % if i = 0, then rotate by X-axis
            rotation_axis = [1 0 0];
        elseif roughing_points(i,8) == 0 % if j = 0, then rotate by Y-axis
            rotation_axis = [0 1 0];
        end

        %% save initial tool orientation
        original_tool_orientation = roughing_points(i,7:9);
            
        while (CL > 0) && (iteration < max_iteration) % && (tetha < max_tetha)

            if rotation_axis == [0 0 0]
                break;
            end

            %% TRANS parameters
            %% [ e4  e5  e6 e1]
            %% [ e7  e8  e9 e2]
            %% [e10 e11 e12 e3]
            %% [  0   0   0  1]

            %% https://en.wikipedia.org/wiki/Transformation_matrix#Affine_transformations
            %% rotation matrix
            %% [r1 r2 r3 0]
            %% [r4 r5 r6 0]
            %% [r7 r8 r9 0]
            %% [0  0  0  1]
            % always taking rx=[0 1 0] as rotation axis
            % rotation_axis = [0 1 0];
            rotation_matrix = vrrotvec2mat([rotation_axis deg2rad(tetha)]);
            r = rotation_matrix;

            %% adjust to trans1 = (e1, ..., e12)
            % trans1 = [
            %     0 0 0 r(1,:) r(2,:) r(3,:)
            %     trx 1 0 0 0 1 0 0 0 1
            % ];

            %% workaround: trans param doesnt work, do our own rotate then coldetect.
            %% ==============================================================
            delete(cylinder_handle);
            delete(cylinder_end_1);
            delete(cylinder_end_2);

            roughing_points(i,7:9) = (r * roughing_points(i,7:9)')';

            %% redraw cylinder after free gouging trial
            p1 = roughing_points(i,4:6);
            p2 = roughing_points(i,4:6) + tool_length * roughing_points(i,7:9) / norm(roughing_points(i,7:9));

            [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, 'y', 1 ,0);
            tri = surf2patch(cylinder_handle, 'triangles');
            cylinder_tri = [tri.vertices(tri.faces(:,1),:) tri.vertices(tri.faces(:,2),:) tri.vertices(tri.faces(:,3),:)];
            working_part = [V(T(:,1),:) V(T(:,2),:) V(T(:,3),:)];
            %% ==============================================================

            % CL = coldetect(cylinder_tri, working_part, trans1, repmat(trans2,2,1))
            CL = coldetect(cylinder_tri, working_part, trans1, trans2);

            tetha = tetha + incremental_tetha;
            % translate_to = translate_to + translate_step

            if tetha >= max_tetha

                %% set back to initial theta
                tetha = 3;
                roughing_points(i,7:9) = original_tool_orientation;

                %% translation matrix, move by translate_step
                %% [tx ty tz]
                %% tx = translate_to; ty = tz = 0;
                %% 
                %% [1 0 0 tx]
                %% [0 1 0 ty]
                %% [0 0 1 tz]
                %% [0 0 0 1 ]
                if rotation_axis == [0 1 0]
                    if roughing_points(i,7) > 0
                        trx = [translate_step 0 0];
                    else
                        trx = [-translate_step 0 0];
                    end
                elseif rotation_axis == [1 0 0]
                    if roughing_points(i,8) > 0
                        trx = [0 translate_step 0];
                    else
                        trx = [0 -translate_step 0];
                    end
                end
                roughing_points(i,4:6) = roughing_points(i,4:6) + trx;            
            end

            iteration = iteration + 1;
        end

        % mark gouging, left the cylinder drawn
        if CL == 0
            % delete(cylinder_handle);
            % delete(cylinder_end_1);
            % delete(cylinder_end_2);
            set(cylinder_handle, 'FaceColor', 'g');
        else
            set(cylinder_handle, 'FaceColor', 'r');
            drawnow;
        end

        %% unmark following block if not using workaround part
        % if ~isempty(r)

        %     delete(cylinder_handle);
        %     delete(cylinder_end_1);
        %     delete(cylinder_end_2);
            
        %     %% new tool orientation
        %     %% rotate tangent vector by rotation matrix r
        %     %% Ref. https://en.wikipedia.org/wiki/Rotation_matrix, the rule is following
        %     %% [xy'] = [r]*[xy] where [xy] is column vector.
        %     roughing_points(i,7:9) = (r * roughing_points(i,7:9)')';
        %     roughing_points(i,4:6) = roughing_points(i,4:6) + trx;

        %     %% redraw cylinder after free gouging trial
        %     p1 = roughing_points(i,4:6);
        %     p2 = roughing_points(i,4:6) + tool_length * roughing_points(i,7:9) / norm(roughing_points(i,7:9));

        %     [cylinder_handle cylinder_end_1 cylinder_end_2] = Cylinder(p1, p2, tool_radius, 20, 'y', 1 ,0);

        %     %% if free gouging, mark cylinder as green, otherwise keep red
        %     if CL == 0
        %         set(cylinder_handle, 'FaceColor', 'g');
        %     else
        %         set(cylinder_handle, 'FaceColor', 'r');
        %     end
        %     drawnow;
        % end
    end
end