// raylib-zig (c) Nikolas Wipper 2023
const rl = @import("raylib");
const std = @import("std");
const ui = @import("./components.zig");
const scfg = @import("./screen.zig");
const props = @import("./props.zig");
const wtf = @import("./wtf.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    const alloc = gpa.allocator();
    rl.initWindow(scfg.screenWidth, scfg.screenHeight, "Flopnote Studio");
    const canvas = ui.FrameGrid(alloc);
    var toolbar = ui.ToolBar(alloc);
    const timeline = ui.Timeline(alloc);
    var project = try props.ProjectProps.init(alloc);

    // tool options init
    var brush = ui.Brush(alloc);
    var eraser = ui.Eraser(alloc);
    var paint = ui.Paint(alloc);
    try toolbar.addChild(&brush);
    try toolbar.addChild(&eraser);
    try toolbar.addChild(&paint);

    // defers all grouped together for organization :shrug:
    defer project.deinit(); //unload project momry
    defer _ = gpa.deinit();
    defer rl.closeWindow(); // Close window and OpenGL context
    rl.setTargetFPS(120); // Set  120 frames-per-second

    // could try making this a default value in struct or at init
    try project.currentFrame.currentLayer.strokes.append(props.Stroke{
        .segments = std.ArrayList(props.Point).init(alloc)
    });

    while (!rl.windowShouldClose()) {
        // mouse input listeners
        try ui.canvasListener(canvas, project, alloc);
        try toolbar.childClickListener(&project);
    
        // render
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

