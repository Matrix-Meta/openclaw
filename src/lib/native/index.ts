/**
 * Native module loader - conditionally loads Zig/Rust native modules
 * based on experimental config flags.
 */

import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Cache for loaded native modules
let _fsSafe: typeof import("./fs-safe-native.js") | null = null;
let _archive: typeof import("./archive-native.js") | null = null;

/**
 * Load fs-safe native module
 * Returns null if not available or disabled
 */
export async function loadFsSafeNative() {
  if (_fsSafe) {
    return _fsSafe;
  }

  try {
    // Try to load from relative path to native modules
    const nativePath = path.resolve(__dirname, "../../native/fs-safe/fs_safe.node");
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
    const nativePath = path.resolve(__dirname, "../../native/archive/archive.node");
    const mod = await import(nativePath);
    _archive = mod;
    return mod;
  } catch {
    return null;
  }
}

/**
 * Check if native modules should be used based on config
 */
export interface NativeConfig {
  experimental?: {
    useZigModules?: {
      enabled?: boolean;
      modules?: {
        fsSafe?: boolean;
        archive?: boolean;
      };
    };
  };
}

export function isNativeEnabled(cfg: NativeConfig, module: "fsSafe" | "archive"): boolean {
  const exp = cfg.experimental?.useZigModules;
  if (!exp?.enabled) {
    return false;
  }
  return exp.modules?.[module] ?? false;
}
