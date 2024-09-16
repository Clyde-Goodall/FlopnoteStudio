const std = @import("std");
const rl = @import("raylib");
const c = @import("./colors.zig");
const scfg = @import("./screen.zig");
const props = @import("./props.zig");
const canvas = @import("./canvas.zig");
const Allocator = std.mem.Allocator;

const Position = enum {
    TopLeft,
    TopRight,
    BottomLeft,
    BottomRight
};

const Mouse = struct {
    x: i32, 
    y: i32
};

pub const Component = struct { 
    allocator: std.mem.Allocator,
    tool: props.Tool,
    unitWidth: i32, // in scale units
    unitHeight: i32, // in scale units
    fillColor: rl.Color,
    position: Position,
    altX: i32 = 0, // X offset/start position of rect draw coords in scale units, optional.
    altY: i32 = 0, //Y offset/start pos of rect ^^
    parent: ?*Component = null,
    children: std.ArrayList(*Component),
    active: bool = false,
    focus: bool = false,
    // customDraw: ?*const fn(component: Component) void,
    // hierarchical nodes would be nice in the future especially for component grouping.

    // function pointer for custom draw instruction would be nice
    pub fn init(
        tool: props.Tool, 
        unitHeight: i32,
        unitWidth: i32,
        fillColor: rl.Color, 
        position: Position,
        parent: ?*Component,
        alloc: std.mem.Allocator,
        altX: ?i32,  
        altY: ?i32,
        // customDraw: ?*const fn(component: Component) void,
    )  !Component{
        const component = Component {
            .allocator = alloc,
            .parent = if(@TypeOf(parent) == Component) parent else null,
            .unitHeight = unitHeight,
            .unitWidth = unitWidth,
            .tool = tool,
            .fillColor = fillColor,
            .position = position,
            .children = std.ArrayList(*Component).init(alloc),
            .altX = altX.?,
            .altY = altY.?,
            // .customDraw = if(@TypeOf(customDraw.*) != null) customDraw else null,

        };
        return component;
    }

    pub fn addChild(self: *@This(), component: *Component) !void {
        try self.children.append(component);
        component.parent = self;
    }

    pub fn hasMouseRegion(self: @This(), mouse: Mouse) !bool {
        const x = mouse.x;
        const y = mouse.y;
        // lower bounds
        const lowerX = self.unitAnchorX();
        const lowerY = self.unitAnchorY();
        // upper bounds
        const upperX = self.realWidth() + lowerX;
        const upperY = self.realHeight() + lowerY;
        // checks upper and lower bounds for mouse/component intersection
        const within = (
            x >= lowerX and 
            x <= upperX and 
            y >= lowerY and 
            y <= upperY
        );
        return within;
    }
    pub fn hasMouseRegionExact(self: @This(), mouse: Mouse) !bool {
        const x = mouse.x;
        const y = mouse.y;
        // lower bounds
        const lowerX = self.unitAnchorExactX();
        const lowerY = self.unitAnchorExactY();
        // upper bounds
        const upperX = self.realWidth() + lowerX;
        const upperY = self.realHeight() + lowerY;
        // checks upper and lower bounds for mouse/component intersection
        const within = (
            x >= lowerX and 
            x <= upperX and 
            y >= lowerY and 
            y <= upperY
        );
        return within;
    }
    // iterates through child components and
    pub fn childClickListener(self: *@This(), project: *props.ProjectProps) !void  {
        for(self.children.items) |child| {
            const mouse = .{.x = rl.getMouseX(), .y = rl.getMouseY()};
            if(try child.hasMouseRegionExact(mouse)) {
                        // would be fun to implement keybinding configs from scratch
                if(rl.isMouseButtonDown(rl.MouseButton.mouse_button_left)) {
                    child.toggleActive(true);
                } else if(rl.isMouseButtonReleased(rl.MouseButton.mouse_button_left)) {
                    child.toggleActive(false);
                    self.toggleCurrentFocus(child.tool);
                    try project.*.changeTool(child.tool);
                    std.debug.print("\n active tool: {}", .{project.*.currentTool});
                }
            }
        }
    }
 
    pub fn toggleActive(self: *@This(), case: bool) void {
        self.active = case;
    }

    pub fn toggleCurrentFocus(self: *@This(), tool: props.Tool) void {
        for(self.children.items) |child| {
            if(child.tool != tool) {
                child.focus = false;
                continue;
            }
            child.focus = true;
        }
    }
     pub fn setFocus(self: *@This(), state: bool) void {
        self.focus = state;
    }
    // actual pixel width after being multipled by SCALE_SIZE * CLUSTER_SIZE
    pub fn realWidth(self: *const Component) i32{
        return self.unitWidth * scfg.SCALAR;
    }

    pub fn realHeight(self: *const Component) i32{
        return self.unitHeight * scfg.SCALAR;
    }

    pub fn unitAnchorX(self: *const Component) i32 {
        const x: i32 = switch (self.position) {
            .TopLeft => 0,
            .BottomLeft => 0,
            .TopRight => rl.getScreenWidth() - self.realWidth(),
            .BottomRight => rl.getScreenWidth() - self.realWidth()
        };
        return x;
    }

    pub fn unitAnchorY(self: *const Component) i32 {
        const y: i32 = switch (self.position) {
            .TopLeft => 0,
            .TopRight => 0,
            .BottomLeft => rl.getScreenHeight() - self.realHeight(),
            .BottomRight => rl.getScreenHeight() - self.realHeight()
        };
        return y;
    }
    pub fn unitAnchorExactX(self: @This()) i32 {
        return self.altX * scfg.SCALAR;
    }   
    pub fn unitAnchorExactY(self: @This()) i32 {
        return self.altY * scfg.SCALAR;
    }
    pub fn draw(self: *const Component) !void {
        rl.drawRectangle(
            self.unitAnchorX(),
            self.unitAnchorY(),
            self.realWidth(),
            self.realHeight(),
            self.fillColor
        );
    }

    pub fn drawCheckered(self: *const Component) !void {
        var offset_switch: bool = false;
        // fill rect to prep for grey checkerboard
        rl.drawRectangle(
            self.unitAnchorX(),
            self.unitAnchorY(),
            self.realWidth(),
            self.realHeight(),
            self.fillColor
        );
        var n: i32 = 0;
        var m: i32 = 0;
        while ( n < self.unitHeight): (n += 1) {
            const anchor_y_curr_block: i32 = self.unitAnchorY() + (n * scfg.SCALAR);

            while ( m < self.unitWidth): (m += 2) { 
                const x_offset_modifier: i32 = if (offset_switch)  (scfg.SCALE_SIZE * scfg.CLUSTER_SIZE) else 0; 
                const anchor_x_curr_block: i32 = self.unitAnchorX() + (m * scfg.SCALE_SIZE * scfg.CLUSTER_SIZE) + x_offset_modifier;
                rl.drawRectangle(
                    anchor_x_curr_block, 
                    anchor_y_curr_block, 
                    scfg.SCALAR, 
                    scfg.SCALAR, 
                    c.palette.LIGHT_GREY
                    );
            }
            m = 0;
            offset_switch = !offset_switch;
        }   
    }
};

