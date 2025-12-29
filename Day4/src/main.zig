const std = @import("std");

const File = std.fs.File;

const allocator = std.heap.page_allocator;

fn printf(comptime format: []const u8, args: anytype) void {
    std.debug.print(format, args);
}

fn readFile(gpa: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        printf("Error opening file: {s}\n", .{@errorName(err)});
        return err;
    };

    var reader = file.reader(&.{});
    const size = try reader.getSize();

    const contents = try reader.interface.readAlloc(gpa, size);
    return contents;
}

const Dimensions = struct {
    width: usize,
    length: usize,
};

// Replace all accessible rolls with 'X' in string.
fn markAccessibleRolls(input: *[]u8, size: Dimensions) void {

    var j: i32 = 0;

    // Account for newline characters
    const trueWidth = size.width + 1;

    while (j < size.length) : (j += 1) {
        var i: i32 = 0;
        while (i < size.width) : (i += 1) {
            const index = @abs(j) * trueWidth + @abs(i);
            const char: u8 = input.*[index];
            if (char != '@') {
                continue;
            }

            const accessible = checkSurroundingCells(input.*, i, j, size);
            if (accessible) {
                input.*[index] = 'X';
            }
        }
    }
}

fn checkSurroundingCells(input: []const u8, posX: i32, posY: i32, size: Dimensions) bool {
    var count: u8 = 0;
    const trueWidth = size.width + 1;

    var j: i8 = -1;
    while (j <= 1) : (j += 1) {
        const y = posY + j;
        if (y < 0 or y >= size.length) {
            continue;
        }
        var i: i8 = -1;
        while (i <= 1) : (i += 1) {
            if (i == 0 and j == 0) continue;
            const x = posX + i;
            if (x < 0 or x >= size.width) {
                continue;
            }

            const index = @abs(y) * trueWidth + @abs(x);

            const char = input[index];
            if (char == '@' or char == 'X') {
                count += 1;
            }
        }
    }
    return count < 4;
}

// Count the number of X's in string.
fn countAccessibleRolls(input: []const u8, size: Dimensions) u32 {
    var total: u32 = 0;

    var j: i32 = 0;

    // Account for newline characters
    const trueWidth = size.width + 1;

    while (j < size.length) : (j += 1) {
        var i: i32 = 0;
        while (i < size.width) : (i += 1) {
            if (input[@abs(j) * trueWidth + @abs(i)] == 'X') {
                total += 1;
            }
        }
    }

    return total;
}

fn removeAccessibleRolls(input: *[]u8) void {
    for (0..input.len) |i| {
        if (input.*[i] == 'X') {
            input.*[i] = '.';
        }
    }
}

fn getDimensions(input: []const u8) Dimensions {
    const width = std.mem.indexOf(u8, input, "\n") orelse 0;
    const height = std.mem.count(u8, input, "\n");

    return Dimensions{
        .width = width,
        .length = height,
    };
}

fn partOne(input: *[]u8, dimensions: Dimensions) u32 {
    markAccessibleRolls(input, dimensions);
    return countAccessibleRolls(input.*, dimensions);
}

fn partTwo(input: *[]u8, dimensions: Dimensions) u32 {
    var total: u32 = 0;
    while (true) {
        markAccessibleRolls(input, dimensions);
        const count = countAccessibleRolls(input.*, dimensions);
        if (count > 0) {
            total += count;
            removeAccessibleRolls(input);
        } else {
            break;
        }
    }
    return total;
}

pub fn main() !void {
    var input = try readFile(allocator, "input");
    defer allocator.free(input);

    const dimensions = getDimensions(input);


    const total = partOne(&input, dimensions);
    printf("Total: {d}\n", .{total});

    const secondTotal = partTwo(&input, dimensions);
    printf("Part two total: {d}\n", .{secondTotal});
}

const expect = std.testing.expect;

test "Example One" {
    const input = 
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
        \\
    ;
    var str: []u8 = try std.testing.allocator.alloc(u8, input.len);
    defer std.testing.allocator.free(str);
    for (0..str.len) |i| {
        str[i] = input[i];
    }

    const dimensions = getDimensions(str);
    printf("Width: {d} Height: {d}\n", .{dimensions.width, dimensions.length});

    const total = partOne(&str, dimensions);

    printf("{d}\n", .{total});
    try expect(total == 13);
}

test "Example Two" {
    const input = 
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
        \\
    ;
    var str: []u8 = try std.testing.allocator.alloc(u8, input.len);
    defer std.testing.allocator.free(str);
    for (0..str.len) |i| {
        str[i] = input[i];
    }

    const dimensions = getDimensions(str);

    const total = partTwo(&str, dimensions);

    printf("Total: {d}\n", .{total});

    try expect(total == 43);
}

