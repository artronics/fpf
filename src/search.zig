const std = @import("std");
const testing = std.testing;
const expect = testing.expect;

pub const Search = struct {
    const Self = @This();

    pub fn search(self: Self, text: []const u8, pattern: []const u8) !?Score {
        _ = self;
        var score = Score{};

        var i = text.len;
        var j = pattern.len;
        var last_pj: u8 = undefined;

        while (i > 0 and j > 0) : (i -= 1) {
            const ti = text[i - 1];
            const pj = pattern[j - 1];

            if (ti == pj) {
                score.copy();
                last_pj = pj;
                j -= 1;
            } else if (last_pj == ti) {
                score.copy();
            }
        }

        return if (j == 0) score else null;
    }

    const Score = struct {
        qc: isize = 1,
        _copy: isize = 0,

        inline fn copy(self: *Score) void {
            self._copy += 1;
        }
        inline fn score(self: Score) isize {
            return self._copy * self.qc;
        }
    };

    const boundary_set = [_]u8{ '.', '_', ' ', '-', '/', '\\' };
    inline fn in_boundary_set(ch: u8) bool {
        inline for (boundary_set) |b| {
            if (ch == b) return true;
        }
        return false;
    }

    const isLower = std.ascii.isLower;
    const isUpper = std.ascii.isUpper;
    fn is_start_boundary(text: []const u8, i: usize) bool {
        const current = text[i];
        if (i == 0) {
            return !in_boundary_set(current);
        }

        const prev = text[i - 1];
        return (isUpper(current) and isLower(prev)) or in_boundary_set(prev);
    }
    fn is_end_boundary(text: []const u8, i: usize) bool {
        const current = text[i];
        if (i == text.len - 1) {
            return !in_boundary_set(current);
        }

        const next = text[i + 1];
        return (isLower(current) and isUpper(next)) or in_boundary_set(next);
    }

    test "is start or end of a boundary?" {
        var s = is_start_boundary("a", 0);
        var e = is_end_boundary("a", 0);
        try expect(s and e);

        s = is_start_boundary("_", 0);
        e = is_end_boundary("_", 0);
        try expect((s or e) == false);

        s = is_start_boundary("Foo", 0);
        e = is_end_boundary("Foo", 2);
        try expect(s and e);

        s = is_start_boundary("Foo", 2);
        e = is_end_boundary("Foo", 0);
        try expect((s or e) == false);

        s = is_start_boundary("FooBar", 3);
        e = is_end_boundary("FooBar", 2);
        try expect(s and e);

        s = is_start_boundary("FooBar", 2);
        e = is_end_boundary("FooBar", 3);
        try expect((s or e) == false);

        s = is_start_boundary("foo_bar", 4);
        e = is_end_boundary("foo_bar", 2);
        try expect(s and e);

        s = is_start_boundary("foo_bar", 3);
        e = is_end_boundary("foo_bar", 3);
        try expect((s or e) == false);

        s = is_start_boundary("BaR", 2);
        e = is_end_boundary("BaR", 2);
        try expect(s and e);
    }
};

test "match" {
    var s = Search{};

    var r = try s.search("", "");
    try expect(r != null);
    r = try s.search("a", "");
    try expect(r != null);

    r = try s.search("a", "a");
    try expect(r != null);

    r = try s.search("b", "a");
    try expect(r == null);

    r = try s.search("xbyaz", "ba");
    try expect(r != null);

    r = try s.search("xbyaz", "ab");
    try expect(r == null);
}

test "score" {
    var s = Search{};

    { // Copy
        var r = try s.search("", "");
        try expect(r.?.score() == 0);
        r = try s.search("a", "");
        try expect(r.?.score() == 0);

        r = try s.search("axy", "a");
        try expect(r.?._copy == 1);
        r = try s.search("xya", "a");
        try expect(r.?._copy == 1);

        r = try s.search("cbbaa", "cba");
        try expect(r.?._copy == 5);
        // Last pj only counts once because search is terminated when j = 0
        r = try s.search("bbaa", "ba");
        try expect(r.?._copy == 3);

        r = try s.search("baxyax", "ba");
        try expect(r.?._copy == 3);
    }
}
