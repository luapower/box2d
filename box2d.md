---
project: box2d
tagline: rectangle math
---

## `local box = require'box2d'`

Math for 2D rectangles defined as `(x, y, w, h)`.

---------------------------------------------------------------------------------------------- --------------------------------------------
**representation forms**
`box.corners(x, y, w, h) -> x1, y1, x2, y2`                                                    left,top and right,bottom corners
`box.rect(x1, y1, x2, y2) -> x, y, w, h`                                                       box given left,top and right,bottom corners
**layouting**
`box.align(w, h, halign, valign, bx, by, bw, bh) -> x, y, w, h`                                align a box in another box
`box.vsplit(i, sh, x, y, w, h) -> x, y, w, h`                                                  slice a box horizontally at a certain height and return the i'th box. if sh is negative, slicing is done from the bottom side.
`box.hsplit(i, sw, x, y, w, h) -> x, y, w, h`                                                  slice a box vertically at a certain width and return the i'th box. if sw is negative, slicing is done from the right side.
`box.nsplit(i, n, direction, x, y, w, h) -> x, y, w, h`                                        slice a box in n equal slices, vertically or horizontally, and return the i'th box. direction = 'v' or 'h'
`box.translate(x0, y0, x, y, w, h) -> x, y, w, h`                                              move a box
`box.offset(d, x, y, w, h) -> x, y, w, h`                                                      offset a box by d, outward if d is positive
`box.fit(w, h, bw, bh) -> w, h`                                                                fit a box into another box preserving aspect ratio. use align() to position the box
**hit testing**
`box.hit(x0, y0, x, y, w, h) -> true | false`                                                  check if a point (x0, y0) is inside rect (x, y, w, h)
`box.hit_margins(x0, y0, d, x, y, w, h) -> hit, left, top, right, bottom`                      hit test for margins and corners
**edge snapping**
`box.snap_margins(d, x, y, w, h, rectangles) -> x, y, w, h`                                    snap the sides of a rectangle against an iterator of rectangles. `rectangles = function() -> x, y, w, h | nil`
`box.snap_pos(d, x, y, w, h, rectangles) -> x, y, w, h`                                        snap the position of a rectangle against an iterator of rectangles.
`box.snapped_margins(d, x1, y1, w1, h1, x2, y2, w2, h2) -> snapped, left, top, right, bottom`  check if two boxes are snapped and on which margins.
---------------------------------------------------------------------------------------------- --------------------------------------------

## OOP API (untested)

Operations never mutate the box object, they always return a new one.

-------------------------------------------------------------------- --------------------------------------------------------------------
`box(x, y, w, h) -> box`                                             create a new box object
`box.x, box.y, box.w, box.h`                                         box coordinates (for reading and writing)
`box:rect() -> x, y, w, h` <br> `box() -> x, y, w, h`                coordinates unpacked
`box:corners() -> x1, y1, x2, y2`                                    left,top and right,bottom corners
`box:align(halign, valign, parent_box) -> box`                       align
`box:vsplit(i, sh) -> box`                                           split vertically
`box:hsplit(i, sw) -> box`                                           split horizontally
`box:nsplit(i, n, direction) -> box`                                 split in equal parts
`box:translate(x0, y0) -> box`                                       translate
`box:offset(d) -> box`                                               offset by d (outward if d is positive)
`box:fit(parent_box, halign, valign) -> box`                         enlarge/shrink-to-fit and align
`box:hit(x0, y0) -> true | false`                                    hit test
`box:hit_margins(x0, y0, d) -> hit, left, top, right, bottom`        hit test for margins
`box:snap_margins(d, boxes) -> box`                                  snap the margins. boxes is an `iterator<box>` or a list of boxes
`box:snap_pos(d, boxes) -> box`                                      snap the position
-------------------------------------------------------------------- --------------------------------------------------------------------

TODO: access x1, y1, x2, y2 directly.

