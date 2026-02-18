/**
 * Native fs-safe module wrapper
 * Provides path safety checks using Zig N-API module
 */

import { loadFsSafeNative, isNativeEnabled, type NativeConfig } from "./index.js";

export interface FsSafeNative {
  isPathSafe(path: string, root: string): boolean;
  openFile(path: string, noFollow: boolean): number;
  closeFile(fd: number): number;
  getVersion(): string;
}

/**
 * Get native fs-safe module if enabled
 */
export async function getFsSafeNative(cfg: NativeConfig): Promise<FsSafeNative | null> {
  if (!isNativeEnabled(cfg, "fsSafe")) {
    return null;
  }
  return loadFsSafeNative() as Promise<FsSafeNative | null>;
}

/**
 * Check if native fs-safe is available
 */
export async function isFsSafeNativeAvailable(): Promise<boolean> {
  const mod = await loadFsSafeNative();
  return mod !== null;
}
