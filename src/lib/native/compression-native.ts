/**
 * Native compression module wrapper (Zig + libarchive)
 * Used when experimental.useZigModules.modules.compression is enabled
 */
import { loadCompressionNative, isNativeEnabled } from "./index.js";

let compressionMod: ReturnType<typeof loadCompressionNative> | null = null;

async function getCompression() {
  if (!compressionMod) {
    compressionMod = loadCompressionNative();
  }
  return await compressionMod;
}

/**
 * Extract archive using native libarchive (supports tar, zip, tar.gz, etc.)
 */
export async function extractArchiveNative(
  archivePath: string,
  destDir: string
): Promise<number> {
  const mod = await getCompression();
  if (!mod) {
    throw new Error("Compression native module not available");
  }
  return mod.extractArchive(archivePath, destDir);
}

/**
 * Validate archive integrity
 */
export async function validateArchiveNative(archivePath: string): Promise<boolean> {
  const mod = await getCompression();
  if (!mod) {
    return false;
  }
  return mod.validateArchive(archivePath);
}

/**
 * Get number of entries in archive
 */
export async function getEntryCountNative(archivePath: string): Promise<number> {
  const mod = await getCompression();
  if (!mod) {
    return -1;
  }
  return mod.getEntryCount(archivePath);
}

/**
 * Check if compression module is available
 */
export function isCompressionNativeEnabled(): boolean {
  return isNativeEnabled({}, "compression");
}
