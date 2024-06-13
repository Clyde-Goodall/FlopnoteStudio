const rl = @import("raylib");
const std = @import("std");
const Pixel = struct {
    color: rl.Color = rl.Color.white,
    active: bool = false,

    pub fn render(self: @This(), referenceXY: struct {x: i32, y: i32}, row: i32, col: i32) !void{
        rl.drawPixel(col + referenceXY.x, row + referenceXY.y, self.color);
    }
};

pub fn buildMatrix(rows: usize, cols: usize, alloc: std.mem.Allocator) std.ArrayList(std.ArrayList(Pixel)) {
    var cols = std.ArrayList(std.ArrayList).init(alloc);
    // similar block for drawing pixel in raylib for entire canvas matrix over in ./props.zig
    for(cols) |col| {
        cols.append(std.ArrayList(Pixel).init(alloc));
        for(rows) |row| {
            cols.items[col].append(Pixe{});
        }
    }
}

pub const CanvasMatrix = struct {
    field: std.ArrayList(std.ArrayList(Pixel)),
    rowLen: i32,
    colLen: i32,

    pub fn init(rows: i32, cols: i32, alloc: std.mem.Allocator) !CanvasMatrix {
        const matrix = CanvasMatrix {
            .field = buildMatrix(rows, cols, alloc),
            .rowLen = rows,
            .colLen = cols,
        };
        return matrix;
    }
};