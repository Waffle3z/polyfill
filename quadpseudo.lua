function Clockwise(A, B, C) -- O(1)
	return (C.Z - A.Z) * (B.X - A.X) > (B.Z - A.Z) * (C.X - A.X)

function PointInPolygon(point) -- O(n); n = number of vertices
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

function PolygonFill(points)
	MinX, MinZ, MaxX, MaxZ; -- minimum and maximum coordinate values in points, representing a bounding box
	PointList = {}
	CurrentPoint = points -- "points" is itself an element in the linked list
	repeat
		Position = CurrentPoint.Position -- coordinates
		add CurrentPoint to PointList
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
	local function Fragment(Position, Size, InsideList, ReferencePosition, ReferenceInside) -- O(n*log4(SquareSize)) worst case
		-- Position - Position of the passed cell
		-- Size - Size of the passed cell
		-- InsideList - List of points inside that cell
		-- ReferencePosition - Position of a corner of that cell that has already
		--                     been evaluated for whether it is inside the polygon
		-- ReferenceInside - Whether the point at ReferencePosition is inside the polygon
		Center = Origin + Position
		CenterInside; -- whether the center of the cell is inside the polygon
		if ReferenceInside == nil -- only the case for the bounding square
			CenterInside = PointInPolygon(Center) -- O(n); n = total number of vertices; only runs once
		else
			CenterInside = PointInPolygonFromReference( -- average case: O(n/4^(SquareSize/Size)), n = total number of vertices
														-- runs at most 4^(SquareSize/Size) times for each level of recursion (each value of Size)
														-- total number of levels of fragmentation recursion = log4(SquareSize)
				Center,						-- Point A
				Origin + ReferencePosition, -- Point B
				InsideList,					-- Edges to check
				ReferenceInside				-- Reference state
			)
		if InsideList is empty or Size == 1 -- no more fragmentation to do
			if CenterInside then
				draw the square
			return
		if Size ~= 1 -- fragment the square
			Quadrant1 = {} -- four quadrants of the fragmented square
			Quadrant2 = {} -- each quadrant contains the corresponding subset of points
			Quadrant3 = {}
			Quadrant4 = {}
			for each point Point in InsideList
				Position1 = Point.Position
				Position2 = Point.Next.Position -- Point's next neighbor
				MinX, MaxX = Position1.X, Position2.X
				MinZ, MaxZ = Position1.Z, Position2.Z
				if MinX > MaxX then swap MinX and MaxX
				if MinZ > MaxZ then swap MinZ and MaxZ
				local function InsideCell(x0, x1, z0, z1) -- edge intersects cell
					local MinX, MaxX, MinZ, MaxZ = MinX, MaxX, MinZ, MaxZ
					-- re-define bounds locally
					if MaxX > x1 then MaxX = x1
					if MinX < x0 then MinX = x0
					if MinX > MaxX then return false
					dx = Position2.X - Position1.X
					if dx ~= 0 -- intersection calculation
						Slope = (Position2.Z - Position1.Z)/dx
						Offset = Position1.Z - Slope*Position1.X
						MinZ = Slope*MinX + Offset
						MaxZ = Slope*MaxX + Offset
					if MaxZ > z1 then MaxZ = z1
					if MinZ < z0 then MinZ = z0
					if MinZ > MaxZ then return false
					return true
				X = Center.X
				Z = Center.Z
				HalfSize = Size*.5
				if InsideCell(X, X + HalfSize, Z, Z + HalfSize)
					add Point to Quadrant1
				if InsideCell(X, X + HalfSize, Z - HalfSize, Z)
					add Point to Quadrant2
				if InsideCell(X - HalfSize, X, Z, Z + HalfSize)
					add Point to Quadrant3
				if InsideCell(x - HalfSize, X, Z - HalfSize, Z)
					add Point to Quadrant4
			HalfSize = Size*.5
			QuarterSize = HalfSize*.5
			Fragment(Position + [ QuarterSize,  QuarterSize], HalfSize, Quadrant1, Position, CenterInside)
			Fragment(Position + [ QuarterSize, -QuarterSize], HalfSize, Quadrant2, Position, CenterInside)
			Fragment(Position + [-QuarterSize,  QuarterSize], HalfSize, Quadrant3, Position, CenterInside)
			Fragment(Position + [-QuarterSize, -QuarterSize], HalfSize, Quadrant4, Position, CenterInside)
	Fragment([0, 0], SquareSize, InsideList, nil, nil)

PolygonFill(linked list of vertices)