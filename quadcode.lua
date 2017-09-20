local function inpolygon(point, set) -- 'point' is inside polygon 'set'
	local current, inside = set, false
	local C = point
	local cx, cz = C.X, C.Z
	repeat
		local A, B = current[1], current[2][1]
		local ax, az, bx, bz = A.X, A.Z, B.X, B.Z
		if ((az > cz) ~= (bz > cz)) and -- A and B are on different sides of point
		   ((cx-ax) < (bx-ax)*(cz-az)/(bz-az)) then
		--if ((az > cz) ~= (bz > cz)) and
		--   ((az > bz) ~= ((cz-az)*(bx-ax) > (bz-az)*(cx-ax))) then
			inside = not inside
		end
		--[[local ac = az > cz
		if ac ~= (bz > cz) and ac ~= ((cz-az)*(bx-ax) > (bz-az)*(cx-ax)) then
			inside = not inside
		end]]
		current = current[2]
	until current == set
	return inside
end

function cw(A, B, C) -- points A, B, C are clockwise in order
	return (C.Z-A.Z)*(B.X-A.X) > (B.Z-A.Z)*(C.X-A.X)
end
function intersect(A,B,C,D) -- line segments AB and CD intersect
	return cw(A,C,D) ~= cw(B,C,D) and cw(A,B,C) ~= cw(A,B,D)
end

local function getside(A, B, edges, inside)
	for i = 1, #edges do
		local e = edges[i]
		local C = e[1]
		if (edges[i-1] or edges[#edges]) ~= e[0] then
			if intersect(A, B, C, e[0][1]) then
				inside = not inside
			end
		end
		if intersect(A, B, C, e[2][1]) then
			inside = not inside
		end
	end
	return inside
end

local wasted = 0
local function render(set)
	local minx, minz =  math.huge,  math.huge
	local maxx, maxz = -math.huge, -math.huge
	local inside = {}
	local current = set
	local f = Instance.new("Folder", workspace)
	repeat
		local p = current[1]
		inside[#inside+1] = current
		if p.X < minx then minx = p.X end
		if p.X > maxx then maxx = p.X end
		if p.Z < minz then minz = p.Z end
		if p.Z > maxz then maxz = p.Z end
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide = true, false
		p.TopSurface, p.BottomSurface = 0, 0
		p.Size = Vector3.new(.3, 1.5, 1.5)
		p.Shape = "Cylinder"
		p.CFrame = CFrame.new(current[1])*CFrame.Angles(0, 0, math.pi*.5)
		p.Parent = f
		local p = p:Clone()
		p.Shape = "Block"
		p.Size = Vector3.new(1.5, .3, (current[1]-current[2][1]).magnitude)
		p.CFrame = CFrame.new((current[1]+current[2][1])*.5,current[2][1])
		p.Parent = f
		current = current[2]
	until current == set
	local maxedge = math.max(maxx-minx, maxz-minz)
	local initialsize = 1
	while initialsize < maxedge do
		initialsize = initialsize * 2
	end
	local origin = Vector3.new((maxx+minx)*.5, 0, (maxz+minz)*.5)
	local clock = tick()
	local function tree(position, size, inside, reference, refstate)
		if tick()-clock > .01 then wasted = wasted + wait(.1) clock = tick() end
				--[[local e = Instance.new("Part")
				e.Size = Vector3.new(size, .2, size)
				e.Anchored = true
				e.TopSurface, e.BottomSurface = 0, 0
				e.Position = origin + position
				e.Parent = workspace
				wait()
				e.Parent = nil]]
		local center = origin + position
		local half = size*.5
		local inC;
		if refstate == nil then
			inC = inpolygon(center, set)
		else
			inC = getside(center, origin + reference, inside, refstate)
		end
		if #inside == 0 or size == 1 then
			if inC then
				local e = Instance.new("Part")
				e.Size = Vector3.new(size, .2, size)
				e.Anchored = true
				e.TopSurface, e.BottomSurface = 0, 0
				e.Position = origin + position
				e.Parent = workspace
				return
			else
				return
			end
		end
		if size ~= 1 then
			local quadrants = {{}, {}, {}, {}}
			local x, z = position.X+origin.X, position.Z+origin.Z
			local half = size*.5
			local quarter = half*.5
			for i = 1, #inside do
				local v = inside[i]
				local p1, p2 = v[1], v[2][1]
				local minx, maxx, minz, maxz = p1.X, p2.X, p1.Z, p2.Z
				if minx > maxx then minx, maxx = maxx, minx end
				if minz > maxz then minz, maxz = maxz, minz end
				local function check(x0, x1, z0, z1)
					local minx, maxx, minz, maxz = minx, maxx, minz, maxz
					if maxx > x1 then maxx = x1 end
					if minx < x0 then minx = x0 end
					if minx > maxx then return false end
					local dx = p2.X-p1.X
					if dx ~= 0 then
						local a = (p2.Z-p1.Z)/dx
						local b = p1.Z - a*p1.X
						minz = a*minx + b
						maxz = a*maxx + b
						if minz > maxz then minz, maxz = maxz, minz end
					end
					if maxz > z1 then maxz = z1 end
					if minz < z0 then minz = z0 end
					if minz > maxz then return false end
					return true
				end
				if check(x, x+half, z, z+half) then
					quadrants[1][#quadrants[1]+1] = v
				end
				if check(x, x+half, z-half, z) then
					quadrants[2][#quadrants[2]+1] = v
				end
				if check(x-half, x, z, z+half) then
					quadrants[3][#quadrants[3]+1] = v
				end
				if check(x-half, x, z-half, z) then
					quadrants[4][#quadrants[4]+1] = v
				end
			end
			tree(position+Vector3.new( quarter, 0,  quarter), half, quadrants[1], position, inC)
			tree(position+Vector3.new( quarter, 0, -quarter), half, quadrants[2], position, inC)
			tree(position+Vector3.new(-quarter, 0,  quarter), half, quadrants[3], position, inC)
			tree(position+Vector3.new(-quarter, 0, -quarter), half, quadrants[4], position, inC)
		end
	end
	tree(Vector3.new(), initialsize, inside)
end

local list = {}
local points = game.ServerStorage:FindFirstChild("Model")
for i = 1, #points:GetChildren() do
	local p = points:FindFirstChild(i).Position
	list[i] = {p*Vector3.new(1,0,1)}
end
for i = 1, #list do
	list[i][0], list[i][2] = list[i-1], list[i+1]
end
list[1][0] = list[#list]
list[#list][2] = list[1]

local set = list[1]
local clock = tick()
render(set)
print("time: "..(tick()-clock - wasted))