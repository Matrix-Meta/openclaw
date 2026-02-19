/**
 * Native module loader - conditionally loads Zig/Rust native modules
 * based on experimental config flags.
 */

import path from "node:path";
import { cwd } from "node:process";

// Cache for loaded native modules
let _fsSafe: typeof import("./fs-safe-native.js") | null = null;
let _archive: typeof import("./archive-native.js") | null = null;

/**
 * Get the native module directory - works both in dev and production
 */
function getNativeDir(): string {
  // Look in dist/native/ first (production), then native/ (dev)
  const distNative = path.resolve(cwd(), "dist/native");
  const devNative = path.resolve(cwd(), "native");

  // Check if dist/native exists (synchronous check)
  const fs = require("node:fs");
  if (fs.existsSync(distNative)) {
    return distNative;
  }
  return devNative;
}

/**
 * Load fs-safe native module
 * Returns null if not available or disabled
 */
export async function loadFsSafeNative() {
  if (_fsSafe) {
    return _fsSafe;
  }

  try {
    const nativeDir = getNativeDir();
    const nativePath = path.join(nativeDir, "fs-safe/fs_safe.node");
    const mod = await import(nativePath);
    _fsSafe = mod;
    return mod;
  } catch {
    // Native module not available
    return null;
  }
}

/**
 * Load archive native module
 * Returns null if not available or disabled
 */
export async function loadArchiveNative() {
  if (_archive) {
    return _archive;
  }

  try {
    const nativeDir = getNativeDir();
    const nativePath = path.join(nativeDir, "archive/archive.node");
    const mod = await import(nativePath);
    _archive = mod;
    return mod;
  } catch {
    return null;
  }
}

/**
 * Check if native modules should be used based on config
 * Uses type assertion for compatibility with different config types
 */

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type NativeConfig = any;

export function isNativeEnabled(cfg: NativeConfig, module: "fsSafe" | "archive"): boolean {
  const exp = cfg.experimental?.useZigModules;
  if (!exp?.enabled) {
    return false;
  }
  return exp.modules?.[module] ?? false;
}
