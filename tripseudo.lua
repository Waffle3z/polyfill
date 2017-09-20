function Clockwise(A, B, C) -- O(1)
	return (C.Z - A.Z) * (B.X - A.X) > (B.Z - A.Z) * (C.X - A.X)

function PointInPolygon(point) -- O(n); n = number of vertices in the whole polygon
	inside = false
	C = point
	for each vertex A in the polygon
		B = the next neighboring vertex
		if A.Z and B.Z are on opposite sides of C.Z -- ((A.Z > C.Z) ~= (B.Z > C.Z))
		 and (A.Z > B.Z) ~= Clockwise(A, B, C) then
			inside = not inside
	return inside
		
function SegmentsIntersect(A,B, C,D) -- O(1)
	return Clockwise(A, C, D) ~= Clockwise(B, C, D) and Clockwise(A, B, C) ~= Clockwise(A, B, D)
	
function PointInPolygonFromReference(A, B, EdgesSubset, ReferenceState) -- O(n); n = number of edges in EdgesSubset
	inside = ReferenceState
	PreviousEdge = the final element in EdgesSubset
	for each CurrentEdge e in EdgesSubset
		if SegmentsIntersect(A, B, vertices of CurrentEdge) then
			inside = not inside
		if PreviousEdge and CurrentEdge are not directly connected then -- (rare edge case)
			if SegmentsIntersect(A, B, vertices of CurrentEdge.PreviousNeighbor) then
				inside = not inside
		-- Edge case is relevant when EdgesSubset contains a list of edges that are not sequential,
		-- meaning when PreviousEdge is not the edge that comes immediately before CurrentEdge in the polygon.
		-- EdgesSubset is actually a list of vertices, and the next vertex is known. If the previous vertex
		-- is not one that neighbors CurrentEdge, though, then that edge is missing from EdgesSubset and needs to be checked.
	return inside

function SegmentIntersectsRectangle(P1, P2, x0, x1, z0, z1) -- O(1)
	MinX, MaxX, MinZ, MaxZ = bounding box of P1 and P2
	if MaxX > x1 then MaxX = x1
	if MinX < x0 then MinX = x0
	if MinX > MaxX then return false -- does not intersect
	dx = P2.X - P1.X
	if dx ~= 0 then
		a = (P2.Z - P1.Z)/dx
		b = P1.Z - a*P1.X
		MinZ = a*MinX + b
		MaxZ = a*MaxX + b
		if MinZ > MaxZ then swap MinZ and MaxZ
	if MaxZ > z1 then MaxZ = z1
	if MinZ < z0 then MinZ = z0
	if MinZ > MaxZ then return false -- does not intersect
	return true -- intersects
	
	
function EdgeIntersectsRectangle(edge, x0, x1, z0, z1) -- O(1)
	P1, P2 = vertices of edge
	return SegmentIntersectsRectangle(P1, P2, x0, x1, z0, z1)

