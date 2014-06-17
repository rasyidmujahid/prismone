%% map_matrix   create map matrix, given arguments cell arrays of
%%              cc points, slicing line, triangle, normal, and
%%              triangle vertice
function outputs = map_matrix(intersections, points_cloud, vertices)
    outputs = zeros(size(points_cloud,1), size(points_cloud,2));
    for i = 1:size(outputs,1)
        for j = 1:size(outputs,2)
            sl = [points_cloud(i,j,1) points_cloud(i,j,2)];
            found_idx = cellfind(sl, cell2mat(intersections(:,2)));
            if ~isempty(found_idx)
                outputs(i,j) = length(found_idx);
            end
        end
    end
end

%% cellfind: find row item in a matrix
function found_idx = cellfind(item, matrix)
    found_idx = [];
    [flag, idx] = ismember(item, matrix, 'rows');
    while flag == 1
        found_idx = [found_idx idx];
        [flag, idx] = ismember(item, matrix(1:idx-1,:), 'rows');
    end
end
