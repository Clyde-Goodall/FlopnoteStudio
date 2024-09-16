const std = @import("std");
const rl =  @import("raylib");
const scfg = @import("screen.zig");
const canvas = @import("canvas.zig");
const Allocator = std.mem.Allocator;
const allocator = std.heap.page_allocator;


pub const Tool = enum {
    Brush,
    Pencil,
    Eraser,
    Paint,
    Select,
    Canvas,
    Toolbar,
    Timeline,
    TimelineFrame,
};

pub const Point = struct {
    x: i32,
    y: i32,
    color: rl.Color = rl.Color.black,
};

pub const Stroke = struct {
    segments: std.ArrayList(Point)
};

pub const EraserQueue = struct {
    queue: std.ArrayList
};

// God willing I will finally use doubly linked lists for something OTHER than fucking l33tcode interview questions
pub const Frame = struct {
    id: i32,
    layers: std.ArrayList(Layer),
    currentLayer: *Layer,
    // left: ?*Frame,
    // right: ?*Frame

    pub fn deinit(self: @This()) void {
        for(self.layers.items) |layer| {
            layer.deinit();
        }
        self.layers.deinit();
    }
};

pub const Layer = struct {
    points: std.ArrayList(Point),
    strokes: std.ArrayList(Stroke),
    matrix: canvas.CanvasMatrix,
    // above: ?*Layer,
    // below: ?*Layer,

    pub fn appendPoint(self: *@This(), point: Point) !void {
        self.points.append(point);
    }

    pub fn deinit(self: @This()) void {
        self.strokes.deinit();
    }
};

pub const ProjectProps = struct {
    // queue for actions for undo/redo would go here
    // width/height in pixels
    canvasWidth: i32,
    canvasHeight: i32,
    number: i32,
    frames: std.ArrayList(Frame),
    currentFrame: *Frame,
    currentTool: Tool,
    currentColor: rl.Color,
    brushType: canvas.BrushType,

    pub fn init(canvasWidth: i32, canvasHeight: i32, gpa: std.mem.Allocator) !ProjectProps{
        var frames = std.ArrayList(Frame).init(gpa);
        var layers = std.ArrayList(Layer).init(gpa);
        try layers.append(Layer {
            .points = std.ArrayList(Point).init(gpa),
            .strokes = std.ArrayList(Stroke).init(gpa),
            .matrix = try canvas.CanvasMatrix.init(canvasWidth, canvasHeight, gpa)
            // .above = null,
            // .below = null
        });

        try frames.append(Frame {
            .id = 0,
            .layers = layers,
            // .currentLayer = &layers.items[0],
            .currentLayer = &layers.items[0],
            // .left = null,
            // .right = null,
        });

        return ProjectProps {
            .canvasWidth = canvasWidth,
            .canvasHeight = canvasHeight,
            .number = 5,
            .currentTool = Tool.Brush,
            .frames = frames,
            .currentFrame = &frames.items[0],
            .currentColor = rl.Color.black,
            .brushType = canvas.BrushType.Oval,
        };
    }

    pub fn deinit(self: @This()) void {
        for(self.frames.items) |frame| {
            frame.deinit();
        }
        self.frames.deinit();
    }

    pub fn changeTool(self: *@This(), tool: Tool) !void {
        self.currentTool = tool;
    }

    pub fn updateTitle(self: *@This(), title: []const u8) !void {
        self.projectTitle.append(title);
        try rl.setWindowTitle(self.title);
    }

    // add drawn points to current open line stroke
    // pub fn draw(self: @This(), point: Point) !void {
        
    //     const numStrokes = self.currentFrame.*.currentLayer.*.strokes.items.len - 1;
    //     // std.debug.print("strokes: {}", .{lastStroke});
    //     try self.currentFrame.*.currentLayer.*.strokes.items[numStrokes].segments.append(point);
    // }

    // draw current open frame in canvas region
    pub fn renderFrame(self: @This()) !void {
        // var n:usize = 0;
        // var m:usize = 0;
        // std.debug.print("{}\n", .{self.currentFrame.layers.items[0].matrix.field.items[0].items[0].color});
        const offsetX: i32 = @intCast(@as(i32, scfg.screenWidth - scfg.canvasWidth));
        const offsetY: i32 = 0;

        // while (n < self.currentFrame.layers.items.len): (n+=1) {
        //     const curr = self.currentFrame.layers.items[n];
        //     var idxH:usize = 0;
        //     var idxW:usize = 0;
        //     while(idxH < curr.matrix.field.items.len): (idxH+=1) {
        //         while(idxW < curr.matrix.field.items[idxH].items.len): (idxW+=1) {
        //             const row = curr.matrix.field.items[idxH];
        //             if(row.items[idxW].active) {
        //                 rl.drawPixel(@intCast(idxW), @intCast(idxH), row.items[idxW].color);
        //             }
        //         }
        //     }
        // }
        for (0..@intCast(self.currentFrame.layers.items.len)) |n| {
            const curr = self.currentFrame.layers.items[n];

            for (0..@intCast(curr.matrix.field.items.len)) |idxH| {
                for(0..@intCast(curr.matrix.field.items[idxH].items.len)) |idxW| {
                    const row = curr.matrix.field.items[idxH];
                    if(row.items[idxW].active) {
                            rl.drawPixel(@intCast(idxW + offsetX), @intCast(idxH + offsetY), row.items[idxW].color);
                    }
                }
            }
        }
    }
};
