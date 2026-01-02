const std = @import("std");
const Day5 = @import("Day5");

const File = std.fs.File;
const ArrayList = std.ArrayList;

const allocator = std.heap.page_allocator;

fn printf(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt, args);
}

fn readFile(gpa: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        printf("Failed to open file at location {s}\n", .{path});
        return err;
    };
    defer file.close();
    var reader = file.reader(&.{});
    const size = try reader.getSize();
    const contents = try reader.interface.readAlloc(gpa, size);
    return contents;
}

pub fn main() !void {
    const input = try readFile(allocator, "input");
    defer allocator.free(input);
    var split = std.mem.splitSequence(u8, input, "\n\n");

    const rangeString = split.next().?;
    var ranges = try parseRanges(allocator, rangeString);
    defer ranges.deinit(allocator);
    var ids = try parseIDs(allocator, split.next().?);
    defer ids.deinit(allocator);


    const totalOne = countValidIDs(ids, ranges);
    printf("Total One: {d}\n", .{totalOne});

    const totalTwo = try countValidIDRanges(allocator, rangeString);
    printf("Total Two: {d}\n", .{totalTwo});

}

const Range = struct {
    min: u64,
    max: u64,
};

fn parseRanges(gpa: std.mem.Allocator, input: []const u8) !ArrayList(Range) {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var ranges = try ArrayList(Range).initCapacity(gpa, 5);
    while (lines.next()) |line| {
        const range = parseRange(line) catch {
            printf("Failed to process a value!", .{});
            continue;
        };
        try ranges.append(gpa, range);
    }
    return ranges;
}

const ParseError = error{ImproperFormat};

// Accepts an input string of format "?-?"
fn parseRange(input: []const u8) !Range {
    var pair = std.mem.splitScalar(u8, input, '-');
    if (pair.peek() == null) {
        return ParseError.ImproperFormat;
    }
    const first = try std.fmt.parseInt(u64, pair.next().?, 10);
    if (pair.peek() == null) {
        return ParseError.ImproperFormat;
    }
    const last = try std.fmt.parseInt(u64, pair.next().?, 10);
    return Range{ .min = first, .max = last };
}

fn parseIDs(gpa: std.mem.Allocator, input: []const u8) !ArrayList(u64) {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var ids = try ArrayList(u64).initCapacity(gpa, input.len / 2);
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const id = try std.fmt.parseInt(u64, line, 10);
        try ids.append(gpa, id);
    }

    return ids;
}

/// Counts all IDs that are within the valid ranges of the passed in array list.
fn countValidIDs(idList: ArrayList(u64), ranges: ArrayList(Range)) u64 {
    var totalValid: u64 = 0;
    outer: for (idList.items) |id| {
        for (ranges.items) |range| {
            if (id >= range.min and id <= range.max) {
                totalValid += 1;
                continue :outer;
            }
        }
    }
    return totalValid;
}

/// Counts all IDs that are valid within the range of IDs.
fn countValidIDRanges(gpa: std.mem.Allocator, input: []const u8) !u64 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var ranges = try ArrayList(Range).initCapacity(gpa, 5);
    defer ranges.deinit(gpa);

    outer: while (lines.next()) |line| {
        var range = try parseRange(line);
        var i: usize = 0;
        while (i < ranges.items.len) {
            const r = ranges.items[i];
            if (range.min >= r.min and range.min <= r.max) {
                range.min = r.max + 1;
                i = 0;
                continue;
            }
            if (range.max >= r.min and range.max <= r.max) {
                range.max = r.min - 1;
                i = 0;
                continue;
            }
            if (range.min < r.min and range.max > r.max) {
                _ = ranges.swapRemove(i);
                continue;
            }

            if (range.min > range.max) {
                continue :outer;
            }

            i += 1;
        }
        try ranges.append(gpa, range);
    }

    const total = blk: {
        var n: u64 = 0;
        for (ranges.items) |range| {
            // Ranges are inclusive of both min and max, so add one.
            const lineTotal: u64 = range.max - range.min + 1;
            n += lineTotal;
        }
        break :blk n;
    };

    return total;
}

const expect = std.testing.expect;

test "Example one" {
    const gpa = std.testing.allocator;
    const input = 
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    ;

    var split = std.mem.splitSequence(u8, input, "\n\n");

    var ranges = try parseRanges(gpa, split.next().?);
    defer ranges.deinit(gpa);
    var ids = try parseIDs(gpa, split.next().?);
    defer ids.deinit(gpa);

    const total = countValidIDs(ids, ranges);

    printf("{d}\n", .{total});
}

test "Example two" {
    const gpa = std.testing.allocator;
    const input = 
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\14-15
    ;

    var ranges = try parseRanges(gpa, input);
    defer ranges.deinit(gpa);

    const total = try countValidIDRanges(gpa, input);

    printf("{d}\n", .{total});
}
