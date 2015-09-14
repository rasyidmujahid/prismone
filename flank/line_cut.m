%% line_cut: give tangen normal and tool length, return all line cuts
function extended_tangen_normal = line_cut(ccpoints_data, tool_length, triangles, vertices)
	extended_tangen_normal = zeros(size(ccpoints_data,1), 3);
	for i = 1:size(extended_tangen_normal ,1)
		extended_tangen_normal(i,:) = tool_length / norm(ccpoints_data(i,9:11)) * ccpoints_data(i,9:11);
	end
	vertex1 = vertices(triangles(:,1),:);
	vertex2 = vertices(triangles(:,2),:);
	vertex3 = vertices(triangles(:,3),:);

	disp(['size vertices ', num2str(size(vertex1))]);
	disp(['size triangles ', num2str(size(triangles))]);
	disp(['size ccpoints_data(:,3:5) ', num2str(size(ccpoints_data(:,3:5)))]);
	disp(['size extended_tangen_normal ', num2str(size(extended_tangen_normal))]);
	
	page_size = size(extended_tangen_normal, 1);
	from = 1;
	to = from + page_size - 1;

	while to <= size(vertex1,1)
		[intersect, t, u, v, xcoor] = TriangleRayIntersection(ccpoints_data(:,3:5), extended_tangen_normal, ...
			vertex1(from:to,:), vertex2(from:to,:), vertex3(from:to,:), ...
			'lineType', 'segment');
		from = to + 1;
		to = from + page_size - 1;
	end

	% last page
	if to > size(vertex1,1) && size(vertex1,1) > size(extended_tangen_normal,1)
		from = from - (to - size(vertex1,1));
		to = to - (to - size(vertex1,1));

		[intersect, t, u, v, xcoor] = TriangleRayIntersection(ccpoints_data(:,3:5), extended_tangen_normal, ...
			vertex1(from:to,:), vertex2(from:to,:), vertex3(from:to,:), ...
			'lineType', 'segment');
	end
end