function PolygonFill(points)
	MinX, MaxX, MinZ, MaxZ = bounding box of points
	RemainingList = {}
	EdgeList = {}
	CurrentPoint = points -- "points" is itself an element in the linked list
	repeat
		Position = CurrentPoint.Position -- coordinates
		add CurrentPoint to EdgeList
		add {Point = CurrentPoint, MarkedConcave = false, Index = #EdgeList} to RemainingList
		CurrentPoint.Index = #EdgeList
		if Position.X < MinX then MinX = Position.X
		if Position.X > MaxX then MaxX = Position.X
		if Position.Z < MinZ then MinZ = Position.Z
		if Position.Z > MaxZ then MazZ = Position.Z
		draw a segment of the border connecting CurrentPoint to its neighbor
		CurrentPoint = CurrentPoint.Next -- move on to the next point in the linked list
	until CurrentPoint == points -- stop after it loops around
	
	LongestEdge = max(MaxX-MinX, MaxZ-MinZ) -- longest edge of the bounding box
	SquareSize = 1 -- turn the bounding box into a square with dimensions that are a power of 2
	while SquareSize < LongestEdge do
		SquareSize = SquareSize * 2
	Origin = [(MaxX + MinX)*.5, (MaxZ + MinZ)*.5] -- Coordinates for the center of the bounding square
	
	QuadTree = {X = Origin.X, Z = Origin.Z, Size = SquareSize,
				Edges = EdgeList, Inside = PointInPolygon(Origin)}
	function Fragment(branch) -- O(#branch.Edges)
		X = branch.X
		Z = branch.Z
		Position = [X, Z]
		HalfSize = branch.Size*.5
		QuarterSize = HalfSize*.5
		InsideReference = branch.Inside
		Quad1, Quad2, Quad3, Quad4 = {}, {}, {}, {}
		for each edge in branch.Edges
			if EdgeIntersectsRectangle(edge, X, X+HalfSize, Z, Z+HalfSize) then Quad1[#Quad1+1] = edge
			if EdgeIntersectsRectangle(edge, X, X+HalfSize, Z-HalfSize, Z) then Quad2[#Quad2+1] = edge
			if EdgeIntersectsRectangle(edge, X-HalfSize, X, Z, Z+HalfSize) then Quad3[#Quad3+1] = edge
			if EdgeIntersectsRectangle(edge, X-HalfSize, X, Z-HalfSize, Z) then Quad4[#Quad4+1] = edge
		Inside1 = PointInPolygonFromReference(Position, [ QuarterSize, 0,  QuarterSize], Quad1, InsideReference)
		Inside2 = PointInPolygonFromReference(Position, [ QuarterSize, 0, -QuarterSize], Quad2, InsideReference)
		Inside3 = PointInPolygonFromReference(Position, [-QuarterSize, 0,  QuarterSize], Quad3, InsideReference)
		Inside4 = PointInPolygonFromReference(Position, [-QuarterSize, 0, -QuarterSize], Quad4, InsideReference)
		branch[1] = {X = X + QuarterSize, Z = Z + QuarterSize, Size = HalfSize, Edges = Quad1, Inside = Inside1}
		branch[2] = {X = X + QuarterSize, Z = Z - QuarterSize, Size = HalfSize, Edges = Quad2, Inside = Inside2}
		branch[3] = {X = X - QuarterSize, Z = Z + QuarterSize, Size = HalfSize, Edges = Quad3, Inside = Inside3}
		branch[4] = {X = X - QuarterSize, Z = Z - QuarterSize, Size = HalfSize, Edges = Quad4, Inside = Inside4}
		branch.Fragmented = true
	
	function GetCellFromPoint(px, pz, branch)
		-- quadtree fragment until the point is alone (or has one neighbor) in a cell
		branch = branch or tree
		bx, bz = branch.X, branch.Z
		if #branch.Edges <= 2 then
			return branch
		else
			if not branch.Fragmented then
				Fragment(branch) -- O(#branch.Edges)
			end
			quadrant = (px > bx) and (pz > bz and 1 or 2) or (pz > bz and 3 or 4)
			return GetCellFromPoint(px, pz, branch[quadrant])
	
	function PointInsideCheck(px, pz) -- O(n); n = total number of vertices
		cell = GetCellFromPoint(px, pz)
		cx, cz = cell.X, cell.Z
		return PointInPolygonFromReference([cx, cz], [px-cx, pz-cz], cell.Edges, cell.Inside) -- O(#branch.Edges)

	function GetCellsLineIntersects(A, B)
		cells = {}
		function Recurse(branch)
			X, Z, Size = branch.X, branch.Z, branch.Size*.5
			if SegmentIntersectsRectangle(A, B, X - Size, X + Size, Z - Size, Z + Size) then
				if branch.Fragmented then
					Recurse(branch[1])
					Recurse(branch[2])
					Recurse(branch[3])
					Recurse(branch[4])
				else
					add branch to cells
		recurse(QuadTree)
		return cells
	
	index = 1
	while #RemainingList >= 3 do
		ListLength = #RemainingList
		index = (index-1)%ListLength + 1 -- wrap around to first index if out of bounds
		while RemainingList[index].MarkedConcave do
			index = index%ListLength + 1 -- next index; wraps around to first
		A = RemainingList[index-1].Point
		B = RemainingList[index  ].Point
		C = RemainingList[index+1].Point
		x0, x1, z0, z1 = bounding box of triangle ABC
		Midpoint = (a + c)*.5 -- midpoint between A and C
		if PointInsideCheck(Midpoint.X, Midpoint.Z) then -- O(n)
			pass = true
			BorderCells = union of GetCellsLineIntersects(A, C) and GetCellsLineIntersects(A, B) and GetCellsLineIntersects(B, C)
			edges = set of edges contained within BorderCells
			for each edge in edges
				P1, P2 = vertices of edge
				if SegmentsIntersect(A, C, P1, P2) or SegmentsIntersect(A, B, P1, P2) or SegmentsIntersect(B, C, P1, P2) then
					-- triangle does not intersect the edge
					pass = false
					break
			if pass then
				draw a triangle between the points [A.X, A.Z], [B.X, B.Z], [C.X, C.Z]
				remove index from RemainingPoints
		if #RemainingPoints == ListLength then -- the current point was not removed; no triangle was drawn
			RemainingList[index].MarkedConcave = true -- mark the point as concave
		else
			RemainingList[index].MarkedConcave = false -- un-mark the neighboring points
			Remaininglist[index-1].MarkedConcave = false -- they might not be concave anymore
			index = index + 1 -- skips over the next current index

PolygonFill(linked list of vertices)