%% save_nc_file: print local coordinate to global coordiante
%% 
function output = save_nc_file(X, Y, Z, i, j, k, lx, ly, lz, lt, tilting_type, filename)
    if tilting_type == 'table'
        output = table_tilting(X, Y, Z, i, j, k, lx, ly, lz, lt);
    elseif tilting_type == 'spindle'
        output = spindle_tilting(X, Y, Z, i, j, k, lx, ly, lz, lt);
    elseif tilting_type == 'table_spindle'
        output = table_spindle_tilting(X, Y, Z, i, j, k, lx, ly, lz, lt);
    else
        ME = MException('NCFileWriter:unrecognizeInput', ...
            'Tilting type is not recognized: table, spindle, table_spindle.');
        throw(ME); 
    end

    output = sortrows(output, [2 1]);

    %% write to file [x y z i j k]
    fileID = fopen([filename, '.nc'], 'w');
    for i = 1:size(output,1)
        fprintf(fileID, 'X%f Y%f Z%f I%f J%f K%f\r\n', output(i,:));
    end
    fclose(fileID);
end

%% table_tilting: generate nc points for table tilting
%% retuns [x y z i j k]
%% 
%% A = arccos(kz)
%% C = arctan2(kx, ky)
%% x = (qx - lx) cos C - (qy -ly) sin C + lx
%% y = (qx - lx) cos A sin C + (qy - ly) cos A cos C - (qz - lz) sin A + ly
%% z = (qx - lx) sin A sin C + (qy - ly) sin A cos C + (qz - lz) cos A + lz
function nc_points = table_tilting(qx, qy, qz, kx, ky, kz, lx, ly, lz, lt)
    A = acos(kz);
    C = atan2(kx, ky);
    nc_points(:, 1) = (qx - lx) .* cos(A) - (qy - ly) .* sin(C) + lx;
    nc_points(:, 2) = (qx - lx) .* cos(A) .* sin(C) + (qy - ly) .* cos(A) .* cos(C) - (qz - lz) .* sin(A) + ly;
    nc_points(:, 3) = (qx - lx) .* sin(A) .* sin(C) + (qy - ly) .* sin(A) .* cos(C) + (qz - lz) .* cos(A) + lz;
    % [qx nc_points(:, 1) qy nc_points(:, 2) qz nc_points(:, 3)]
    nc_points(:, 4:6) = [kx, ky, kz];
end

%% table_tilting: generate nc points for spindle tilting
%% retuns [x y z i j k]
%%
%%
function [nc_points] = spindle_tilting(qx, qy, qz, kx, ky, kz, lx, ly, lz, lt)
    nc_points = [];
end

%% table_tilting: generate nc points for table & spindle tilting
%% retuns [x y z i j k]
%%
%%
function [nc_points] = table_spindle_tilting(qx, qy, qz, kx, ky, kz, lx, ly, lz, lt)
    nc_points = [];
end

