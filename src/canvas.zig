const rl = @import("raylib");
const std = @import("std");
const ui = @import("components.zig");
const props = @import("props.zig");
const scfg = @import("screen.zig");

pub const BrushStrategy = struct { brushMatrix: []const []const u8, offsetX: i32, offsetY: i32 };

pub const BrushType = enum {
    xSmall,
    Small,
    Medium,
    Large,
    xLarge,
    Oval,
};

pub const coord = struct {
    x: u32,
    y: u32
};

pub fn resolveShape(brush: BrushType) BrushStrategy {
    return switch (brush) {
        .xSmall => BrushStrategy{ .brushMatrix = &[1][]const u8{&[1]u8{1}}, .offsetX = 0, .offsetY = 0 },
        .Small => BrushStrategy{
            .brushMatrix = &[3][]const u8{
                &[3]u8{ 1, 1, 1 },
                &[3]u8{ 1, 1, 1 },
                &[3]u8{ 1, 1, 1 },
            },
            .offsetX = 2,
            .offsetY = 2,
        },
        .Medium => BrushStrategy{
            .brushMatrix = &[5][]const u8{
                &[5]u8{ 0, 1, 1, 1, 0 },
                &[5]u8{ 1, 1, 1, 1, 1 },
                &[5]u8{ 1, 1, 1, 1, 1 },
                &[5]u8{ 1, 1, 1, 1, 1 },
                &[5]u8{ 0, 1, 1, 1, 0 },
            },
            .offsetX = 3,
            .offsetY = 3,
        },
        .Large => BrushStrategy{
            .brushMatrix = &[9][]const u8{
                &[9]u8{ 0, 0, 0, 1, 1, 1, 0, 0, 0 },
                &[9]u8{ 0, 0, 1, 1, 1, 1, 1, 0, 0 },
                &[9]u8{ 0, 1, 1, 1, 1, 1, 1, 1, 0 },
                &[9]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1 },
                &[9]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1 },
                &[9]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1 },
                &[9]u8{ 0, 1, 1, 1, 1, 1, 1, 1, 0 },
                &[9]u8{ 0, 0, 1, 1, 1, 1, 1, 0, 0 },
                &[9]u8{ 0, 0, 0, 1, 1, 1, 0, 0, 0 },
            },
            .offsetX = 5,
            .offsetY = 5,
        },
        .xLarge => BrushStrategy{
            .brushMatrix = &[15][]const u8{
                &[15]u8{ 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0 },
                &[15]u8{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
                &[15]u8{ 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
                &[15]u8{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
                &[15]u8{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
                &[15]u8{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
                &[15]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
                &[15]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
                &[15]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
                &[15]u8{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
                &[15]u8{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
                &[15]u8{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
                &[15]u8{ 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
                &[15]u8{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
                &[15]u8{ 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0 },
            },
            .offsetX = 8,
            .offsetY = 8,
        },
        .Oval => BrushStrategy{
            .brushMatrix = &[9][]const u8{
                &[7]u8{0, 0, 0, 1, 0, 0, 0,},
                &[7]u8{0, 1, 0, 0, 0, 1, 0,},
                &[7]u8{0, 0, 0, 0, 0, 0, 0,},
                &[7]u8{0, 1, 0, 0, 0, 1, 0,},
                &[7]u8{0, 0, 0, 0, 0, 0, 0,},
                &[7]u8{0, 1, 0, 0, 0, 1, 0,},
                &[7]u8{0, 0, 0, 0, 0, 0, 0,},
                &[7]u8{0, 1, 0, 0, 0, 1, 0,},
                &[7]u8{0, 0, 0, 1, 0, 0, 0,},
            },
            .offsetX = 4,
            .offsetY = 5
        }
    };
}

const Pixel = struct {
    color: rl.Color = rl.Color.white,
    active: bool = false,

    pub fn render(self: @This(), referenceXY: struct { x: i32, y: i32 }, row: i32, col: i32) !void {
        rl.drawPixel(col + referenceXY.x, row + referenceXY.y, self.color);
    }
    pub fn setPixel(self: *@This(), color: rl.Color, status: bool) !void {
        self.color = color;
        self.active = status;
    }
};

pub fn buildMatrix(rSize: i32, cSize: i32, alloc: std.mem.Allocator) !std.ArrayList(std.ArrayList(Pixel)) {
    var cols = std.ArrayList(std.ArrayList(Pixel)).init(alloc);
    for (0..@intCast(cSize)) |i| {
        // inserting row
        try cols.append(std.ArrayList(Pixel).init(alloc));
        for (0..@intCast(rSize)) |_| {
            // inserting column
            try cols.items[i].append(Pixel{});
        }
    }
    return cols;
}

pub const CanvasMatrix = struct {
    field: std.ArrayList(std.ArrayList(Pixel)),
    pixelBuffer: ?coord,
    rowLen: i32,
    colLen: i32,

    pub fn init(rows: i32, cols: i32, alloc: std.mem.Allocator) !CanvasMatrix {
        const matrix = CanvasMatrix{
            .field = try buildMatrix(rows, cols, alloc),
            .pixelBuffer = null,
            .rowLen = rows,
            .colLen = cols,
        };
        return matrix;
    }

    pub fn maskBrushPixels(self: *@This(), tool: props.Tool, brush: BrushType, mouse: props.Point, color: rl.Color) !void {
        const offsetX: f32 = scfg.screenWidth - scfg.canvasWidth;
        const offsetY: f32 = 0;
        const brushShape = resolveShape(brush);
        const xLen: usize = brushShape.brushMatrix.len;
        const yLen: usize = brushShape.brushMatrix[0].len;
        const brushCenterX: usize = (xLen - 1) / 2;
        const brushCenterY: usize = (yLen - 1) / 2;
        const mouseX = @as(u32, @bitCast(mouse.x - @as(i32, offsetX)));
        const mouseY = @as(u32, @bitCast(mouse.y - @as(i32, offsetY)));
        var visible = true;
        if(tool == props.Tool.Eraser) {
            visible = false;
        }
        // Just flips the pixel color value to whatever the current brush color value is, or disables if eraser is active
        // integer overflow is still an issue, and I figure it has something to do with going off-canvas while drawing
        // and then trying to continue draing.
        // Still need a solution for lines drawn fast
        for(0..@intCast(xLen)) |x| {
            for(0..@intCast(yLen)) |y| {
                if(brushShape.brushMatrix[x][y] == 1 and 
                        (mouseX - brushCenterX) > 0 and 
                        (mouseX + brushCenterX) < self.rowLen and
                        (mouseY - brushCenterY) > 0 and 
                        (mouseY + brushCenterY) < self.colLen
                    ) {
                        // what a mouthful :3
                        try self
                            .field
                            .items[mouseY - brushCenterY + y]
                            .items[mouseX - brushCenterX + x]
                            .setPixel(color, visible);
                        self.pixelBuffer = coord {
                            .x = mouseX, 
                            .y = mouseY
                        };
                }
            }
        }
    }
};

fn lerp(a: u32, b: u32, t: usize) u32 {
    return a + @as(u32, @ptrCast(@as(usize, t))) * (b - a);
}