const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const address = std.net.Address.parseIp4("127.0.0.1", 3000) catch unreachable;
    var server = try address.listen(.{ .reuse_address = true });
    defer server.deinit();

    std.log.info("Serving HTTP on http://127.0.0.1:3000/", .{});

    while (true) {
        const conn = server.accept() catch |err| {
            std.log.err("accept error: {}", .{err});
            continue;
        };

        handleConnection(allocator, conn) catch |err| {
            std.log.err("request error: {}", .{err});
        };
        conn.stream.close();
    }
}

fn handleConnection(allocator: std.mem.Allocator, conn: std.net.Server.Connection) !void {
    var read_buf: [8192]u8 = undefined;
    var write_buf: [8192]u8 = undefined;

    var reader = conn.stream.reader(&read_buf);
    var writer = conn.stream.writer(&write_buf);

    var http_server = std.http.Server.init(reader.interface(), &writer.interface);

    var req = try http_server.receiveHead();
    try handleRequest(allocator, &req);
}

fn handleRequest(allocator: std.mem.Allocator, req: *std.http.Server.Request) !void {
    const path = req.head.target;

    // Security: reject paths with ..
    if (std.mem.indexOf(u8, path, "..") != null) {
        try req.respond("Invalid path", .{ .status = .bad_request });
        return;
    }

    // Determine file path - serve from zig-out/web/
    const clean_path = if (std.mem.eql(u8, path, "/")) "/index.html" else path;
    const file_path = try std.fmt.allocPrint(allocator, "zig-out/web{s}", .{clean_path});
    defer allocator.free(file_path);

    // Try to open and serve the file
    const file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            try req.respond("404 Not Found", .{ .status = .not_found });
        } else {
            try req.respond("500 Internal Server Error", .{ .status = .internal_server_error });
        }
        return;
    };
    defer file.close();

    // Read entire file into memory
    const stat = try file.stat();
    const file_size = stat.size;
    const content = try allocator.alloc(u8, file_size);
    defer allocator.free(content);
    const bytes_read = try file.readAll(content);

    // Get content type
    const content_type = getContentType(clean_path);

    // Send response
    try req.respond(content[0..bytes_read], .{
        .status = .ok,
        .extra_headers = &.{
            .{ .name = "content-type", .value = content_type },
            .{ .name = "cache-control", .value = "no-cache" },
        },
    });
}

fn getContentType(path: []const u8) []const u8 {
    const ext = std.fs.path.extension(path);
    if (std.mem.eql(u8, ext, ".html")) return "text/html; charset=utf-8";
    if (std.mem.eql(u8, ext, ".js")) return "application/javascript";
    if (std.mem.eql(u8, ext, ".css")) return "text/css";
    if (std.mem.eql(u8, ext, ".wasm")) return "application/wasm";
    if (std.mem.eql(u8, ext, ".json")) return "application/json";
    if (std.mem.eql(u8, ext, ".png")) return "image/png";
    if (std.mem.eql(u8, ext, ".jpg") or std.mem.eql(u8, ext, ".jpeg")) return "image/jpeg";
    if (std.mem.eql(u8, ext, ".gif")) return "image/gif";
    if (std.mem.eql(u8, ext, ".svg")) return "image/svg+xml";
    if (std.mem.eql(u8, ext, ".ico")) return "image/x-icon";
    if (std.mem.eql(u8, ext, ".mp3")) return "audio/mpeg";
    if (std.mem.eql(u8, ext, ".wav")) return "audio/wav";
    if (std.mem.eql(u8, ext, ".ogg")) return "audio/ogg";
    return "application/octet-stream";
}
