const std = @import("std");

const allocator = std.heap.page_allocator;

const File = std.fs.File;
const stdout = File.stdout();

fn printf(comptime format: []const u8, args: anytype) void {
    std.debug.print(format, args);
}

// Read the file into a heap-allocated string, then close it.
fn readFile(gpa: std.mem.Allocator, path: []const u8) ![]u8 {
    const cwd = std.fs.cwd();
    const file = cwd.openFile(path, .{}) catch |err| {
        std.debug.print("Failed to open file {s}\n", .{@errorName(err)});
        return err;
    };
    defer file.close();

    var reader = file.reader(&.{});
    const size = try reader.getSize();
    const contents = try reader.interface.readAlloc(gpa, size);
    return contents;
}

// Find IDs made of a sequence of digits repeated twice.
fn findInvalidIDsOne(idList: *std.ArrayList(u64), gpa: std.mem.Allocator, input: []const u8) !void {
    var rangeIterator = std.mem.splitAny(u8, input, ",\n");
    while (rangeIterator.next()) |range| {
        // Remove empty lines
        if (std.mem.eql(u8, range, "")) continue;
        // printf("Range: {s}\n", .{range});

        var iter = std.mem.splitAny(u8, range, "-");
        const min = iter.first();
        const max = iter.next() orelse "0";

        var index = try std.fmt.parseInt(u64, min, 0);
        const end = try std.fmt.parseInt(u64, max, 0);
        while (index <= end) : (index += 1) {
            // Find the place of the middle digit.
            const log = std.math.log10_int(index);
            // All values with an odd number of digits are valid.
            if (log % 2 == 0) {
                index = std.math.pow(u64, 10, log + 1);
                continue;
            }

            // If the first half of digits equal the second half, append the ID.
            const middle = std.math.pow(u64, 10, log / 2 + 1);
            if (index / middle == index % middle) {
                try idList.*.append(gpa, index);
            }
        }
    }
}

// Find IDs that are made of a sequence of digits repeated at least twice.
fn findInvalidIDsTwo(idList: *std.ArrayList(u64), gpa: std.mem.Allocator, input: []const u8) !void {
    var rangeIterator = std.mem.splitAny(u8, input, ",\n");
    while (rangeIterator.next()) |range| {
        // Remove empty lines
        if (std.mem.eql(u8, range, "")) continue;
        // printf("Range: {s}\n", .{range});

        var iter = std.mem.splitAny(u8, range, "-");
        const min = iter.first();
        const max = iter.next() orelse "0";

        var index = try std.fmt.parseInt(u64, min, 0);
        const end = try std.fmt.parseInt(u64, max, 0);
        while (index <= end) : (index += 1) {
            const invalid = checkInvalidIDTwo(index);
            if (invalid) {
                try idList.*.append(gpa, index);
            }
        }
    }
}

fn checkInvalidIDTwo(id: u64) bool {
    const log = std.math.log10_int(id);
    const digits = log + 1;

    // Progressively increase the number of digits in the pattern.
    var patternSize: u32 = 1;
    pattern: while (patternSize <= digits / 2) : (patternSize += 1) {
        // The pattern size must be a factor of the number of digits in the ID.
        if (digits % patternSize != 0) continue;


        const pattern = id / std.math.pow(u64, 10, digits - patternSize);

        var pos = digits - patternSize;
        while (pos >= patternSize) : (pos -= patternSize) {
            const nextSequence = (id % std.math.pow(u64, 10, pos)) / std.math.pow(u64, 10, pos - patternSize);
            if (nextSequence != pattern) {
                continue :pattern;
            }
        }

        // Return true if the pattern makes it through the previous loop.
        return true;
    }

    return false;
}

pub fn main() !void {
    const input = try readFile(allocator, "input");
    defer allocator.free(input);

    var invalidIDs = try std.ArrayList(u64).initCapacity(allocator, 10);
    defer invalidIDs.deinit(allocator);
    try findInvalidIDsTwo(&invalidIDs, allocator, input);

    var sum: u64 = 0;
    for (invalidIDs.items) |id| {
        sum += id;
    }

    printf("Sum: {d}\n", .{sum});
}


const expect = std.testing.expect;
test "Example Test One" {
    const input = 
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,
        \\1698522-1698528,446443-446449,38593856-38593862,565653-565659,
        \\824824821-824824827,2121212118-2121212124
    ;

    const gpa = std.testing.allocator;

    var invalidIDs = try std.ArrayList(u64).initCapacity(allocator, 10); 
    try findInvalidIDsOne(&invalidIDs, gpa, input);
    defer invalidIDs.deinit(allocator);

    var sum: u64 = 0;
    for (invalidIDs.items) |id| {
        sum += id;
    }

    // printf("Sum: {d}\n", .{sum});

    try expect(sum == 1227775554);
}

test "Check Two" {
    try expect(!checkInvalidIDTwo(95));
    try expect(checkInvalidIDTwo(99));
    try expect(!checkInvalidIDTwo(110));
    try expect(checkInvalidIDTwo(111));
}

test "Example Test Two" {
    const input = 
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,
        \\1698522-1698528,446443-446449,38593856-38593862,565653-565659,
        \\824824821-824824827,2121212118-2121212124
    ;

    const gpa = std.testing.allocator;

    var invalidIDs = try std.ArrayList(u64).initCapacity(gpa, 10); 
    try findInvalidIDsTwo(&invalidIDs, gpa, input);
    defer invalidIDs.deinit(gpa);

    var sum: u64 = 0;
    for (invalidIDs.items) |id| {
        sum += id;
    }

    printf("Sum: {d}\n", .{sum});

    try expect(sum == 4174379265);
}

