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

// Find and return the concatenation of the "size" number of greatest digits in the string as a number.
fn findHighestJoltage(comptime size: u8, bank: []const u8) u64 {
    var batteries = [_]u8{0} ** size;

    for (bank) |digit| {
        const value = digit - '0';

        var i: u8 = 0;
        while (i < size - 1) : (i += 1) {
            // Slowly shift stronger batteries to the front, popping out batteries that are weaker.
            if (batteries[i] < batteries[i + 1]) {
                // For future reference, be careful about going to recursion too quickly.
                // This could have easily been accomplished inside the loop, but I don't have time to fix it.
                // Time to just use a break statement instead.
                shiftBatteries(i, size, &batteries);
                break;
            }
        }
        if (batteries[size - 1] < value) {
            batteries[size - 1] = value;
        }
    }

    var joltage: u64 = 0;
    for (batteries) |battery| {
        joltage *= 10;
        joltage += battery;
    }

    return joltage;
}

fn shiftBatteries(index: u8, size: u8, batteries: []u8) void {
    if (index >= size - 1) {
        batteries[size - 1] = 0;
        return;
    }
    batteries[index] = batteries[index + 1];
    shiftBatteries(index + 1, size, batteries);
}

pub fn main() !void {
    const input = try readFile(allocator, "input");
    defer allocator.free(input);

    var banks = std.mem.splitAny(u8, input, "\n");
    var sum: u64 = 0;

    while (banks.next()) |bank| {
        if (bank.len == 0) continue;
        const value = findHighestJoltage(12, bank);
        printf("Bank: {s}\nValue: {d}\n", .{bank, value});
        sum += value;
    }

    printf("Sum: {d}\n", .{sum});

}


const expect = std.testing.expect;
test "Example One" {
    const banks = [_]u64{
        findHighestJoltage(2, "987654321111111"),
        findHighestJoltage(2, "811111111111119"),
        findHighestJoltage(2, "234234234234278"),
        findHighestJoltage(2, "818181911112111"),
    };

    printf("[{d} {d} {d} {d}]\n", .{banks[0], banks[1], banks[2], banks[3]});

    try expect(banks[0] == 98);
    try expect(banks[1] == 89);
    try expect(banks[2] == 78);
    try expect(banks[3] == 92);

    var sum: u64 = banks[0];
    sum += banks[1];
    sum += banks[2];
    sum += banks[3];
    try expect(sum == 357);

}

test "Example Two" {
    const banks = [_]u64{
        findHighestJoltage(12, "987654321111111"),
        findHighestJoltage(12, "811111111111119"),
        findHighestJoltage(12, "234234234234278"),
        findHighestJoltage(12, "818181911112111"),
    };

    printf("[{d} {d} {d} {d}]\n", .{banks[0], banks[1], banks[2], banks[3]});

    try expect(banks[0] == 987654321111);
    try expect(banks[1] == 811111111119);
    try expect(banks[2] == 434234234278);
    try expect(banks[3] == 888911112111);

    var sum: u64 = banks[0];
    sum += banks[1];
    sum += banks[2];
    sum += banks[3];
    try expect(sum == 3121910778619); 
}

