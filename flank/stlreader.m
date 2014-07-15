function [T,V] = stlreader(filename)

    % stlreader imports geometry from an STL file into MATLAB.
    %
    %    [T,V] = stlreader(FILENAME) returns the triangles T and vertices V separately,
    %            T(:,1:3) have vertex indices
    %            T(:,4:6) have face normal vector
    %            V vertices

    %filename = 'parts/0_001stl_ugpart2asc.stl';
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

    argsout = cell(1,2);
    argsout{1} = T;
    argsout{2} = V;

end