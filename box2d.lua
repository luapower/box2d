--math for 2D rectangles defined as (x, y, w, h). (Cosmin Apreutesei, public domain)

--representation forms

local function corners(x, y, w, h)
	return x, y, x + w, y + h
end

local function rect(x1, y1, x2, y2)
	return x1, y1, x2 - x1, y2 - y1
end

--layouting

local function align(w, h, halign, valign, bx, by, bw, bh) --align a box in another box
	local x =
		halign == 'center' and (2 * bx + bw - w) / 2 or
		halign == 'left' and bx or
		halign == 'right' and bx + bw - w
	local y =
		valign == 'center' and (2 * by + bh - h) / 2 or
		valign == 'top' and by or
		valign == 'bottom' and by + bh - h
	return x, y, w, h
end

--slice a box horizontally at a certain height and return the i'th box.
--if sh is negative, slicing is done from the bottom side.
local function vsplit(i, sh, x, y, w, h)
	if sh < 0 then
		sh = h + sh
		i = 3 - i
	end
	if i == 1 then
		return x, y, w, sh
	else
		return x, y + sh, w, h - sh
	end
end

--slice a box vertically at a certain width and return the i'th box.
--if sw is negative, slicing is done from the right side.
local function hsplit(i, sw, x, y, w, h)
	if sw < 0 then
		sw = w + sw
		i = 3 - i
	end
	if i == 1 then
		return x, y, sw, h
	else
		return x + sw, y, w - sw, h
	end
end

--slice a box in n equal slices, vertically or horizontally, and return the i'th box.
local function nsplit(i, n, direction, x, y, w, h) --direction = 'v' or 'h'
	assert(direction == 'v' or direction == 'h', 'invalid direction')
	if direction == 'v' then
		return x, y + (i - 1) * h / n, w, h / n
	else
		return x + (i - 1) * w / n, y, w / n, h
	end
end

local function translate(x0, y0, x, y, w, h)
	return x + x0, y + y0, w, h
end

local function offset(d, x, y, w, h) --offset a rectangle by d (outward if d is positive)
	return x - d, y - d, w + 2*d, h + 2*d
end

local function fit(w, h, bw, bh) --deals only with sizes; use align() to position the box
	if w / h > bw / bh then
		return bw, bw * h / w
	else
		return bh * w / h, bh
	end
end

--hit testing

local function hit(x0, y0, x, y, w, h) --check if a point (x0, y0) is inside rect (x, y, w, h)
	return x0 >= x and x0 <= x + w and y0 >= y and y0 <= y + h
end

local function hit_margins(x0, y0, d, x, y, w, h) --hit, left, top, right, bottom
	if hit(x0, y0, offset(d, x, y, 0, 0)) then
		return true, true, true, false, false
	elseif hit(x0, y0, offset(d, x + w, y, 0, 0)) then
		return true, false, true, true, false
	elseif hit(x0, y0, offset(d, x, y + h, 0, 0)) then
		return true, true, false, false, true
	elseif hit(x0, y0, offset(d, x + w, y + h, 0, 0)) then
		return true, false, false, true, true
	elseif hit(x0, y0, offset(d, x, y, w, 0)) then
		return true, false, true, false, false
	elseif hit(x0, y0, offset(d, x, y + h, w, 0)) then
		return true, false, false, false, true
	elseif hit(x0, y0, offset(d, x, y, 0, h)) then
		return true, true, false, false, false
	elseif hit(x0, y0, offset(d, x + w, y, 0, h)) then
		return true, false, false, true, false
	end
	return false, false, false, false, false
end

--edge snapping

local function near(x1, x2, d) --two 1D points are closer to one another than d
	return math.abs(x1 - x2) < d
end

local function closer(x1, x, x2) --x1 is closer to x than x2 is to x
	return math.abs(x1 - x) < math.abs(x2 - x)
end

local function overlap(ax1, ax2, bx1, bx2) --two 1D segments overlap
	return not (ax2 < bx1 or bx2 < ax1)
end

local function offset_seg(x1, x2, d) --offset a 1D segment by d (outward if d is positive)
	return x1 - d, x2 + d
end

--if side A (ax1, ax2, ay) should snap to parallel side B (bx1, bx2, by), then return side B's y
--to snap, sides should be close enough and overlapping, and side A should be closer to side B than to side C, if any.
local function snap_side(d, cy, ax1, ax2, ay, bx1, bx2, by)
	return near(by, ay, d) and (not cy or closer(by, ay, cy)) and
				overlap(ax1, ax2, offset_seg(bx1, bx2, d)) and by
end

--snap the sides of a rectangle against an iterator of rectangles.
local function snap(d, ax1, ay1, ax2, ay2, rectangles)

	local cx1, cy1, cx2, cy2 --snapped sides

	for x, y, w, h in rectangles do
		local bx1, by1, bx2, by2 = corners(x, y, w, h)

		cy1 = snap_side(d, cy1, ax1, ax2, ay1, bx1, bx2, by1) or
				snap_side(d, cy1, ax1, ax2, ay1, bx1, bx2, by2) or cy1

		cy2 = snap_side(d, cy2, ax1, ax2, ay2, bx1, bx2, by1) or
				snap_side(d, cy2, ax1, ax2, ay2, bx1, bx2, by2) or cy2

		cx1 = snap_side(d, cx1, ay1, ay2, ax1, by1, by2, bx1) or
				snap_side(d, cx1, ay1, ay2, ax1, by1, by2, bx2) or cx1

		cx2 = snap_side(d, cx2, ay1, ay2, ax2, by1, by2, bx1) or
				snap_side(d, cx2, ay1, ay2, ax2, by1, by2, bx2) or cx2
	end

	return cx1, cy1, cx2, cy2
