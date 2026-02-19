// Simple test function in Zig
// This will be compiled to a static library and called from N-API

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub export fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

// String length function
pub export fn string_length(ptr: [*:0]u8) usize {
    var len: usize = 0;
    while (ptr[len] != 0) : (len += 1) {}
    return len;
}
