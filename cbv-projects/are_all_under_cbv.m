%% are_all_under_cbv: check if these points are all under cbv
%% arguments:   @sorted_points points sorted from min to max
%%              @boundary_points
%% returns:     boolean true if all these @sorted_points are under cbv, false otherwise
function under_cbv = are_all_under_cbv(sorted_points, boundary_points)
    %% check min max points only to consider

    % under_cbv = is_under_cbv(sorted_points(1,:), boundary_points) & ...
    %     is_under_cbv(sorted_points(end,:), boundary_points);

    %% TODO: cant check only min and max, since if doubled cbv, 
    %% this function will return true, while should be false.
    %% DONE.

    under_cbv = true;
    for i = 1:size(sorted_points,1)
        under_cbv = under_cbv && is_under_cbv(sorted_points(i,:), boundary_points);
        if ~under_cbv
            break;
        end
    end
end