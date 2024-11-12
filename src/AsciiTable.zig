const std = @import("std");

const Self = @This();

// TODO: Create a list of lists of strings
// outer list represents every row and column
// inner list each represent a row themselves and each index represents a column

allocator: std.mem.Allocator = undefined,
lists: std.ArrayList([][]const u8) = undefined,

/// ! DO NOT MODIFY DIRECTLY
columns_count: usize = undefined,

/// ! DO NOT MODIFY DIRECTLY
// TODO: each index holds a usize that represents the width of the column in char lengths
// Make sure to check and always make sure its length is the same as columns_count
//columns_widths: []usize = undefined,

// Chars that make-up the table borders
corner_char: u8 = '+',
horizontal_char: u8 = '-',
vertical_char: u8 = '|',
// Probably not needed (instead return through methods):
// rows_count: usize = undefined,
// columns_count: usize = undefined,

pub fn init(allocator: std.mem.Allocator, column_count: usize) Self {
    return .{
        .allocator = allocator,
        .lists = std.ArrayList([][]const u8).init(allocator),
        .columns_count = column_count,
    };
}

pub fn deinit(self: *Self) void {
    self.lists.deinit();
}

// NOTE: to add a row it must be done in a similar manner as the following:
// var table_entry = [_][]const u8{ "a", "b" };
// try ascii_table.addRow(&table_entry);
pub fn addRow(self: *Self, row: [][]const u8) !void {
    if (row.len != self.columns_count) {
        std.debug.print("ERROR: Row length does not match columns count\n", .{});
        return error.InvalidRowLength;
    }

    try self.lists.append(row);
}

// TODO: eventually seperate out into two methods: GetAsciiTableBuff() and GetAsciiTableAlloc()
/// Both writes to the buffer or returns a slice of the exact length written (the exact length of the ascii table returned)
pub fn GetAsciiTable(self: *Self, buffer: []u8) []const u8 {
    var ascii_table_stream = std.io.fixedBufferStream(buffer);
    const ascii_table_writer = ascii_table_stream.writer();

    for (0.., self.lists.items) |i, row| {
        for (0.., row) |j, column_value| {
            std.debug.print("column: {s}\ni: {d}\n", .{ column_value, i });
            if (i == 0 and j == 0) {
                ascii_table_writer.print("{c} {c}{c}{c} {c} ", .{ self.corner_char, self.horizontal_char, self.horizontal_char, self.horizontal_char, self.corner_char }) catch unreachable;
                ascii_table_writer.print("{c}{c}{c} {c}\n", .{ self.horizontal_char, self.horizontal_char, self.horizontal_char, self.corner_char }) catch unreachable;
            }

            ascii_table_writer.print("{c}  {s}  ", .{ self.vertical_char, column_value }) catch unreachable;
        }

        ascii_table_writer.print("{c}\n", .{self.vertical_char}) catch unreachable;
    }
    ascii_table_writer.print("{c} {c}{c}{c} {c} ", .{ self.corner_char, self.horizontal_char, self.horizontal_char, self.horizontal_char, self.corner_char }) catch unreachable;
    ascii_table_writer.print("{c}{c}{c} {c}", .{ self.horizontal_char, self.horizontal_char, self.horizontal_char, self.corner_char }) catch unreachable;

    // Return a slice of the buffer that was written to
    return buffer[0..ascii_table_stream.pos];
}

// TODO: pub fn GetAsciiTableBuff(self: *Self, buffer: []u8) []const u8 {}
// TODO: pub fn GetAsciiTableAlloc(self: *Self) []const u8 {}
// TODO: pub fn rowCount(self: *Self) usize { }
// TODO: pub fn columnCount(self: *Self) usize { }

test "Adding rows to the table" {
    const allocator = std.testing.allocator;
    var table = init(allocator, 2);
    defer table.deinit();

    var row1 = [_][]const u8{ "a", "b" };
    var row2 = [_][]const u8{ "c", "d" };
    var row3 = [_][]const u8{"e"};
    var row4 = [_][]const u8{ "f", "g", "h", "i" };

    try table.addRow(&row1); // OK
    try table.addRow(&row2); // OK
    try std.testing.expectError(error.InvalidRowLength, table.addRow(&row3)); // ERROR
    try std.testing.expectError(error.InvalidRowLength, table.addRow(&row4)); // ERROR

    std.debug.print("Table:\n{s}\n", .{table.lists.items});
}

test "Memory scope" {
    const allocator = std.testing.allocator;
    var table = init(allocator, 2);
    defer table.deinit();

    {
        var row1 = [_][]const u8{ "a", "b" };
        try table.addRow(&row1); // OK
    }

    try std.testing.expectEqualStrings("a", table.lists.items[0][0]);
    try std.testing.expectEqualStrings("b", table.lists.items[0][1]);
}

test "GetAsciiTable" {
    const allocator = std.testing.allocator;
    var table = init(allocator, 2);
    defer table.deinit();

    var row1 = [_][]const u8{ "a", "b" };
    var row2 = [_][]const u8{ "c", "d" };

    try table.addRow(&row1); // OK
    try table.addRow(&row2); // OK

    const expected_table =
        \\+ --- + --- +
        \\|  a  |  b  |
        \\|  c  |  d  |
        \\+ --- + --- +
    ;

    var buffer: [2048]u8 = undefined;
    const generated_table = table.GetAsciiTable(&buffer);
    std.debug.print("Generated Table:\n{s}\n", .{generated_table});

    try std.testing.expectEqualStrings(expected_table, generated_table);
}

// TODO:
// test "Printing ascii table with two columns" {
//     const allocator = std.testing.allocator;
//     var table = init(allocator, 2);
//     defer table.deinit();
//
//     var row1 = [_][]const u8{ "a", "b" };
//     var row2 = [_][]const u8{ "c", "d" };
//
//     try table.addRow(&row1); // OK
//     try table.addRow(&row2); // OK
//
//     std.testing.expectEqualStrings("+ ---", table.GetAsciiTable());
//
//     std.debug.print("Table:\n{s}\n", .{table.GetAsciiTable()});
// }
//
// test "Printing ascii table with three columns" {
//     const allocator = std.testing.allocator;
//     var table = init(allocator, 3);
//     defer table.deinit();
//
//     var row1 = [_][]const u8{ "a", "b", "c" };
//     var row2 = [_][]const u8{ "d", "e", "f" };
//
//     try table.addRow(&row1); // OK
//     try table.addRow(&row2); // OK
//
//     std.debug.print("Table:\n{s}\n", .{table.GetAsciiTable()});
// }