end

--margin snapping

local function snap_margins(d, x, y, w, h, rectangles)
	local ax1, ay1, ax2, ay2 = corners(x, y, w, h)
	local cx1, cy1, cx2, cy2 = snap(d, ax1, ay1, ax2, ay2, rectangles)
	return rect(cx1 or ax1, cy1 or ay1, cx2 or ax2, cy2 or ay2)
end

--position snapping

local function snap_seg_pos(ax1, ax2, cx1, cx2)
	if cx1 and cx2 then
		if math.abs(cx1 - ax1) < math.abs(cx2 - ax2) then --move to whichever point is closer
			cx2 = cx1 + (ax2 - ax1) --move to cx1
		else
			cx1 = cx2 - (ax2 - ax1) --move to cx2
		end
	elseif cx1 then
		cx2 = cx1 + (ax2 - ax1)
	elseif cx2 then
		cx1 = cx2 - (ax2 - ax1)
	else
		cx1, cx2 = ax1, ax2
	end
	return cx1, cx2
end

local function snap_pos(d, x, y, w, h, rectangles)
	local ax1, ay1, ax2, ay2 = corners(x, y, w, h)
	local cx1, cy1, cx2, cy2 = snap(d, ax1, ay1, ax2, ay2, rectangles)
	cx1, cx2 = snap_seg_pos(ax1, ax2, cx1, cx2)
	cy1, cy2 = snap_seg_pos(ay1, ay2, cy1, cy2)
	return rect(cx1, cy1, cx2, cy2)
end

--snapping info

local function snapped_margins(d, x1, y1, w1, h1, x2, y2, w2, h2)
	local ax1, ay1, ax2, ay2 = corners(x1, y1, w1, h1)
	local bx1, by1, bx2, by2 = corners(x2, y2, w2, h2)
	local left    = overlap(ay1, ay2, by1, by2) and (near(bx1, ax1, d) or near(bx2, ax1, d))
	local top     = overlap(ax1, ax2, bx1, bx2) and (near(by1, ay1, d) or near(by2, ay1, d))
	local right   = overlap(ay1, ay2, by1, by2) and (near(bx1, ax2, d) or near(bx2, ax2, d))
	local bottom  = overlap(ax1, ax2, bx1, bx2) and (near(by1, ay2, d) or near(by2, ay2, d))
	return left or top or right or bottom, left, top, right, bottom
end

--box class

local box = {}
local box_mt = {__index = box}

local function new(x, y, w, h)
	return setmetatable({x = x, y = y, w = w, h = h}, box_mt)
end

function box:rect()
	return self.x, self.y, self.w, self.h
end

box_mt.__call = box.rect

function box:corners()
	return corners(self())
end

function box:align(halign, valign, parent_box)
	return new(align(self.w, self.h, halign, valign, parent_box()))
end

function box:vsplit(i, sh)
	return new(vsplit(i, sh, self()))
end

function box:hsplit(i, sw)
	return new(hsplit(i, sw, self()))
end

function box:nsplit(i, n, direction)
	return new(nsplit(i, n, direction, self()))
end

function box:translate(x0, y0)
	return new(translate(x0, y0, self()))
end

function box:offset(d) --offset a rectangle by d (outward if d is positive)
	return new(offset(d, self()))
end

function box:fit(parent_box, halign, valign)
	local w, h = fit(self.w, self.h, parent_box.w, parent_box.h)
	local x, y = align(w, h, halign or 'center', valign or 'center', parent_box())
	return new(x, y, w, h)
end

function box:hit(x0, y0)
	return hit(x0, y0, self())
end

function box:hit_margins(x0, y0, d)
	return hit_margins(x0, y0, d, self())
end

local function box_iter(rectangles)
	return function()
		local box = rectangles()
		return box and box()
	end
end

function box:snap_margins(d, rectangles)
	local x, y, w, h = self()
	return new(snap_margins(d, x, y, w, h, box_iter(rectangles)))
end

function box:snap_pos(d, rectangles)
	local x, y, w, h = self()
	return new(snap_pos(d, x, y, w, h, box_iter(rectangles)))
end

function box:snapped_margins(d)
	return snapped_margins(d, self())
end


local box_module = {
	--representation forms
	corners = corners,
	rect = rect,
	--layouting
	align = align,
	vsplit = vsplit,
	hsplit = hsplit,
	nsplit = nsplit,
	translate = translate,
	offset = offset,
	fit = fit,
	--hit testing
	hit = hit,
	hit_margins = hit_margins,
	--snapping
	snap_margins = snap_margins,
	snap_pos = snap_pos,
	snapped_margins = snapped_margins,
}

setmetatable(box_module, {__call = function(self, ...) return new(...) end})


if not ... then require'cplayer.toolbox_demo' end


return box_module
