function A = read_stl_file ()

filename = 'parts/0_001stl_ugpart2asc.stl';
disp(filename);
fileExist = exist(filename);
if fileExist == 0,
    disp('File does not exist');
    filename = 'datar.stl';
end
file = fopen(filename,'r');

% min dan max ukuran stl
xMnMx = [1000 -1000];
yMnMx = [1000 -1000];
zMnMx = [1000 -1000];
i = 1;
j = 1;
count = 0;
arry = zeros(3);

while (1)
    line = fgetl(file);
    if ~ischar(line),
        break;
    end
    
    [a,b] = strtok(line, ' ');
     if strcmpi(a, 'facet')
        [c,d]= strtok(b, ' ');
        for k=4:6,
            [e,d] = strtok(d, ' ');
            invertex = inline(e);
            T(i,k) = invertex(1);
        end
        count = 1;
     elseif strcmpi(a, 'endsolid'),
        i = i - 1;
        j = j - 1;
     elseif strcmpi(a, 'endfacet')
        T(i,1) = arry(1);
        T(i,2) = arry(2);
        T(i,3) = arry(3);
        i= i + 1;
     elseif strcmpi(a, 'vertex')
        [a,b] = strtok(b, ' ');
        [b,c] = strtok(b, ' ');
        korvertex = inline(a);
        korvex(1) = korvertex(1);
        korvertex = inline(b);
        korvex(2) = korvertex(2);
        korvertex = inline(c);
        korvex(3) = korvertex(3);
        
        V(j,1) = 0;
        V(j,2) = 0;
        V(j,3) = 0;
                   
        index = 0;
        for kaka = 1:j,
            if (abs(V(kaka, 1) - korvex(1)) < 1e-4 && abs(korvex(2) - V(kaka ,2)) < 1e-4...
                    && abs(korvex(3) - V(kaka, 3)) < 1e-4)
                index = kaka;
                break;
            end
        end
        
        if index == 0, % masukkan ke vertex
            V(j,1) = korvex(1);
            V(j,2) = korvex(2);
            V(j,3) = korvex(3);
            % koordinat vertex belum normalisasi
            % disp([V(j,1) V(j,2) V(j,3)]);
            
            % Proses normalisasi koordinat
            deltaX = xMnMx(1) - 0;
            deltaY = yMnMx(1) - 0;
            deltaZ = zMnMx(1) - 0;
                        
            if xMnMx(1) > V(j,1),
                xMnMx(1) = V(j,1);
            end
            if xMnMx(2) < V(j,1),
                xMnMx(2) = V(j,1);
            end
            if yMnMx(1) > V(j,2),
                yMnMx(1) = V(j,2);
            end
            if yMnMx(2) < V(j,2),
                yMnMx(2) = V(j,2);
            end
            if zMnMx(1) > V(j,3),
                zMnMx(1) = V(j,3);
            end
            if zMnMx(2) < V(j,3),
                zMnMx(2) = V(j,3);
            end
            arry(count) = j;
        else
            arry(count) = index;
            j = j - 1;
        end
        j= j + 1;
        count = count + 1;
     else
         % disp([a, b]);
     end
end

fclose(file);

% xMnMx(1) = xMnMx(1) - deltaX;
% xMnMx(2) = xMnMx(2) - deltaX;
% yMnMx(1) = yMnMx(1) - deltaY;
% yMnMx(2) = yMnMx(2) - deltaY;
% zMnMx(1) = zMnMx(1) - deltaZ;
% zMnMx(2) = zMnMx(2) - deltaZ;

%Menampilkan nilai minimum dan maximum
%disp([xMnMx(1) xMnMx(2)]);
%disp([yMnMx(1) yMnMx(2)]);
%disp([zMnMx(1) zMnMx(2)]);

%Menampilkan jumlah index segitiga dan jumlah index vertex
%index segitiga = i;
%index vertex = j;
disp(['Total triangles and vertices : ', num2str([i, j])]);
for i = 1:i,
    %Menampilkan index vertek segitiga dari masing-masing index segitiga
    % i = index segitiga
    % T(i,1) T(i,2) T(i,3) = index vertex segitiga
%     disp([i T(i,1) T(i,2) T(i,3)]);
end

for ii = 1:j,
    V(ii,1) = V(ii,1) - deltaX;
    V(ii,2) = V(ii,2) - deltaY;
    V(ii,3) = V(ii,3) - deltaZ;
    %Menampilkan koordinat vertek dari masing-masing index vertex segitiga
    % ii = index vertex segitiga
    % V(ii,1) V(ii,2) V(ii,3) = koordinat vertex segitiga
    %disp([ii V(ii,1) V(ii,2) V(ii,3)]);
end

% find center of triangles
% loop over triangles, foreach triangle T
% foreach their vertices v
% calculate their avarages point
for i = 1:size(T,1)
    vid1 = T(i,1);  % first vertex ID
    vid2 = T(i,2);
    vid3 = T(i,3);
    centerX = ( V(vid1,1) + V(vid2,1) + V(vid3,1) ) / 3;
    centerY = ( V(vid1,2) + V(vid2,2) + V(vid3,2) ) / 3;
    centerZ = ( V(vid1,3) + V(vid2,3) + V(vid3,3) ) / 3;
    tricenter(i,:) = [centerX centerY centerZ];
end

X = V(:, 1);
Y = V(:, 2);
Z = V(:, 3);

% plotparts = plot3(X, Y, Z, '.', 'LineWidth', 2);
% set('plotparts');
% grid on;

h3 = trisurf ( T(:,1:3), X, Y, Z, 'FaceColor', 'Interp' );
  
axis equal;

xlabel ( '--X axis--' )
ylabel ( '--Y axis--' )
zlabel ( '--Z axis--' )

hold on;

% surfnorm( T(:,4), T(:,5), T(:,6) );

% plot normal vector along with triangle surface
quiver3( tricenter(:,1), tricenter(:,2), tricenter(:,3), T(:,4), T(:,5), T(:,6) );