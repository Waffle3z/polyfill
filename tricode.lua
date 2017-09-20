function round(x)
	return math.floor(x+.5)
end

function cw(A, B, C) -- points A, B, C are clockwise in order
	return (C.Z-A.Z)*(B.X-A.X) > (B.Z-A.Z)*(C.X-A.X)
end
function intersect(A,B,C,D) -- line segments AB and CD intersect
	if A == B or A == C or A == D or B == C or B == D or C == D then return false end
	return cw(A,C,D) ~= cw(B,C,D) and cw(A,B,C) ~= cw(A,B,D)
end

function cw2(A, B, C)
	local cb, bc = (C.Z-A.Z)*(B.X-A.X), (B.Z-A.Z)*(C.X-A.X)
	if math.abs(cb-bc)/math.abs((cb+bc)*.5) < .01 then return nil end
	return (C.Z-A.Z)*(B.X-A.X) > (B.Z-A.Z)*(C.X-A.X)
end
function intersect2(A,B,C,D)
	local acd, bcd, abc, abd = cw2(A,C,D), cw2(B,C,D), cw2(A,B,C), cw2(A,B,D)
	if acd == nil or bcd == nil then
		if abc == nil or abd == nil then
			return false
		else
			return abc ~= abd
		end
	elseif abc == nil or abd == nil then
		return acd ~= bcd
	else
		return acd ~= bcd and abc ~= abd
	end
end
function intersect2(A, B, C, D)
	if A == B or A == C or A == D or B == C or B == D or C == D then return false end
	local v = intersect(A, B, C, D)
	if v then
		local x = Instance.new("Part")
		x.Anchored = true
		x.Size = Vector3.new(.5, 5, .5)
		x.BrickColor = BrickColor.new("Bright blue")
		x.CFrame = CFrame.new(A.X, 0, A.Z)
		x.Parent = workspace
		local y = x:Clone()
		y.BrickColor = BrickColor.new("Bright red")
		y.CFrame = CFrame.new(B.X, 0, B.Z)
		y.Parent = workspace
		local z = x:Clone()
		z.BrickColor = BrickColor.new("Black")
		z.CFrame = CFrame.new(C.X, 0, C.Z)
		z.Parent = workspace
		local w = x:Clone()
		w.BrickColor = BrickColor.new("White")
		w.CFrame = CFrame.new(D.X, 0, D.Z)
		w.Parent = workspace
		print("pause")
		x.Parent, y.Parent, z.Parent, w.Parent = nil
	end
	return v
end

function inpolygon(point, set) -- 'point' is inside polygon 'set'
	local current, inside = set, false
	repeat
		local A, B = current[1], current[2][1]
		local C = point
		--if (C.X >= A.X) ~= (C.X >= B.X) and
			--(B.X >= A.X) ~= ((C.Z-A.Z)*(B.X-A.X) >= (B.Z-A.Z)*(C.X-A.X)) then
		if((A.Z >= point.Z) ~= (B.Z >= point.Z)) -- A and B are on different sides of point
		and ((point.X-A.X) <= (B.X-A.X)*(point.Z-A.Z)/(B.Z-A.Z)) then
			inside = not inside
		end
		current = current[2]
	until current == set
	return inside
end

local function getside(A, offset, edges, inside)
	local B = A + offset
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

local function SegmentIntersectsRectangle(p1, p2, x0, x1, z0, z1)
	local minx, maxx, minz, maxz = p1.X, p2.X, p1.Z, p2.Z
	if minx > maxx then minx, maxx = maxx, minx end
	if minz > maxz then minz, maxz = maxz, minz end
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

local function inrect(v, x0, x1, z0, z1)
	local p1, p2 = v[1], v[2][1]
	local minx, maxx, minz, maxz = p1.X, p2.X, p1.Z, p2.Z
	if minx > maxx then minx, maxx = maxx, minx end
	if minz > maxz then minz, maxz = maxz, minz end
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

local function inrect(v, x0, x1, z0, z1) -- bounding boxes overlap (temporary replacement function)
	local p1, p2 = v[1], v[2][1]
	local minx, maxx, minz, maxz = p1.X, p2.X, p1.Z, p2.Z
	if minx > maxx then minx, maxx = maxx, minx end
	if minz > maxz then minz, maxz = maxz, minz end
	if x0 > x1 then x0, x1 = x1, x0 end
	if z0 > z1 then z0, z1 = z1, z0 end
	if minx > x1 or maxx < x0 or minz > z1 or maxz < z0 then
		return false
	end
	return true
end

