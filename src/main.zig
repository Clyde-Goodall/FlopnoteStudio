// raylib-zig (c) Nikolas Wipper 2023
const rl = @import("raylib");
const std = @import("std");
const ui = @import("./components.zig");
const scfg = @import("./screen.zig");
const props = @import("./props.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    rl.initWindow(scfg.screenWidth, scfg.screenHeight, "Shitnote Studio"); // screen height/width seems to work normally here, but canvas doesn't
    const canvas = ui.FrameGrid(alloc);
    var toolbar = ui.ToolBar(alloc);
    const timeline = ui.Timeline(alloc);
    var project = try props.ProjectProps.init(scfg.canvasWidth, scfg.canvasHeight, alloc);
    std.debug.print("\nscreen -> width:{}px height:{}px\n", .{ scfg.screenWidth, scfg.screenHeight });
    std.debug.print("\ncanvas matrix size -> w:{}, h:{} \n", .{ 
        project.currentFrame.currentLayer.matrix.field.items.len, 
        project.currentFrame.currentLayer.matrix.field.items[0].items.len 
    });

    // tool options init
    var brush = ui.Brush(alloc);
    var eraser = ui.Eraser(alloc);
    var paint = ui.Paint(alloc);
    try toolbar.addChild(&brush);
    try toolbar.addChild(&eraser);
    try toolbar.addChild(&paint);
    defer project.deinit(); //deallocate all project memory
    defer rl.closeWindow(); // Close window and OpenGL context
    rl.setTargetFPS(120); // Set our game to run at 60 frames-per-second

    // could try making this a default value in struct or at init
    // try project.currentFrame.currentLayer.strokes.append(props.Stroke{ .segments = std.ArrayList(props.Point).init(alloc) });

    while (!rl.windowShouldClose()) {
        // mouse input listeners
        try ui.canvasListener(canvas, project);
        try toolbar.childClickListener(&project);

        // draw scope
        rl.beginDrawing();
        defer rl.endDrawing();

        // regions
        rl.clearBackground(rl.Color.white);
        try canvas.drawCheckered();
        try toolbar.draw();
        try timeline.draw();

        // tools
        ui.drawToolItems(toolbar);

        // canvas rendering
        try project.renderFrame();

    }
}
