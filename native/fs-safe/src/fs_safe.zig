const std = @import("std");
const c = @cImport({
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
});

export fn isPathSafe(resolved_path: [*:0]const u8, root_with_sep: [*:0]const u8) c_int {
    const rpath = std.mem.sliceTo(resolved_path, 0);
    const root = std.mem.sliceTo(root_with_sep, 0);
    if (std.mem.startsWith(u8, rpath, root)) {
        return 1;
    }
    return 0;
}

export fn openFile(path: [*:0]const u8, no_follow: c_int) c_int {
    const p = std.mem.sliceTo(path, 0);
    var flags: c_int = c.O_RDONLY;
    if (no_follow != 0) {
        flags |= c.O_NOFOLLOW;
    }
    
    const mode: c_uint = 0;
    const fd = c.open(p, flags, mode);
    return fd;
}

export fn closeFile(fd: c_int) c_int {
    return c.close(fd);
}

export fn freeMem(ptr: ?*anyopaque) void {
    _ = ptr;
}
