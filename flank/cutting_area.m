%% cutting_area: create cutting area formed by squared of 4 vertices
%% return pairs of rail
function rail_pairs = cutting_area(ccp, scale)
	rail_pairs = [];
	all_y_values = sort(unique(ccp(:,2)));

	for i = 1:size(all_y_values)-1
		
		%% rail start
		y1 = all_y_values(i);
		rails1 = create_rails(ccp, y1, scale);
		
		%% rail end
		y2 = all_y_values(i+1);
		rails2 = create_rails(ccp, y2, scale);

		rail_pairs = [rail_pairs; rails1 rails2];
	end
end

%% create_rails: create rails
function rails = create_rails(ccp, y, scale)
	rails = [];

	ccp_at_y = ccp(find(ccp(:,2) == y),:);
	unit = size(ccp_at_y,1) / scale;

	for i = unit:unit:size(ccp_at_y,1)
		index = round(i);
		if index <= 0
			index = 1;
		end
		rails = [rails; ccp_at_y(index,:)];
	end
end


%% distance: calculate surface length given connected points.
function dist = surface_length(ccp_at_y)
	dist = 0;
	for i = 1:size(ccp_at_y,1) - 1
		dist_unit = pdist([ccp_at_y(i,:); ccp_at_y(i+1,:)]);
		dist = dist + dist_unit;
	end
end