local function Triangle(ax,az,bx,bz,cx,cz)
	local px,pz,tx,tz=ax,az,cx,cz
	local x0,z0=bx-ax,bz-az
	local x1,z1=cx-ax,cz-az
	local dot,d=x0*x1+z0*z1
	if dot<=0 then
		px,pz,tx,tz=cx,cz,ax,az
		x0,z0=bx-cx,bz-cz
		d=-(x0*x1+z0*z1)/(x0*x0+z0*z0)
	else
		d=dot/(x0*x0+z0*z0)
		if d>1 then
			tx,tz,x0,z0=bx,bz,x1,z1
			d=dot/(x0*x0+z0*z0)	
		end
	end
	local X,Z=tx-px-d*x0,tz-pz-d*z0
	local w,h=(x0*x0+z0*z0)^.5,(X*X+Z*Z)^.5
	local yx,yz,zx,zz=X/h,Z/h,x0/w,z0/w
	local xy=yz*zx-yx*zz
	local color=BrickColor.random()
	local fill=Instance.new('Model')
	fill.Name='Part'
	local w1=Instance.new('WedgePart',fill)
	--w1.BrickColor=color
	w1.Anchored,w1.CanCollide,w1.BottomSurface=true,false,'Smooth'
	w1.Size=Vector3.new(.2,.2,.2)
	w1.CFrame=CFrame.new(x0*.5*d    +.5*X+px, .1, z0*.5*d    +.5*Z+pz,0,yx, zx, xy,0,0,0,yz, zz)
	local m=Instance.new("SpecialMesh",w1)
	m.MeshType="Wedge"
	m.Scale=Vector3.new(0,h*5,    d*w*5)
	local w2=Instance.new('WedgePart',fill)
	--w2.BrickColor=color
	w2.Anchored,w2.CanCollide,w2.BottomSurface=true,false,'Smooth'
	w2.Size=Vector3.new(.2,.2,.2)
	w2.CFrame=CFrame.new(x0*.5*(d+1)+.5*X+px, .1, z0*.5*(d+1)+.5*Z+pz,0,yx,-zx,-xy,0,0,0,yz,-zz)
	local m=Instance.new("SpecialMesh",w2)
	m.MeshType="Wedge"
	m.Scale=Vector3.new(0,h*5,(1-d)*w*5)
	return fill
end

