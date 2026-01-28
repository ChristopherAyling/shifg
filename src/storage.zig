const std = @import("std");

pub const Quat = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    pub fn identity() Quat {
        return Quat{ .x = 0, .y = 0, .z = 0, .w = 1 };
    }
};

pub const V3 = struct {
    x: f32,
    y: f32,
    z: f32,
    pub fn init(x: f32, y: f32, z: f32) V3 {
        return V3{ .x = x, .y = y, .z = z };
    }
    pub fn zeros() V3 {
        return V3{ .x = 0, .y = 0, .z = 0 };
    }

    pub fn ones() V3 {
        return V3{ .x = 1, .y = 1, .z = 1 };
    }

    pub fn somes(n: f32) V3 {
        return V3{ .x = n, .y = n, .z = n };
    }

    pub fn print(self: V3) void {
        std.log.debug("V3: {d} {d} {d}", .{ self.x, self.y, self.z });
    }

    pub fn add(self: V3, other: V3) V3 {
        return V3{ .x = self.x + other.x, .y = self.y + other.y, .z = self.z + other.z };
    }

    pub fn mul(self: V3, other: V3) V3 {
        return V3{ .x = self.x * other.x, .y = self.y * other.y, .z = self.z * other.z };
    }

    pub fn dot(self: V3, other: V3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn div(self: V3, other: V3) V3 {
        return V3{ .x = self.x / other.x, .y = self.y / other.y, .z = self.z / other.z };
    }

    pub fn sub(self: V3, other: V3) V3 {
        return V3{ .x = self.x - other.x, .y = self.y - other.y, .z = self.z - other.z };
    }

    pub fn neg(self: V3) V3 {
        return V3{ .x = -self.x, .y = -self.y, .z = -self.z };
    }

    pub fn cross(self: V3, other: V3) V3 {
        return V3{ .x = self.y * other.z - self.z * other.y, .y = self.z * other.x - self.x * other.z, .z = self.x * other.y - self.y * other.x };
    }

    pub fn normalize(self: V3) V3 {
        return self.div(V3.somes(self.length()));
    }

    pub fn length(self: V3) f32 {
        return @sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    pub fn reflect(self: V3, normal: V3) V3 {
        // I - 2*dot(N,I)*N
        const dotp = V3.somes(self.dot(normal));
        const dot_2 = dotp.mul(V3.somes(2));
        const dot_2_n = dot_2.mul(normal);
        return self.sub(dot_2_n);
    }
};