// checkered region where you draw stuff.
pub fn FrameGrid(alloc: std.mem.Allocator) Component {
    const region = try Component.init(
        .Canvas,
        scfg.CANVAS_UNIT_H,
        scfg.CANVAS_UNIT_W,
        rl.Color.white,
        Position.TopRight,
        null,
        alloc,
        0,
        0
        // *drawBrushTool,
    );
    return region;
}
// left-hand tools
pub fn ToolBar(alloc: std.mem.Allocator) Component {
    const region = try Component.init(
        .Toolbar,
        scfg.TOOLBAR_UNIT_H,
        scfg.TOOLBAR_UNIT_W,
        c.palette.OFF_WHITE,
        Position.TopLeft,
        null,
        alloc,
        0,
        0
        // &drawBrushTool,
    );
    return region;
}

// Tools
pub fn Brush(alloc: std.mem.Allocator) Component {
    
    const region = try Component.init(
        .Brush,
        1,
        2,
        c.palette.LIGHT_ORANGE,
        Position.TopLeft,
        null,
        alloc,
        1,
        1
        // &drawBrushTool,
    );
    return region;
}

pub fn Eraser(alloc: std.mem.Allocator) Component {
    
    const region = try Component.init(
        .Eraser,
        1,
        2,
        c.palette.LIGHT_ORANGE,
        Position.TopLeft,
        null,
        alloc,
        1,
        3
        // &drawBrushTool,
    );
    return region;
}

pub fn Paint(alloc: std.mem.Allocator) Component {
    
    const region = try Component.init(
        .Paint,
        1,
        2,
        c.palette.LIGHT_ORANGE,
        Position.TopLeft,
        null,
        alloc,
        1,
        5
        // &drawBrushTool,
    );
    return region;
}

pub fn TimelineFrame(alloc: std.mem.Allocator) Component {
    const region = try Component.init(
        .TimelineFrame,
        2,
        3,
        rl.Color.white,
        Position.TopLeft,
        null,
        alloc,
        1,
        1
    );
    return region;
}

