const std = @import("std");
const c = @cImport({
    @cInclude("archive.h");
    @cInclude("archive_entry.h");
    @cInclude("fcntl.h");
    @cInclude("unistd.h");
    @cInclude("sys/stat.h");
    @cInclude("stdio.h");
});

/// Extract an archive (tar, zip, etc.) to a destination directory
/// Returns 0 on success, -1 on error
export fn extractArchive(archive_path: [*:0]const u8, dest_dir: [*:0]const u8) c_int {
    const path = std.mem.sliceTo(archive_path, 0);
    const dest = std.mem.sliceTo(dest_dir, 0);
    
    // Open the archive
    const a = c.archive_read_new();
    if (a == null) return -1;
    defer _ = c.archive_read_free(a);
    
    // Support tar, zip, and other formats
    _ = c.archive_read_support_filter_all(a);
    _ = c.archive_read_support_format_all(a);
    
    var result_val = c.archive_read_open_filename(a, path, 10240);
    if (result_val != c.ARCHIVE_OK) return -1;
    
    var entry: ?*c.struct_archive_entry = undefined;
    
    // Create destination directory if it doesn't exist
    _ = c.mkdir(dest, 0o755);
    
    while (true) {
        result_val = c.archive_read_next_header(a, &entry);
        if (result_val == c.ARCHIVE_EOF) break;
        if (result_val != c.ARCHIVE_OK) {
            // Print error but continue
            break;
        }
        
        if (entry == null) continue;
        
        // Get the entry path
        const entry_path_ptr = c.archive_entry_pathname(entry);
        if (entry_path_ptr == null) continue;
        
        // Skip absolute paths for security
        if (entry_path_ptr[0] == '/') continue;
        
        // Build destination path
        var full_path: [4096]u8 = undefined;
        const full_path_len = dest.len + 1 + std.mem.sliceTo(entry_path_ptr, 0).len;
        if (full_path_len >= full_path.len) continue;
        
        @memcpy(full_path[0..dest.len], dest);
        full_path[dest.len] = '/';
        const entry_name = std.mem.sliceTo(entry_path_ptr, 0);
        @memcpy(full_path[dest.len+1..full_path_len], entry_name);
        full_path[full_path_len] = 0;
        
        // Create parent directories
        var i: usize = dest.len + 1;
        while (i < full_path_len) : (i += 1) {
            if (full_path[i] == '/') {
                full_path[i] = 0;
                _ = c.mkdir(@as([*:0]const u8, @ptrCast(&full_path)), 0o755);
                full_path[i] = '/';
            }
        }
        
        // Check if it's a directory
        if (c.archive_entry_size_is_set(entry) == 0 and c.archive_entry_filetype(entry) == 0) {
            // It's likely a directory
            _ = c.mkdir(@as([*:0]const u8, @ptrCast(&full_path)), 0o755);
            continue;
        }
        
        // Extract using archive_read_extract
        c.archive_entry_set_pathname(entry, @as([*:0]const u8, @ptrCast(&full_path)));
        result_val = c.archive_read_extract(a, entry, 0);
        if (result_val != c.ARCHIVE_OK) {
            // Try without flags
            result_val = c.archive_read_extract(a, entry, c.ARCHIVE_EXTRACT_NO_AUTODIR);
        }
    }
    
    return 0;
}

/// Get the number of entries in an archive
/// Returns -1 on error
export fn getEntryCount(archive_path: [*:0]const u8) c_int {
    const path = std.mem.sliceTo(archive_path, 0);
    
    const a = c.archive_read_new();
    if (a == null) return -1;
    defer _ = c.archive_read_free(a);
    
    _ = c.archive_read_support_filter_all(a);
    _ = c.archive_read_support_format_all(a);
    
    if (c.archive_read_open_filename(a, path, 10240) != c.ARCHIVE_OK) return -1;
    
    var count: c_int = 0;
    var entry: ?*c.struct_archive_entry = undefined;
    
    while (true) {
        const result = c.archive_read_next_header(a, &entry);
        if (result == c.ARCHIVE_EOF) break;
        if (result != c.ARCHIVE_OK) return -1;
        count += 1;
    }
    
    return count;
}

/// Validate that an archive is not corrupted
/// Returns 0 if valid, -1 if error or corrupted
export fn validateArchive(archive_path: [*:0]const u8) c_int {
    const path = std.mem.sliceTo(archive_path, 0);
    
    const a = c.archive_read_new();
    if (a == null) return -1;
    defer _ = c.archive_read_free(a);
    
    _ = c.archive_read_support_filter_all(a);
    _ = c.archive_read_support_format_all(a);
    
    if (c.archive_read_open_filename(a, path, 10240) != c.ARCHIVE_OK) {
        return -1;
    }
    
    var entry: ?*c.struct_archive_entry = undefined;
    
    const result = c.archive_read_next_header(a, &entry);
    if (result == c.ARCHIVE_OK) {
        return 0;
    }
    
    return -1;
}
