/**
 * Native archive module wrapper
 * Provides archive extraction safety using Zig N-API module
 */

import { loadArchiveNative, isNativeEnabled, type NativeConfig } from "./index.js";

export interface ArchiveNative {
  createBudget(maxEntryBytes: number, maxExtractedBytes: number): bigint;
  startEntry(budget: bigint): undefined;
  addBytes(budget: bigint, bytes: number): number;
  addEntrySize(budget: bigint, size: number): number;
  freeBudget(budget: bigint): undefined;
  validatePath(path: string): boolean;
  getVersion(): string;
}

/**
 * Get native archive module if enabled
 */
export async function getArchiveNative(cfg: NativeConfig): Promise<ArchiveNative | null> {
  if (!isNativeEnabled(cfg, "archive")) {
    return null;
  }
  return loadArchiveNative() as Promise<ArchiveNative | null>;
}

/**
 * Check if native archive is available
 */
export async function isArchiveNativeAvailable(): Promise<boolean> {
  const mod = await loadArchiveNative();
  return mod !== null;
}