// Drawing region of scrollable frames. 
// Currently not sure how to approach the scrolling and focus-based x-axis shifting.
// Will need focus-based highlighting
// At the cost of UX ergonomics, I could have a hotkey-triggered overlay that
//  hides other elements to provide a more DSi-like experience when moving through frames.
// Sort of an approximation of top-screen UI under certain conditions for specific features.
// It would be cool from a technical standpoint but would potentially be no better than 
//  anchoring to where it currently reside with a scrollable list of frames. 
// It would give it more space and room for tools though....
pub fn  drawTimelineFrames(component: Component) void {
    for(component.children.items) |child| {
        const frame = child.*;
        const rect = rl.Rectangle{
            .x = @floatFromInt(child.altX * scfg.SCALAR), 
            .y = @floatFromInt(child.altY * scfg.SCALAR),
            .width = @floatFromInt(frame.unitWidth * scfg.SCALAR),
            .height = @floatFromInt(frame.unitHeight * scfg.SCALAR),
        };
        rl.drawRectangleRounded(
            rect,
            0.35,
            30,
            frame.fillCOlor,
        );
    }
}

// tool visual state changing
pub fn drawToolItems(component: Component) void {
    // all children of parent component i.e. toolbar
    for(component.children.items) |child| {
        const tool = child.*;
        const thickness = 4;
        // const parent = component.parent;
        var fill = tool.fillColor;
        var border = c.palette.ORANGE;
        var rect = rl.Rectangle{
            .x = @floatFromInt(child.altX * scfg.SCALAR), 
            .y = @floatFromInt(child.altY * scfg.SCALAR),
            .width = @floatFromInt(tool.unitWidth * scfg.SCALAR),
            .height = @floatFromInt(tool.unitHeight * scfg.SCALAR),
        };
        var outerRect = rl.Rectangle{
            .x = rect.x - thickness, 
            .y = rect.y - thickness,
            .width = @floatFromInt((tool.unitWidth * scfg.SCALAR) + thickness * 2),
            .height = @floatFromInt((tool.unitHeight * scfg.SCALAR) + thickness * 2),
        };

        if(tool.active) {
            rect.y += thickness;
            outerRect.y += thickness;
            // fill = c.palette.YELLOW;
        }
        if(tool.focus) {
            fill = c.palette.YELLOW;
            border = rl.Color.black;
        }

        rl.drawRectangleRounded(
            outerRect,
            0.5,
            10,
            border,
        );

        rl.drawRectangleRounded(
            rect,
            0.35,
            30,
            fill,
        );
    }
}

pub fn Timeline(alloc: std.mem.Allocator) Component {
    const region = try Component.init(
        .Timeline,
        scfg.TIMELINE_UNIT_H,
        scfg.TIMELINE_UNIT_W,
        c.palette.OFF_WHITE,
        Position.BottomLeft,
        null,
        alloc,
        0,
        0
        // &drawBrushTool,
    );  
    return region;
}


// the ears
pub fn buttonListener(component: *Component) void {
    const mouse = .{.x = rl.getMouseX(), .y = rl.getMouseY()};
    if(try component.hasMouseRegionExact(mouse)) {
                // would be fun to implement keybinding configs from scratch
        if(rl.isMouseButtonDown(rl.MouseButton.mouse_button_left)) {
            component.toggleActive(true);
        } else if(rl.isMouseButtonReleased(rl.MouseButton.mouse_button_left)) {
            component.toggleActive(false);
            component.toggleFocus();

        }
    }
}

pub fn canvasListener(cvs: Component, project: props.ProjectProps) !void {
    const mouse = Mouse {
        .x = rl.getMouseX(), 
        .y = rl.getMouseY()
    };

    if(try cvs.hasMouseRegion(mouse)) {
        // would be fun to implement keybinding configs from scratch
        // try canvasActionDelegator(cvs, project, mouse, alloc);
        if(rl.isMouseButtonDown(rl.MouseButton.mouse_button_left)) {
            const point = props.Point{
                .x = mouse.x,
                .y = mouse.y,
                .color = project.currentColor,
            };
            // pixel masking call should be in here somewhere
            try project.currentFrame.currentLayer.matrix.maskBrushPixels(
                project.currentTool,
                project.brushType, 
                point, 
                project.currentColor
            );
        } 
        // else if(rl.isMouseButtonReleased(rl.MouseButton.mouse_button_left)) {
            
        // }
    }
}

// picks behavior for user input based on current tool type
pub fn canvasActionDelegator(cvs: Component, project: props.ProjectProps, mouse: Mouse) !void {
    if(try cvs.hasMouseRegion(mouse)) {
        if(rl.isMouseButtonDown(rl.MouseButton.mouse_button_left)) {
            switch (project.currentTool) {
                props.Tool.Brush => try canvasDraw(project, mouse),
                props.Tool.Eraser => try canvasDraw(project, mouse),
                // props.Tool.Paint => try prePaint(project, mouse),
                else => return
            }
        } 
    }
}
// preps input for draw function in ProjectProps
pub fn canvasDraw(project: props.ProjectProps, mouse: Mouse) !void{
    const point = props.Point{
        .x = mouse.x,
        .y = mouse.y,
        .color = project.currentColor,
    };
    try project.draw(point);
}

pub fn canvasPaint(project: props.ProjectProps, mouse: Mouse) !void {
    _ = project;
    _ = mouse;
    // TODO
}
