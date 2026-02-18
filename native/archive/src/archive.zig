const std = @import("std");

/// Maximum number of budget trackers we can have
const MAX_BUDGETS = 128;

/// Budget tracker state
pub const BudgetState = struct {
    entry_bytes: u64 = 0,
    extracted_bytes: u64 = 0,
    max_entry_bytes: u64,
    max_extracted_bytes: u64,
    in_use: bool = true,
};

/// Global budget storage
var budgets: [MAX_BUDGETS]BudgetState = undefined;
var budget_init = false;

fn initBudgets() void {
    if (!budget_init) {
        for (&budgets) |*b| {
            b.* = BudgetState{ .max_entry_bytes = 0, .max_extracted_bytes = 0, .in_use = false };
        }
        budget_init = true;
    }
}

/// Create a new budget tracker - returns index or -1 on error
export fn createByteBudget(max_entry_bytes: u64, max_extracted_bytes: u64) i32 {
    initBudgets();
    
    for (0..MAX_BUDGETS) |i| {
        if (!budgets[i].in_use) {
            budgets[i] = BudgetState{
                .max_entry_bytes = max_entry_bytes,
                .max_extracted_bytes = max_extracted_bytes,
                .in_use = true,
            };
            return @intCast(i);
        }
    }
    return -1;
}

/// Start processing a new entry
export fn startEntry(budget_idx: i32) void {
    if (budget_idx < 0) return;
    const idx = @as(usize, @intCast(budget_idx));
    if (idx >= MAX_BUDGETS) return;
    if (!budgets[idx].in_use) return;
    budgets[idx].entry_bytes = 0;
}

/// Add bytes to the budget - returns 0 on success, -1 on error
export fn addBytes(budget_idx: i32, bytes: u64) i32 {
    if (budget_idx < 0) return -1;
    const idx = @as(usize, @intCast(budget_idx));
    if (idx >= MAX_BUDGETS) return -1;
    var b = &budgets[idx];
    if (!b.in_use) return -1;
    
    if (bytes == 0) return 0;
    
    b.entry_bytes += bytes;
    if (b.entry_bytes > b.max_entry_bytes) {
        return -1; // Entry size exceeded
    }
    
    b.extracted_bytes += bytes;
    if (b.extracted_bytes > b.max_extracted_bytes) {
        return -1; // Extracted size exceeded
    }
    
    return 0;
}

/// Add entry size - returns 0 on success, -1 on error  
export fn addEntrySize(budget_idx: i32, size: u64) i32 {
    if (budget_idx < 0) return -1;
    const idx = @as(usize, @intCast(budget_idx));
    if (idx >= MAX_BUDGETS) return -1;
    var b = &budgets[idx];
    if (!b.in_use) return -1;
    
    if (size > b.max_entry_bytes) {
        return -1;
    }
    b.entry_bytes += size;
    b.extracted_bytes += size;
    if (b.extracted_bytes > b.max_extracted_bytes) {
        return -1;
    }
    return 0;
}

/// Free budget tracker
export fn freeBudget(budget_idx: i32) void {
    if (budget_idx < 0) return;
    const idx = @as(usize, @intCast(budget_idx));
    if (idx >= MAX_BUDGETS) return;
    budgets[idx].in_use = false;
}

/// Validate archive entry path - check for path traversal
/// Returns 1 if safe, 0 if dangerous
export fn validateEntryPath(path: [*:0]const u8) i32 {
    const p = std.mem.sliceTo(path, 0);
    
    // Check for absolute path
    if (p.len > 0 and p[0] == '/') {
        return 0;
    }
    
    // Check for parent directory traversal
    var i: usize = 0;
    while (i < p.len) : (i += 1) {
        if (i + 1 < p.len and p[i] == '.' and p[i+1] == '.') {
            if (i + 2 >= p.len or p[i+2] == '/') {
                return 0;
            }
        }
    }
    
    return 1;
}
