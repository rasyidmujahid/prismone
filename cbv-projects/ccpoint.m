function ccpoints = ccpoint(triangles, vertices, density)
%% ccpoint  find cutter contact point (ccpoint)
%%          from given triangle structures and vertices,
%%          with density determines the distance among
%%          slicing lines (SL).

    max_min = maxmin(vertices);
    sl_points = points_cloud(max_min, density);
    
    X = sl_points(:,:,1);
    Y = sl_points(:,:,2);
    Z = sl_points(:,:,3);
    ccpoints = [X(:) Y(:) Z(:)];
end

function output = points_cloud(max_min, density)
%% points_cloud     populate all points cloud given max_min matrix 
%%                  maximum and minimum coordinates
    
    disp('Generating points cloud..');
    
    %% Iterating all slicing lines to cut through the part.
    %% Okay, now, generate all possible slicing lines (SL).
    %% An SL is expressed with (i,j) i in X and j in Y.
    min_y = max_min(2,2);
    max_y = max_min(1,2);
    min_x = max_min(2,1);
    max_x = max_min(1,1);
    min_z = max_min(2,3);
    max_z = max_min(1,3);
    
    Y = [min_y:density:max_y max_y];
    X = [min_x:density:max_x max_x];
    
    disp(X);
    disp(Y);
    
    output = zeros(length(Y), length(X), 3);
    
    for iy = 1:length(Y)
        for ix = 1:length(X)
            output(iy, ix, 1) = X(ix);
            output(iy, ix, 2) = Y(iy);
            output(iy, ix, 3) = 0;
        end
    end
end

function output = maxmin(vertices)
%% maxmin       find maximum and minimum coordinates
%%              from given vertices
    
    %% [max_x max_y max_z;
    %% min_x min_y min_z]
    output(1,:) = [max(vertices(:,1)) max(vertices(:,2)) max(vertices(:,3))];
    output(2,:) = [min(vertices(:,1)) min(vertices(:,2)) min(vertices(:,3))];
    disp(['max ', num2str(output(1,:)), ' min ', num2str(output(2,:))]);
end
