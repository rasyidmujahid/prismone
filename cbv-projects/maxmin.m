function output = maxmin(vertices)
%% maxmin       find maximum and minimum coordinates
%%              from given vertices
%% returns:
%% [max_x max_y max_z;
%% min_x min_y min_z]

    output(1,:) = [max(vertices(:,1)) max(vertices(:,2)) max(vertices(:,3))];
    output(2,:) = [min(vertices(:,1)) min(vertices(:,2)) min(vertices(:,3))];
    
end
