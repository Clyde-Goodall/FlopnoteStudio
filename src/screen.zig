// screen sizing config copied over from rust version
pub const SCALE_SIZE: i32 = 10;
pub const CLUSTER_SIZE: i32 = 3;
pub const SCALAR: i32 = SCALE_SIZE * CLUSTER_SIZE;


// change these to impact panel sizings

// canvas area
pub const CANVAS_UNIT_W: f32 = 29;
pub const CANVAS_UNIT_H: f32 = 15;

// toolbar region
pub const TOOLBAR_UNIT_W: i32 = 4;
pub const TOOLBAR_UNIT_H: i32 = 15;

// frame(s) playback and scrollable region
// const DEFAULT_FRAME_PANEL_SIZE_W: f32 = 20.0;
pub const TIMELINE_UNIT_W: i32 = 33;
pub const TIMELINE_UNIT_H: i32 = 5;

// playback control box
// const DEFAULT_PLAYBACK_CTRL_W: f32 = 20.0;
// const DEFAULT_PLAYBACK_CTRL_H: f32 = 5.0;

// final calculation of window dimensions
// TODO: logic that takes all vertical/horizontal combinations for all component arrangement, 
// and chooses the largest sum so there's no clipping
pub const screenWidth = (SCALAR * (CANVAS_UNIT_W + TOOLBAR_UNIT_W));
pub const screenHeight = (SCALAR * (TOOLBAR_UNIT_H + TIMELINE_UNIT_H));

pub const CANVAS_REAL_WIDTH = SCALAR * CANVAS_UNIT_W;
pub const CANVAS_REAL_HEIGHT = SCALAR * CANVAS_UNIT_H;
