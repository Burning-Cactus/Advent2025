const std = @import("std");

const File = std.fs.File;

const stdout = File.stdout();
const stdin = File.stdin();

const allocator = std.heap.page_allocator;

fn println(comptime text: []const u8, args: anytype) void {
    var buf: [64]u8 = undefined;
    const output = std.fmt.bufPrint(&buf, text, args) catch {return;};
    _ = stdout.write(output) catch {};
    _ = stdout.write("\n") catch {};
}

fn readFile(gpa: std.mem.Allocator, path: []const u8) ![]u8 {
    const cwd = std.fs.cwd();
    const file = cwd.openFile(path, .{}) catch |err| {
        std.debug.print("Failed to open file: {s}\n", .{@errorName(err)});
        return err;
    };
    defer file.close();
    var reader = file.reader(&.{});
    const size = try reader.getSize();

    const contents = try reader.interface.readAlloc(gpa, size);
    return contents;
}

fn rotateRight(dial: *i32, distance: i32) u32 {
    var cycles = @abs(@divFloor(distance, 100));
    dial.* += @mod(distance, 100);
    if (dial.* >= 100) {
        cycles += 1;
    }
    dial.* = @mod(dial.*, 100);
    return cycles;
}

fn rotateLeft(dial: *i32, distance: i32) u32 {
    if (dial.* == 0) dial.* += 100;
    var cycles = @abs(@divFloor(distance, 100));
    dial.* -= @mod(distance, 100);
    if (dial.* <= 0) {
        cycles += 1;
    }
    dial.* = @mod(dial.*, 100);
    return cycles;
}

pub fn main() !void {
   const input = try readFile(allocator, "input");
   defer allocator.free(input);

   var sequences = std.mem.splitAny(u8, input, " \n");

   var dial: i32 = 50;
   var passes: u32 = 0;
   while (sequences.next()) |rotation| {
       if (rotation.len < 2) continue;

       const direction = rotation[0];
       const number = try std.fmt.parseInt(i32, rotation[1..], 0);

       var cycles: u32 = undefined;
       if (direction == 'R') {
           cycles = rotateRight(&dial, number);
       } else {
           cycles = rotateLeft(&dial, number);
       }

       passes += cycles;
   }
   println("Passes: {d}", .{passes});
}

const expect = std.testing.expect;


test "0 + 200" {
    var dial: i32 = 0;
    try expect(2 == rotateRight(&dial, 200));
    try expect(2 == rotateLeft(&dial, 200));
}

test "50 + 250" {
    var dial: i32 = 50;
    const cycles = rotateLeft(&dial, 250);
    std.debug.print("{d}\n", .{cycles});
    try expect(0 == dial);
    try expect(3 == cycles);
}


test "50 + 1000" {
    var dial: i32 = 50;
    try expect(10 == rotateRight(&dial, 1000));
}

test "Default case" {
    var dial: i32 = 50;
    // L68 to 82
    var cycles: u32 = rotateLeft(&dial, 68);
    try expect(dial == 82);
    try expect(cycles == 1);

    // L30 to 52
    cycles += rotateLeft(&dial, 30);
    try expect(dial == 52);
    try expect(cycles == 1);

    // R48 to 0
    cycles += rotateRight(&dial, 48);
    try expect(dial == 0);
    try expect(cycles == 2);

    // L5 to 95
    cycles += rotateLeft(&dial, 5);
    try expect(dial == 95);
    try expect(cycles == 2);

    // R60 to 55
    cycles += rotateRight(&dial, 60);
    try expect(dial == 55);
    try expect(cycles == 3);
    
    // L55 to 0
    cycles += rotateLeft(&dial, 55);
    try expect(dial == 0);
    try expect(cycles == 4);

    // L1 to 99
    cycles += rotateLeft(&dial, 1);
    try expect(dial == 99);
    try expect(cycles == 4);
    
    // L99 to 0
    cycles += rotateLeft(&dial, 99);
    try expect(dial == 0);
    try expect(cycles == 5);

    // R14 to 14
    cycles += rotateRight(&dial, 14);
    try expect(dial == 14);
    try expect(cycles == 5);

    // L82 to 32
    cycles += rotateLeft(&dial, 82);
    try expect(dial == 32);
    try expect(cycles == 6);
}



