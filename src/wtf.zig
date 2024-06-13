const std = @import("std");

const TestStruct = struct {
    piss: i32,

    pub fn shitItOut(self: *TestStruct) !void {
        std.debug.print("{}", .{self.piss});
    }
};

pub fn initializer(num: i32) !TestStruct {
    const strucc = TestStruct{ .piss = num} ;
    return strucc;
}