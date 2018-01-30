%% save_nc_file: print local coordinate to global coordinate
function nc_data = save_nc_file(X, Y, Z, i, j, k, lx, ly, lz, lt, tilting_type, filename)
    if tilting_type == 'table'
        nc_data = table_tilting(X, Y, Z, i, j, k, lx, ly, lz, lt);
    elseif tilting_type == 'spindle'
        nc_data = spindle_tilting(X, Y, Z, i, j, k, lx, ly, lz, lt);
    elseif tilting_type == 'table_spindle'
        nc_data = table_spindle_tilting(X, Y, Z, i, j, k, lx, ly, lz, lt);
    else
        ME = MException('NCFileWriter:unrecognizeInput', ...
            'Tilting type is not recognized: table, spindle, table_spindle.');
        throw(ME); 
    end

    %% write to file [x y z i j k]
    fileID = fopen([filename, '.nc'], 'w');
    for i = 1:size(nc_data,1)
        nc_line = sprintf('X%+.3f Y%+.3f Z%+.3f I%+.3f J%+.3f K%+.3f', nc_data(i,:));
        nc_line = strrep(nc_line,'+0.000','0.0');
        fprintf(fileID, '%s\r\n', nc_line);
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
    nc_points = [];
    A = acos(kz);
    C = atan2(kx, ky);
    nc_points(:, 1) = (qx - lx) .* cos(C) - (qy - ly) .* sin(C) + lx;
    nc_points(:, 2) = (qx - lx) .* cos(A) .* sin(C) + (qy - ly) .* cos(A) .* cos(C) - (qz - lz) .* sin(A) + ly;
    nc_points(:, 3) = (qx - lx) .* sin(A) .* sin(C) + (qy - ly) .* sin(A) .* cos(C) + (qz - lz) .* cos(A) + lz;
    % [qx nc_points(:, 1) qy nc_points(:, 2) qz nc_points(:, 3)]
    nc_points(:, 4:6) = [kx, ky, kz];

end

%% table_tilting: generate nc points for table tilting
%% retuns [x y z i j k]
%% another reference
%%
%% A = arccos(kz)
%% C = arctan2(kx/sinA, ky/sinA)
%% x = qx cosC + qy sinC
%% y = qy cosA/cosC - x cosA sinC/cosC + (qz - Dz) sinA - Dy (1 - cosA)
%% z = (qz - y sinA - Dy sinA - Dz) / cosA + Dz
function nc_points = table_tilting_alt(qx, qy, qz, kx, ky, kz, lx, ly, lz, lt)
    nc_points = [];
    A = acos(kz);
    C = atan2(kx ./ sin(A), ky ./ sin(A));
    %% let Dz and Dy are 1
    Dz = 1;
    Dy = 1;
    x = qx .* cos(C) + qy .* sin(C);
    y = qy .* cos(A) ./ cos(C) - x .* cos(A) .* sin(C) ./ cos(C) + (qz - Dz) .* sin(A) - Dy .* (1 - cos(A));
    z = (qz - y .* sin(A) - Dy .* sin(A) - Dz) ./ cos(A) + Dz;

    nc_points(:, 1:6) = [x, y, z, kx, ky, kz];
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

