%% map_matrix   create map matrix, given arguments cell arrays of
%%              |cc points|slicing line|triangle|normal|
%%              and points_cloud
function outputs = map_matrix(intersections, points_cloud)
    outputs = zeros(size(points_cloud,1), size(points_cloud,2));
    for i = 1:size(outputs,1)
        for j = 1:size(outputs,2)
            sl = [points_cloud(i,j,1) points_cloud(i,j,2)];
            found_idx = find_rows_in_matrix(sl, cell2mat(intersections(:,2)));
            if ~isempty(found_idx)
                outputs(i,j) = length(found_idx);
            end
        end
    end
end