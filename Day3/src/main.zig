const std = @import("std");

const File = std.fs.File;
const stdout = File.stdout();

const allocator = std.heap.page_allocator;


fn printf(comptime format: []const u8, args: anytype) void {
    std.debug.print(format, args);
}

/// Read the file into a heap-allocated string, then close it.
fn readFile(gpa: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        std.debug.print("Error reading file {s}\n", .{@errorName(err)});
        return err;
    };
    defer file.close();

    var reader = file.reader(&.{});
    const size = try reader.getSize();
    const contents = try reader.interface.readAlloc(gpa, size);
    return contents;
}

// Find and return the concatenation of the two greatest digits in the string as a number.
fn findHighestJoltage(bank: []const u8) u8 {
    var left: u8 = 0;
    var right: u8 = 0;

    for (bank) |digit| {
        const value = digit - '0';
        if (right > left) {
            left = right;
            right = value;
        } else if (value > right) {
            right = value;
        }
    }
    const joltage = left * 10 + right;
    return joltage;
}

pub fn main() !void {
    const input = try readFile(allocator, "input");
    defer allocator.free(input);

    var banks = std.mem.splitAny(u8, input, "\n");
    var sum: u32 = 0;

    while (banks.next()) |bank| {
        if (bank.len == 0) continue;
        const value = findHighestJoltage(bank);
        printf("Bank: {s}\nValue: {d}\n", .{bank, value});
        sum += value;
    }

    printf("Sum: {d}\n", .{sum});

}


const expect = std.testing.expect;
test "Example One" {
    const banks = [_]u8{
        findHighestJoltage("987654321111111"),
        findHighestJoltage("811111111111119"),
        findHighestJoltage("234234234234278"),
        findHighestJoltage("818181911112111"),
    };

    printf("[{d} {d} {d} {d}]\n", .{banks[0], banks[1], banks[2], banks[3]});

    try expect(banks[0] == 98);
    try expect(banks[1] == 89);
    try expect(banks[2] == 78);
    try expect(banks[3] == 92);

    var sum: u32 = banks[0];
    sum += banks[1];
    sum += banks[2];
    sum += banks[3];
    try expect(sum == 357);

}

