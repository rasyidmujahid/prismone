%% cellfind: find row item in a matrix
function found_idx = find_rows_in_matrix(item, matrix)
    found_idx = [];
    [flag, idx] = ismember(item, matrix, 'rows');
    %% since ismember only return the latest, loop back to the beginning
    while flag == 1
        found_idx = [found_idx idx];
        [flag, idx] = ismember(item, matrix(1:idx-1,:), 'rows');
    end
end