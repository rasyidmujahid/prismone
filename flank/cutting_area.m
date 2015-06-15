%% cutting_area_by_scale: create cutting area formed by squared of 4 ccp.
%% return pairs of ccp
function ccp_pairs = cutting_area(cc_points)
	ccp_pairs = [];
	all_y_values = sort(unique(cc_points(:,2)));

	for i = 1:size(all_y_values)-1
		
		% %% rail start
		y1 = all_y_values(i);
		
		% %% rail end
		y2 = all_y_values(i+1);

		ccpoints_1 = cc_points_at_y(cc_points, y1);
		ccpoints_2 = cc_points_at_y(cc_points, y2);

		pairs = create_pairs(cc_points, ccpoints_1, ccpoints_2);

		ccp_pairs = [ccp_pairs; pairs];
	end
end

%% create_pairs: given two list of ccpoints, return pairs of each two of them
function pairs = create_pairs(all_ccp, ccpoints_1, ccpoints_2)

	%% IDX = knnsearch(X,Y) finds the nearest neighbor in X for each point in Y. 
	%% IDX is a column vector with my rows. Each row in IDX contains the index of 
	%% nearest neighbor in X for the corresponding row in Y.
	neighbor_index_in_ccp2 = knnsearch(ccpoints_2, ccpoints_1);

	neighbors_in_ccp2 = ccpoints_2(neighbor_index_in_ccp2, :);

	% [~, loc1] = ismember(ccpoints, ccpoints_1);
	% [~, loc2] = ismember(ccpoints, neighbors_in_ccp2);

	% %% only save ccp index
	% pairs = [loc1 loc2];

	pairs = [ccpoints_1 neighbors_in_ccp2];
end

%% cc_points_at_y: return all ccpoints have y = requested y
function ccpoints = cc_points_at_y(cc_points, y)
	ccpoints = cc_points(find(cc_points(:,2) == y),:);
end