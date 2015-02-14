classdef Util
	methods (Static)
		%% returns max and min vertex of vertices
		function m = minmax(vertices)
			m = [min(vertices); max(vertices)];
		end
	end
end