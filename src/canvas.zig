const rl = @import("raylib");
const std = @import("std");
const ui = @import("components.zig");
const props = @import("props.zig");

pub const BrushStrategy = struct{
    brushMatrix: []const []const u8, 
    offsetX: i32, 
    offsetY: i32
};

pub const BrushType = enum {
    xSmall,
    Small,
    Medium,
    Large,
    xLarge,
};

pub fn resolveShape(brush: BrushType) BrushStrategy {
        return switch (brush) {
            .xSmall => BrushStrategy{
                .brushMatrix = &[1][]const u8 { 
                    &[1]u8{ 1 } 
                },

                .offsetX = 0,
                .offsetY = 0
            },
            .Small => BrushStrategy {
                .brushMatrix = &[3][]const u8 {
                &[3]u8{1, 1, 1},
                &[3]u8{1, 1, 1},
                &[3]u8{1, 1, 1},
                },
                .offsetX = 2,
                .offsetY= 2,
            },
            .Medium => BrushStrategy{
                .brushMatrix = &[5][]const u8 {
                    &[5]u8{0, 1, 1, 1, 0},
                    &[5]u8{1, 1, 1, 1, 1},
                    &[5]u8{1, 1, 1, 1, 1},
                    &[5]u8{1, 1, 1, 1, 1},
                    &[5]u8{0, 1, 1, 1, 0},
                },
                .offsetX = 3,
                .offsetY= 3,
            },
            .Large => BrushStrategy {
                .brushMatrix = &[9][]const u8 {
                    &[9]u8{0, 0, 0, 1, 1, 1, 0, 0, 0},
                    &[9]u8{0, 0, 1, 1, 1, 1, 1, 0, 0},
                    &[9]u8{0, 1, 1, 1, 1, 1, 1, 1, 0},
                    &[9]u8{1, 1, 1, 1, 1, 1, 1, 1, 1},
                    &[9]u8{1, 1, 1, 1, 1, 1, 1, 1, 1},
                    &[9]u8{1, 1, 1, 1, 1, 1, 1, 1, 1},
                    &[9]u8{0, 1, 1, 1, 1, 1, 1, 1, 0},
                    &[9]u8{0, 0, 1, 1, 1, 1, 1, 0, 0},
                    &[9]u8{0, 0, 0, 1, 1, 1, 0, 0, 0},
                },
                .offsetX = 5,
                .offsetY= 5,
            },
            .xLarge => BrushStrategy{
                .brushMatrix = &[15][]const u8 {
                    &[15]u8{0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0},
                    &[15]u8{0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0},
                    &[15]u8{0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0},
                    &[15]u8{0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
                    &[15]u8{0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
                    &[15]u8{0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
                    &[15]u8{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
                    &[15]u8{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
                    &[15]u8{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
                    &[15]u8{0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
                    &[15]u8{0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
                    &[15]u8{0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
                    &[15]u8{0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0},
                    &[15]u8{0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0},
                    &[15]u8{0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0},
                },
                .offsetX = 8,
                .offsetY= 8,
            }
        };
    }

const Pixel = struct {
    color: rl.Color = rl.Color.white,
    active: bool = false,
 
    pub fn render(self: @This(), referenceXY: struct {x: i32, y: i32}, row: i32, col: i32) !void{
        rl.drawPixel(col + referenceXY.x, row + referenceXY.y, self.color);
    }

    pub fn setPixel(self: *@This(), color: rl.Color, status: bool) !void {
        self.color = color;
        self.active = status;
    }
};

pub fn buildMatrix(rSize: i32, cSize: i32, alloc: std.mem.Allocator) !std.ArrayList(std.ArrayList(Pixel)) {
    var cols = std.ArrayList(std.ArrayList(Pixel)).init(alloc);
    // similar block for drawing pixel in raylib for entire canvas matrix over in ./props.zig
    std.debug.print("masking pixels", .{});
    var i: usize = 0;
    var j: usize = 0;
    while(i < cSize): (i += 1) {
        // building screen matrix
        try cols.append(std.ArrayList(Pixel).init(alloc));
        while(j < rSize): (j += 1) {
            try cols.items[i].append(Pixel{});
        }
    }
    return cols;
}

pub const CanvasMatrix = struct {
    field: std.ArrayList(std.ArrayList(Pixel)),
    rowLen: i32,
    colLen: i32,

    pub fn init(rows: i32, cols: i32, alloc: std.mem.Allocator) !CanvasMatrix {
        const matrix = CanvasMatrix {
            .field = try buildMatrix(rows, cols, alloc),
            .rowLen = rows,
            .colLen = cols,
        };
        return matrix;
    }

    pub fn maskBrushPixels(self: @This(), brush: BrushType, mouse: props.Point, color: rl.Color)!void{
        const brushShape = resolveShape(brush);
        const xLen: usize = brushShape.brushMatrix.len;
        const yLen: usize = brushShape.brushMatrix[0].len;
        const anchorX: usize = @as(usize, @bitCast(@as(i64, mouse.x - brushShape.offsetX)));
        const anchorY: usize = @as(usize, @bitCast(@as(i64, mouse.y - brushShape.offsetY)));
        const width: usize = anchorX + xLen;
        const height: usize = anchorY + yLen;

        var i = anchorX;
        var j = anchorY;
        while(i < height): (i += 1) {
            while(j < width): (j += 1) {
                if(brushShape.brushMatrix[xLen][yLen] == 1) {
                    try self.field.items[i].items[j].setPixel(color, true);
                }
            }
        }
    }
};