local wasted = 0
function render(set)
	local clock = tick()
	local drawlist = {}
	local f = Instance.new("Folder")
	local list, edgelist = {}, {}
	local minx, maxx, minz, maxz = math.huge, -math.huge, math.huge, -math.huge
	local current = set
	repeat
		local p = current[1]
		edgelist[#edgelist+1] = current
		list[#list+1] = {p, false, index = #edgelist}
		current.index = #edgelist
		if p.X < minx then minx = p.X end
		if p.X > maxx then maxx = p.X end
		if p.Z < minz then minz = p.Z end
		if p.Z > maxz then maxz = p.Z end
		local c = Instance.new("Part")
		c.Anchored, c.CanCollide = true, false
		c.TopSurface, c.BottomSurface = 0, 0
		c.Size = Vector3.new(.3, 1.5, 1.5)
		c.Shape = "Cylinder"
		c.CFrame = CFrame.new(p)*CFrame.Angles(0, 0, math.pi*.5)
		c.Parent = f
		local b = c:Clone()
		b.Shape = "Block"
		b.Size = Vector3.new(1.5, .3, (p-current[2][1]).magnitude)
		b.CFrame = CFrame.new((p+current[2][1])*.5,current[2][1])
		b.Parent = f
		current=current[2]
	until current == set
	local maxdim = math.max(maxx-minx, maxz-minz)
	local origin = Vector3.new((maxx+minx)*.5, 0, (maxz+minz)*.5)
	local initsize = 1
	while initsize < maxdim do
		initsize = initsize*2
	end
	local tree = {X = origin.X, Z = origin.Z, size = initsize,
		          edges = edgelist, inside = inpolygon(origin, set)}
	local function fragment(branch)
		local pos = Vector3.new(branch.X, 0, branch.Z)
		local x, z = pos.X, pos.Z
		local half = branch.size*.5
		local quarter = half*.5
		local quad1, quad2, quad3, quad4 = {}, {}, {}, {}
		for i = 1, #branch.edges do
			local v = branch.edges[i]
			if inrect(v, x, x+half, z, z+half) then
				quad1[#quad1+1] = v
			end
			if inrect(v, x, x+half, z-half, z) then
				quad2[#quad2+1] = v
			end
			if inrect(v, x-half, x, z, z+half) then
				quad3[#quad3+1] = v
			end
			if inrect(v, x-half, x, z-half, z) then
				quad4[#quad4+1] = v
			end
		end
		local inside1 = getside(pos, Vector3.new( quarter, 0,  quarter), quad1, branch.inside)
		local inside2 = getside(pos, Vector3.new( quarter, 0, -quarter), quad2, branch.inside)
		local inside3 = getside(pos, Vector3.new(-quarter, 0,  quarter), quad3, branch.inside)
		local inside4 = getside(pos, Vector3.new(-quarter, 0, -quarter), quad4, branch.inside)
		branch[1] = {X = x+quarter, Z = z+quarter, size = half, edges = quad1, inside = inside1}
		branch[2] = {X = x+quarter, Z = z-quarter, size = half, edges = quad2, inside = inside2}
		branch[3] = {X = x-quarter, Z = z+quarter, size = half, edges = quad3, inside = inside3}
		branch[4] = {X = x-quarter, Z = z-quarter, size = half, edges = quad4, inside = inside4}
		branch.fragmented = true
	end
	local function GetCellFromPoint(px, pz, branch)
		branch = branch or tree
		local bx, bz = branch.X, branch.Z
		if #branch.edges <= 2 then
			return branch
		else
			if not branch.fragmented then
				fragment(branch)
			end
			return GetCellFromPoint(px, pz, branch[(px > bx) and (pz > bz and 1 or 2) or (pz > bz and 3 or 4)])
		end
	end
	local function checkinside(px, pz)
		local cell = GetCellFromPoint(px, pz)
		local cx, cz = cell.X, cell.Z
		return getside(Vector3.new(cx, 0, cz), Vector3.new(px-cx, 0, pz-cz), cell.edges, cell.inside)
	end
	--[[local function GetCellsLineIntersects(a, b)
		local cells = {}
		local listed = {}
		local ax, az, bx, bz = a.X, a.Z, b.X, b.Z
		local length = ((ax-bx)^2+(az-bz)^2)^.5
		local unitX, unitZ = (bx-ax)/length, (bz-az)/length
		local px, pz = ax, az
		for i = 1, length do
			local cell = GetCellFromPoint(px, pz)
			listed[cell] = true
			cells[#cells+1] = cell
			px, pz = px + unitX, pz + unitZ
		end
		return cells
	end]]
	--[[local function GetCellsLineIntersects(a, b)
		local segments = {{a, b}}
		local cells = {}
		local listed = {}
		while #segments ~= 0 do
			local new = {}
			local visited = {}
			for _, segment in pairs(segments) do
				local a, b = segment[1], segment[2]
				local cella = GetCellFromPoint(a.X, a.Z)
				local cellb = GetCellFromPoint(b.X, b.Z)
				if not listed[cella] then
					visited[#visited+1] = cella
				end
				if cella ~= cellb then
					if not listed[cellb] then
						visited[#visited+1] = cellb
					end
					if math.abs(a.X - b.X) > .1 or math.abs(a.Z - b.Z) > .1 then
						local mid = {X = (a.X + b.X)*.5, Z = (a.Z + b.Z)*.5}
						new[#new+1] = {a, mid}
						new[#new+1] = {b, mid}
					end
				end
			end
			segments = new
			for _, cell in pairs(visited) do
				if not listed[cell] then
					listed[cell] = true
					cells[#cells+1] = cell
				end
			end
			--print(#segments, #visited) wait()
		end
		return cells
	end]]
	local function GetCellsLineIntersects(a, b)
		local cells = {}
		local function recurse(branch)
			local x, z, size = branch.X, branch.Z, branch.size*.5
			if SegmentIntersectsRectangle(a, b, x - size, x + size, z - size, z + size) then
				if branch.fragmented then
					recurse(branch[1])
					recurse(branch[2])
					recurse(branch[3])
					recurse(branch[4])
				else
					cells[#cells+1] = branch
				end
			end
		end
		recurse(tree)
		return cells
	end
	f.Parent=workspace
	setmetatable(list,{__index=function(t,k)return k==0 and rawget(t,#t)or k==#t+1 and rawget(t,1)or rawget(t,k)end})
	local i = 1
	local T = tick()
	while #list >= 3 do
		i = (i-1)%(#list) + 1
		local currenti = i
		local broke = false
		while list[i][2] do
			i = i%(#list) + 1
			if i == currenti then
				i = i%(#list) + 1
				broke = true
				break
			end
		end
		local ai, bi, ci = list[i-1].index, list[i].index, list[i+1].index
		local a, b, c = list[i-1][1], list[i][1], list[i+1][1]
		if tick()-T>.01 then wasted = wasted + wait() T=tick() end
		local listlength = #list
		local x0, x1, z0, z1 = a.X, c.X, a.Z, c.Z
		if x0 > x1 then x0, x1 = x1, x0 end
		if z0 > z1 then z0, z1 = z1, z0 end
		local p = (a + c)*.5
		if checkinside(p.X, p.Z) then
			local pass = true
			local listed = {}
			local cells = GetCellsLineIntersects(a, c)
			local cells2 = GetCellsLineIntersects(a, b)
			local cells3 = GetCellsLineIntersects(b, c)
			for i = 1, #cells do listed[cells[i]] = true end
			for i = 1, #cells2 do local c = cells2[i] if not listed[c] then listed[c] = true cells[#cells+1] = c end end
			for i = 1, #cells3 do local c = cells3[i] if not listed[c] then listed[c] = true cells[#cells+1] = c end end
			local edges = {}
			for c = 1, #cells do
				local celledges = cells[c].edges
				for e = 1, #celledges do
					local edge = celledges[e]
					if not edges[edge] then
						edges[edge] = true
						edges[#edges+1] = edge
					end
				end
			end
			local edges2 = edges
			for _, v in pairs(edges2) do
				edges2[v] = true
			end
			--[[local edges = {}
			local start = current
			repeat
				edges[#edges+1] = current
				current = current[2]
			until current == start]]
			for e = 1, #edges do
				local edge = edges[e]
				local A, B = edge[1], edge[2][1]
				local ei, e2i = edge.index, edge[2].index
				--if edge.index ~= ci and edge[2].index ~= ai and edge[2][2].index ~= ai and edge[2][2].index ~= ci then
					if intersect(a, c, A, B) or intersect(a, b, A, B) or intersect(b, c, A, B) then
						if not edges2[edge] then
							local e = Instance.new("Part")
							e.TopSurface = 0
							e.Anchored = true
							e.Size = Vector3.new(.2, .2, (a-c).magnitude)
							e.CFrame = CFrame.new((a+c)/2, c)+Vector3.new(0, 1, 0)
							e.Parent = workspace
							local e = e:Clone()
							e.Size = Vector3.new(.2, .2, (a-b).magnitude)
							e.CFrame = CFrame.new((a+b)/2, b)+Vector3.new(0, 1, 0)
							e.Parent = workspace
							local e = e:Clone()
							e.Size = Vector3.new(.2, .2, (b-c).magnitude)
							e.CFrame = CFrame.new((b+c)/2, c)+Vector3.new(0, 1, 0)
							e.Parent = workspace
							for i = 1, #edges2 do
								local x = edges2[i]
								local e = e:Clone()
								e.BrickColor = BrickColor.new("Really red")
								local p1, p2 = x[1], x[2][1]
								e.Size = Vector3.new(.2, .2, (p1-p2).magnitude)
								e.CFrame = CFrame.new((p1+p2)/2, p2)+Vector3.new(0, 2, 0)
								e.Parent = workspace
							end
							for i = 1, #cells do
								local x = cells[i]
								local e = e:Clone()
								e.BrickColor = BrickColor.new("Bright blue")
								e.Transparency = .5
								e.Size = Vector3.new(x.size, .2, x.size)
								e.CFrame = CFrame.new(x.X, 5, x.Z)
								e.Parent = workspace
							end
							error("missing edge")
						end
						pass = false
						if broke then print(edge.index, edge[2].index, ai, bi, ci) end
						break
					end
				--end
			end
			
			--[[local currenti = current.index
			repeat
				--local clock = tick()
				local nextcurrent = current[2]
				local nextcurrenti = nextcurrent.index
				local A, B = current[1], nextcurrent[1]
				if currenti ~= ci and nextcurrenti ~= ai then
					--local clock2 = tick()
					local xm, xx, zm, zx = A.X, B.X, A.Z, B.Z
					if xm > xx then xm, xx = xx, xm end
					if zm > zx then zm, zx = zx, zm end
					if not (x0 > xx or x1 < xm) and not (z0 > zx or z1 < zm) then
						local int = intersect(a,c,A,B)
						if int then
							pass = false
							break
						end
					end
				end
				current = nextcurrent
				currenti = nextcurrenti
			until current == set
			current = set]]
			
			if pass then
				Triangle(a.X, a.Z, b.X, b.Z, c.X, c.Z).Parent = f
				table.remove(list, i)
			end
		end
		if #list == listlength then
			list[i][2] = true
		else
			list[i][2] = false
			list[i-1][2] = false
			i = i + 1
		end
	end
	print("time: "..(tick()-clock - wasted))
	--[[for _, v in pairs(drawlist) do
		Triangle(unpack(v)).Parent = f
	end]]
	return f
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
--local clock = tick()
render(set)
--print("time: "..(tick()-clock))