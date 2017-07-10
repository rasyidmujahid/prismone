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
    fprintf(fileID, '%s', header());
    for i = 1:size(nc_data,1)
        nc_line = sprintf('X%+.3f Y%+.3f Z%+.3f I%+.3f J%+.3f K%+.3f', nc_data(i,:));
        nc_line = strrep(nc_line,'+0.000','0.0');
        fprintf(fileID, '%s\r\n', nc_line);
    end
    fprintf(fileID, '%s', footer());
    fclose(fileID);
end

%% functionname: function description
function outputs = header()
    header = {  '%'
                'O0010'
                '(DATE :  20.1.2018)'
                '(TIME :  16:42:40)'
                'G00 G17 G21 G40 G80 G90'
                'G90 G54 G80 G17 G40 G69'
                'G91 G28 Z0'
                'G91 G28 X0 Y0'
                'M13'
                'M33'
                'M31'
                'G90 G54 G00 A0 C0'
                'T1 M06 ( DIA_4: D= 4. R= 0.0)'
                'S2000 M03'
                'G05.2 Q1.'
                'G05.3 P50 '
                '(5X PRODUCTION-PRO #9)'
                '(>>>>>>>>> CON_SCENARIO=TOOL-CHANGE - CON_CONTEXT=1)'
                'G01 X-10.031 Y-16.187 I0.0 J0.0 K+1. F5000.'
                'M09'
                '(----------> EOC START)'
                'M12'
                'M32'
                'X-10.031 Y-16.187'
                'G43 H1 Z150.'
                '(----------> EOC END)'
                'G01 Z4.062 I0.0 J0.0 K+1. F5000.'
            };
    outputs = sprintf('%s\n', header{:});
end

%% functionname: function description
function outputs = footer()
    footer = {
                'Z5.462 I0.0 J0.0 K+1.'
                'Z15.462 I0.0 J0.0 K+1. F5000.'
                'Z150. I0.0 J0.0 K+1.'
                'M129'
                'M140'
                'M09'
                'M05'
                'G91 G28 Z0'
                'G91 G28 X0 Y0'
                'M13'
                'M33'
                'M31'
                'G90 G54 G00 A0 C0'
                'M30'
                '(FEED TIME  :  00:02:21)'
                '(AIR TIME   :  00:00:21)'
                '(TOTAL TIME :  00:02:41)'
                '% '
            };
    outputs = sprintf('%s\n', footer{:});
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

