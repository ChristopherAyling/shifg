const std = @import("std");
const ThingPool = @import("things.zig").ThingPool;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: thingdump <thingfile>\n", .{});
        return;
    }

    const path = args[1];

    const things = try allocator.create(ThingPool);
    defer allocator.destroy(things);
    things.* = .{};

    things.from_file(path);

    var slot: usize = 0;
    for (&things.things) |*thing| {
        if (thing.active) {
            const name_slice = std.mem.sliceTo(&thing.name, 0);
            std.debug.print("[{d:4}] {s: <8} \"{s}\" x={d} y={d} sprite={s} rep={d}\n", .{
                slot,
                @tagName(thing.kind),
                name_slice,
                thing.x,
                thing.y,
                @tagName(thing.spritekey),
                thing.reputation,
            });
        }
        slot += 1;
    }
}
