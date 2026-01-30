pub const LEVEL_W = 512;
pub const LEVEL_H = 512;

pub const NATIVE_W = 160;
pub const NATIVE_H = 144;
pub const SCALE = 4;
pub const UPSCALED_W = NATIVE_W * SCALE;
pub const UPSCALED_H = NATIVE_H * SCALE;

pub const NATIVE_W_HALF = @divFloor(NATIVE_W, 2);
pub const NATIVE_H_HALF = @divFloor(NATIVE_H, 2);

pub const FONT_W = 3;
pub const FONT_H = 5;
