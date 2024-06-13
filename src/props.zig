const std = @import("std");
const rl =  @import("raylib");
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
    Timeline
};

pub const Point = struct {
    x: i32,
    y: i32,
    color: rl.Color = rl.Color.black,
    brushSize: f32 = 4.0,
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
    number: i32,
    frames: std.ArrayList(Frame),
    currentFrame: *Frame,
    currentTool: Tool,
    currentColor: rl.Color,
    brushSize: f32 = 4,

    pub fn init(gpa: std.mem.Allocator) !ProjectProps{
        var frames = std.ArrayList(Frame).init(gpa);
        var layers = std.ArrayList(Layer).init(gpa);
        try layers.append(Layer {
            .points = std.ArrayList(Point).init(gpa),
            .strokes = std.ArrayList(Stroke).init(gpa)
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
            .number = 5,
            .currentTool = Tool.Brush,
            .frames = frames,
            .currentFrame = &frames.items[0],
            .currentColor = rl.Color.black,
            .brushSize = 8.0,
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
    pub fn draw(self: @This(), point: Point) !void {
        const numStrokes = self.currentFrame.*.currentLayer.*.strokes.items.len - 1;
        // std.debug.print("strokes: {}", .{lastStroke});
        try self.currentFrame.*.currentLayer.*.strokes.items[numStrokes].segments.append(point);
    }

    // draw current open frame in canvas region
    pub fn renderFrame(self: @This()) !void {
        var n:usize = 0;
        var m:usize = 0;

        while (n < self.currentFrame.layers.items.len): (n+=1) {
            const curr = self.currentFrame.layers.items[n];

            // going by strokes/line segments so it's easier to differentiate lines for undo/redo flow as well as render
            // each stroke has a set of points,a nd each layer has a set of strokes, and each layer is within a frame :)
            for(curr.strokes.items) |stroke| {
                // gotta reset the starting point on each stroke or find a way to have a temp null value but I'm lazy and tired
                var prevPoint =  Point{.x = -100.0, .y = -100.0};

                while (m < stroke.segments.items.len): (m+=1) {
                    const current = stroke.segments.items[m];
                    // need a jointer/miter w/e to make the lines look connected
                    rl.drawCircle(current.x, current.y, self.brushSize/2, current.color);

                    if( 
                        prevPoint.x > 0 and 
                        prevPoint.y > 0 and
                        @sqrt( // distance formula, as readble as I could do at 3am
                            std.math.pow(f32, @floatFromInt(current.x - prevPoint.x), 2) + 
                            std.math.pow(f32, @floatFromInt(current.y - prevPoint.y), 2)
                        ) > self.brushSize / 3
                    )
                        {
                        rl.drawLineEx(
                            rl.Vector2{
                                .x = @floatFromInt(prevPoint.x), 
                                .y = @floatFromInt(prevPoint.y)
                            }, 
                            rl.Vector2{
                                .x = @floatFromInt(current.x), 
                                .y = @floatFromInt(current.y)
                            }, 
                            prevPoint.brushSize,
                            prevPoint.color
                        );
                    } 
                    prevPoint = current;
                }
                // reset point increment counter
                m = 0;
            }
        }
    }
};
